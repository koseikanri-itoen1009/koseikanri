CREATE OR REPLACE VIEW APPS.XXSKY_顧客拠点マスタ_基本_V
(
 組織番号
,組織_ステータス
,組織_ステータス名
,顧客拠点_マスタ受信日
,顧客拠点_番号
,顧客拠点_名称
,顧客拠点_略称
,顧客拠点_カナ名
,顧客拠点_ステータス
,顧客拠点_ステータス名
,顧客拠点_区分
,顧客拠点_区分名
,顧客拠点_適用開始日
,顧客拠点_適用終了日
,顧客拠点_郵便番号
,顧客拠点_住所１
,顧客拠点_住所２
,顧客拠点_電話番号
,顧客拠点_FAX番号
,拠点_引当順
,拠点_ドリンク運賃振替基準
,拠点_ドリンク運賃振替基準名
,拠点_リーフ運賃振替基準
,拠点_リーフ運賃振替基準名
,拠点_振替グループ
,拠点_振替グループ名
,拠点_物流ブロック
,拠点_物流ブロック名
,拠点_拠点大分類
,拠点_拠点大分類名
,拠点_旧本部コード
,拠点_新本部コード
,拠点_本部適用開始日
,拠点_実績有無区分
,拠点_実績有無区分名
,拠点_出荷管理元区分
,拠点_出荷管理元区分名
,拠点_倉替対象可否区分
,拠点_倉替対象可否区分名
,顧客拠点_中止客申請フラグ
,顧客拠点_中止客申請フラグ名
,拠点_ドリンク拠点カテゴリ
,拠点_ドリンク拠点カテゴリ名
,拠点_リーフ拠点カテゴリ
,拠点_リーフ拠点カテゴリ名
,拠点_出荷依頼自動作成区分
,拠点_出荷依頼自動作成区分名
,顧客_直送区分
,顧客_直送区分名
,顧客_当月売上拠点コード
,顧客_当月売上拠点名
,顧客_予約売上拠点コード
,顧客_予約売上拠点名
,顧客_売上チェーン店
,顧客_売上チェーン店名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        HP.party_number                  --組織番号
       ,HP.status                        --組織_ステータス
       ,DECODE(HP.status, 'A', '有効', 'I', '無効')
        status_name                      --組織_ステータス名
       ,HP.attribute24                   --顧客拠点_マスタ受信日
       ,HCA.account_number               --顧客拠点_番号
       ,XP.party_name                    --顧客拠点_名称
       ,XP.party_short_name              --顧客拠点_略称
       ,XP.party_name_alt                --顧客拠点_カナ名
       ,HCA.status                       --顧客拠点_ステータス
       ,DECODE(HCA.status, 'A', '有効', 'I', '無効')
        status_name                      --顧客拠点_ステータス名
       ,HCA.customer_class_code          --顧客拠点_区分
       ,FLV01.meaning                    --顧客拠点_区分名
       ,XP.start_date_active             --顧客拠点_適用開始日
       ,XP.end_date_active               --顧客拠点_適用終了日
       ,XP.zip                           --顧客拠点_郵便番号
       ,XP.address_line1                 --顧客拠点_住所１
       ,XP.address_line2                 --顧客拠点_住所２
       ,XP.phone                         --顧客拠点_電話番号
       ,XP.fax                           --顧客拠点_FAX番号
       ,XP.reserve_order                 --拠点_引当順
       ,XP.drink_transfer_std            --拠点_ドリンク運賃振替基準
       ,FLV02.meaning                    --拠点_ドリンク運賃振替基準名
       ,XP.leaf_transfer_std             --拠点_リーフ運賃振替基準
       ,FLV03.meaning                    --拠点_リーフ運賃振替基準名
       ,XP.transfer_group                --拠点_振替グループ
       ,FLV04.meaning                    --拠点_振替グループ名
       ,XP.distribution_block            --拠点_物流ブロック
       ,FLV05.meaning                    --拠点_物流ブロック名
       ,XP.base_major_division           --拠点_拠点大分類
       ,FLV06.meaning                    --拠点_拠点大分類名
       ,HCA.attribute1                   --拠点_旧本部コード
       ,HCA.attribute2                   --拠点_新本部コード
       ,HCA.attribute3                   --拠点_本部適用開始日
       ,HCA.attribute4                   --拠点_実績有無区分
       ,FLV09.meaning                    --拠点_実績有無区分名
       ,HCA.attribute5                   --拠点_出荷管理元区分
       ,FLV10.meaning                    --拠点_出荷管理元区分名
       ,HCA.attribute6                   --拠点_倉替対象可否区分
       ,FLV11.meaning                    --拠点_倉替対象可否区分名
-- 2009/10/27 Y.Kawano Mod Start 本番#1675
--       ,HCA.attribute12                  --顧客拠点_中止客申請フラグ
       ,CASE hca.customer_class_code
        WHEN '1' THEN
          CASE hp.duns_number_c
          WHEN '30' THEN '0'
          WHEN '40' THEN '0'
          WHEN '99' THEN '0'
          ELSE '2'
          END
        WHEN '10' THEN
          CASE hp.duns_number_c
          WHEN '30' THEN '0'
          WHEN '40' THEN '0'
          ELSE '2'
          END
        END cust_enable_flag               --顧客拠点_中止客申請フラグ
--       ,FLV12.meaning                    --顧客拠点_中止客申請フラグ名
       ,CASE hca.customer_class_code
        WHEN '1'  THEN FLV12.meaning
        WHEN '10' THEN FLV122.meaning
        END meaning                      --顧客拠点_中止客申請フラグ名
-- 2009/10/27 Y.Kawano Mod End 本番#1675
       ,HCA.attribute13                  --拠点_ドリンク拠点カテゴリ
       ,FLV13.meaning                    --拠点_ドリンク拠点カテゴリ名
       ,HCA.attribute16                  --拠点_リーフ拠点カテゴリ
       ,FLV14.meaning                    --拠点_リーフ拠点カテゴリ名
       ,HCA.attribute14                  --拠点_出荷依頼自動作成区分
       ,FLV15.meaning                    --拠点_出荷依頼自動作成区分名
       ,HCA.attribute15                  --顧客_直送区分
       ,FLV16.meaning                    --顧客_直送区分名
       ,HCA.attribute17                  --顧客_当月売上拠点コード
       ,XCAV01.party_name                --顧客_当月売上拠点名
       ,HCA.attribute18                  --顧客_予約売上拠点コード
       ,XCAV02.party_name                --顧客_予約売上拠点名
       ,HCA.attribute19                  --顧客_売上チェーン店
       ,HCA.attribute20                  --顧客_売上チェーン店名
       ,FU_CB.user_name                  --作成者
       ,TO_CHAR( XP.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --作成日
       ,FU_LU.user_name                  --最終更新者
       ,TO_CHAR( XP.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --最終更新日
       ,FU_LL.user_name                  --最終更新ログイン
  FROM  xxcmn_parties           XP       --パーティアドオンマスタ
       ,hz_parties              HP       --パーティマスタ
       ,hz_cust_accounts        HCA      --顧客マスタ
       ,xxsky_cust_accounts_v   XCAV01   --顧客情報VIEW(顧客_当月売上拠点名)
       ,xxsky_cust_accounts_v   XCAV02   --顧客情報VIEW(顧客_予約売上拠点名)
       ,fnd_user                FU_CB    --ユーザーマスタ(created_by名称取得用)
       ,fnd_user                FU_LU    --ユーザーマスタ(last_updated_by名称取得用)
       ,fnd_user                FU_LL    --ユーザーマスタ(last_update_login名称取得用)
       ,fnd_logins              FL_LL    --ログインマスタ(last_update_login名称取得用)
       ,fnd_lookup_values       FLV01    --クイックコード(顧客拠点_区分名)
       ,fnd_lookup_values       FLV02    --クイックコード(拠点_ドリンク運賃振替基準名)
       ,fnd_lookup_values       FLV03    --クイックコード(拠点_リーフ運賃振替基準名)
       ,fnd_lookup_values       FLV04    --クイックコード(拠点_振替グループ名)
       ,fnd_lookup_values       FLV05    --クイックコード(拠点_物流ブロック名)
       ,fnd_lookup_values       FLV06    --クイックコード(拠点_拠点大分類名)
       ,fnd_lookup_values       FLV09    --クイックコード(拠点_実績有無区分名)
       ,fnd_lookup_values       FLV10    --クイックコード(拠点_出荷管理元区分名)
       ,fnd_lookup_values       FLV11    --クイックコード(拠点_倉替対象可否区分名)
       ,fnd_lookup_values       FLV12    --クイックコード(顧客拠点_中止客申請フラグ名)
-- 2009/10/27 Y.Kawano Mod Start 本番#1675
       ,fnd_lookup_values       FLV122   --クイックコード(顧客拠点_中止客申請フラグ名)
-- 2009/10/27 Y.Kawano Mod End   本番#1675
       ,fnd_lookup_values       FLV13    --クイックコード(拠点_ドリンク拠点カテゴリ名)
       ,fnd_lookup_values       FLV14    --クイックコード(拠点_リーフ拠点カテゴリ名)
       ,fnd_lookup_values       FLV15    --クイックコード(拠点_出荷依頼自動作成区分名)
       ,fnd_lookup_values       FLV16    --クイックコード(顧客_直送区分名)
 WHERE  HP.status = 'A'                                    --ステータス：有効
   AND  XP.party_id = HP.party_id
-- 2009/10/02 DEL START
--   AND  HCA.status = 'A'                                   --ステータス：有効
-- 2009/10/02 DEL END
-- 2009/03/30 H.Iida Add Start 本番障害#1346
   AND  HCA.customer_class_code IN ('1', '10')
-- 2009/03/30 H.Iida Add End
   AND  XP.party_id = HCA.party_id
   AND  HCA.attribute17 = XCAV01.party_number(+)
   AND  HCA.attribute18 = XCAV02.party_number(+)
   AND  XP.created_by        = FU_CB.user_id(+)
   AND  XP.last_updated_by   = FU_LU.user_id(+)
   AND  XP.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   AND  FLV01.language(+)    = 'JA'                        --言語
   AND  FLV01.lookup_type(+) = 'CUSTOMER CLASS'            --クイックコードタイプ
   AND  FLV01.lookup_code(+) = HCA.customer_class_code     --クイックコード
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV02.lookup_code(+) = XP.drink_transfer_std
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV03.lookup_code(+) = XP.leaf_transfer_std
   AND  FLV04.language(+)    = 'JA'
   AND  FLV04.lookup_type(+) = 'XXCMN_D04'
   AND  FLV04.lookup_code(+) = XP.transfer_group
   AND  FLV05.language(+)    = 'JA'
   AND  FLV05.lookup_type(+) = 'XXCMN_D12'
   AND  FLV05.lookup_code(+) = XP.distribution_block
   AND  FLV06.language(+)    = 'JA'
   AND  FLV06.lookup_type(+) = 'XXWIP_BASE_MAJOR_DIVISION'
   AND  FLV06.lookup_code(+) = XP.base_major_division
   AND  FLV09.language(+)    = 'JA'
   AND  FLV09.lookup_type(+) = 'XXCMN_BASE_RESULTS_CLASS'
   AND  FLV09.lookup_code(+) = HCA.attribute4
   AND  FLV10.language(+)    = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_SHIPMENT_MANAGEMENT'
   AND  FLV10.lookup_code(+) = HCA.attribute5
   AND  FLV11.language(+)    = 'JA'
   AND  FLV11.lookup_type(+) = 'XXCMN_INV_OBJEC_CLASS'
   AND  FLV11.lookup_code(+) = HCA.attribute6
   AND  FLV12.language(+)    = 'JA'
   AND  FLV12.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
-- 2009/10/27 Y.Kawano Mod Start 本番#1675
--   AND  FLV12.lookup_code(+) = HCA.attribute12
   AND  FLV12.lookup_code(+) = DECODE(HP.duns_number_c,'30','0','40','0','99','0','2')
   AND  FLV122.language(+)    = 'JA'
   AND  FLV122.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
   AND  FLV122.lookup_code(+) = DECODE(HP.duns_number_c,'30','0','40','0','2')
-- 2009/10/27 Y.Kawano Mod End 本番#1675
   AND  FLV13.language(+)    = 'JA'
   AND  FLV13.lookup_type(+) = 'XXWSH_DRINK_BASE_CATEGORY'
   AND  FLV13.lookup_code(+) = HCA.attribute13
   AND  FLV14.language(+)    = 'JA'
   AND  FLV14.lookup_type(+) = 'XXWSH_LEAF_BASE_CATEGORY'
   AND  FLV14.lookup_code(+) = HCA.attribute16
   AND  FLV15.language(+)    = 'JA'
   AND  FLV15.lookup_type(+) = 'XXCMN_SHIPMENT_AUTO'
   AND  FLV15.lookup_code(+) = HCA.attribute14
   AND  FLV16.language(+)    = 'JA'
   AND  FLV16.lookup_type(+) = 'XXCMN_DROP_SHIP_DIV'
   AND  FLV16.lookup_code(+) = HCA.attribute15
/
COMMENT ON TABLE APPS.XXSKY_顧客拠点マスタ_基本_V IS 'SKYLINK用顧客拠点マスタ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.組織番号 IS '組織番号'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.組織_ステータス IS '組織_ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.組織_ステータス名 IS '組織_ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_マスタ受信日 IS '顧客拠点_マスタ受信日'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_番号 IS '顧客拠点_番号'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_名称 IS '顧客拠点_名称'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_略称 IS '顧客拠点_略称'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_カナ名 IS '顧客拠点_カナ名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_ステータス IS '顧客拠点_ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_ステータス名 IS '顧客拠点_ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_区分 IS '顧客拠点_区分'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_区分名 IS '顧客拠点_区分名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_適用開始日 IS '顧客拠点_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_適用終了日 IS '顧客拠点_適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_郵便番号 IS '顧客拠点_郵便番号'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_住所１ IS '顧客拠点_住所１'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_住所２ IS '顧客拠点_住所２'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_電話番号 IS '顧客拠点_電話番号'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_FAX番号 IS '顧客拠点_FAX番号'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_引当順 IS '拠点_引当順'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_ドリンク運賃振替基準 IS '拠点_ドリンク運賃振替基準'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_ドリンク運賃振替基準名 IS '拠点_ドリンク運賃振替基準名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_リーフ運賃振替基準 IS '拠点_リーフ運賃振替基準'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_リーフ運賃振替基準名 IS '拠点_リーフ運賃振替基準名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_振替グループ IS '拠点_振替グループ'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_振替グループ名 IS '拠点_振替グループ名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_物流ブロック IS '拠点_物流ブロック'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_物流ブロック名 IS '拠点_物流ブロック名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_拠点大分類 IS '拠点_拠点大分類'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_拠点大分類名 IS '拠点_拠点大分類名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_旧本部コード IS '拠点_旧本部コード'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_新本部コード IS '拠点_新本部コード'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_本部適用開始日 IS '拠点_本部適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_実績有無区分 IS '拠点_実績有無区分'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_実績有無区分名 IS '拠点_実績有無区分名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_出荷管理元区分 IS '拠点_出荷管理元区分'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_出荷管理元区分名 IS '拠点_出荷管理元区分名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_倉替対象可否区分 IS '拠点_倉替対象可否区分'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_倉替対象可否区分名 IS '拠点_倉替対象可否区分名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_中止客申請フラグ IS '顧客拠点_中止客申請フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客拠点_中止客申請フラグ名 IS '顧客拠点_中止客申請フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_ドリンク拠点カテゴリ IS '拠点_ドリンク拠点カテゴリ'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_ドリンク拠点カテゴリ名 IS '拠点_ドリンク拠点カテゴリ名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_リーフ拠点カテゴリ IS '拠点_リーフ拠点カテゴリ'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_リーフ拠点カテゴリ名 IS '拠点_リーフ拠点カテゴリ名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_出荷依頼自動作成区分 IS '拠点_出荷依頼自動作成区分'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.拠点_出荷依頼自動作成区分名 IS '拠点_出荷依頼自動作成区分名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客_直送区分 IS '顧客_直送区分'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客_直送区分名 IS '顧客_直送区分名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客_当月売上拠点コード IS '顧客_当月売上拠点コード'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客_当月売上拠点名 IS '顧客_当月売上拠点名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客_予約売上拠点コード IS '顧客_予約売上拠点コード'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客_予約売上拠点名 IS '顧客_予約売上拠点名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客_売上チェーン店 IS '顧客_売上チェーン店'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.顧客_売上チェーン店名 IS '顧客_売上チェーン店名'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_顧客拠点マスタ_基本_V.最終更新ログイン IS '最終更新ログイン'
/
