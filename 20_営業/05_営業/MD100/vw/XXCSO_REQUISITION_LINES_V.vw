/*************************************************************************
 * 
 * VIEW Name       : xxcso_requisition_lines_v
 * Description     : 共通用：発注依頼明細情報ビュー
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2014/05/01    1.1  K.Nakamura    [E_本稼動_11853]ベンダー購入対応
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_requisition_lines_v
(
 requisition_line_id
,requisition_header_id
,line_num
,category_id
,category_kbn
,blanket_po_header_id
,blanket_po_line_num
,un_number_id
,hazard_class_id
,install_code
,withdraw_install_code
,sp_decision_number
,sp_decision_approval_date
,approval_base
,applicant
,install_at_customer_code
,install_at_customer_name
,install_at_customer_kana
,install_at_zip
,install_at_prefectures
,install_at_city
,install_at_addr1
,install_at_add2
,install_at_area_code
,install_at_phone
,install_at_employee_name
,work_hope_year
,work_hope_month
,work_hope_day
,work_hope_time_type
,work_hope_time_hour
,work_hope_time_minute
,sold_charge_base
,install_place_type
,install_place_floor
,preview_type
,install_step_type
,install_inclination_type
,electric_construction_type
,installed_side_type
,import_step_type
,raising_type
,unic_type
,elevator_frontage
,elevator_depth
,stairs_lift_type
,install_fall_prevention
,concrete_board
,extension_code_type
,extension_code_meter
,lease_type
,withdrawal_type
,abolishment_install_code
,abolishment_approval_reason
,intermediary_company
,remarks1
,remarks2
,remarks3
,work_company_code
,work_location_code
,withdraw_company_code
,withdraw_location_code
-- 2014/05/01 Ver.1.1 Add Start
,declaration_place
-- 2014/05/01 Ver.1.1 Add End
,lookup_start_date
,lookup_end_date
,category_start_date
,category_end_date
,created_by
,creation_date
,last_updated_by
,last_update_date
,last_update_login
)
AS
SELECT
 prl.requisition_line_id
,prl.requisition_header_id
,prl.line_num
,prl.category_id
,flvv.attribute1
,prl.blanket_po_header_id
,prl.blanket_po_line_num
,prl.un_number_id
,prl.hazard_class_id
,prl.attribute1
,prl.attribute2
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'SP_DECISION_NUMBER')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'SP_DECISION_APPROVAL_DATE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'APPROVAL_BASE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'APPLICANT')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_CUSTOMER_CODE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_CUSTOMER_NAME')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_CUSTOMER_KANA')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_ZIP')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_PREFECTURES')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_CITY')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_ADDR1')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_ADD2')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_AREA_CODE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_PHONE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_AT_EMPLOYEE_NAME')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WORK_HOPE_YEAR')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WORK_HOPE_MONTH')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WORK_HOPE_DAY')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WORK_HOPE_TIME_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WORK_HOPE_TIME_HOUR')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WORK_HOPE_TIME_MINUTE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'SOLD_CHARGE_BASE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_PLACE_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_PLACE_FLOOR')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'PREVIEW_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_STEP_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_INCLINATION_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'ELECTRIC_CONSTRUCTION_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALLED_SIDE_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'IMPORT_STEP_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'RAISING_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'UNIC_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'ELEVATOR_FRONTAGE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'ELEVATOR_DEPTH')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'STAIRS_LIFT_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INSTALL_FALL_PREVENTION')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'CONCRETE_BOARD')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'EXTENSION_CODE_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'EXTENSION_CODE_METER')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'LEASE_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WITHDRAWAL_TYPE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'ABOLISHMENT_INSTALL_CODE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'ABOLISHMENT_APPROVAL_REASON')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'INTERMEDIARY_COMPANY')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'REMARKS1')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'REMARKS2')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'REMARKS3')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WORK_COMPANY_CODE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WORK_LOCATION_CODE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WITHDRAW_COMPANY_CODE')
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'WITHDRAW_LOCATION_CODE')
-- 2014/05/01 Ver.1.1 Add Start
,xxcso_ipro_common_pkg.get_temp_info(prl.requisition_line_id,'DECLARATION_PLACE')
-- 2014/05/01 Ver.1.1 Add End
,flvv.start_date_active
,flvv.end_date_active
,mcb.start_date_active
,mcb.end_date_active
,prl.created_by
,prl.creation_date
,prl.last_updated_by
,prl.last_update_date
,prl.last_update_login
FROM
po_requisition_lines prl
,mtl_categories_b mcb
,fnd_lookup_values_vl flvv
WHERE
prl.category_id = mcb.category_id AND
mcb.enabled_flag = 'Y' AND
mcb.segment1 = flvv.meaning(+) AND
flvv.lookup_type(+) = 'XXCSO1_PO_CATEGORY_TYPE'
WITH READ ONLY
;
-- 2014/05/01 Ver.1.1 Add Start
COMMENT ON COLUMN  xxcso_requisition_lines_v.requisition_line_id              IS '購買依頼明細ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.requisition_header_id            IS '購買依頼ヘッダID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.line_num                         IS '購買依頼明細番号';
COMMENT ON COLUMN  xxcso_requisition_lines_v.category_id                      IS 'カテゴリID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.category_kbn                     IS 'カテゴリ区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.blanket_po_header_id             IS '包括発注ヘッダID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.blanket_po_line_num              IS '包括発注明細番号';
COMMENT ON COLUMN  xxcso_requisition_lines_v.un_number_id                     IS '機種ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.hazard_class_id                  IS '機器区分ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_code                     IS '設置用物件コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.withdraw_install_code            IS '引揚用物件コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.sp_decision_number               IS 'SP専決番号';
COMMENT ON COLUMN  xxcso_requisition_lines_v.sp_decision_approval_date        IS 'SP専決承認日';
COMMENT ON COLUMN  xxcso_requisition_lines_v.approval_base                    IS '申請拠点';
COMMENT ON COLUMN  xxcso_requisition_lines_v.applicant                        IS '申請者';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_customer_code         IS '設置先_顧客コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_customer_name         IS '設置先_顧客名';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_customer_kana         IS '設置先_顧客名カナ';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_zip                   IS '設置先_郵便番号';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_prefectures           IS '設置先_都道府県';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_city                  IS '設置先_市・区';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_addr1                 IS '設置先_住所１';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_add2                  IS '設置先_住所２';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_area_code             IS '設置先_地区コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_phone                 IS '設置先_電話番号';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_employee_name         IS '設置先_担当者名';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_year                   IS '作業希望年';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_month                  IS '作業希望月';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_day                    IS '作業希望日';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_time_type              IS '作業希望時間区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_time_hour              IS '作業希望時';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_time_minute            IS '作業希望分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.sold_charge_base                 IS '売上・担当拠点';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_place_type               IS '設置場所区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_place_floor              IS '設置場所階数';
COMMENT ON COLUMN  xxcso_requisition_lines_v.preview_type                     IS '下見区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_step_type                IS '設置段差区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_inclination_type         IS '設置傾斜区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.electric_construction_type       IS '電気工事区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.installed_side_type              IS '据付面区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.import_step_type                 IS '搬入段差区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.raising_type                     IS '手上げ区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.unic_type                        IS 'ユニック区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.elevator_frontage                IS 'エレベータ間口';
COMMENT ON COLUMN  xxcso_requisition_lines_v.elevator_depth                   IS 'エレベータ奥行き';
COMMENT ON COLUMN  xxcso_requisition_lines_v.stairs_lift_type                 IS '階段昇降機区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_fall_prevention          IS '設置転倒防止';
COMMENT ON COLUMN  xxcso_requisition_lines_v.concrete_board                   IS 'コンクリート板';
COMMENT ON COLUMN  xxcso_requisition_lines_v.extension_code_type              IS '延長コード区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.extension_code_meter             IS '延長コード（ｍ）';
COMMENT ON COLUMN  xxcso_requisition_lines_v.lease_type                       IS 'リース区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.withdrawal_type                  IS '引揚区分';
COMMENT ON COLUMN  xxcso_requisition_lines_v.abolishment_install_code         IS '廃棄_物件コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.abolishment_approval_reason      IS '廃棄申請理由';
COMMENT ON COLUMN  xxcso_requisition_lines_v.intermediary_company             IS '仲介会社';
COMMENT ON COLUMN  xxcso_requisition_lines_v.remarks1                         IS '備考１';
COMMENT ON COLUMN  xxcso_requisition_lines_v.remarks2                         IS '備考２';
COMMENT ON COLUMN  xxcso_requisition_lines_v.remarks3                         IS '備考３';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_company_code                IS '作業会社コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_location_code               IS '事業所コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.withdraw_company_code            IS '引揚会社コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.withdraw_location_code           IS '引揚事業所コード';
COMMENT ON COLUMN  xxcso_requisition_lines_v.declaration_place                IS '申告地';
COMMENT ON COLUMN  xxcso_requisition_lines_v.lookup_start_date                IS '品目カテゴリ（営業）適用開始日';
COMMENT ON COLUMN  xxcso_requisition_lines_v.lookup_end_date                  IS '品目カテゴリ（営業）適用終了日';
COMMENT ON COLUMN  xxcso_requisition_lines_v.category_start_date              IS '標準カテゴリ適用開始日';
COMMENT ON COLUMN  xxcso_requisition_lines_v.category_end_date                IS '標準カテゴリ適用終了日';
COMMENT ON COLUMN  xxcso_requisition_lines_v.created_by                       IS '購買依頼明細作成者';
COMMENT ON COLUMN  xxcso_requisition_lines_v.creation_date                    IS '購買依頼明細作成日';
COMMENT ON COLUMN  xxcso_requisition_lines_v.last_updated_by                  IS '購買依頼明細最終更新者';
COMMENT ON COLUMN  xxcso_requisition_lines_v.last_update_date                 IS '購買依頼明細最終更新日';
COMMENT ON COLUMN  xxcso_requisition_lines_v.last_update_login                IS '購買依頼明細最終ログイン';
-- 2014/05/01 Ver.1.1 Add End
COMMENT ON TABLE XXCSO_REQUISITION_LINES_V IS '共通用：発注依頼明細情報ビュー';
