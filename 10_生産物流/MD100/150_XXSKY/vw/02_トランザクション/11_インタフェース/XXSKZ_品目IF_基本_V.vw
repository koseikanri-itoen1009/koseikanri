/*************************************************************************
 * 
 * View  Name      : XXSKZ_品目IF_基本_V
 * Description     : XXSKZ_品目IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_品目IF_基本_V
(
SEQ番号
,更新区分
,更新区分名
,品目コード
,品目名
,品名略称
,品名カナ名
,旧_群コード
,新_群コード
,群コード_適用開始日
,政策群コード
,マーケ用群コード
,旧_定価
,新_定価
,定価_適用開始日
,旧_標準原価
,新_標準原価
,標準原価_適用開始日
,旧_営業原価
,新_営業原価
,営業原価_適用開始日
,旧_消費税率
,新_消費税率
,消費税率_適用開始日
,率区分
,率区分名
,ケース入数
,商品製品区分
,商品製品区分名
,NET
,重量_体積
,商品区分
,商品区分名
,バラ茶区分
,バラ茶区分名
,親品名コード
,親品名コード名
,親品名コード略称
,売上対象区分
,売上対象区分名
,JANコード
,発売製造開始日
,廃止区分
,廃止区分名
,廃止_製造中止日
,原料使用量
,原料
,再製費
,資材費
,包装費
,外注管理費
,保管費
,その他経費
,予備
,予備１
,予備２
,予備３
)
AS
SELECT
 XII.seq_number                      --SEQ番号
,XII.proc_code                       --更新区分
,CASE XII.proc_code                  --更新区分名
    WHEN 1 THEN '登録'
    WHEN 2 THEN '更新'
    WHEN 3 THEN '削除'
 END                                 --更新区分名
,XII.item_code                       --品目コード
,XII.item_name                       --品目名
,XII.item_short_name                 --品名略称
,XII.item_name_alt                   --品名カナ名
,XII.old_crowd_code                  --旧_群コード
,XII.new_crowd_code                  --新_群コード
,XII.crowd_start_date                --群コード_適用開始日
,XII.policy_group_code               --政策群コード
,XII.marke_crowd_code                --マーケ用群コード
,NVL( TO_NUMBER( XII.old_price ), 0 )
                                     --旧_定価
,NVL( TO_NUMBER( XII.new_price ), 0 )
                                     --新_定価
,XII.price_start_date                --定価_適用開始日
,NVL( TO_NUMBER( XII.old_standard_cost ), 0 )
                                     --旧_標準原価
,NVL( TO_NUMBER( XII.new_standard_cost ), 0 )
                                     --新_標準原価
,XII.standard_start_date             --標準原価_適用開始日
,NVL( TO_NUMBER( XII.old_business_cost ), 0 )
                                     --旧_営業原価
,NVL( TO_NUMBER( XII.new_business_cost ), 0 )
                                     --新_営業原価
,XII.business_start_date             --営業原価_適用開始日
,NVL( TO_NUMBER( XII.old_tax ), 0 )  --旧_消費税率
,NVL( TO_NUMBER( XII.new_tax ), 0 )  --新_消費税率
,XII.tax_start_date                  --消費税率_適用開始日
,XII.rate_code                       --率区分
,FLV_RIT.meaning                     --率区分名
,NVL( TO_NUMBER( XII.case_num ), 0 ) --ケース入数
,XII.product_div_code                --商品製品区分
,FLV_SSK.meaning                     --商品製品区分名
,NVL( TO_NUMBER( XII.net ), 0 )      --NET
,NVL( TO_NUMBER( XII.weight_volume ), 0 )
                                     --重量_体積
,XII.arti_div_code                   --商品区分
,FLV_SK.meaning                      --商品区分名
,XII.div_tea_code                    --バラ茶区分
,FLV_BAR.meaning                     --バラ茶区分名
,XII.parent_item_code                --親品名コード
,XIMV.item_name                      --親品名コード名
,XIMV.item_short_name                --親品名コード略称
,XII.sale_obj_code                   --売上対象区分
,FLV_URI.meaning                     --売上対象区分名
,XII.jan_code                        --JANコード
,XII.sale_start_date                 --発売製造開始日
,XII.abolition_code                  --廃止区分
,CASE XII.abolition_code             --廃止区分名
    WHEN '0' THEN '取扱中'
    WHEN '1' THEN '廃止'
 END
,XII.abolition_date                  --廃止_製造中止日
,NVL( TO_NUMBER( XII.raw_mate_consumption ), 0 )
                                     --原料使用量
,NVL( TO_NUMBER( XII.raw_material_cost ), 0 )
                                     --原料
,NVL( TO_NUMBER( XII.agein_cost ), 0 )
                                     --再製費
,NVL( TO_NUMBER( XII.material_cost ), 0 )
                                     --資材費
,NVL( TO_NUMBER( XII.pack_cost ), 0 )
                                     --包装費
,NVL( TO_NUMBER( XII.out_order_cost ), 0 )
                                     --外注管理費
,NVL( TO_NUMBER( XII.safekeep_cost ), 0 )
                                     --保管費
,NVL( TO_NUMBER( XII.other_expense_cost ), 0 )
                                     --その他経費
,NVL( TO_NUMBER( XII.spare ), 0 )
                                     --予備
,NVL( TO_NUMBER( XII.spare1 ), 0 )
                                     --予備１
,NVL( TO_NUMBER( XII.spare2 ), 0 )
                                     --予備２
,NVL( TO_NUMBER( XII.spare3 ), 0 )
                                     --予備３
FROM    xxcmn_item_if       XII      --品目インタフェース_V
       ,xxskz_item_mst2_v   XIMV     --親品目名取得用
       ,fnd_lookup_values   FLV_RIT  --率区分名取得
       ,fnd_lookup_values   FLV_SSK  --商品製品区分名取得
       ,fnd_lookup_values   FLV_SK   --商品区分名取得
       ,fnd_lookup_values   FLV_BAR  --バラ茶区分名取得
       ,fnd_lookup_values   FLV_URI  --売上対象区分名取得
WHERE
    XII.parent_item_code = XIMV.item_no(+)      --親品目名取得用結合
AND XIMV.start_date_active(+) <= NVL(XII.sale_start_date,SYSDATE)
AND XIMV.end_date_active(+)   >= NVL(XII.sale_start_date,SYSDATE)
AND FLV_RIT.language(+) = 'JA'                  --率区分名取得用結合
AND FLV_RIT.lookup_type(+) = 'XXCMN_RATE'
AND FLV_RIT.lookup_code(+) = XII.rate_code
AND FLV_SSK.language(+) = 'JA'                  --商品製品区分名取得用結合
AND FLV_SSK.lookup_type(+) = 'XXCMN_PRODUCT_OR_NOT'
AND FLV_SSK.lookup_code(+) = XII.product_div_code
AND FLV_SK.language(+) = 'JA'                   --商品区分名取得用結合
AND FLV_SK.lookup_type(+) = 'XXWIP_ITEM_TYPE'
AND FLV_SK.lookup_code(+) = XII.arti_div_code
AND FLV_BAR.language(+) = 'JA'                  --バラ茶区分名取得用結合
AND FLV_BAR.lookup_type(+) = 'XXCMN_BARACHA'
AND FLV_BAR.lookup_code(+) = XII.div_tea_code
AND FLV_URI.language(+) = 'JA'                  --売上対象区分名取得用結合
AND FLV_URI.lookup_type(+) = 'XXCMN_SALES_TARGET_CLASS'
AND FLV_URI.lookup_code(+) = XII.sale_obj_code
/
COMMENT ON TABLE APPS.XXSKZ_品目IF_基本_V IS 'XXSKZ_品目IF (基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.SEQ番号               IS 'SEQ番号'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.更新区分              IS '更新区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.更新区分名            IS '更新区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.品目コード            IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.品目名                IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.品名略称              IS '品名略称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.品名カナ名            IS '品名カナ名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.旧_群コード           IS '旧_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.新_群コード           IS '新_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.群コード_適用開始日   IS '群コード_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.政策群コード          IS '政策群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.マーケ用群コード      IS 'マーケ用群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.旧_定価               IS '旧_定価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.新_定価               IS '新_定価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.定価_適用開始日       IS '定価_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.旧_標準原価           IS '旧_標準原価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.新_標準原価           IS '新_標準原価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.標準原価_適用開始日   IS '標準原価_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.旧_営業原価           IS '旧_営業原価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.新_営業原価           IS '新_営業原価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.営業原価_適用開始日   IS '営業原価_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.旧_消費税率           IS '旧_消費税率'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.新_消費税率           IS '新_消費税率'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.消費税率_適用開始日   IS '消費税率_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.率区分                IS '率区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.率区分名              IS '率区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.ケース入数            IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.商品製品区分          IS '商品製品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.商品製品区分名        IS '商品製品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.NET                   IS 'NET'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.重量_体積             IS '重量_体積'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.商品区分              IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.商品区分名            IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.バラ茶区分            IS 'バラ茶区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.バラ茶区分名          IS 'バラ茶区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.親品名コード          IS '親品名コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.親品名コード名        IS '親品名コード名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.親品名コード略称      IS '親品名コード略称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.売上対象区分          IS '売上対象区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.売上対象区分名        IS '売上対象区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.JANコード             IS 'JANコード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.発売製造開始日        IS '発売製造開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.廃止区分              IS '廃止区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.廃止区分名            IS '廃止区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.廃止_製造中止日       IS '廃止_製造中止日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.原料使用量            IS '原料使用量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.原料                  IS '原料'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.再製費                IS '再製費'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.資材費                IS '資材費'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.包装費                IS '包装費'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.外注管理費            IS '外注管理費'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.保管費                IS '保管費'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.その他経費            IS 'その他経費'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.予備                  IS '予備'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.予備１                IS '予備１'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.予備２                IS '予備２'
/
COMMENT ON COLUMN APPS.XXSKZ_品目IF_基本_V.予備３                IS '予備３'
/
