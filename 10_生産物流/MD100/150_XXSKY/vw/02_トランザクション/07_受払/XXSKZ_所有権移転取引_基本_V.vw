/*******************************************************************************
 * 
 * View  Name      : XXSKZ_所有権移転取引_基本_V
 * Description     : XXSKZ_所有権移転取引_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------      -------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ------------      -------------------------------------
 *  2024/07/04    1.0   ITOEN M.Shiraishi 初回作成
 ******************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_所有権移転取引_基本_V
(
 会社コード
,計上拠点
,取引日
,品目コード
,品目名
,保管場所
,税率
,数量
,購入単価
,購入金額
,取引タイプ名
,伝票番号
,所有権移転取引フラグ
,移動元保管場所
,売上拠点
-- ,元標準原価
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
,要求ID
,アプリケーションID
,プログラムID
,プログラム更新日
)
AS
select
     XIRC.company_code                 -- 会社コード
    ,XIRC.grcp_adj_dept_code           -- 計上拠点
    ,XIRC.transaction_date             -- 取引日
    ,XIRC.item_code                    -- 品目コード
    ,(select xhkv.品目名
        from XXSKZ_品目マスタ_基本_V   xhkv
        where xhkv.品目コード = XIRC.item_code
        AND   XIRC.transaction_date BETWEEN xhkv.適用開始日
                                        AND xhkv.適用終了日
     )                                 -- 品目名
    ,XIRC.subinventory_code            -- 保管場所
    ,XITR.tax                          -- 税率
    ,XIRC.quantity                     -- 数量
    ,XIRC.purchase_unit_price          -- 購入単価
    ,XIRC.purchase_amount              -- 購入金額
    ,XIRC.transaction_type_name        -- 取引タイプ名
    ,XIRC.slip_number                  -- 伝票番号
    ,XIRC.transfer_ownership_flg       -- 所有権移転取引フラグ
    ,XIRC.transfer_subinventory        -- 移動元保管場所
    ,XIRC.sales_base_code              -- 売上拠点
--    ,XIRC.standard_cost                -- 元標準原価
    ,XIRC.created_by                   -- 作成者
    ,XIRC.creation_date                -- 作成日
    ,XIRC.last_updated_by              -- 最終更新者
    ,XIRC.last_update_date             -- 最終更新日
    ,XIRC.last_update_login            -- 最終更新ログイン
    ,XIRC.request_id                   -- 要求ID
    ,XIRC.program_application_id       -- アプリケーションID
    ,XIRC.program_id                   -- プログラムID
    ,XIRC.program_update_date          -- プログラム更新日
from   
     XXCOI.xxcoi_inv_recept_g_company XIRC --グループ会社受払
    ,XXCMM_ITEM_TAX_RATE_V XITR --品目別消費税VIEW
where 1 = 1
    and XIRC.item_code = XITR.item_no
    and XIRC.transaction_date BETWEEN XITR.start_date_active and  XITR.end_date_active
    and XIRC.transfer_ownership_flg = '1' -- 所有権移転取引フラグ
/
COMMENT ON TABLE APPS.XXSKZ_所有権移転取引_基本_V IS 'SKYLINK用所有権移転取引（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.会社コード IS '会社コード'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.計上拠点 IS '計上拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.取引日 IS '取引日'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.保管場所 IS '保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.税率 IS '税率'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.数量 IS '数量'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.購入単価 IS '購入単価'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.購入金額 IS '購入金額'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.取引タイプ名 IS '取引タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.伝票番号 IS '伝票番号'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.所有権移転取引フラグ IS '所有権移転取引フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.移動元保管場所 IS '移動元保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.売上拠点 IS '売上拠点'
/
-- COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.元標準原価 IS '元標準原価'
-- /
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.最終更新ログイン IS '最終更新ログイン'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.要求ID IS '要求ID'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.アプリケーションID IS 'アプリケーションID'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.プログラムID IS 'プログラムID'
/
COMMENT ON COLUMN APPS.XXSKZ_所有権移転取引_基本_V.プログラム更新日 IS 'プログラム更新日'
/
