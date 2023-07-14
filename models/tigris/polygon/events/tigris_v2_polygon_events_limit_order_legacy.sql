{{ config(
	tags=['legacy'],
	
    schema = 'tigris_v2_polygon',
    alias = alias('events_limit_order', legacy_model=True),
    partition_by = ['day'],
    materialized = 'incremental',
    file_format = 'delta',
    incremental_strategy = 'merge',
    unique_key = ['evt_block_time', 'evt_tx_hash', 'position_id']
    )
}}

WITH 

pairs as (
        SELECT 
            * 
        FROM 
        {{ ref('tigris_v2_polygon_events_asset_added_legacy') }}
),

{% set limit_order_trading_evt_tables = [
    'Trading_evt_LimitOrderExecuted',
    'TradingV2_evt_LimitOrderExecuted',
    'TradingV3_evt_LimitOrderExecuted'

] %}

limit_orders AS (
    {% for limit_order_trading_evt in limit_order_trading_evt_tables %}
        SELECT
            '{{ 'v2.' + loop.index | string }}' as version,
            date_trunc('day', t.evt_block_time) as day,
            t.evt_block_time,
            t.evt_index,
            t.evt_tx_hash,
            t.id as position_id,
            t.openPrice/1e18 as price,
            t.margin/1e18 as margin,
            t.lev/1e18 as leverage,
            t.margin/1e18 * t.lev/1e18 as volume_usd,
            '' as margin_asset,
            ta.pair,
            CASE WHEN t.direction = true THEN 'true' ELSE 'false' END as direction,
            '' as referral,
            t.trader as trader
        FROM {{ source('tigristrade_v2_polygon', limit_order_trading_evt) }} t
        INNER JOIN pairs ta
            ON t.asset = ta.asset_id
        {% if is_incremental() %}
        WHERE t.evt_block_time >= date_trunc("day", now() - interval '1 week')
        {% endif %}
        {% if not loop.last %}
        UNION ALL
        {% endif %}
    {% endfor %}
)

SELECT *
FROM limit_orders
;