{{ config(
	tags=['legacy'],
	
        alias = alias('flashloans', legacy_model=True),
        post_hook='{{ expose_spells(\'["ethereum","arbitrum", "optimism", "polygon", "gnosis"]\',
                                "project",
                                "balancer",
                                \'["hildobby"]\') }}'
        )
}}

{% set balancer_models = [
ref('balancer_v2_ethereum_flashloans_legacy')
, ref('balancer_v2_optimism_flashloans_legacy')
, ref('balancer_v2_arbitrum_flashloans_legacy')
, ref('balancer_v2_polygon_flashloans_legacy')
, ref('balancer_v2_gnosis_flashloans_legacy')
] %}


SELECT *
FROM (
    {% for flash_model in balancer_models %}
    SELECT
        blockchain,
        project,
        version,
        block_time,
        amount,
        amount_usd,
        tx_hash,
        evt_index,
        fee,
        currency_contract,
        currency_symbol,
        contract_address
    FROM {{ flash_model }}
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
)
;