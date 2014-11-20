/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_stc_headers_sum_v
 * Description     : 入庫予定要約ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/14    1.0   K.Kiriu         新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_stc_headers_sum_v
(
   header_id                    --ヘッダID
  ,party_id                     --パーティID
  ,organization_id              --組織ID
  ,to_subinventory_code         --搬送先保管場所（コード）
  ,to_subinventory_name         --搬送先保管場所（名称）
  ,move_order_num               --移動オーダー番号
  ,edi_chain_code               --EDIチェーン店コード
  ,edi_chain_name               --EDIチェーン店名称
  ,shop_code                    --店コード
  ,center_code                  --センターコード
  ,other_party_department_code  --相手先部門コード
  ,invoice_number               --伝票番号
  ,schedule_shipping_date       --出荷予定日
  ,schedule_arrival_date        --入庫予定日
  ,rcpt_possible_date           --受入可能日
  ,inspect_schedule_date        --検品予定日
  ,invoice_class                --伝票区分
  ,classification_class         --分類区分
  ,whse_class                   --倉庫区分
  ,regular_ar_sale_class        --定番/特売区分
  ,opportunity_code             --便コード
  ,fix_flag                     --確定フラグ
  ,fix_conditions               --確定状況
  ,edi_send_flag                --EDI送信済みフラグ
  ,edi_send_conditions          --EDI送信状況
  ,edi_send_date                --EDI送信日時
  ,created_by                   --作成者
  ,creation_date                --作成日
  ,last_updated_by              --最終更新者
  ,last_update_date             --最終更新日
)
AS
SELECT   xesh.header_id                    header_id                    --ヘッダID
        ,hca2.party_id                     party_id                     --パーティID
        ,xesh.organization_id              organization_id              --組織ID
        ,xesh.to_subinventory_code         to_subinventory_code         --搬送先保管場所（コード）
        ,msi.description                   to_subinventory_name         --搬送先保管場所（名称）
        ,xesh.move_order_num               move_order_num               --移動オーダー番号
        ,xesh.edi_chain_code               edi_chain_code               --EDIチェーン店コード
        ,hca2.party_name                   edi_chain_name               --EDIチェーン店名称
        ,xesh.shop_code                    shop_code                    --店コード
        ,xesh.center_code                  center_code                  --センターコード
        ,xesh.other_party_department_code  other_party_department_code  --相手先部門コード
        ,xesh.invoice_number               invoice_number               --伝票番号
        ,xesh.schedule_shipping_date       schedule_shipping_date       --出荷予定日
        ,xesh.schedule_arrival_date        schedule_arrival_date        --入庫予定日
        ,xesh.rcpt_possible_date           rcpt_possible_date           --受入可能日
        ,xesh.inspect_schedule_date        inspect_schedule_date        --検品予定日
        ,xesh.invoice_class                invoice_class                --伝票区分
        ,xesh.classification_class         classification_class         --分類区分
        ,xesh.whse_class                   whse_class                   --倉庫区分
        ,xesh.regular_ar_sale_class        regular_ar_sale_class        --定番/特売区分
        ,xesh.opportunity_code             opportunity_code             --便コード
        ,xesh.fix_flag                     fix_flag                     --確定フラグ
        ,flvv.meaning                      fix_conditions               --確定状況
        ,xesh.edi_send_flag                edi_send_flag                --EDI送信済みフラグ
        ,DECODE(  xesh.edi_send_flag
                 ,'Y', xxccp_common_pkg.get_msg(
                          'XXCOS'
                         ,'APP-XXCOS1-12456'  --済
                       )
                 ,'N', xxccp_common_pkg.get_msg(
                          'XXCOS'
                         ,'APP-XXCOS1-12457'  --未
                       ) )                 edi_send_conditions          --EDI送信状況
        ,xesh.edi_send_date                edi_send_date                --EDI送信日時
        ,xesh.created_by                   created_by                   --作成者
        ,xesh.creation_date                creation_date                --作成日
        ,xesh.last_updated_by              last_updated_by              --最終更新者
        ,xesh.last_update_date             last_update_date             --最終更新日
FROM     xxcos_edi_stc_headers      xesh   --入庫予定ヘッダ
        ,( SELECT   xca.ship_storage_code  ship_storage_code   --出荷元保管場所
                   ,xca.chain_store_code   chain_store_code    --EDIチェーン店コード
                   ,hca.account_number     account_number      --顧客コード
                   ,xca.delivery_base_code delivery_base_code  --出荷元拠点
           FROM     hz_cust_accounts         hca
                   ,xxcmm_cust_accounts      xca
                   ,hz_parties               hp
                   ,xxcos_login_base_info_v  xlbiv
           WHERE    hca.customer_class_code =  '10'  -- 顧客
           AND      hca.status              =  'A'   -- ステータス(有効)
           AND      hp.duns_number_c        <> '90'  -- 顧客ステータス(中止決裁以外)
           AND      hca.party_id            =  hp.party_id
           AND      hca.cust_account_id     =  xca.customer_id
           AND      xca.delivery_base_code  =  xlbiv.base_code
         )                          hca1   --顧客
        ,mtl_secondary_inventories  msi    --保管場所マスタ
        ,( SELECT   xca.chain_store_code   chain_store_code  --EDIチェーン店コード
                   ,hp.party_name          party_name        --顧客名称
                   ,hp.party_id            party_id          --パーティID
           FROM     hz_cust_accounts    hca
                   ,xxcmm_cust_accounts xca
                   ,hz_parties          hp
           WHERE    hca.customer_class_code =  '18'  -- チェーン店
           AND      hca.cust_account_id     =  xca.customer_id
           AND      hca.party_id            =  hp.party_id
         )                          hca2   --顧客(チェーン店)
        ,fnd_lookup_values_vl       flvv   --クイックコード(確定フラグ)
WHERE    xesh.to_subinventory_code  = hca1.ship_storage_code
AND      xesh.edi_chain_code        = hca1.chain_store_code
AND      hca1.account_number        =
           ( SELECT   MAX(hca.account_number)
             FROM     hz_cust_accounts    hca
                     ,xxcmm_cust_accounts xca
                     ,hz_parties          hp
             WHERE    hca.customer_class_code =  '10'
             AND      hca.status              =  'A'
             AND      hp.duns_number_c        <> '90'
             AND      hca.party_id            =  hp.party_id
             AND      hca.cust_account_id     =  xca.customer_id
             AND      xca.ship_storage_code   =  hca1.ship_storage_code
             AND      xca.chain_store_code    =  hca1.chain_store_code
             AND      xca.delivery_base_code  =  hca1.delivery_base_code
           )                               --顧客が複数件存在する為、1件に絞る
AND      xesh.to_subinventory_code  = msi.secondary_inventory_name
AND      xesh.organization_id       = msi.organization_id
AND      xesh.edi_chain_code        = hca2.chain_store_code
AND      flvv.lookup_type           = 'XXCOS1_FIX_FLAG'
AND      xesh.fix_flag              = flvv.lookup_code
AND      flvv.enabled_flag          = 'Y'
AND      (
           ( flvv.start_date_active IS NULL )
           OR
           ( flvv.start_date_active <= TRUNC(SYSDATE) )
         )
AND      (
           ( flvv.end_date_active IS NULL )
           OR
           ( flvv.end_date_active >=  TRUNC(SYSDATE) )
         )
/
