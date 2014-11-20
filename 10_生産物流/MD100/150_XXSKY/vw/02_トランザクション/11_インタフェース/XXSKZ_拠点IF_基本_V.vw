/*************************************************************************
 * 
 * View  Name      : XXSKZ_拠点IF_基本_V
 * Description     : XXSKZ_拠点IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_拠点IF_基本_V
(
 SEQ番号
,更新区分
,更新区分名
,拠点コード
,拠点名
,拠点略称
,拠点カナ名
,住所
,郵便番号
,郵便番号２
,電話番号
,FAX番号
,旧_本部コード
,新_本部コード
,本部_適用開始日
,拠点実績有無区分
,拠点実績有無区分名
,出庫管理元区分
,出庫管理元区分名
,本部_地区名
,倉替対象可否区分
,倉替対象可否区分名
,端末有無区分
,端末有無区分名
,予備
)
AS
SELECT 
        XPI.seq_number                      --SEQ番号
       ,XPI.proc_code                       --更新区分
       ,CASE XPI.proc_code                  --更新区分名
            WHEN    1   THEN    '登録'
            WHEN    2   THEN    '更新'
            WHEN    3   THEN    '削除'
        END                     proc_name
       ,XPI.base_code                       --拠点コード
       ,XPI.party_name                      --拠点名
       ,XPI.party_short_name                --拠点略称
       ,XPI.party_name_alt                  --拠点カナ名
       ,XPI.address                         --住所
       ,XPI.ZIP                             --郵便番号
       ,XPI.ZIP2                            --郵便番号２
       ,XPI.phone                           --電話番号
       ,XPI.fax                             --FAX番号
       ,XPI.old_division_code               --旧_本部コード
       ,XPI.new_division_code               --新_本部コード
       ,XPI.division_start_date             --本部_適用開始日
       ,XPI.location_rel_code               --拠点実績有無区分
       ,FLV01.meaning                       --拠点実績有無区分名
       ,XPI.ship_mng_code                   --出庫管理元区分
       ,FLV02.meaning                       --出庫管理元区分名
       ,XPI.district_code                   --本部_地区名
       ,XPI.warehouse_code                  --倉替対象可否区分
       ,FLV03.meaning                       --倉替対象可否区分名
       ,XPI.terminal_code                   --端末有無区分
       ,CASE XPI.terminal_code              --端末有無区分名
            WHEN    '0' THEN    '無'
            WHEN    '1' THEN    '有'
        END                 terminal_name
       ,XPI.spare                           --予備
  FROM  xxcmn_party_if      XPI             --拠点インタフェース
       ,fnd_lookup_values   FLV01           --拠点実績有無区分名取得用
       ,fnd_lookup_values   FLV02           --出庫管理元区分名取得用
       ,fnd_lookup_values   FLV03           --倉替対象可否区分名取得用
 WHERE
   --拠点実績有無区分名取得条件
        FLV01.language(+)       = 'JA'
   AND  FLV01.lookup_type(+)    = 'XXCMN_BASE_RESULTS_CLASS'
   AND  FLV01.lookup_code(+)    = XPI.location_rel_code
   --出庫管理元区分名取得条件
   AND  FLV02.language(+)       = 'JA'
   AND  FLV02.lookup_type(+)    = 'XXCMN_SHIPMENT_MANAGEMENT'
   AND  FLV02.lookup_code(+)    = XPI.ship_mng_code
   --倉替対象可否区分名取得条件
   AND  FLV03.language(+)       = 'JA'
   AND  FLV03.lookup_type(+)    = 'XXCMN_INV_OBJEC_CLASS'
   AND  FLV03.lookup_code(+)    = XPI.warehouse_code
/
COMMENT ON TABLE APPS.XXSKZ_拠点IF_基本_V                       IS 'SKYLINK用拠点IF（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.SEQ番号              IS 'SEQ番号'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.更新区分             IS '更新区分'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.更新区分名           IS '更新区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.拠点コード           IS '拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.拠点名               IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.拠点略称             IS '拠点略称'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.拠点カナ名           IS '拠点カナ名'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.住所                 IS '住所'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.郵便番号             IS '郵便番号'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.郵便番号２           IS '郵便番号２'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.電話番号             IS '電話番号'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.FAX番号              IS 'FAX番号'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.旧_本部コード        IS '旧_本部コード'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.新_本部コード        IS '新_本部コード'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.本部_適用開始日      IS '本部_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.拠点実績有無区分     IS '拠点実績有無区分'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.拠点実績有無区分名   IS '拠点実績有無区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.出庫管理元区分       IS '出庫管理元区分'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.出庫管理元区分名     IS '出庫管理元区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.本部_地区名          IS '本部_地区名'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.倉替対象可否区分     IS '倉替対象可否区分'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.倉替対象可否区分名   IS '倉替対象可否区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.端末有無区分         IS '端末有無区分'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.端末有無区分名       IS '端末有無区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_拠点IF_基本_V.予備                 IS '予備'
/