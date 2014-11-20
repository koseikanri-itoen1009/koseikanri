/*************************************************************************
 * 
 * View  Name      : XXSKZ_発注受入ヘッダ_基本_V
 * Description     : XXSKZ_発注受入ヘッダ_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/21    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_発注受入ヘッダ_基本_V
(
 発注番号
,受入返品番号
,ステータス
,ステータス名
,購買担当者番号
,購買担当者名
,仕入先コード
,仕入先名
,仕入先サイトコード
,仕入先サイト名
,搬送先事業所コード
,搬送先事業所名
,請求先事業所コード
,請求先事業所名
,仕入先承諾要フラグ
,仕入先承諾要フラグ名
,斡旋者コード
,斡旋者名
,納入日
,納入先コード
,納入先名
,直送区分
,直送区分名
,配送先コード
,配送先名
,依頼番号
,部署コード
,部署名
,発注区分
,発注区分名
,ヘッダ摘要
,組織名
,依頼者コード
,依頼者名
,依頼者部署コード
,依頼者部署名
,依頼先部署コード
,依頼先部署名
,依頼日
,発注承諾フラグ
,発注承認フラグ名
,発注承諾者番号
,発注承諾者名
,発注承諾日付
,仕入承諾フラグ
,仕入承諾フラグ名
,仕入承諾ユーザー番号
,仕入承諾ユーザー名
,仕入承諾日付
,変更フラグ
,変更フラグ名
,発注_作成者
,発注_作成日
,発注_最終更新者
,発注_最終更新日
,発注_最終更新ログイン
,受入_実績区分
,受入_実績区分名
,受入_支給依頼番号
,受入_取引先コード
,受入_取引先名
,受入_工場コード
,受入_工場名
,受入_入出庫先コード
,受入_入出庫先名
,返品ヘッダ摘要
)
AS
SELECT
        POH.po_number                                       po_number                     --発注番号
       ,POH.rcv_rtn_number                                  rcv_rtn_number                --受入返品番号（NULLでも結合条件として使用する為 'Dummy' で表示）
       ,POH.status                                          status                        --ステータス
       ,POH.status_name                                     status_name                   --ステータス名
       ,PAPF1.employee_number                               po_charge                     --購買担当者番号
-- 2009/07/10 T.Yoshimoto Mod Start 本番#1572
--       ,REPLACE( PAPF1.per_information18, CHR(9) )          po_charge_name                --購買担当者名(タブ文字対応)
       ,REPLACE( PAPF1.per_information18 || PAPF1.per_information19, CHR(9) )
                                                            po_charge_name                --購買担当者名(タブ文字対応)
-- 2009/07/10 T.Yoshimoto Mod End 本番#1572
       ,VNDR1.segment1                                      vendor_code                   --仕入先コード
       ,VNDR1.vendor_name                                   vendor_name                   --仕入先名
       ,VDST1.vendor_site_code                              vendor_site_code              --仕入先サイトコード
       ,VDST1.vendor_site_name                              vendor_site_name              --仕入先サイト名
       ,LOCT1.location_code                                 ship_to_loct_code             --搬送先事業所コード
       ,LOCT1.location_name                                 ship_to_loct_name             --搬送先事業所名
       ,LOCT2.location_code                                 bill_to_loct_code             --請先事業所コード
       ,LOCT2.location_name                                 bill_to_loct_name             --請求先事業所名
       ,POH.vendor_approved_flg                             vendor_approved_flg           --仕入先承諾フラグ
       ,CASE WHEN POH.vendor_approved_flg = 'Y' THEN '必要'
             WHEN POH.vendor_approved_flg = 'N' THEN '不要'
        END                                                 vendor_approved_flg_name      --仕入先承諾フラグ名
       ,VNDR2.segment1                                      assist_code                   --斡旋者コード
       ,VNDR2.vendor_name                                   assist_name                   --斡旋者名
       ,POH.deliver_date                                    deliver_date                  --納入日
       ,POH.deliver_in                                      deliver_in                    --納入先コード
       ,ILOC1.description                                   deliver_in_name               --納入先名
       ,POH.drop_ship_type                                  drop_ship_type                --直送区分
       ,FLV01.meaning                                       drop_ship_type_name           --直送区分名
       ,POH.deliver_to                                      deliver_to                    --配送先コード
       ,DELV.name                                           deliver_to_name               --配送先名
       ,POH.request_no                                      request_no                    --依頼番号
       ,POH.dept_code                                       dept_code                     --部署コード
       ,LOCT3.location_name                                 dept_name                     --部署名
       ,POH.po_type                                         po_type                       --発注区分
       ,FLV02.meaning                                       po_type_name                  --発注区分名
       ,POH.h_header_desc                                   h_header_desc                 --ヘッダ摘要
       ,HAOUT.name                                          org_name                      --組織名
       ,POH.requested_by_code                               requested_by_code             --依頼者コード
-- 2009/07/10 T.Yoshimoto Mod Start 本番#1572
--       ,REPLACE( PAPF2.per_information18, CHR(9) )          requested_by_name             --依頼者名(タブ文字対応)
       ,REPLACE( PAPF2.per_information18 || PAPF2.per_information19, CHR(9) )
                                                            requested_by_name             --依頼者名(タブ文字対応)
-- 2009/07/10 T.Yoshimoto Mod End 本番#1572
       ,POH.requested_dept_code                             requested_dept_code           --依頼者部署コード
       ,LOCT4.location_name                                 requested_dept_name           --依頼者部署名
       ,POH.requested_to_dept_code                          requested_to_dept_code        --依頼先部署コード
       ,LOCT5.location_name                                 requested_to_dept_name        --依頼先部署名
       ,POH.requested_date                                  requested_date                --依頼日
       ,POH.order_approved_flg                              order_approved_flg            --発注承諾フラグ
       ,CASE WHEN POH.order_approved_flg = 'Y' THEN '承認済'
             WHEN POH.order_approved_flg = 'N' THEN '未承認'
        END                                                 order_approved_flg_name       --発注承諾フラグ名
       ,PAPF3.employee_number                               order_approved_code           --発注承諾者番号
-- 2009/07/10 T.Yoshimoto Mod Start 本番#1572
--       ,REPLACE( PAPF3.per_information18, CHR(9) )          order_approved_name           --発注承諾者名(タブ文字対応)
       ,REPLACE( PAPF3.per_information18 || PAPF3.per_information19, CHR(9) )
                                                            order_approved_name           --発注承諾者名(タブ文字対応)
-- 2009/07/10 T.Yoshimoto Mod End 本番#1572
       ,POH.order_approved_date                             order_approved_date           --発注承諾日付
       ,POH.purchase_approved_flg                           purchase_approved_flg         --仕入承諾フラグ
       ,CASE WHEN POH.purchase_approved_flg = 'Y' THEN '承認済'
             WHEN POH.purchase_approved_flg = 'N' THEN '未承認'
        END                                                 purchase_approved_flg_name    --仕入承諾フラグ名
       ,PAPF4.employee_number                               purchase_approved_code        --仕入承諾者番号
-- 2009/07/10 T.Yoshimoto Mod Start 本番#1572
--       ,REPLACE( PAPF4.per_information18, CHR(9) )          purchase_approved_name        --仕入承諾者名(タブ文字対応)
       ,REPLACE( PAPF4.per_information18 || PAPF4.per_information19, CHR(9) )
                                                            purchase_approved_name        --仕入承諾者名(タブ文字対応)
-- 2009/07/10 T.Yoshimoto Mod End 本番#1572
       ,POH.purchase_approved_date                          purchase_approved_date        --仕入承諾日付
       ,POH.change_flag                                     change_flg                    --変更フラグ
       ,CASE WHEN POH.change_flag = 'Y' THEN '変更あり'
             WHEN POH.change_flag = 'N' THEN '変更なし'
        END                                                 change_flg_name               --変更フラグ名
       ,FU_CB_H.user_name                                   h_created_by                  --発注_作成者
       ,TO_CHAR( POH.h_creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            h_creation_date               --発注_作成日
       ,FU_LU_H.user_name                                   h_last_updated_by             --発注_最終更新者
       ,TO_CHAR( POH.h_last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            h_last_update_date            --発注_最終更新日
       ,FU_LL_H.user_name                                   h_last_update_login           --発注_最終更新ログイン
       ,POH.u_txns_type                                     u_txns_type                   --受入_実績区分
       ,FLV03.meaning                                       u_txns_type_name              --受入_実績区分名
       ,POH.u_supply_requested_no                           u_supply_requested_no         --受入_支給依頼番号
       ,POH.u_vendor_code                                   u_vendor_code                 --受入_取引先コード
       ,VNDR3.vendor_name                                   u_vendor_name                 --受入_取引先名
       ,POH.u_factory_code                                  u_factory_code                --受入_工場コード
       ,VDST2.vendor_site_name                              u_factory_name                --受入_工場名
       ,POH.u_loct_code                                     u_loct_code                   --受入_入出庫先コード
       ,ILOC2.description                                   u_loct_name                   --受入_入出庫先名
       ,POH.u_header_desc                                   u_header_desc                 --返品ヘッダ摘要
  FROM
       ( --【発注依頼】【発注受入】【発注あり返品】【発注無し返品】 の各データを取得
          --========================================================================
          -- 発注依頼データ （発注依頼データ NOT EXISTS 発注データ）
          --========================================================================
          SELECT
                  XRH.po_header_number                      po_number                     --発注番号
                 ,'Dummy'                                   rcv_rtn_number                --受入返品番号（受入実績データが存在しない為に 'Dummy' 固定）
                 ,XRH.status                                status                        --ステータス
                 ,FLV.meaning                               status_name                   --ステータス名
                 ,NULL                                      pa_agent_id                   --購買担当ID
                 ,XRH.vendor_id                             vendor_id                     --仕入先ID
                 ,XRH.vendor_site_id                        vendor_site_id                --仕入先サイトID
                 ,NULL                                      ship_to_location_id           --搬送先事業所ID
                 ,NULL                                      bill_to_location_id           --請求先事業所ID
                 ,NULL                                      vendor_approved_flg           --仕入先承諾要フラグ
                 ,NULL                                      assist_id                     --斡旋者ID
                 ,XRH.promised_date                         deliver_date                  --納入日
                 ,XRH.location_code                         deliver_in                    --納入先コード
                 ,XRH.drop_ship_type                        drop_ship_type                --直送区分
                 ,XRH.delivery_code                         deliver_to                    --配送先コード
                 ,NULL                                      request_no                    --依頼番号
                 ,NULL                                      dept_code                     --部署コード
                 ,NULL                                      po_type                       --発注区分
                 ,XRH.description                           h_header_desc                 --ヘッダ摘要
                 ,NULL                                      org_id                        --組織ID
                 ,XRH.requested_by_code                     requested_by_code             --依頼者コード
                 ,XRH.requested_dept_code                   requested_dept_code           --依頼者部署コード
                 ,XRH.requested_to_department_code          requested_to_dept_code        --依頼先部署コード
                 ,NULL                                      requested_date                --依頼日
                 ,NULL                                      order_approved_flg            --発注承諾フラグ
                 ,NULL                                      order_approved_by             --発注承諾者ID
                 ,NULL                                      order_approved_date           --発注承諾日付
                 ,NULL                                      purchase_approved_flg         --仕入承諾フラグ
                 ,NULL                                      purchase_approved_by          --仕入承諾者ID
                 ,NULL                                      purchase_approved_date        --仕入承諾日付
                 ,XRH.change_flag                           change_flag                   --変更フラグ
                 ,XRH.created_by                            h_created_by                  --発注_作成者
                 ,XRH.creation_date                         h_creation_date               --発注_作成日
                 ,XRH.last_updated_by                       h_last_updated_by             --発注_最終更新者
                 ,XRH.last_update_date                      h_last_update_date            --発注_最終更新日
                 ,XRH.last_update_login                     h_last_update_login           --発注_最終更新ログイン
                 ,NULL                                      u_txns_type                   --受入_実績区分
                 ,NULL                                      u_supply_requested_no         --受入_支給依頼番号
                 ,NULL                                      u_vendor_id                   --受入_取引先ID
                 ,NULL                                      u_vendor_code                 --受入_取引先コード
                 ,NULL                                      u_factory_id                  --受入_工場ID
                 ,NULL                                      u_factory_code                --受入_工場コード
                 ,NULL                                      u_loct_code                   --受入_入出庫先コード
                 ,NULL                                      u_header_desc                 --返品ヘッダ摘要（受入データのヘッダ摘要はLOT単位で記載される為、取得しない）
            FROM
                  xxpo_requisition_headers                  XRH                           --発注依頼ヘッダ(アドオン)
                 ,fnd_lookup_values                         FLV                           --クイックコード(ステータス名)
           WHERE
             -- 発注済データは『発注･受入データ』として表示する為、除外する
                  NOT EXISTS
                  (
                    SELECT  E_XRH.requisition_header_id
                      FROM  xxpo_requisition_headers        E_XRH                         --発注依頼ヘッダ(アドオン)
                           ,po_headers_all                  E_PHA                         --発注ヘッダ
                     WHERE  E_XRH.po_header_number          = E_PHA.segment1              --発注番号で結合
                       AND  E_XRH.requisition_header_id     = XRH.requisition_header_id
                  )
             --ステータス名
             AND  FLV.language(+)                           = 'JA'
             AND  FLV.lookup_type(+)                        = 'XXPO_AUTHORIZATION_STATUS' --発注･受入データとは異なる為、個々で取得
             AND  FLV.lookup_code(+)                        = XRH.status
          --[ 発注依頼データ  END ]
        UNION ALL
          --========================================================================
          -- 発注・受入データ （受入実績区分 = '1'）
          --========================================================================
          SELECT  DISTINCT    -- ⇒受入返品アドオンデータがロット単位でデータ保持している為、重複データとなってしまう
                  PHA.segment1                              po_number                     --発注番号
                 ,NVL( XRART.rcv_rtn_number, 'Dummy' )      rcv_rtn_number                --受入返品番号（受入実績データが存在しない場合は 'Dummy' 固定）
                 ,PHA.attribute1                            status                        --ステータス
                 ,FLV.meaning                               status_name                   --ステータス名
                 ,PHA.agent_id                              pa_agent_id                   --購買担当ID
                 ,PHA.vendor_id                             vendor_id                     --仕入先ID
                 ,PHA.vendor_site_id                        vendor_site_id                --仕入先サイトID
                 ,PHA.ship_to_location_id                   ship_to_location_id           --搬送先事業所ID
                 ,PHA.bill_to_location_id                   bill_to_location_id           --請求先事業所ID
                 ,PHA.attribute2                            vendor_approved_flg           --仕入先承諾要フラグ
                 ,TO_NUMBER( PHA.attribute3 )               assist_id                     --斡旋者ID
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --納入日
                 ,PHA.attribute5                            deliver_in                    --納入先コード
                 ,PHA.attribute6                            drop_ship_type                --直送区分
                 ,PHA.attribute7                            deliver_to                    --配送先コード
                 ,PHA.attribute9                            request_no                    --依頼番号
                 ,PHA.attribute10                           dept_code                     --部署コード
                 ,PHA.attribute11                           po_type                       --発注区分
                 ,PHA.attribute15                           h_header_desc                 --ヘッダ摘要
                 ,TO_NUMBER( PHA.org_id )                   org_id                        --組織ID
                 ,XHA.requested_by_code                     requested_by_code             --依頼者コード
                 ,XHA.requested_department_code             requested_dept_code           --依頼者部署コード
                 ,XRH.requested_to_department_code          requested_to_dept_code        --依頼先部署コード
                 ,XHA.requested_date                        requested_date                --依頼日
                 ,XHA.order_approved_flg                    order_approved_flg            --発注承諾フラグ
                 ,XHA.order_approved_by                     order_approved_by             --発注承諾者ID
                 ,XHA.order_approved_date                   order_approved_date           --発注承諾日付
                 ,XHA.purchase_approved_flg                 purchase_approved_flg         --仕入承諾フラグ
                 ,XHA.purchase_approved_by                  purchase_approved_by          --仕入承諾者ID
                 ,XHA.purchase_approved_date                purchase_approved_date        --仕入承諾日付
                 ,NULL                                      change_flag                   --変更フラグ
                 ,XHA.created_by                            h_created_by                  --発注_作成者
                 ,XHA.creation_date                         h_creation_date               --発注_作成日
                 ,XHA.last_updated_by                       h_last_updated_by             --発注_最終更新者
                 ,XHA.last_update_date                      h_last_update_date            --発注_最終更新日
                 ,XHA.last_update_login                     h_last_update_login           --発注_最終更新ログイン
                 ,XRART.txns_type                           u_txns_type                   --受入_実績区分
                 ,XRART.supply_requested_number             u_supply_requested_no         --受入_支給依頼番号
                 ,XRART.vendor_id                           u_vendor_id                   --受入_取引先ID
                 ,XRART.vendor_code                         u_vendor_code                 --受入_取引先コード
                 ,XRART.factory_id                          u_factory_id                  --受入_工場ID
                 ,XRART.factory_code                        u_factory_code                --受入_工場コード
                 ,XRART.location_code                       u_loct_code                   --受入_入出庫先コード
                 ,NULL                                      u_header_desc                 --返品ヘッダ摘要（受入データのヘッダ摘要はLOT単位で記載される為、取得しない）
            FROM
                  po_headers_all                            PHA                           --発注ヘッダ
                 ,xxpo_headers_all                          XHA                           --発注ヘッダアドオン
                 ,xxpo_rcv_and_rtn_txns                     XRART                         --受入返品実績アドオン
                 ,xxpo_requisition_headers                  XRH                           --発注依頼ヘッダアドオン(依頼先部署コード取得用)
                 ,fnd_lookup_values                         FLV                           --クイックコード(ステータス名)
           WHERE
             --発注ヘッダアドオンとの結合
                  PHA.segment1                              = XHA.po_header_number
             --受入返品実績アドオンとの結合   ⇒発注止まり（受入実績データ無し）のデータも取得する為、外部結合
             AND  XRART.txns_type(+)                        = '1'                         --実績区分:'1:受入'
             AND  PHA.segment1                              = XRART.rcv_rtn_number(+)
             --発注依頼ヘッダアドオンとの結合
             AND  PHA.segment1                              = XRH.po_header_number(+)
             --ステータス名
             AND  FLV.language(+)                           = 'JA'
             AND  FLV.lookup_type(+)                        = 'XXPO_PO_ADD_STATUS'        --発注依頼データとは異なる為、個々で取得
             AND  FLV.lookup_code(+)                        = PHA.attribute1
          --[ 発注依頼データ  END ]
        UNION ALL
          --========================================================================
          -- 発注あり返品データ （受入実績区分 = '2'）
          --========================================================================
          SELECT  DISTINCT    -- ⇒受入返品アドオンデータがロット単位でデータ保持している為、重複データとなってしまう
                  PHA.segment1                              po_number                     --発注番号（発注ありなので発注番号は必ず存在する）
                 ,XRART.rcv_rtn_number                      rcv_rtn_number                --受入返品番号（返品データなので返品番号が必ず存在する）
                 ,PHA.attribute1                            status                        --ステータス
                 ,FLV.meaning                               status_name                   --ステータス名
                 ,PHA.agent_id                              pa_agent_id                   --購買担当ID
                 ,PHA.vendor_id                             vendor_id                     --仕入先ID
                 ,PHA.vendor_site_id                        vendor_site_id                --仕入先サイトID
                 ,PHA.ship_to_location_id                   ship_to_location_id           --搬送先事業所ID
                 ,PHA.bill_to_location_id                   bill_to_location_id           --請求先事業所ID
                 ,PHA.attribute2                            vendor_approved_flg           --仕入先承諾要フラグ
                 ,TO_NUMBER( PHA.attribute3 )               assist_id                     --斡旋者ID
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --納入日
                 ,PHA.attribute5                            deliver_in                    --納入先コード
                 ,PHA.attribute6                            drop_ship_type                --直送区分
                 ,PHA.attribute7                            deliver_to                    --配送先コード
                 ,PHA.attribute9                            request_no                    --依頼番号
                 ,PHA.attribute10                           dept_code                     --部署コード
                 ,PHA.attribute11                           po_type                       --発注区分
                 ,PHA.attribute15                           h_header_desc                 --ヘッダ摘要
                 ,TO_NUMBER( PHA.org_id )                   org_id                        --組織ID
                 ,XHA.requested_by_code                     requested_by_code             --依頼者コード
                 ,XHA.requested_department_code             requested_dept_code           --依頼者部署コード
                 ,XRH.requested_to_department_code          requested_to_dept_code        --依頼先部署コード
                 ,XHA.requested_date                        requested_date                --依頼日
                 ,XHA.order_approved_flg                    order_approved_flg            --発注承諾フラグ
                 ,XHA.order_approved_by                     order_approved_by             --発注承諾者ID
                 ,XHA.order_approved_date                   order_approved_date           --発注承諾日付
                 ,XHA.purchase_approved_flg                 purchase_approved_flg         --仕入承諾フラグ
                 ,XHA.purchase_approved_by                  purchase_approved_by          --仕入承諾者ID
                 ,XHA.purchase_approved_date                purchase_approved_date        --仕入承諾日付
                 ,NULL                                      change_flag                   --変更フラグ
                 ,XHA.created_by                            h_created_by                  --発注_作成者
                 ,XHA.creation_date                         h_creation_date               --発注_作成日
                 ,XHA.last_updated_by                       h_last_updated_by             --発注_最終更新者
                 ,XHA.last_update_date                      h_last_update_date            --発注_最終更新日
                 ,XHA.last_update_login                     h_last_update_login           --発注_最終更新ログイン
                 ,XRART.txns_type                           u_txns_type                   --受入_実績区分
                 ,XRART.supply_requested_number             u_supply_requested_no         --受入_支給依頼番号
                 ,XRART.vendor_id                           u_vendor_id                   --受入_取引先ID
                 ,XRART.vendor_code                         u_vendor_code                 --受入_取引先コード
                 ,XRART.factory_id                          u_factory_id                  --受入_工場ID
                 ,XRART.factory_code                        u_factory_code                --受入_工場コード
                 ,XRART.location_code                       u_loct_code                   --受入_入出庫先コード
                 ,XRART.header_description                  u_header_desc                 --返品ヘッダ摘要（返品データの場合のみ取得する）
            FROM
                  po_headers_all                            PHA                           --発注ヘッダ
                 ,xxpo_headers_all                          XHA                           --発注ヘッダアドオン
                 ,xxpo_rcv_and_rtn_txns                     XRART                         --受入返品実績アドオン
                 ,xxpo_requisition_headers                  XRH                           --発注依頼ヘッダアドオン(依頼先部署コード取得用)
                 ,fnd_lookup_values                         FLV                           --クイックコード(ステータス名)
           WHERE
             --発注ヘッダアドオンとの結合
                  PHA.segment1                              = XHA.po_header_number
             --受入返品実績アドオンとの結合   ⇒外部結合しない
             AND  XRART.txns_type                           = '2'                         --実績区分:'2:発注あり返品'
             AND  PHA.segment1                              = XRART.source_document_number
             --発注依頼ヘッダアドオンとの結合
             AND  PHA.segment1                              = XRH.po_header_number(+)
             --ステータス名
             AND  FLV.language(+)                           = 'JA'
             AND  FLV.lookup_type(+)                        = 'XXPO_PO_ADD_STATUS'        --発注依頼データとは異なる為、個々で取得
             AND  FLV.lookup_code(+)                        = PHA.attribute1
          --[ 発注あり返品データ  END ]
        UNION ALL
          --========================================================================
          -- 発注無し返品データ （受入実績区分 = '3'）
          --========================================================================
          SELECT  DISTINCT    -- ⇒受入返品アドオンデータがロット単位でデータ保持している為、重複データとなってしまう
                  'Dummy'                                   po_number                     --発注番号（発注データ無しなので 'Dummy' 固定）
                 ,XRART.rcv_rtn_number                      rcv_rtn_number                --受入返品番号（返品データなので返品番号が必ず存在する）
                 ,NULL                                      status                        --ステータス
                 ,NULL                                      status_name                   --ステータス名
                 ,NULL                                      pa_agent_id                   --購買担当ID
                 ,NULL                                      vendor_id                     --仕入先ID
                 ,NULL                                      vendor_site_id                --仕入先サイトID
                 ,NULL                                      ship_to_location_id           --搬送先事業所ID
                 ,NULL                                      bill_to_location_id           --請求先事業所ID
                 ,NULL                                      vendor_approved_flg           --仕入先承諾要フラグ
                 ,XRART.vendor_id                           assist_id                     --斡旋者ID
                 ,XRART.txns_date                           deliver_date                  --納入日
                 ,XRART.location_code                       deliver_in                    --納入先コード
                 ,XRART.drop_ship_type                      drop_ship_type                --直送区分
                 ,XRART.delivery_code                       deliver_to                    --配送先コード
                 ,NULL                                      request_no                    --依頼番号
                 ,XRART.department_code                     dept_code                     --部署コード
                 ,NULL                                      po_type                       --発注区分
                 ,NULL                                      h_header_desc                 --ヘッダ摘要
                 ,NULL                                      org_id                        --組織ID
                 ,NULL                                      requested_by_code             --依頼者コード
                 ,NULL                                      requested_dept_code           --依頼者部署コード
                 ,NULL                                      requested_to_dept_code        --依頼先部署コード
                 ,NULL                                      requested_date                --依頼日
                 ,NULL                                      order_approved_flg            --発注承諾フラグ
                 ,NULL                                      order_approved_by             --発注承諾者ID
                 ,NULL                                      order_approved_date           --発注承諾日付
                 ,NULL                                      purchase_approved_flg         --仕入承諾フラグ
                 ,NULL                                      purchase_approved_by          --仕入承諾者ID
                 ,NULL                                      purchase_approved_date        --仕入承諾日付
                 ,NULL                                      change_flag                   --変更フラグ
                 ,NULL                                      h_created_by                  --発注_作成者
                 ,NULL                                      h_creation_date               --発注_作成日
                 ,NULL                                      h_last_updated_by             --発注_最終更新者
                 ,NULL                                      h_last_update_date            --発注_最終更新日
                 ,NULL                                      h_last_update_login           --発注_最終更新ログイン
                 ,XRART.txns_type                           u_txns_type                   --受入_実績区分
                 ,XRART.supply_requested_number             u_supply_requested_no         --受入_支給依頼番号
                 ,XRART.vendor_id                           u_vendor_id                   --受入_取引先ID
                 ,XRART.vendor_code                         u_vendor_code                 --受入_取引先コード
                 ,XRART.factory_id                          u_factory_id                  --受入_工場ID
                 ,XRART.factory_code                        u_factory_code                --受入_工場コード
                 ,XRART.location_code                       u_loct_code                   --受入_入出庫先コード
                 ,XRART.header_description                  u_header_desc                 --返品ヘッダ摘要（返品データの場合のみ取得する）
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART                         --受入返品実績アドオン
           WHERE
                  XRART.txns_type                           = '3'                         --実績区分:'3:発注無し返品'
          --[ 発注無し返品データ  END ]
       )                                          POH                           --発注受入ヘッダデータ
       ------------------------------------------
       -- 以下、名称取得用
       ------------------------------------------
      ,( --配送先名取得用（直送区分の値によって取得先が異なる）
           --直送区分が'2:出荷'の場合は配送先名を取得
           SELECT  2                              class                         --2_配送先
                  ,party_site_number              code                          --配送先No
                  ,party_site_name                name                          --配送先名
                  ,start_date_active              start_date_active             --適用開始日
                  ,end_date_active                end_date_active               --適用終了日
             FROM  xxskz_party_sites2_v                                         --配送先情報VIEW2
         UNION ALL
           --直送区分が'3:支給'の場合は取引先サイト名を取得
           SELECT  3                              class                         --3_取引先
                  ,vendor_site_code               code                          --仕入先サイトNo
                  ,vendor_site_name               name                          --仕入先サイト名
                  ,start_date_active              start_date_active             --適用開始日
                  ,end_date_active                end_date_active               --適用終了日
             FROM  xxskz_vendor_sites2_v                                        --仕入先サイト情報VIEW2
       )                                          DELV                          --配送先情報取得用
       ,xxskz_vendors2_v                          VNDR1                         --SKYLINK用中間VIEW 仕入先情報VIEW2(仕入先)
       ,xxskz_vendors2_v                          VNDR2                         --SKYLINK用中間VIEW 仕入先情報VIEW2(斡旋者)
       ,xxskz_vendors2_v                          VNDR3                         --SKYLINK用中間VIEW 仕入先情報VIEW2(受入_取引先)
       ,xxskz_vendor_sites2_v                     VDST1                         --SKYLINK用中間VIEW 仕入先サイト情報VIEW2(仕入先サイト)
       ,xxskz_vendor_sites2_v                     VDST2                         --SKYLINK用中間VIEW 仕入先サイト情報VIEW2(受入_工場)
       ,xxskz_locations2_v                        LOCT1                         --SKYLINK用中間VIEW 事業所情報VIEW2(搬送先事業所)
       ,xxskz_locations2_v                        LOCT2                         --SKYLINK用中間VIEW 事業所情報VIEW2(請求先事業所)
       ,xxskz_locations2_v                        LOCT3                         --SKYLINK用中間VIEW 事業所情報VIEW2(部署)
       ,xxskz_locations2_v                        LOCT4                         --SKYLINK用中間VIEW 事業所情報VIEW2(依頼者部署)
       ,xxskz_locations2_v                        LOCT5                         --SKYLINK用中間VIEW 事業所情報VIEW2(依頼先部署)
       ,xxskz_item_locations_v                    ILOC1                         --SKYLINK用中間VIEW OPM保管場所情報VIEW2(納入先)
       ,xxskz_item_locations_v                    ILOC2                         --SKYLINK用中間VIEW OPM保管場所情報VIEW2(受入_入出庫先)
       ,per_all_people_f                          PAPF1                         --従業員マスタ(購買担当者情報取得用)
       ,per_all_people_f                          PAPF2                         --従業員マスタ(依頼者名)
       ,per_all_people_f                          PAPF3                         --従業員マスタ(発注承諾者名)
       ,per_all_people_f                          PAPF4                         --従業員マスタ(仕入承諾者名)
       ,hr_all_organization_units_tl              HAOUT                         --組織マスタ(組織名取得用)
       ,fnd_user                                  FU_CB_H                       --ユーザーマスタ(created_by名称取得用)
       ,fnd_user                                  FU_LU_H                       --ユーザーマスタ(last_updated_by名称取得用)
       ,fnd_user                                  FU_LL_H                       --ユーザーマスタ(last_update_login名称取得用)
       ,fnd_logins                                FL_LL_H                       --ログインマスタ(last_update_login名称取得用)
       ,fnd_lookup_values                         FLV01                         --クイックコード(直送区分)
       ,fnd_lookup_values                         FLV02                         --クイックコード(発注区分)
       ,fnd_lookup_values                         FLV03                         --クイックコード(受入_実績区分)
 WHERE
   --配送先情報取得条件
        POH.drop_ship_type                        = DELV.class(+)
   AND  POH.deliver_to                            = DELV.code(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= DELV.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= DELV.end_date_active(+)
   --購買担当者情報取得
   AND  POH.pa_agent_id                           = PAPF1.person_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= PAPF1.effective_start_date(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= PAPF1.effective_end_date(+)
-- 2009/03/30 H.Iida Add Start 本番障害#1346
   AND  NVL( PAPF1.attribute3, '1' )             IN ('1', '2')
-- 2009/03/30 H.Iida Add End
   --仕入先情報取得
   AND  POH.vendor_id                             = VNDR1.vendor_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VNDR1.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VNDR1.end_date_active(+)
   --仕入先サイト情報取得
   AND  POH.vendor_site_id                        = VDST1.vendor_site_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VDST1.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VDST1.end_date_active(+)
   --搬送先事業所情報取得
   AND  POH.ship_to_location_id                   = LOCT1.location_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT1.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT1.end_date_active(+)
   --請求先事業所情報取得
   AND  POH.bill_to_location_id                   = LOCT2.location_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT2.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT2.end_date_active(+)
   --斡旋者名取得条件
   AND  POH.assist_id                             = VNDR2.vendor_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VNDR2.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VNDR2.end_date_active(+)
   --納入先情報取得
   AND  POH.deliver_in                            = ILOC1.segment1(+)
   --部署情報取得
   AND  POH.dept_code                             = LOCT3.location_code(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT3.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT3.end_date_active(+)
   --組織名取得
   AND  HAOUT.language(+)                         = 'JA'
   AND  POH.org_id                                = HAOUT.organization_id(+)
   --依頼者情報取得
   AND  POH.requested_by_code                     = PAPF2.employee_number(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= PAPF2.effective_start_date(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= PAPF2.effective_end_date(+)
-- 2009/03/30 H.Iida Add Start 本番障害#1346
-- 2009/07/10 T.Yoshimoto Mod Start 内部気付き
   --AND  PAPF2.attribute3                          IN ('1', '2')
   AND  NVL( PAPF2.attribute3, '1' )              IN ('1', '2')
-- 2009/07/10 T.Yoshimoto Mod End 内部気付き
-- 2009/03/30 H.Iida Add End
   --依頼者部署情報取得
   AND  POH.requested_dept_code                   = LOCT4.location_code(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT4.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT4.end_date_active(+)
   --依頼先部署情報取得
   AND  POH.requested_to_dept_code                = LOCT5.location_code(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT5.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT5.end_date_active(+)
   --発注承諾者情報取得
   AND  POH.order_approved_by                     = PAPF3.person_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= PAPF3.effective_start_date(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= PAPF3.effective_end_date(+)
-- 2009/03/30 H.Iida Add Start 本番障害#1346
-- 2009/07/10 T.Yoshimoto Mod Start 内部気付き
   --AND  PAPF3.attribute3                          IN ('1', '2')
   AND  NVL( PAPF3.attribute3, '1' )              IN ('1', '2')
-- 2009/07/10 T.Yoshimoto Mod End 内部気付き
-- 2009/03/30 H.Iida Add End
   --発注承諾者情報取得
   AND  POH.purchase_approved_by                  = PAPF4.person_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= PAPF4.effective_start_date(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= PAPF4.effective_end_date(+)
-- 2009/03/30 H.Iida Add Start 本番障害#1346
-- 2009/07/10 T.Yoshimoto Mod Start 内部気付き
   --AND  PAPF4.attribute3                          IN ('1', '2')
   AND  NVL( PAPF4.attribute3, '1' )              IN ('1', '2')
-- 2009/07/10 T.Yoshimoto Mod End 内部気付き
-- 2009/03/30 H.Iida Add End
   --発注ヘッダのWHOカラム情報取得
   AND  POH.h_created_by                          = FU_CB_H.user_id(+)
   AND  POH.h_last_updated_by                     = FU_LU_H.user_id(+)
   AND  POH.h_last_update_login                   = FL_LL_H.login_id(+)
   AND  FL_LL_H.user_id                           = FU_LL_H.user_id(+)
   --受入_取引先情報取得
   AND  POH.u_vendor_id                           = VNDR3.vendor_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VNDR3.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VNDR3.end_date_active(+)
   --受入_工場情報取得
   AND  POH.u_factory_id                          = VDST2.vendor_site_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VDST2.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VDST2.end_date_active(+)
   --受入_入出庫先情報取得
   AND  POH.u_loct_code                           = ILOC2.segment1(+)
   --【クイックコード】直送区分名取得用
   AND  FLV01.language(+)                         = 'JA'
   AND  FLV01.lookup_type(+)                      = 'XXPO_DROP_SHIP_TYPE'
   AND  FLV01.lookup_code(+)                      = POH.drop_ship_type
   --【クイックコード】発生区分名取得用
   AND  FLV02.language(+)                         = 'JA'
   AND  FLV02.lookup_type(+)                      = 'XXPO_PO_TYPE'
   AND  FLV02.lookup_code(+)                      = POH.po_type
   --【クイックコード】発生区分名取得用
   AND  FLV03.language(+)                         = 'JA'
   AND  FLV03.lookup_type(+)                      = 'XXPO_TXNS_TYPE'
   AND  FLV03.lookup_code(+)                      = POH.u_txns_type
/
COMMENT ON TABLE APPS.XXSKZ_発注受入ヘッダ_基本_V IS 'SKYLINK用発注受入ヘッダ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注番号              IS '発注番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入返品番号          IS '受入返品番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.ステータス            IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.ステータス名          IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.購買担当者番号        IS '購買担当者番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.購買担当者名          IS '購買担当者名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入先コード          IS '仕入先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入先名              IS '仕入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入先サイトコード    IS '仕入先サイトコード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入先サイト名        IS '仕入先サイト名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.搬送先事業所コード    IS '搬送先事業所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.搬送先事業所名        IS '搬送先事業所名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.請求先事業所コード    IS '請求先事業所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.請求先事業所名        IS '請求先事業所名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入先承諾要フラグ    IS '仕入先承諾要フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入先承諾要フラグ名  IS '仕入先承諾要フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.斡旋者コード          IS '斡旋者コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.斡旋者名              IS '斡旋者名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.納入日                IS '納入日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.納入先コード          IS '納入先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.納入先名              IS '納入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.直送区分              IS '直送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.直送区分名            IS '直送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.配送先コード          IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.配送先名              IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.依頼番号              IS '依頼番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.部署コード            IS '部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.部署名                IS '部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注区分              IS '発注区分'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注区分名            IS '発注区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.ヘッダ摘要            IS 'ヘッダ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.組織名                IS '組織名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.依頼者コード          IS '依頼者コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.依頼者名              IS '依頼者名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.依頼者部署コード      IS '依頼者部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.依頼者部署名          IS '依頼者部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.依頼先部署コード      IS '依頼先部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.依頼先部署名          IS '依頼先部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.依頼日                IS '依頼日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注承諾フラグ        IS '発注承諾フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注承認フラグ名      IS '発注承認フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注承諾者番号        IS '発注承諾者番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注承諾者名          IS '発注承諾者名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注承諾日付          IS '発注承諾日付'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入承諾フラグ        IS '仕入承諾フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入承諾フラグ名      IS '仕入承諾フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入承諾ユーザー番号  IS '仕入承諾ユーザー番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入承諾ユーザー名    IS '仕入承諾ユーザー名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.仕入承諾日付          IS '仕入承諾日付'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.変更フラグ            IS '変更フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.変更フラグ名          IS '変更フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注_作成者           IS '発注_作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注_作成日           IS '発注_作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注_最終更新者       IS '発注_最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注_最終更新日       IS '発注_最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.発注_最終更新ログイン IS '発注_最終更新ログイン'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_実績区分         IS '受入_実績区分'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_実績区分名       IS '受入_実績区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_支給依頼番号     IS '受入_支給依頼番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_取引先コード     IS '受入_取引先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_取引先名         IS '受入_取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_工場コード       IS '受入_工場コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_工場名           IS '受入_工場名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_入出庫先コード   IS '受入_入出庫先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.受入_入出庫先名       IS '受入_入出庫先名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入ヘッダ_基本_V.返品ヘッダ摘要        IS '返品ヘッダ摘要'
/
