/*************************************************************************
 * 
 * View  Name      : XXSKZ_倉替返品IF_基本_V
 * Description     : XXSKZ_倉替返品IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_倉替返品IF_基本_V
(
 データ種別
,RNO
,計上年月
,入力拠点コード
,入力拠点名
,相手拠点コード
,相手拠点名
,伝区
,伝区名
,計上日付_着日
,配送先コード
,配送先名
,顧客コード
,顧客名
,伝票NO
,品目コード
,品目名
,品目略称
,親品目コード
,親品目名
,親品目略称
,群コード
,ケース数
,入数
,バラ_本数
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
         XRI.data_class                         --データ種別
        ,XRI.r_no                               --Rno
        ,XRI.recorded_year                      --計上年月
        ,XRI.input_base_code                    --入力拠点コード
        ,XCA2V01.party_name                     --入力拠点名
        ,XRI.receive_base_code                  --相手拠点コード
        ,XCA2V02.party_name                     --相手拠点名
        ,XRI.invoice_class_1                    --伝区
        ,FLV01.meaning                          --伝区名
        ,XRI.recorded_date                      --計上日付_着日
        ,XRI.ship_to_code                       --配送先コード
        ,XPS2V.party_site_name                  --配送先名
        ,XRI.customer_code                      --顧客コード
        ,XCA2V03.party_name                     --顧客名
        ,XRI.invoice_no                         --伝票No
        ,XRI.item_code                          --品目コード
        ,XIM2V01.item_name                      --品目名
        ,XIM2V01.item_short_name                --品目略称
        ,XRI.parent_item_code                   --親品目コード
        ,XIM2V02.item_name                      --親品目名
        ,XIM2V02.item_short_name                --親品目略称
        ,XRI.crowd_code                         --群コード
        ,XRI.case_amount_of_content             --ケース数
        ,XRI.quantity_in_case                   --入数
        ,XRI.quantity                           --バラ_本数
        ,FU_CB.user_name                        --作成者
        ,TO_CHAR( XRI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --作成日
        ,FU_LU.user_name                        --最終更新者
        ,TO_CHAR( XRI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --最終更新日
        ,FU_LL.user_name                        --最終更新ログイン
FROM
         xxwsh_reserve_interface    XRI         --倉替返品インタフェーステーブル(アドオン)
        ,fnd_lookup_values          FLV01       --クイックコード表(伝区名)
        ,xxskz_party_sites2_v       XPS2V       --SKYLINK用中間VIEW 配送先情報VIEW2(配送先名)
        ,xxskz_cust_accounts2_v     XCA2V01     --SKYLINK用中間VIEW 顧客情報VIEW2(入力拠点名)
        ,xxskz_cust_accounts2_v     XCA2V02     --SKYLINK用中間VIEW 顧客情報VIEW2(相手拠点名)
        ,xxskz_cust_accounts2_v     XCA2V03     --SKYLINK用中間VIEW 顧客情報VIEW2(顧客名)
        ,xxskz_item_mst2_v          XIM2V01     --SKYLINK用中間VIEW OPM品目情報VIEW2(品目名、品目略称)
        ,xxskz_item_mst2_v          XIM2V02     --SKYLINK用中間VIEW OPM品目情報VIEW2(親品目名、親品目略称)
        ,fnd_user                   FU_CB       --ユーザーマスタ(CREATED_BY名称取得用)
        ,fnd_user                   FU_LU       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
        ,fnd_user                   FU_LL       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_logins                 FL_LL       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
        -- 入力拠点名
        XCA2V01.party_number(+)         = XRI.input_base_code
   AND  XCA2V01.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XCA2V01.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- 相手拠点名
   AND  XCA2V02.party_number(+)         = XRI.receive_base_code
   AND  XCA2V02.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XCA2V02.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- 伝区名
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWSH_SHIPPING_CLASS'
   AND  FLV01.lookup_code(+)            = XRI.invoice_class_1
        -- 配送先名
   AND  XRI.ship_to_code                = XPS2V.party_site_number(+)
   AND  XPS2V.start_date_active(+)      <= NVL( XRI.recorded_date, SYSDATE )
   AND  XPS2V.end_date_active(+)        >= NVL( XRI.recorded_date, SYSDATE )
        -- 顧客名
   AND  XCA2V03.party_number(+)         = XRI.customer_code
   AND  XCA2V03.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XCA2V03.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- 品目名、品目略称
   AND  XIM2V01.item_no(+)              = XRI.item_code
   AND  XIM2V01.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XIM2V01.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- 親品目名、親品目略称
   AND  XIM2V02.item_no(+)              = XRI.parent_item_code
   AND  XIM2V02.start_date_active(+)    <= NVL( XRI.recorded_date, SYSDATE )
   AND  XIM2V02.end_date_active(+)      >= NVL( XRI.recorded_date, SYSDATE )
        -- ユーザ名など
   AND  XRI.created_by                  = FU_CB.user_id(+)
   AND  XRI.last_updated_by             = FU_LU.user_id(+)
   AND  XRI.last_update_login           = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_倉替返品IF_基本_V IS 'SKYLINK用倉替返品インターフェース（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.データ種別       IS 'データ種別'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.RNO              IS 'Rno'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.計上年月         IS '計上年月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.入力拠点コード   IS '入力拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.入力拠点名       IS '入力拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.相手拠点コード   IS '相手拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.相手拠点名       IS '相手拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.伝区             IS '伝区'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.伝区名           IS '伝区名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.計上日付_着日    IS '計上日付_着日'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.配送先コード     IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.配送先名         IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.顧客コード       IS '顧客コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.顧客名           IS '顧客名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.伝票NO           IS '伝票No'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.品目コード       IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.品目名           IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.品目略称         IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.親品目コード     IS '親品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.親品目名         IS '親品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.親品目略称       IS '親品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.群コード         IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.ケース数         IS 'ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.入数             IS '入数'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.バラ_本数        IS 'バラ_本数'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.作成者           IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.作成日           IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.最終更新者       IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.最終更新日       IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品IF_基本_V.最終更新ログイン IS '最終更新ログイン'
/
