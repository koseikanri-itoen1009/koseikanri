/*************************************************************************
 * 
 * VIEW Name       : xxcso_requisition_lines_v
 * Description     : ���ʗp�F�����˗����׏��r���[
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 *  2014/05/01    1.1  K.Nakamura    [E_�{�ғ�_11853]�x���_�[�w���Ή�
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
COMMENT ON COLUMN  xxcso_requisition_lines_v.requisition_line_id              IS '�w���˗�����ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.requisition_header_id            IS '�w���˗��w�b�_ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.line_num                         IS '�w���˗����הԍ�';
COMMENT ON COLUMN  xxcso_requisition_lines_v.category_id                      IS '�J�e�S��ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.category_kbn                     IS '�J�e�S���敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.blanket_po_header_id             IS '������w�b�_ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.blanket_po_line_num              IS '��������הԍ�';
COMMENT ON COLUMN  xxcso_requisition_lines_v.un_number_id                     IS '�@��ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.hazard_class_id                  IS '�@��敪ID';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_code                     IS '�ݒu�p�����R�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.withdraw_install_code            IS '���g�p�����R�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.sp_decision_number               IS 'SP�ꌈ�ԍ�';
COMMENT ON COLUMN  xxcso_requisition_lines_v.sp_decision_approval_date        IS 'SP�ꌈ���F��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.approval_base                    IS '�\�����_';
COMMENT ON COLUMN  xxcso_requisition_lines_v.applicant                        IS '�\����';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_customer_code         IS '�ݒu��_�ڋq�R�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_customer_name         IS '�ݒu��_�ڋq��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_customer_kana         IS '�ݒu��_�ڋq���J�i';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_zip                   IS '�ݒu��_�X�֔ԍ�';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_prefectures           IS '�ݒu��_�s���{��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_city                  IS '�ݒu��_�s�E��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_addr1                 IS '�ݒu��_�Z���P';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_add2                  IS '�ݒu��_�Z���Q';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_area_code             IS '�ݒu��_�n��R�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_phone                 IS '�ݒu��_�d�b�ԍ�';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_at_employee_name         IS '�ݒu��_�S���Җ�';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_year                   IS '��Ɗ�]�N';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_month                  IS '��Ɗ�]��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_day                    IS '��Ɗ�]��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_time_type              IS '��Ɗ�]���ԋ敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_time_hour              IS '��Ɗ�]��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_hope_time_minute            IS '��Ɗ�]��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.sold_charge_base                 IS '����E�S�����_';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_place_type               IS '�ݒu�ꏊ�敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_place_floor              IS '�ݒu�ꏊ�K��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.preview_type                     IS '�����敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_step_type                IS '�ݒu�i���敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_inclination_type         IS '�ݒu�X�΋敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.electric_construction_type       IS '�d�C�H���敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.installed_side_type              IS '���t�ʋ敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.import_step_type                 IS '�����i���敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.raising_type                     IS '��グ�敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.unic_type                        IS '���j�b�N�敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.elevator_frontage                IS '�G���x�[�^�Ԍ�';
COMMENT ON COLUMN  xxcso_requisition_lines_v.elevator_depth                   IS '�G���x�[�^���s��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.stairs_lift_type                 IS '�K�i���~�@�敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.install_fall_prevention          IS '�ݒu�]�|�h�~';
COMMENT ON COLUMN  xxcso_requisition_lines_v.concrete_board                   IS '�R���N���[�g��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.extension_code_type              IS '�����R�[�h�敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.extension_code_meter             IS '�����R�[�h�i���j';
COMMENT ON COLUMN  xxcso_requisition_lines_v.lease_type                       IS '���[�X�敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.withdrawal_type                  IS '���g�敪';
COMMENT ON COLUMN  xxcso_requisition_lines_v.abolishment_install_code         IS '�p��_�����R�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.abolishment_approval_reason      IS '�p���\�����R';
COMMENT ON COLUMN  xxcso_requisition_lines_v.intermediary_company             IS '������';
COMMENT ON COLUMN  xxcso_requisition_lines_v.remarks1                         IS '���l�P';
COMMENT ON COLUMN  xxcso_requisition_lines_v.remarks2                         IS '���l�Q';
COMMENT ON COLUMN  xxcso_requisition_lines_v.remarks3                         IS '���l�R';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_company_code                IS '��Ɖ�ЃR�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.work_location_code               IS '���Ə��R�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.withdraw_company_code            IS '���g��ЃR�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.withdraw_location_code           IS '���g���Ə��R�[�h';
COMMENT ON COLUMN  xxcso_requisition_lines_v.declaration_place                IS '�\���n';
COMMENT ON COLUMN  xxcso_requisition_lines_v.lookup_start_date                IS '�i�ڃJ�e�S���i�c�Ɓj�K�p�J�n��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.lookup_end_date                  IS '�i�ڃJ�e�S���i�c�Ɓj�K�p�I����';
COMMENT ON COLUMN  xxcso_requisition_lines_v.category_start_date              IS '�W���J�e�S���K�p�J�n��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.category_end_date                IS '�W���J�e�S���K�p�I����';
COMMENT ON COLUMN  xxcso_requisition_lines_v.created_by                       IS '�w���˗����׍쐬��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.creation_date                    IS '�w���˗����׍쐬��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.last_updated_by                  IS '�w���˗����׍ŏI�X�V��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.last_update_date                 IS '�w���˗����׍ŏI�X�V��';
COMMENT ON COLUMN  xxcso_requisition_lines_v.last_update_login                IS '�w���˗����׍ŏI���O�C��';
-- 2014/05/01 Ver.1.1 Add End
COMMENT ON TABLE XXCSO_REQUISITION_LINES_V IS '���ʗp�F�����˗����׏��r���[';
