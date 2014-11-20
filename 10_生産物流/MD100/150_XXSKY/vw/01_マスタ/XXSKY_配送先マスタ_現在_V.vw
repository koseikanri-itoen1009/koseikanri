CREATE OR REPLACE VIEW APPS.XXSKY_配送先マスタ_現在_V
(
 組織番号
,顧客拠点_マスタ受信日
,顧客拠点_番号
,顧客拠点_名称
,顧客拠点_略称
,顧客拠点_カナ名
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
,配送先_番号
,配送先_名称
,配送先_略称
,配送先_カナ名
,配送先_適用開始日
,配送先_適用終了日
,配送先_拠点コード
,配送先_拠点名
,配送先_郵便番号
,配送先_住所１
,配送先_住所２
,配送先_電話番号
,配送先_FAX番号
,配送先_鮮度条件
,配送先_鮮度条件名
,配送先_マスタ受信日
,配送先_ドリンク基準カレンダ
,配送先_ドリンク基準カレンダ名
,配送先_JPRユーザコード
,配送先_都道府県コード
,配送先_都道府県名
,配送先_最大入庫車輌
,配送先_指定項目区分
,配送先_指定項目区分名
,配送先_付帯業務リフト区分
,配送先_付帯業務リフト区分名
,配送先_付帯業務専用伝票区分
,配送先_付帯業務専用伝票区分名
,配送先_付帯業務パレット積替
,配送先_付帯業務パレット積替名
,配送先_付帯業務荷造区分
,配送先_付帯業務荷造区分名
,配送先_付帯業務パレットカゴ
,配送先_付帯業務パレットカゴ名
,配送先_ルール区分
,配送先_ルール区分名
,配送先_段積輸送可否区分
,配送先_段積輸送可否区分名
,配送先_通行許可証区分
,配送先_通行許可証区分名
,配送先_入場許可証区分
,配送先_入場許可証区分名
,配送先_車輌指定区分
,配送先_車輌指定区分名
,配送先_納品時連絡区分
,配送先_納品時連絡区分名 
,配送先_リーフ基準カレンダ
,配送先_リーフ基準カレンダ名
,配送先_主フラグ
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        HP.party_number                  --組織番号
       ,HP.attribute24                   --顧客拠点_マスタ受信日
       ,HCA.account_number               --顧客拠点_番号
       ,XP.party_name                    --顧客拠点_名称
       ,XP.party_short_name              --顧客拠点_略称
       ,XP.party_name_alt                --顧客拠点_カナ名
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
       ,HL.province                      --配送先_番号
       ,XPS.party_site_name              --配送先_名称
       ,XPS.party_site_short_name        --配送先_略称
       ,XPS.party_site_name_alt          --配送先_カナ名
       ,XPS.start_date_active            --配送先_適用開始日
       ,XPS.end_date_active              --配送先_適用終了日
       ,XPS.base_code                    --配送先_拠点コード
       ,XCAV03.party_name                --配送先_拠点名
       ,XPS.zip                          --配送先_郵便番号
       ,XPS.address_line1                --配送先_住所１
       ,XPS.address_line2                --配送先_住所２
       ,XPS.phone                        --配送先_電話番号
       ,XPS.fax                          --配送先_FAX番号
       ,XPS.freshness_condition          --配送先_鮮度条件
       ,FLV17.meaning                    --配送先_鮮度条件名
       ,HPS.attribute19                  --配送先_マスタ受信日
       ,HCASA.attribute1                 --配送先_ドリンク基準カレンダ
       ,MSH01.calendar_desc              --配送先_ドリンク基準カレンダ名
       ,HCASA.attribute2                 --配送先_JPRユーザコード
       ,HCASA.attribute3                 --配送先_都道府県コード
       ,FLV18.meaning                    --配送先_都道府県名
       ,HCASA.attribute4                 --配送先_最大入庫車輌
       ,HCASA.attribute5                 --配送先_指定項目区分
       ,FLV19.meaning                    --配送先_指定項目区分名
       ,HCASA.attribute6                 --配送先_付帯業務リフト区分
       ,FLV20.meaning                    --配送先_付帯業務リフト区分名
       ,HCASA.attribute7                 --配送先_付帯業務専用伝票区分
       ,FLV21.meaning                    --配送先_付帯業務専用伝票区分名
       ,HCASA.attribute8                 --配送先_付帯業務パレット積替
       ,FLV22.meaning                    --配送先_付帯業務パレット積替名
       ,HCASA.attribute9                 --配送先_付帯業務荷造区分
       ,FLV23.meaning                    --配送先_付帯業務荷造区分名
       ,HCASA.attribute10                --配送先_付帯業務パレットカゴ
       ,FLV24.meaning                    --配送先_付帯業務パレットカゴ名
       ,HCASA.attribute11                --配送先_ルール区分
       ,FLV25.meaning                    --配送先_ルール区分名
       ,HCASA.attribute12                --配送先_段積輸送可否区分
       ,FLV26.meaning                    --配送先_段積輸送可否区分名
       ,HCASA.attribute13                --配送先_通行許可証区分
       ,FLV27.meaning                    --配送先_通行許可証区分名
       ,HCASA.attribute14                --配送先_入場許可証区分
       ,FLV28.meaning                    --配送先_入場許可証区分名
       ,HCASA.attribute15                --配送先_車輌指定区分
       ,FLV29.meaning                    --配送先_車輌指定区分名
       ,HCASA.attribute16                --配送先_納品時連絡区分
       ,FLV30.meaning                    --配送先_納品時連絡区分名
       ,HCASA.attribute19                --配送先_リーフ基準カレンダ
       ,MSH02.calendar_desc              --配送先_リーフ基準カレンダ名
       ,HCSUA.primary_flag               --配送先_主フラグ
       ,FU_CB.user_name                  --作成者
       ,TO_CHAR( XPS.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --作成日
       ,FU_LU.user_name                  --最終更新者
       ,TO_CHAR( XPS.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --最終更新日
       ,FU_LL.user_name                  --最終更新ログイン
  FROM  xxcmn_parties           XP       --パーティアドオンマスタ
       ,hz_parties              HP       --パーティマスタ
       ,hz_cust_accounts        HCA      --顧客マスタ
       ,xxcmn_party_sites       XPS      --パーティサイトアドオンマスタ
       ,hz_party_sites          HPS      --パーティサイトマスタ
       ,hz_locations            HL       --顧客事業所マスタ
       ,hz_cust_acct_sites_all  HCASA    --顧客所在地マスタ
       ,hz_cust_site_uses_all   HCSUA    --顧客使用目的マスタ
       ,xxsky_cust_accounts_v   XCAV01   --顧客情報VIEW(顧客_当月売上拠点名)
       ,xxsky_cust_accounts_v   XCAV02   --顧客情報VIEW(顧客_予約売上拠点名)
       ,xxsky_cust_accounts_v   XCAV03   --顧客情報VIEW(配送先_拠点名)
       ,mr_shcl_hdr             MSH01    --基準カレンダ(配送先_ドリンク基準カレンダ名)
       ,mr_shcl_hdr             MSH02    --基準カレンダ(配送先_リーフ基準カレンダ名)
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
       ,fnd_lookup_values       FLV17    --クイックコード(配送先_鮮度条件名)
       ,fnd_lookup_values       FLV18    --クイックコード(配送先_都道府県名)
       ,fnd_lookup_values       FLV19    --クイックコード(配送先_指定項目区分名)
       ,fnd_lookup_values       FLV20    --クイックコード(配送先_付帯業務リフト区分名)
       ,fnd_lookup_values       FLV21    --クイックコード(配送先_付帯業務専用伝票区分名)
       ,fnd_lookup_values       FLV22    --クイックコード(配送先_付帯業務パレット積替名)
       ,fnd_lookup_values       FLV23    --クイックコード(配送先_付帯業務荷造区分名)
       ,fnd_lookup_values       FLV24    --クイックコード(配送先_付帯業務パレットカゴ名)
       ,fnd_lookup_values       FLV25    --クイックコード(配送先_ルール区分名)
       ,fnd_lookup_values       FLV26    --クイックコード(配送先_段積輸送可否区分名)
       ,fnd_lookup_values       FLV27    --クイックコード(配送先_通行許可証区分名)
       ,fnd_lookup_values       FLV28    --クイックコード(配送先_入場許可証区分名)
       ,fnd_lookup_values       FLV29    --クイックコード(配送先_車輌指定区分名)
       ,fnd_lookup_values       FLV30    --クイックコード(配送先_納品時連絡区分名)
 WHERE
   --パーティアドオンマスタ（顧客･拠点情報取得）の条件
        XP.start_date_active <= TRUNC(SYSDATE)
   AND  XP.end_date_active   >= TRUNC(SYSDATE)
   --パーティマスタ（顧客･拠点情報取得）との結合
   AND  HP.status = 'A'                --ステータス：有効
   AND  XP.party_id = HP.party_id
   --顧客マスタ（顧客･拠点情報取得）との結合
   AND  HCA.status = 'A'               --ステータス：有効
   AND  XP.party_id = HCA.party_id
   --パーティサイトアドオンマスタ（顧客･拠点情報取得）との結合
   AND  XPS.start_date_active <= TRUNC(SYSDATE)
   AND  XPS.end_date_active   >= TRUNC(SYSDATE)
   AND  XP.party_id = XPS.party_id
   --パーティサイトマスタ（配送先情報取得）との結合
   AND  HPS.status = 'A'               --ステータス：有効
   AND  XPS.party_site_id = HPS.party_site_id
   --顧客事業所マスタ（配送先情報取得）との結合
   AND  XPS.location_id = HL.location_id
   --顧客所在地マスタ（配送先情報取得）との結合
   AND  HCASA.status = 'A'             --ステータス：有効
   AND  XPS.party_site_id = HCASA.party_site_id
   --顧客使用目的マスタ（配送先情報取得）との結合
   AND  HCSUA.status = 'A'                                 --ステータス：有効
   AND  HCSUA.site_use_code = 'SHIP_TO'
   AND  HCASA.cust_acct_site_id = HCSUA.cust_acct_site_id
   --当月売上拠点名取得
   AND  HCA.attribute17 = XCAV01.party_number(+)
   --予約売上拠点名取得
   AND  HCA.attribute18 = XCAV02.party_number(+)
   --拠点名取得
   AND  XPS.base_code = XCAV03.party_number(+)
   --ドリンク基準カレンダ名取得
   AND  HCASA.attribute1 = MSH01.calendar_no(+)
   --リーフ基準カレンダ名取得
   AND  HCASA.attribute19 = MSH02.calendar_no(+)
   --WHOカラム情報取得
   AND  XPS.created_by        = FU_CB.user_id(+)
   AND  XPS.last_updated_by   = FU_LU.user_id(+)
   AND  XPS.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   --区分名取得
   AND  FLV01.language(+)    = 'JA'                        --言語
   AND  FLV01.lookup_type(+) = 'CUSTOMER CLASS'            --クイックコードタイプ
   AND  FLV01.lookup_code(+) = HCA.customer_class_code     --クイックコード
   --ドリンク運賃振替基準名取得
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV02.lookup_code(+) = XP.drink_transfer_std
   --リーフ運賃振替基準名取得
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV03.lookup_code(+) = XP.leaf_transfer_std
   --振替グループ名取得
   AND  FLV04.language(+)    = 'JA'
   AND  FLV04.lookup_type(+) = 'XXCMN_D04'
   AND  FLV04.lookup_code(+) = XP.transfer_group
   --物流ブロック名取得
   AND  FLV05.language(+)    = 'JA'
   AND  FLV05.lookup_type(+) = 'XXCMN_D12'
   AND  FLV05.lookup_code(+) = XP.distribution_block
   --拠点大分類名取得
   AND  FLV06.language(+)    = 'JA'
   AND  FLV06.lookup_type(+) = 'XXWIP_BASE_MAJOR_DIVISION'
   AND  FLV06.lookup_code(+) = XP.base_major_division
   --実績有無区分名取得
   AND  FLV09.language(+)    = 'JA'
   AND  FLV09.lookup_type(+) = 'XXCMN_BASE_RESULTS_CLASS'
   AND  FLV09.lookup_code(+) = HCA.attribute4
   --出荷管理元区分名取得
   AND  FLV10.language(+)    = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_SHIPMENT_MANAGEMENT'
   AND  FLV10.lookup_code(+) = HCA.attribute5
   --倉替対象可否区分名取得
   AND  FLV11.language(+)    = 'JA'
   AND  FLV11.lookup_type(+) = 'XXCMN_INV_OBJEC_CLASS'
   AND  FLV11.lookup_code(+) = HCA.attribute6
   --中止客申請フラグ名取得
   AND  FLV12.language(+)    = 'JA'
   AND  FLV12.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
-- 2009/10/27 Y.Kawano Mod Start 本番#1675
--   AND  FLV12.lookup_code(+) = HCA.attribute12
   AND  FLV12.lookup_code(+) = DECODE(HP.duns_number_c,'30','0','40','0','99','0','2')
   AND  FLV122.language(+)    = 'JA'
   AND  FLV122.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
   AND  FLV122.lookup_code(+) = DECODE(HP.duns_number_c,'30','0','40','0','2')
-- 2009/10/27 Y.Kawano Mod End 本番#1675
   --ドリンク拠点カテゴリ名取得
   AND  FLV13.language(+)    = 'JA'
   AND  FLV13.lookup_type(+) = 'XXWSH_DRINK_BASE_CATEGORY'
   AND  FLV13.lookup_code(+) = HCA.attribute13
   --リーフ拠点カテゴリ名取得
   AND  FLV14.language(+)    = 'JA'
   AND  FLV14.lookup_type(+) = 'XXWSH_LEAF_BASE_CATEGORY'
   AND  FLV14.lookup_code(+) = HCA.attribute16
   --出荷依頼自動作成区分名取得
   AND  FLV15.language(+)    = 'JA'
   AND  FLV15.lookup_type(+) = 'XXCMN_SHIPMENT_AUTO'
   AND  FLV15.lookup_code(+) = HCA.attribute14
   --直送区分名取得
   AND  FLV16.language(+)    = 'JA'
   AND  FLV16.lookup_type(+) = 'XXCMN_DROP_SHIP_DIV'
   AND  FLV16.lookup_code(+) = HCA.attribute15
   --鮮度条件名取得
   AND  FLV17.language(+)    = 'JA'
   AND  FLV17.lookup_type(+) = 'XXCMN_FRESHNESS_CONDITION'
   AND  FLV17.lookup_code(+) = XPS.freshness_condition
   --都道府県名取得
   AND  FLV18.language(+)    = 'JA'
   AND  FLV18.lookup_type(+) = 'XXCMN_AREA_CODE'
   AND  FLV18.lookup_code(+) = HCASA.attribute3
   --指定項目区分名取得
   AND  FLV19.language(+)    = 'JA'
   AND  FLV19.lookup_type(+) = 'XXCMN_SPECIFY_ITEM'
   AND  FLV19.lookup_code(+) = HCASA.attribute5
   --付帯業務リフト区分名取得
   AND  FLV20.language(+)    = 'JA'
   AND  FLV20.lookup_type(+) = 'XXCMN_ADD_LIFT_CLASS'
   AND  FLV20.lookup_code(+) = HCASA.attribute6
   --付帯業務専用伝票区分名取得
   AND  FLV21.language(+)    = 'JA'
   AND  FLV21.lookup_type(+) = 'XXCMN_ADD_L03'
   AND  FLV21.lookup_code(+) = HCASA.attribute7
   --付帯業務パレット積替名取得
   AND  FLV22.language(+)    = 'JA'
   AND  FLV22.lookup_type(+) = 'XXCMN_ADD_PALETTE'
   AND  FLV22.lookup_code(+) = HCASA.attribute8
   --付帯業務荷造区分名取得
   AND  FLV23.language(+)    = 'JA'
   AND  FLV23.lookup_type(+) = 'XXCMN_ADD_PACK_CLASS'
   AND  FLV23.lookup_code(+) = HCASA.attribute9
   --付帯業務パレットカゴ名取得
   AND  FLV24.language(+)    = 'JA'
   AND  FLV24.lookup_type(+) = 'XXCMN_ADD_PALETTE_BASKET'
   AND  FLV24.lookup_code(+) = HCASA.attribute10
   --ルール区分名取得
   AND  FLV25.language(+)    = 'JA'
   AND  FLV25.lookup_type(+) = 'XXCMN_RULE_CLASS'
   AND  FLV25.lookup_code(+) = HCASA.attribute11
   --段積輸送可否区分名取得
   AND  FLV26.language(+)    = 'JA'
   AND  FLV26.lookup_type(+) = 'XXCMN_TRANSPORT_CLASS'
   AND  FLV26.lookup_code(+) = HCASA.attribute12
   --通行許可証区分名取得
   AND  FLV27.language(+)    = 'JA'
   AND  FLV27.lookup_type(+) = 'XXCMN_PERMIT_CLASS'
   AND  FLV27.lookup_code(+) = HCASA.attribute13
   --入場許可証区分名取得
   AND  FLV28.language(+)    = 'JA'
   AND  FLV28.lookup_type(+) = 'XXCMN_ADMISSION_CLASS'
   AND  FLV28.lookup_code(+) = HCASA.attribute14
   --車輌指定区分名取得
   AND  FLV29.language(+)    = 'JA'
   AND  FLV29.lookup_type(+) = 'XXCMN_VEHICLES_SPECIFY'
   AND  FLV29.lookup_code(+) = HCASA.attribute15
   --納品時連絡区分名取得
   AND  FLV30.language(+)    = 'JA'
   AND  FLV30.lookup_type(+) = 'XXCMN_DELIVERY_CLASS'
   AND  FLV30.lookup_code(+) = HCASA.attribute16
/
COMMENT ON TABLE APPS.XXSKY_配送先マスタ_現在_V IS 'SKYLINK用配送先マスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.組織番号                      IS '組織番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_マスタ受信日         IS '顧客拠点_マスタ受信日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_番号                 IS '顧客拠点_番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_名称                 IS '顧客拠点_名称'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_略称                 IS '顧客拠点_略称'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_カナ名               IS '顧客拠点_カナ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_区分                 IS '顧客拠点_区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_区分名               IS '顧客拠点_区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_適用開始日           IS '顧客拠点_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_適用終了日           IS '顧客拠点_適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_郵便番号             IS '顧客拠点_郵便番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_住所１               IS '顧客拠点_住所１'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_住所２               IS '顧客拠点_住所２'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_電話番号             IS '顧客拠点_電話番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_FAX番号              IS '顧客拠点_FAX番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_引当順                   IS '拠点_引当順'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_ドリンク運賃振替基準     IS '拠点_ドリンク運賃振替基準'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_ドリンク運賃振替基準名   IS '拠点_ドリンク運賃振替基準名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_リーフ運賃振替基準       IS '拠点_リーフ運賃振替基準'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_リーフ運賃振替基準名     IS '拠点_リーフ運賃振替基準名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_振替グループ             IS '拠点_振替グループ'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_振替グループ名           IS '拠点_振替グループ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_物流ブロック             IS '拠点_物流ブロック'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_物流ブロック名           IS '拠点_物流ブロック名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_拠点大分類               IS '拠点_拠点大分類'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_拠点大分類名             IS '拠点_拠点大分類名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_旧本部コード             IS '拠点_旧本部コード'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_新本部コード             IS '拠点_新本部コード'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_本部適用開始日           IS '拠点_本部適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_実績有無区分             IS '拠点_実績有無区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_実績有無区分名           IS '拠点_実績有無区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_出荷管理元区分           IS '拠点_出荷管理元区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_出荷管理元区分名         IS '拠点_出荷管理元区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_倉替対象可否区分         IS '拠点_倉替対象可否区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_倉替対象可否区分名       IS '拠点_倉替対象可否区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_中止客申請フラグ     IS '顧客拠点_中止客申請フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客拠点_中止客申請フラグ名   IS '顧客拠点_中止客申請フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_ドリンク拠点カテゴリ     IS '拠点_ドリンク拠点カテゴリ'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_ドリンク拠点カテゴリ名   IS '拠点_ドリンク拠点カテゴリ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_リーフ拠点カテゴリ       IS '拠点_リーフ拠点カテゴリ'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_リーフ拠点カテゴリ名     IS '拠点_リーフ拠点カテゴリ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_出荷依頼自動作成区分     IS '拠点_出荷依頼自動作成区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.拠点_出荷依頼自動作成区分名   IS '拠点_出荷依頼自動作成区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客_直送区分                 IS '顧客_直送区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客_直送区分名               IS '顧客_直送区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客_当月売上拠点コード       IS '顧客_当月売上拠点コード'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客_当月売上拠点名           IS '顧客_当月売上拠点名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客_予約売上拠点コード       IS '顧客_予約売上拠点コード'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客_予約売上拠点名           IS '顧客_予約売上拠点名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客_売上チェーン店           IS '顧客_売上チェーン店'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.顧客_売上チェーン店名         IS '顧客_売上チェーン店名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_番号                   IS '配送先_番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_名称                   IS '配送先_名称'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_略称                   IS '配送先_略称'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_カナ名                 IS '配送先_カナ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_適用開始日             IS '配送先_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_適用終了日             IS '配送先_適用終了日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_拠点コード             IS '配送先_拠点コード'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_拠点名                 IS '配送先_拠点名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_郵便番号               IS '配送先_郵便番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_住所１                 IS '配送先_住所１'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_住所２                 IS '配送先_住所２'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_電話番号               IS '配送先_電話番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_FAX番号                IS '配送先_FAX番号'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_鮮度条件               IS '配送先_鮮度条件'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_鮮度条件名             IS '配送先_鮮度条件名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_マスタ受信日           IS '配送先_マスタ受信日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_ドリンク基準カレンダ   IS '配送先_ドリンク基準カレンダ'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_ドリンク基準カレンダ名 IS '配送先_ドリンク基準カレンダ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_JPRユーザコード        IS '配送先_JPRユーザコード'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_都道府県コード         IS '配送先_都道府県コード'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_都道府県名             IS '配送先_都道府県名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_最大入庫車輌           IS '配送先_最大入庫車輌'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_指定項目区分           IS '配送先_指定項目区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_指定項目区分名         IS '配送先_指定項目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務リフト区分     IS '配送先_付帯業務リフト区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務リフト区分名   IS '配送先_付帯業務リフト区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務専用伝票区分   IS '配送先_付帯業務専用伝票区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務専用伝票区分名 IS '配送先_付帯業務専用伝票区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務パレット積替   IS '配送先_付帯業務パレット積替'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務パレット積替名 IS '配送先_付帯業務パレット積替名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務荷造区分       IS '配送先_付帯業務荷造区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務荷造区分名     IS '配送先_付帯業務荷造区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務パレットカゴ   IS '配送先_付帯業務パレットカゴ'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_付帯業務パレットカゴ名 IS '配送先_付帯業務パレットカゴ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_ルール区分             IS '配送先_ルール区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_ルール区分名           IS '配送先_ルール区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_段積輸送可否区分       IS '配送先_段積輸送可否区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_段積輸送可否区分名     IS '配送先_段積輸送可否区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_通行許可証区分         IS '配送先_通行許可証区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_通行許可証区分名       IS '配送先_通行許可証区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_入場許可証区分         IS '配送先_入場許可証区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_入場許可証区分名       IS '配送先_入場許可証区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_車輌指定区分           IS '配送先_車輌指定区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_車輌指定区分名         IS '配送先_車輌指定区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_納品時連絡区分         IS '配送先_納品時連絡区分'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_納品時連絡区分名       IS '配送先_納品時連絡区分名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_リーフ基準カレンダ     IS '配送先_リーフ基準カレンダ'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_リーフ基準カレンダ名   IS '配送先_リーフ基準カレンダ名'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.配送先_主フラグ               IS '配送先_主フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.作成者                        IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.作成日                        IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.最終更新者                    IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.最終更新日                    IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_配送先マスタ_現在_V.最終更新ログイン              IS '最終更新ログイン'
/