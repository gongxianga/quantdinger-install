"""
QuantDinger 全市场交易对自动同步脚本
=====================================
功能：从 Binance 拉取所有 USDT 永续合约交易对，自动更新到指定截面策略。

依赖：pip install requests ccxt
用法：python update_symbols.py
"""

import sys
import json
import requests

# ===================== 配置区 =====================
QD_URL      = "http://localhost:8888"   # QuantDinger 地址
QD_USER     = "quantdinger"             # 登录账号
QD_PASS     = "123456"                  # 登录密码（如已改请修改这里）
STRATEGY_ID = None                      # 填写策略ID，留空则列出所有策略让你选
MARKET_TYPE = "swap"                    # swap=永续合约 / spot=现货
QUOTE       = "USDT"                    # 只保留 USDT 计价的交易对
MIN_VOLUME  = 1_000_000                 # 过滤24h成交量（USD），低于此值的排除
# ==================================================


def login(url, user, pwd):
    resp = requests.post(f"{url}/api/auth/login",
                         json={"username": user, "password": pwd}, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    token = data.get("data", {}).get("access_token") or data.get("access_token")
    if not token:
        print("[ERROR] 登录失败，请检查账号密码")
        print(resp.text)
        sys.exit(1)
    print(f"[OK] 登录成功")
    return token


def get_strategies(url, token):
    resp = requests.get(f"{url}/api/agent/v1/strategies",
                        headers={"Authorization": f"Bearer {token}"}, timeout=10)
    resp.raise_for_status()
    return resp.json().get("data", [])


def fetch_binance_symbols(market_type, quote, min_volume):
    try:
        import ccxt
    except ImportError:
        print("[ERROR] 缺少 ccxt，请先运行：pip install ccxt")
        sys.exit(1)

    print(f"[INFO] 正在从 Binance 拉取所有 {quote} {market_type} 交易对...")
    if market_type == "swap":
        exchange = ccxt.binance({"options": {"defaultType": "future"}})
    else:
        exchange = ccxt.binance()

    markets = exchange.load_markets()

    symbols = []
    for sym, info in markets.items():
        if not sym.endswith(f"/{quote}"):
            continue
        if market_type == "swap" and info.get("type") not in ("swap", "future"):
            continue
        if market_type == "spot" and info.get("type") != "spot":
            continue
        if not info.get("active", True):
            continue

        # 成交量过滤
        try:
            ticker = exchange.fetch_ticker(sym)
            vol = ticker.get("quoteVolume") or 0
            if vol < min_volume:
                continue
        except Exception:
            pass  # 拉不到 ticker 就保留

        symbols.append(f"Crypto:{sym}")

    print(f"[OK] 共找到 {len(symbols)} 个交易对")
    return symbols


def fetch_all_symbols_simple(market_type, quote):
    """不做成交量过滤的快速版本（不需要逐个请求ticker）"""
    try:
        import ccxt
    except ImportError:
        print("[ERROR] 缺少 ccxt，请先运行：pip install ccxt")
        sys.exit(1)

    print(f"[INFO] 正在从 Binance 拉取所有 {quote} {market_type} 交易对（快速模式）...")
    if market_type == "swap":
        exchange = ccxt.binance({"options": {"defaultType": "future"}})
    else:
        exchange = ccxt.binance()

    markets = exchange.load_markets()

    symbols = []
    for sym, info in markets.items():
        if not sym.endswith(f"/{quote}"):
            continue
        if market_type == "swap" and info.get("type") not in ("swap", "future"):
            continue
        if market_type == "spot" and info.get("type") != "spot":
            continue
        if not info.get("active", True):
            continue
        symbols.append(f"Crypto:{sym}")

    # 排除稳定币对
    stables = {"USDC", "BUSD", "TUSD", "USDP", "DAI", "FDUSD"}
    symbols = [s for s in symbols if s.split(":")[1].split("/")[0] not in stables]

    symbols.sort()
    print(f"[OK] 共找到 {len(symbols)} 个交易对")
    return symbols


def update_strategy(url, token, strategy_id, symbol_list):
    resp = requests.patch(
        f"{url}/api/agent/v1/strategies/{strategy_id}",
        headers={"Authorization": f"Bearer {token}",
                 "Content-Type": "application/json"},
        json={"trading_config": {"symbol_list": symbol_list}},
        timeout=15
    )
    resp.raise_for_status()
    return resp.json()


def main():
    # 1. 登录
    token = login(QD_URL, QD_USER, QD_PASS)

    # 2. 获取策略列表，让用户选择
    strategy_id = STRATEGY_ID
    if not strategy_id:
        strategies = get_strategies(QD_URL, token)
        if not strategies:
            print("[ERROR] 未找到任何策略，请先在 QuantDinger 里创建截面策略")
            sys.exit(1)
        print("\n现有策略：")
        for s in strategies:
            print(f"  ID={s.get('id')}  名称={s.get('name')}  类型={s.get('trading_config',{}).get('cs_strategy_type','single')}")
        strategy_id = input("\n请输入要更新的策略 ID: ").strip()

    # 3. 从 Binance 拉取所有交易对（快速模式，不过滤成交量）
    if MIN_VOLUME > 0:
        print("[INFO] 成交量过滤已启用，这会比较慢（需逐个请求ticker）")
        print("      如需快速模式，请将 MIN_VOLUME 设为 0")
        choice = input("使用快速模式（不过滤成交量）？(Y/N，默认Y): ").strip().lower()
        if choice != "n":
            symbols = fetch_all_symbols_simple(MARKET_TYPE, QUOTE)
        else:
            symbols = fetch_binance_symbols(MARKET_TYPE, QUOTE, MIN_VOLUME)
    else:
        symbols = fetch_all_symbols_simple(MARKET_TYPE, QUOTE)

    print(f"\n前10个交易对预览：")
    for s in symbols[:10]:
        print(f"  {s}")
    print(f"  ... 共 {len(symbols)} 个")

    confirm = input(f"\n确认更新策略 {strategy_id}？(Y/N): ").strip().lower()
    if confirm != "y":
        print("已取消")
        sys.exit(0)

    # 4. 更新策略
    result = update_strategy(QD_URL, token, strategy_id, symbols)
    if result.get("code") == 0 or result.get("data"):
        print(f"\n[OK] 策略已更新，共 {len(symbols)} 个交易对")
    else:
        print(f"\n[ERROR] 更新失败：{result}")


if __name__ == "__main__":
    main()
