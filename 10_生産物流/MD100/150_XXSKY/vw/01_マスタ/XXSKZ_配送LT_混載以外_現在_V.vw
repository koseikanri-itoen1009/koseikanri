/*************************************************************************
 * 
 * View  Name      : XXSKZ_配送LT_混載以外_現在_V
 * Description     : XXSKZ_配送LT_混載以外_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_配送LT_混載以外_現在_V
(
 コード区分１
,コード区分名１
,入出庫場所コード１
,入出庫場所名１
,コード区分２
,コード区分名２
,入出庫場所コード２
,入出庫場所名２
,配送LT_適用開始日
,配送LT_適用終了日
,配送リードタイム
,ドリンク生産物流LT
,リーフ生産物流LT
,引取変更LT
,出荷方法
,出荷方法名
,出荷方法_適用開始日
,出荷方法_適用終了日
,ドリンク積載重量
,リーフ積載重量
,ドリンク積載容積
,リーフ積載容積
,パレット最大枚数
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  XDL.code_class1                     code_class1                   --コード区分１
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning                       code_class_name1              --コード区分名１
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01                         --クイックコード(コード区分名1)
         WHERE FLV01.language    = 'JA'
           AND FLV01.lookup_type = 'XXCMN_D06'
           AND FLV01.lookup_code = XDL.code_class1
        ) code_class_name1
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDL.entering_despatching_code1      entering_despatching_code1    --入出庫場所コード１
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,ED01.name                           entering_despatching_name1    --入出庫場所名１
       ,CASE 
          --コード区分が'1:拠点'の場合は拠点名を取得
          WHEN XDL.code_class1 = 1 THEN
            (SELECT party_name                               --拠点名
             FROM xxskz_cust_accounts_v                      --顧客･拠点VIEW
             WHERE party_number = XDL.entering_despatching_code1)
          --コード区分が'4:倉庫'の場合はOPM保管倉庫名を取得
          WHEN XDL.code_class1 = 4 THEN
            (SELECT description                              --保管倉庫名
             FROM xxskz_item_locations_v                     --保管倉庫
             WHERE segment1 = XDL.entering_despatching_code1)
          --コード区分が'9:配送先'の場合は配送先名を取得
          WHEN XDL.code_class1 = 9 THEN
            (SELECT party_site_name                          --配送先名
             FROM xxskz_party_sites_v                        --配送先VIEW
             WHERE party_site_number = XDL.entering_despatching_code1)
          --コード区分が'11:支給先'の場合は支給先名を取得
          WHEN XDL.code_class1 = 11 THEN
            (SELECT vendor_site_name                         --支給先名
             FROM xxskz_vendor_sites_v                       --仕入先サイトVIEW
             WHERE vendor_site_code = XDL.entering_despatching_code1)
          ELSE NULL
        END entering_despatching_name1
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDL.code_class2                     code_class2                   --コード区分２
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                       code_class_name2              --コード区分名２
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02                         --クイックコード(コード区分名2)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXCMN_D06'
           AND FLV02.lookup_code = XDL.code_class2
        ) code_class_name2
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDL.entering_despatching_code2      entering_despatching_code2    --入出庫場所コード２
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,ED02.name                           entering_despatching_name2    --入出庫場所名２
       ,CASE 
          --コード区分が'1:拠点'の場合は拠点名を取得
          WHEN XDL.code_class2 = 1 THEN
            (SELECT party_name                               --拠点名
             FROM xxskz_cust_accounts_v                      --顧客･拠点VIEW
             WHERE party_number = XDL.entering_despatching_code2)
          --コード区分が'4:倉庫'の場合はOPM保管倉庫名を取得
          WHEN XDL.code_class2 = 4 THEN
            (SELECT description                              --保管倉庫名
             FROM xxskz_item_locations_v                     --保管倉庫
             WHERE segment1 = XDL.entering_despatching_code2)
          --コード区分が'9:配送先'の場合は配送先名を取得
          WHEN XDL.code_class2 = 9 THEN
            (SELECT party_site_name                          --配送先名
             FROM xxskz_party_sites_v                        --配送先VIEW
             WHERE party_site_number = XDL.entering_despatching_code2)
          --コード区分が'11:支給先'の場合は支給先名を取得
          WHEN XDL.code_class2 = 11 THEN
            (SELECT vendor_site_name                         --支給先名
             FROM xxskz_vendor_sites_v                       --仕入先サイトVIEW
             WHERE vendor_site_code = XDL.entering_despatching_code2)
          ELSE NULL
        END entering_despatching_name2
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XDL.start_date_active               start_date_active             --配送LT_適用開始日
       ,XDL.end_date_active                 end_date_active               --配送LT_適用終了日
       ,XDL.delivery_lead_time              delivery_lead_time            --配送リードタイム
       ,XDL.drink_lead_time_day             drink_lead_time_day           --ドリンク生産物流LT
       ,XDL.leaf_lead_time_day              leaf_lead_time_day            --リーフ生産物流LT
       ,XDL.receipt_change_lead_time_day    receipt_change_lead_time_day  --引取変更LT
       ,XSM.ship_method                     ship_method                   --出荷方法
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning                       ship_method_name              --出荷方法名
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03                         --クイックコード(出荷方法名)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXCMN_SHIP_METHOD'
           AND FLV03.lookup_code = XSM.ship_method
        ) ship_method_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XSM.start_date_active               start_date_active             --出荷方法_適用開始日
       ,XSM.end_date_active                 end_date_active               --出荷方法_適用終了日
       ,XSM.drink_deadweight                drink_deadweight              --ドリンク積載重量
       ,XSM.leaf_deadweight                 leaf_deadweight               --リーフ積載重量
       ,XSM.drink_loading_capacity          drink_loading_capacity        --ドリンク積載容積
       ,XSM.leaf_loading_capacity           leaf_loading_capacity         --リーフ積載容積
       ,XSM.palette_max_qty                 palette_max_qty               --パレット最大枚数
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name                     created_by_name               --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XDL.created_by = FU_CB.user_id
        ) created_by_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XDL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            creation_date                 --作成日時
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name                     last_updated_by_name          --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XDL.last_updated_by = FU_LU.user_id
        ) last_updated_by_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XDL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            last_update_date              --更新日時
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name                     last_update_login_name        --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
             ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XDL.last_update_login = FL_LL.login_id
           AND FL_LL.user_id         = FU_LL.user_id
        ) last_update_login_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  xxcmn_delivery_lt         XDL                                     --配送LTアドオンマスタ
       ,xxcmn_ship_methods        XSM                                     --出荷方法アドオンマスタ
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,(--入出庫場所名１取得用
       --     --コード区分が'1:拠点'の場合は拠点名を取得
       --     SELECT 1                    class                         --1:拠点
       --           ,party_number         code                          --拠点No
       --           ,party_name           name                          --拠点名
       --       FROM xxsky_cust_accounts_v                              --顧客･拠点VIEW
       --   UNION ALL
       --     --コード区分が'4:倉庫'の場合はOPM保管倉庫名を取得
       --     SELECT 4                    class                         --4:倉庫
       --           ,segment1             code                          --保管倉庫No
       --           ,description          name                          --保管倉庫名
       --       FROM xxsky_item_locations_v                             --保管倉庫
       --   UNION ALL
       --     --コード区分が'9:配送先'の場合は配送先名を取得
       --     SELECT 9                    class                         --9:配送先
       --           ,party_site_number    code                          --配送先No
       --           ,party_site_name      name                          --配送先名
       --       FROM xxsky_party_sites_v                                --配送先VIEW
       --   UNION ALL
       --     --コード区分が'11:支給先'の場合は支給先名を取得
       --     SELECT 11                   class                         --11:支給先
       --           ,vendor_site_code     code                          --支給先No
       --           ,vendor_site_name     name                          --支給先名
       --       FROM xxsky_vendor_sites_v                               --仕入先サイトVIEW
       -- )                               ED01                          --入出庫場所１
       --,(--入出庫場所名２取得用
       --     --コード区分が'1:拠点'の場合は拠点名を取得
       --     SELECT 1                    class                         --1:拠点
       --           ,party_number         code                          --拠点No
       --           ,party_name           name                          --拠点名
       --       FROM xxsky_cust_accounts_v                              --顧客･拠点VIEW
       --   UNION ALL
       --     --コード区分が'4:倉庫'の場合はOPM保管倉庫名を取得
       --     SELECT 4                    class                         --4:倉庫
       --           ,segment1             code                          --保管倉庫No
       --           ,description          name                          --保管倉庫名
       --       FROM xxsky_item_locations_v                             --保管倉庫
       --   UNION ALL
       --     --コード区分が'9:配送先'の場合は配送先名を取得
       --     SELECT 9                    class                         --9:配送先
       --           ,party_site_number    code                          --配送先No
       --           ,party_site_name      name                          --配送先名
       --       FROM xxsky_party_sites_v                                --配送先VIEW
       --   UNION ALL
       --     --コード区分が'11:支給先'の場合は支給先名を取得
       --     SELECT 11                   class                         --11:支給先
       --           ,vendor_site_code     code                          --支給先No
       --           ,vendor_site_name     name                          --支給先名
       --       FROM xxsky_vendor_sites_v                               --仕入先サイトVIEW
       -- )                               ED02                          --入出庫場所２
       --,fnd_lookup_values       FLV01                                 --クイックコード(コード区分名1)
       --,fnd_lookup_values       FLV02                                 --クイックコード(コード区分名2)
       --,fnd_lookup_values       FLV03                                 --クイックコード(出荷方法名)
       --,fnd_user                FU_CB                                 --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user                FU_LU                                 --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user                FU_LL                                 --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins              FL_LL                                 --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE (   XDL.consolidated_flag <> '1'
        OR XDL.consolidated_flag IS NULL )                            --混載許可以外
   AND  XDL.start_date_active <= TRUNC(SYSDATE)
   AND  XDL.end_date_active   >= TRUNC(SYSDATE)
   AND  XDL.code_class1 = XSM.code_class1(+)
   AND  XDL.entering_despatching_code1 = XSM.entering_despatching_code1(+)
   AND  XDL.code_class2 = XSM.code_class2(+)
   AND  XDL.entering_despatching_code2 = XSM.entering_despatching_code2(+)
   AND  XSM.start_date_active(+) <= TRUNC(SYSDATE)
   AND  XSM.end_date_active(+)   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  XDL.code_class1 = ED01.class(+)
   --AND  XDL.entering_despatching_code1 = ED01.code(+)
   --AND  XDL.code_class2 = ED02.class(+)
   --AND  XDL.entering_despatching_code2 = ED02.code(+)
   --クイックコード：コード区分名１取得
   --AND  FLV01.language(+) = 'JA'
   --AND  FLV01.lookup_type(+) = 'XXCMN_D06'
   --AND  FLV01.lookup_code(+) = XDL.code_class1
   --クイックコード：コード区分名２取得
   --AND  FLV02.language(+) = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_D06'
   --AND  FLV02.lookup_code(+) = XDL.code_class2
   --クイックコード：出荷方法名取得
   --AND  FLV03.language(+) = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   --AND  FLV03.lookup_code(+) = XSM.ship_method
   --WHOカラム取得
   --AND  XDL.created_by = FU_CB.user_id(+)
   --AND  XDL.last_updated_by = FU_LU.user_id(+)
   --AND  XDL.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKZ_配送LT_混載以外_現在_V IS 'SKYLINK用配送LTマスタ_混載以外（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.コード区分１        IS 'コード区分１'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.コード区分名１      IS 'コード区分名１'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.入出庫場所コード１  IS '入出庫場所コード１'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.入出庫場所名１      IS '入出庫場所名１'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.コード区分２        IS 'コード区分２'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.コード区分名２      IS 'コード区分名２'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.入出庫場所コード２  IS '入出庫場所コード２'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.入出庫場所名２      IS '入出庫場所名２'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.配送LT_適用開始日   IS '配送LT_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.配送LT_適用終了日   IS '配送LT_適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.配送リードタイム    IS '配送リードタイム'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.ドリンク生産物流LT  IS 'ドリンク生産物流LT'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.リーフ生産物流LT    IS 'リーフ生産物流LT'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.引取変更LT          IS '引取変更LT'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.出荷方法            IS '出荷方法'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.出荷方法名          IS '出荷方法名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.出荷方法_適用開始日 IS '出荷方法_適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.出荷方法_適用終了日 IS '出荷方法_適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.ドリンク積載重量    IS 'ドリンク積載重量'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.リーフ積載重量      IS 'リーフ積載重量'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.ドリンク積載容積    IS 'ドリンク積載容積'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.リーフ積載容積      IS 'リーフ積載容積'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.パレット最大枚数    IS 'パレット最大枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.作成者              IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.作成日              IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.最終更新者          IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.最終更新日          IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送LT_混載以外_現在_V.最終更新ログイン    IS '最終更新ログイン'
/
