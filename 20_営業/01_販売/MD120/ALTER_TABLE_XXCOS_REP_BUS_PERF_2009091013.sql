ALTER TABLE XXCOS.XXCOS_REP_BUS_PERF MODIFY
  (
    NORMA                           NUMBER,                     --当月ノルマ
    ACTUAL_DATE_QUANTITY            NUMBER,                     --実働日数
    COURSE_DATE_QUANTITY            NUMBER,                     --経過日数
    SALE_SHOP_DATE_TOTAL            NUMBER,                     --純売上量販店日計
    SALE_SHOP_TOTAL                 NUMBER,                     --純売上量販店累計
    RTN_SHOP_DATE_TOTAL             NUMBER,                     --返品量販店日計
    RTN_SHOP_TOTAL                  NUMBER,                     --返品量販店累計
    DISCOUNT_SHOP_DATE_TOTAL        NUMBER,                     --値引量販店日計
    DISCOUNT_SHOP_TOTAL             NUMBER,                     --値引量販店累計
    SUP_SAM_SHOP_DATE_TOTAL         NUMBER,                     --協賛見本量販店日計
    SUP_SAM_SHOP_TOTAL              NUMBER,                     --協賛見本量販店累計
    KEEP_SHOP_QUANTITY              NUMBER,                     --持軒数量販店
    SALE_CVS_DATE_TOTAL             NUMBER,                     --純売上CVS日計
    SALE_CVS_TOTAL                  NUMBER,                     --純売上CVS累計
    RTN_CVS_DATE_TOTAL              NUMBER,                     --返品CVS日計
    RTN_CVS_TOTAL                   NUMBER,                     --返品CVS累計
    DISCOUNT_CVS_DATE_TOTAL         NUMBER,                     --値引CVS日計
    DISCOUNT_CVS_TOTAL              NUMBER,                     --値引CVS累計
    SUP_SAM_CVS_DATE_TOTAL          NUMBER,                     --協賛見本CVS日計
    SUP_SAM_CVS_TOTAL               NUMBER,                     --協賛見本CVS累計
    KEEP_SHOP_CVS                   NUMBER,                     --持軒数CVS
    SALE_WHOLESALE_DATE_TOTAL       NUMBER,                     --純売上問屋日計
    SALE_WHOLESALE_TOTAL            NUMBER,                     --純売上問屋累計
    RTN_WHOLESALE_DATE_TOTAL        NUMBER,                     --返品問屋日計
    RTN_WHOLESALE_TOTAL             NUMBER,                     --返品問屋累計
    DISCOUNT_WHOL_DATE_TOTAL        NUMBER,                     --値引問屋日計
    DISCOUNT_WHOL_TOTAL             NUMBER,                     --値引問屋累計
    SUP_SAM_WHOL_DATE_TOTAL         NUMBER,                     --協賛見本問屋日計
    SUP_SAM_WHOL_TOTAL              NUMBER,                     --協賛見本問屋累計
    KEEP_SHOP_WHOLESALE             NUMBER,                     --持軒数問屋
    SALE_OTHERS_DATE_TOTAL          NUMBER,                     --純売上その他日計
    SALE_OTHERS_TOTAL               NUMBER,                     --純売上その他累計
    RTN_OTHERS_DATE_TOTAL           NUMBER,                     --返品その他日計
    RTN_OTHERS_TOTAL                NUMBER,                     --返品その他累計
    DISCOUNT_OTHERS_DATE_TOTAL      NUMBER,                     --値引その他日計
    DISCOUNT_OTHERS_TOTAL           NUMBER,                     --値引その他累計
    SUP_SAM_OTHERS_DATE_TOTAL       NUMBER,                     --協賛見本その他日計
    SUP_SAM_OTHERS_TOTAL            NUMBER,                     --協賛見本その他累計
    KEEP_SHOP_OTHERS                NUMBER,                     --持軒数その他
    SALE_VD_DATE_TOTAL              NUMBER,                     --純売上VD日計
    SALE_VD_TOTAL                   NUMBER,                     --純売上VD累計
    RTN_VD_DATE_TOTAL               NUMBER,                     --返品VD日計
    RTN_VD_TOTAL                    NUMBER,                     --返品VD累計
    DISCOUNT_VD_DATE_TOTAL          NUMBER,                     --値引VD日計
    DISCOUNT_VD_TOTAL               NUMBER,                     --値引VD累計
    SUP_SAM_VD_DATE_TOTAL           NUMBER,                     --協賛見本VD日計
    SUP_SAM_VD_TOTAL                NUMBER,                     --協賛見本VD累計
    KEEP_SHOP_VD                    NUMBER,                     --持軒数VD
    SALE_BUSINESS_CAR               NUMBER,                     --純売上営業車
    RTN_BUSINESS_CAR                NUMBER,                     --返品営業車
    DISCOUNT_BUSINESS_CAR           NUMBER,                     --値引営業車
    SUP_SAM_BUSINESS_CAR            NUMBER,                     --協賛見本営業車
    DROP_SHIP_FACT_SEND_DIRECTLY    NUMBER,                     --純売上工場直送
    RTN_FACTORY_SEND_DIRECTLY       NUMBER,                     --返品工場直送
    DISCOUNT_FACT_SEND_DIRECTLY     NUMBER,                     --値引工場直送
    SUP_FACT_SEND_DIRECTLY          NUMBER,                     --協賛見本工場直送
    SALE_MAIN_WHSE                  NUMBER,                     --純売上メイン倉庫
    RTN_MAIN_WHSE                   NUMBER,                     --返品メイン倉庫
    DISCOUNT_MAIN_WHSE              NUMBER,                     --値引メイン倉庫
    SUP_SAM_MAIN_WHSE               NUMBER,                     --協賛見本メイン倉庫
    SALE_OTHERS_WHSE                NUMBER,                     --純売上その他倉庫
    RTN_OTHERS_WHSE                 NUMBER,                     --返品その他倉庫
    DISCOUNT_OTHERS_WHSE            NUMBER,                     --値引その他倉庫
    SUP_SAM_OTHERS_WHSE             NUMBER,                     --協賛見本その他倉庫
    SALE_OTHERS_BASE_WHSE_SALE      NUMBER,                     --純売上他拠点倉庫売上
    RTN_OTHERS_BASE_WHSE_SALE       NUMBER,                     --返品他拠点倉庫売上
    DISCOUNT_OTH_BASE_WHSE_SALE     NUMBER,                     --値引他拠点倉庫売上
    SUP_SAM_OTH_BASE_WHSE_SALE      NUMBER,                     --協賛見本他拠点倉庫売上
    SALE_ACTUAL_TRANSFER            NUMBER,                     --純売上実績振替
    RTN_ACTUAL_TRANSFER             NUMBER,                     --返品実績振替
    DISCOUNT_ACTUAL_TRANSFER        NUMBER,                     --値引実績振替
    SUP_SAM_ACTUAL_TRANSFER         NUMBER,                     --協賛見本実績振替
    SPRCIAL_SALE                    NUMBER,                     --純売上特売売上
    RTN_ASPRCIAL_SALE               NUMBER,                     --返品特売売上
    SALE_NEW_CONTRIBUTION_SALE      NUMBER,                     --純売上新規貢献売上
    RTN_NEW_CONTRIBUTION_SALE       NUMBER,                     --返品新規貢献売上
    DISCOUNT_NEW_CONTR_SALE         NUMBER,                     --値引新規貢献売上
    SUP_SAM_NEW_CONTR_SALE          NUMBER,                     --協賛見本新規貢献売上
    COUNT_YET_VISIT_PARTY           NUMBER,                     --件数未訪問客
    COUNT_YET_DEALINGS_PARTY        NUMBER,                     --件数未取引客
    COUNT_DELAY_VISIT_COUNT         NUMBER,                     --件数延訪問件数
    COUNT_DELAY_VALID_COUNT         NUMBER,                     --件数延有効件数
    COUNT_VALID_COUNT               NUMBER,                     --件数実有効件数
    COUNT_NEW_COUNT                 NUMBER,                     --件数新規件数
    COUNT_NEW_VENDOR_COUNT          NUMBER,                     --件数新規ベンダー件数
    COUNT_NEW_POINT                 NUMBER(13,2),               --件数新規ポイント
    COUNT_MC_PARTY                  NUMBER,                     --件数MC訪問
    SALE_AMOUNT                     NUMBER,                     --売上金額
    BUSINESS_COST                   NUMBER                      --営業原価
  );