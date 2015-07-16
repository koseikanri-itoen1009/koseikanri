CREATE OR REPLACE PACKAGE BODY APPS.XXCOI003A18C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI003A18C(body)
 * Description      : ���_�ԑq��CSV�A�b�v���[�h
 * MD.050           : ���_�ԑq��CSV�A�b�v���[�h MD050_COI_003_A18
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������                              (A-1)
 *  get_if_data                  IF�f�[�^�擾                          (A-2)
 *  divide_item                  �A�b�v���[�h�t�@�C�����ڕ���          (A-3)
 *  validate_item                �Ó����`�F�b�N�����ڒl���o            (A-4)
 *  ins_hht_inv_tran             HHT���o�Ɉꎞ�\�o�^                   (A-5)
 *  ins_lot_trx_temp             ���b�g�ʎ��TEMP�o�^                  (A-6)
 *  delete_if_data               IF�f�[�^�폜                          (A-7)
 *
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/06/24    1.0   S.Yamashita      �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N�G���[
  lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI003A18C'; -- �p�b�P�[�W��
--
  cv_csv_delimiter      CONSTANT VARCHAR2(1) := ',';        -- �J���}
  cv_const_y            CONSTANT VARCHAR2(1) := 'Y';        -- 'Y'
  cv_const_n            CONSTANT VARCHAR2(1) := 'N';        -- 'N'
  cv_const_a            CONSTANT VARCHAR2(1) := 'A';        -- �ڋq�X�e�[�^�X�F'A'�i�L���j
  cv_const_e            CONSTANT VARCHAR2(1) := 'E';        -- �ۊǏꏊ�ϊ��敪�F'E'�i�a���拒�_�j
  cv_const_d            CONSTANT VARCHAR2(1) := 'D';        -- �ۊǏꏊ�ϊ��敪�F'D'�i�����_�j
  cv_status_0           CONSTANT VARCHAR2(1) := '0';        -- �����X�e�[�^�X�F'0'�i�������j
  cv_kuragae_div_1      CONSTANT VARCHAR2(1) := '1';        -- �q�֑Ώۉۋ敪�F'1'�i�q�։j
  cv_sales_class_1      CONSTANT VARCHAR2(1) := '1';        -- ����Ώۋ敪�F'1'�i�Ώہj
  cv_subinv_kbn_1       CONSTANT VARCHAR2(1) := '1';        -- �ۊǏꏊ�敪�F'1'�i�q�Ɂj
  cv_subinv_kbn_4       CONSTANT VARCHAR2(1) := '4';        -- �ۊǏꏊ�敪�F'4'�i���X�j
  cv_cust_class_code_1  CONSTANT VARCHAR2(1) := '1';        -- �ڋq�敪�F'1'�i���_�j
  cv_cust_class_code_10 CONSTANT VARCHAR2(2) := '10';       -- �ڋq�敪�F'10'�i�ڋq�j
  cv_cust_status_30     CONSTANT VARCHAR2(2) := '30';       -- �ڋq�X�e�[�^�X�F'30'�i���F�ρj
  cv_cust_status_40     CONSTANT VARCHAR2(2) := '40';       -- �ڋq�X�e�[�^�X�F'40'�i�ڋq�j
  cv_cust_status_50     CONSTANT VARCHAR2(2) := '50';       -- �ڋq�X�e�[�^�X�F'50'�i�x�~�j
  cv_cust_low_type_21   CONSTANT VARCHAR2(2) := '21';       -- �Ƒԏ����ށF'21'�i�C���V���b�v�j
  cv_cust_low_type_22   CONSTANT VARCHAR2(2) := '22';       -- �Ƒԏ����ށF'22'�i���В��c�j
  cv_dept_hht_div_1     CONSTANT VARCHAR2(1) := '1';        -- �S�ݓXHHT�敪�F'1'�i�S�ݓX�j
  cv_dept_hht_div_2     CONSTANT VARCHAR2(1) := '2';        -- �S�ݓXHHT�敪�F'2'�i���_�P�j
  cv_flag_normal_0      CONSTANT VARCHAR2(1) := '0';        -- �G���[�t���O�F'0'�i����j
  cv_flag_err_1         CONSTANT VARCHAR2(1) := '1';        -- �G���[�t���O�F'1'�i�G���[�j
  cv_record_type_30     CONSTANT VARCHAR2(2) := '30';       -- ���R�[�h��ʁF'30'�i���o�Ɂj
  cv_invoice_type_9     CONSTANT VARCHAR2(1) := '9';        -- �`�[�敪�F'9'�i�����_�֏o�Ɂj
  cv_invoice_type_4     CONSTANT VARCHAR2(1) := '4';        -- �`�[�敪�F'4'�i�q�ɂ���a����ցj
  cv_invoice_type_5     CONSTANT VARCHAR2(1) := '5';        -- �`�[�敪�F'5'�i�a���悩��q�ɂցj
  cv_base_deliv_flag_0  CONSTANT VARCHAR2(1) := '0';        -- ���_�ԑq�փt���O�F'0'
  cv_department_flag_99 CONSTANT VARCHAR2(2) := '99';       -- �S�ݓX�t���O�F'99'�i�_�~�[�j
  cv_department_flag_5  CONSTANT VARCHAR2(1) := '5';        -- �S�ݓX�t���O�F'5'�i�����_���a����j
  cv_department_flag_6  CONSTANT VARCHAR2(1) := '6';        -- �S�ݓX�t���O�F'6'�i�a���恨�����_�j
  cv_tran_type_code_20  CONSTANT VARCHAR2(2) := '20';       -- ����^�C�v�R�[�h�F20�i�q�ցj
  cv_inout_code_22      CONSTANT VARCHAR2(2) := '22';       -- ���o�ɃR�[�h�F22�i�q�֏o�Ɂj
  cv_invoice_num_0      CONSTANT VARCHAR2(8) := '00000000'; -- �`�[�ԍ�0���ߗp
  cv_status_inactive    CONSTANT VARCHAR2(8) := 'Inactive'; -- �i�ڃX�e�[�^�X�FInactive
--
  cn_unit_price         CONSTANT NUMBER  := 0;      -- �P��:0
--
  cn_c_base_code        CONSTANT NUMBER  := 1;      -- ���_�R�[�h
  cn_c_invoice_date     CONSTANT NUMBER  := 2;      -- �`�[���t
  cn_c_outside_code     CONSTANT NUMBER  := 3;      -- �o�ɑ��R�[�h
  cn_c_inside_code      CONSTANT NUMBER  := 4;      -- ���ɑ��R�[�h
  cn_c_employee_num     CONSTANT NUMBER  := 5;      -- �c�ƈ��R�[�h
  cn_c_item_code        CONSTANT NUMBER  := 6;      -- �i�ڃR�[�h
  cn_c_case_quantity    CONSTANT NUMBER  := 7;      -- �P�[�X��
  cn_c_quantity         CONSTANT NUMBER  := 8;      -- �{��
  cn_c_header_all       CONSTANT NUMBER  := 8;      -- CSV�t�@�C�����ڐ�
--
  -- �o�̓^�C�v
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';--�o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';   --���O(�V�X�e���Ǘ��җp�o�͐�)
--
  -- �����}�X�N
  cv_date_format_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- ���t����
  cv_date_format_ym     CONSTANT VARCHAR2(6)   := 'YYYYMM';      -- ���t����
--
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi        CONSTANT VARCHAR2(5)   := 'XXCOI'; --�A�h�I���F�݌ɗ̈�
  cv_msg_kbn_cos        CONSTANT VARCHAR2(5)   := 'XXCOS'; --�A�h�I���F�̔��̈�
  cv_msg_kbn_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP'; --���ʂ̃��b�Z�[�W
--
  -- �v���t�@�C��
  cv_inv_org_code       CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE'; -- �݌ɑg�D�R�[�h
--
  -- �Q�ƃ^�C�v
  cv_type_upload_obj    CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ'; -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
--
  -- ����R�[�h
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ���b�Z�[�W��
  cv_msg_ccp_90000      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_msg_ccp_90002      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_msg_ccp_90003      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
--
  cv_msg_coi_00005      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';  -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_coi_00006      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_coi_00011      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';  -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_coi_00026      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00026';  -- �݌ɉ�v���ԃX�e�[�^�X�擾�G���[���b�Z�[�W
  cv_msg_coi_00028      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';  -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_coi_10042      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10042';  -- �`�[���t���������b�Z�[�W
  cv_msg_coi_10092      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10092';  -- �������_�擾�G���[���b�Z�[�W
  cv_msg_coi_10142      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10142';  -- �t�@�C���A�b�v���[�hIF�e�[�u�����b�N�G���[���b�Z�[�W
  cv_msg_coi_10214      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10214';  -- �Ǌ����_�擾�G���[
  cv_msg_coi_10215      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10215';  -- �Ǌ����_���ݒ�G���[
  cv_msg_coi_10216      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10216';  -- �ڋq�X�e�[�^�X�G���[
  cv_msg_coi_10227      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10227';  -- �i�ڑ��݃`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10228      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10228';  -- �i�ڃX�e�[�^�X�L���`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10229      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10229';  -- �i�ڔ���Ώۋ敪�L���`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10230      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10230';  -- ��P�ʗL���`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10231      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10231';  -- �݌ɉ�v���ԃ`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10232      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10232';  -- �R���J�����g���̓p�����[�^
  cv_msg_coi_10267      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10267';  -- ���ʐ������G���[���b�Z�[�W
  cv_msg_coi_10271      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10271';  -- �������_�擾�G���[���b�Z�[�W
  cv_msg_coi_10272      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10272';  -- �ڋq�ǉ����擾�G���[���b�Z�[�W
  cv_msg_coi_10318      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10318';  -- ��P�ʑ��݃`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10420      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10420';  -- �o�ɑ�AFF����G���[���b�Z�[�W
  cv_msg_coi_10421      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10421';  -- ���ɑ�AFF����G���[���b�Z�[�W
  cv_msg_coi_10426      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10426';  -- �����ʃG���[���b�Z�[�W
  cv_msg_coi_10508      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10508';  -- �o�ɑ��q�ɊǗ��Ώۋ敪�擾�G���[
  cv_msg_coi_10510      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10510';  -- ���b�g�ʎ��TEMP�쐬�G���[
  cv_msg_coi_10611      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10611';  -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
  cv_msg_coi_10633      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10633';  -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_coi_10635      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10635';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_coi_10661      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10661';  -- �K�{���ڃG���[
  cv_msg_coi_10666      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10666';  -- ���_�Z�L�����e�B�`�F�b�N�G���[���b�Z�[�W�i��ʋ��_�j
  cv_msg_coi_10667      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10667';  -- �o�ɑ��ۊǏꏊ���擾�G���[���b�Z�[�W
  cv_msg_coi_10668      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10668';  -- ���ɑ��ۊǏꏊ���擾�G���[���b�Z�[�W
  cv_msg_coi_10669      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10669';  -- �ΏۊO����G���[���b�Z�[�W
  cv_msg_coi_10670      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10670';  -- CSV�A�b�v���[�h�s�ԍ�
  cv_msg_coi_10671      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10671';  -- HHT���o�Ɉꎞ�\�o�^����
  cv_msg_coi_10672      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10672';  -- ���b�g�ʎ��TEMP�o�^����
  cv_msg_coi_10679      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10679';  -- �������_�s��v�G���[���b�Z�[�W
  cv_msg_coi_10680      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10680';  -- �����擾�G���[���b�Z�[�W
  cv_msg_coi_10681      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10681';  -- �S�ݓX�p������s�G���[���b�Z�[�W
  cv_msg_coi_10682      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10682';  -- �o�ɑ��q�֑ΏۉۃG���[���b�Z�[�W
  cv_msg_coi_10683      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10683';  -- ���ɑ��q�֑ΏۉۃG���[���b�Z�[�W
  cv_msg_coi_10684      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10684';  -- �o�ɑ��R�[�h�����_�G���[���b�Z�[�W
  cv_msg_coi_10685      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10685';  -- ���ɑ��R�[�h�����_�G���[���b�Z�[�W
  cv_msg_coi_10686      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10686';  -- �o�ɑ��R�[�h�i���_�j�����G���[���b�Z�[�W
  cv_msg_coi_10687      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10687';  -- ���ɑ��R�[�h�i���_�j�����G���[���b�Z�[�W
  cv_msg_coi_10688      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10688';  -- �o�ɑ��Ǘ������_�s��v�G���[���b�Z�[�W
  cv_msg_coi_10689      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10689';  -- ���ɑ��Ǘ������_�s��v�G���[���b�Z�[�W
  cv_msg_coi_10690      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10690';  -- �o�ɑ��Ǌ����_�s��v�G���[���b�Z�[�W
  cv_msg_coi_10691      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10691';  -- ���ɑ��Ǌ����_�s��v�G���[���b�Z�[�W
  cv_msg_coi_10692      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10692';  -- �Ƒԏ����ރG���[���b�Z�[�W
  cv_msg_coi_10693      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10693';  -- ���_�Z�L�����e�B�`�F�b�N�G���[���b�Z�[�W�i�Ǘ������_�j
  cv_msg_coi_10694      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10694';  -- ���_�Z�L�����e�B�`�F�b�N�G���[���b�Z�[�W�i�������_�j
  cv_msg_coi_10695      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10695';  -- �o�ɑ��R�[�h�i�q�Ɂj���݃G���[���b�Z�[�W
  cv_msg_coi_10696      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10696';  -- �Ǘ������_�擾�G���[���b�Z�[�W
  cv_msg_coi_10697      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10697';  -- �c�ƈ��������_�擾�G���[���b�Z�[�W
  cv_msg_coi_10698      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10698';  -- �����i�Ǘ����j���_�s��v�G���[���b�Z�[�W
  cv_msg_coi_10699      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10699';  -- �`�[���t�`���G���[���b�Z�[�W
  cv_msg_coi_10707      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10707';  -- ���l�`���G���[���b�Z�[�W�i�P�[�X���j
  cv_msg_coi_10708      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10708';  -- ���l�`���G���[���b�Z�[�W�i�{���j
  
--
  cv_msg_cos_11293      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11293';  -- �t�@�C���A�b�v���[�h���̎擾�G���[���b�Z�[�W
  cv_msg_cos_11295      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11295';  -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
--
  -- ���b�Z�[�W��(�g�[�N��)
  cv_tkn_coi_10502       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10502';  -- ���_�R�[�h
  cv_tkn_coi_10673       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10673';  -- �`�[���t
  cv_tkn_coi_10674       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10674';  -- �o�ɑ��R�[�h
  cv_tkn_coi_10675       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10675';  -- ���ɑ��R�[�h
  cv_tkn_coi_10676       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10676';  -- �c�ƈ��R�[�h
  cv_tkn_coi_10677       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10677';  -- �i�ڃR�[�h
  cv_tkn_coi_10586       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10586';  -- �P�[�X��
  cv_tkn_coi_10678       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10678';  -- �{��
  cv_tkn_coi_10634       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10634';  -- �t�@�C���A�b�v���[�hIF
--
  -- �g�[�N����
  cv_tkn_pro_tok         CONSTANT VARCHAR2(100) := 'PRO_TOK';         -- �v���t�@�C����
  cv_tkn_org_code_tok    CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';    -- �݌ɑg�D�R�[�h
  cv_tkn_file_id         CONSTANT VARCHAR2(100) := 'FILE_ID';         -- �t�@�C��ID
  cv_tkn_file_name       CONSTANT VARCHAR2(100) := 'FILE_NAME';       -- �t�@�C����
  cv_tkn_file_upld_name  CONSTANT VARCHAR2(100) := 'FILE_UPLD_NAME';  -- �t�@�C���A�b�v���[�h����
  cv_tkn_format_ptn      CONSTANT VARCHAR2(100) := 'FORMAT_PTN';      -- �t�H�[�}�b�g�p�^�[��
  cv_tkn_base_code       CONSTANT VARCHAR2(100) := 'BASE_CODE';       -- ���_�R�[�h
  cv_tkn_dept_code       CONSTANT VARCHAR2(100) := 'DEPT_CODE';       -- ���_�R�[�h
  cv_tkn_dept_code1      CONSTANT VARCHAR2(100) := 'DEPT_CODE1';      -- ���_�R�[�h1
  cv_tkn_dept_code2      CONSTANT VARCHAR2(100) := 'DEPT_CODE2';      -- ���_�R�[�h2
  cv_tkn_item_code       CONSTANT VARCHAR2(100) := 'ITEM_CODE';       -- �i�ڃR�[�h
  cv_tkn_item_column     CONSTANT VARCHAR2(100) := 'ITEM_COLUMN';     -- ���ږ���
  cv_tkn_primary_uom     CONSTANT VARCHAR2(100) := 'PRIMARY_UOM';     -- ��P��
  cv_tkn_target_date     CONSTANT VARCHAR2(100) := 'TARGET_DATE';     -- �Ώۓ�
  cv_tkn_invoice_date    CONSTANT VARCHAR2(100) := 'INVOICE_DATE';    -- �`�[���t
  cv_tkn_subinv_code     CONSTANT VARCHAR2(100) := 'SUBINV_CODE';     -- �ۊǏꏊ�R�[�h
  cv_tkn_sub_inv_code    CONSTANT VARCHAR2(100) := 'SUB_INV_CODE';    -- �ۊǏꏊ�R�[�h
  cv_tkn_employee_num    CONSTANT VARCHAR2(100) := 'EMPLOYEE_NUM';    -- �c�ƈ��R�[�h
  cv_tkn_cust_code       CONSTANT VARCHAR2(100) := 'CUST_CODE';       -- �ڋq�R�[�h
  cv_tkn_outside_code    CONSTANT VARCHAR2(100) := 'OUTSIDE_CODE';    -- �o�ɑ��R�[�h
  cv_tkn_inside_code     CONSTANT VARCHAR2(100) := 'INSIDE_CODE';     -- ���ɑ��R�[�h
  cv_tkn_table_name      CONSTANT VARCHAR2(100) := 'TABLE_NAME';      -- �e�[�u����
  cv_tkn_record_type     CONSTANT VARCHAR2(100) := 'RECORD_TYPE';     -- ���R�[�h���
  cv_tkn_invoice_type    CONSTANT VARCHAR2(100) := 'INVOICE_TYPE';    -- �`�[�敪
  cv_tkn_dept_flag       CONSTANT VARCHAR2(100) := 'DEPT_FLAG';       -- �S�ݓX�t���O
  cv_tkn_invoice_no      CONSTANT VARCHAR2(100) := 'INVOICE_NO';      -- �`�[No
  cv_tkn_column_no       CONSTANT VARCHAR2(100) := 'COLUMN_NO';       -- �R����No
  cv_tkn_key_data        CONSTANT VARCHAR2(100) := 'KEY_DATA';        -- �L�[�f�[�^
  cv_tkn_line_num        CONSTANT VARCHAR2(100) := 'LINE_NUM';        -- �s�ԍ�
  cv_tkn_err_msg         CONSTANT VARCHAR2(100) := 'ERR_MSG';         -- �G���[���b�Z�[�W
  cv_tkn_data            CONSTANT VARCHAR2(100) := 'DATA';            -- �f�[�^
--
  cv_base_dummy          CONSTANT VARCHAR2(5) := 'DUMMY';             -- �_�~�[�l
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �������ڕ�����f�[�^�i�[�p
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER; -- 1�����z��
  g_if_data_tab             g_var_data_ttype;                                   -- ���_�ԑq�փf�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_inv_org_code           VARCHAR2(100);   -- �݌ɑg�D�R�[�h
  gn_inv_org_id             NUMBER;          -- �݌ɑg�DID
  gn_hht_inv_tran_cnt       NUMBER;          -- HHT���o�Ɉꎞ�\�o�^����
  gn_lot_trx_temp_cnt       NUMBER;          -- ���b�g�ʎ��TEMP�o�^����
  gv_err_flag               VARCHAR2(1);     -- �G���[�t���O
  gv_validate_err_flag      VARCHAR2(1);     -- �Ó����G���[�t���O
  gv_line_num               VARCHAR2(5000);  -- CSV�A�b�v���[�h�s�ԍ�
  gd_process_date           DATE;            -- �Ɩ����t
  gd_invoice_date           DATE;            -- �`�[���t
  gv_belong_base_code       xxcoi_hht_inv_transactions.base_code%TYPE; -- �������_�R�[�h
--
  gt_transaction_id         xxcoi_hht_inv_transactions.transaction_id%TYPE;       -- ���o�Ɉꎞ�\ID
  gt_invoice_no             xxcoi_hht_inv_transactions.invoice_no%TYPE;           -- �`�[No
  gt_dept_hht_div           xxcmm_cust_accounts.dept_hht_div%TYPE;                -- �S�ݓXHHT�敪
  gt_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE;            -- �i��ID
  gt_primary_uom_code       mtl_system_items_b.primary_uom_code%TYPE;             -- ��P�ʃR�[�h
  gt_case_in_qty            xxcoi_hht_inv_transactions.case_in_quantity%TYPE;     -- ����
  gt_total_qty              xxcoi_hht_inv_transactions.total_quantity%TYPE;       -- ���{��
  gt_invoice_type           xxcoi_hht_inv_transactions.invoice_type%TYPE;         -- �`�[�敪
  gt_department_flag        xxcoi_hht_inv_transactions.department_flag%TYPE;      -- �S�ݓX�t���O
  gt_out_base_code          xxcoi_hht_inv_transactions.base_code%TYPE;            -- �o�ɑ����_�R�[�h
  gt_in_base_code           xxcoi_hht_inv_transactions.base_code%TYPE;            -- ���ɑ����_�R�[�h
  gt_out_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE;  -- �o�ɑ��ۊǏꏊ�R�[�h
  gt_in_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;   -- ���ɑ��ۊǏꏊ�R�[�h
  gt_out_warehouse_flag     mtl_secondary_inventories.attribute14%TYPE;           -- �o�ɑ��q�ɊǗ��Ώۋ敪
  gt_out_subinv_code_conv   xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE; -- �o�ɑ��ۊǏꏊ�ϊ��敪
  gt_in_subinv_code_conv    xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;  -- ���ɑ��ۊǏꏊ�ϊ��敪
  gt_out_business_low_type  xxcoi_hht_inv_transactions.outside_business_low_type%TYPE;    -- �o�ɑ��Ƒԏ�����
  gt_in_business_low_type   xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;     -- ���ɑ��Ƒԏ�����
  gt_out_cust_code          xxcoi_hht_inv_transactions.outside_cust_code%TYPE;            -- �o�ɑ��ڋq�R�[�h
  gt_in_cust_code           xxcoi_hht_inv_transactions.inside_cust_code%TYPE;             -- ���ɑ��ڋq�R�[�h
  gt_hht_program_div        xxcoi_hht_inv_transactions.hht_program_div%TYPE;              -- ���o�ɃW���[�i�������敪
  gt_item_convert_div       xxcoi_hht_inv_transactions.item_convert_div%TYPE;             -- ���i�U�֋敪
  gt_stock_uncheck_list_div xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;       -- ���ɖ��m�F���X�g�Ώۋ敪
  gt_stock_balance_list_div xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;       -- ���ɍ��يm�F���X�g�Ώۋ敪
  gt_consume_vd_flag        xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;              -- ����VD��[�Ώۃt���O
--
  -- �t�@�C���A�b�v���[�hIF�f�[�^
  gt_file_line_data_tab      xxccp_common_pkg2.g_file_data_tbl;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER,       --   �t�@�C��ID
    iv_file_format IN  VARCHAR2,     --   �t�@�C���t�H�[�}�b�g
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- �݌ɑg�D�R�[�h�̎擾
    -- ===============================
    gv_inv_org_code := FND_PROFILE.VALUE( cv_inv_org_code );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_00005 -- �݌ɑg�D�R�[�h�擾�G���[
                    ,iv_token_name1   => cv_tkn_pro_tok
                    ,iv_token_value1  => cv_inv_org_code  -- �v���t�@�C���F�݌ɑg�D�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �݌ɑg�DID�̎擾
    -- ===============================
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => gv_inv_org_code
                     );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_00006  -- �݌ɑg�DID�擾�G���[
                    ,iv_token_name1  => cv_tkn_org_code_tok
                    ,iv_token_value1 => gv_inv_org_code   -- �݌ɑg�D�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ɩ����t�̎擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �擾�ł��Ȃ��ꍇ
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_00011 -- �Ɩ����t�擾�G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �������_�R�[�h�̎擾
    -- ===============================
    gv_belong_base_code := xxcoi_common_pkg.get_base_code(
                             in_user_id     => cn_created_by  -- ���[�U�[ID
                            ,id_target_date => SYSDATE        -- �Ώۓ�
                           );
    IF ( gv_belong_base_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10271  -- �������_�擾�G���[���b�Z�[�W
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �S�ݓXHHT�敪�̎擾
    -- ===============================
    BEGIN
      SELECT xca.dept_hht_div  AS dept_hht_div -- �S�ݓXHHT�敪
      INTO   gt_dept_hht_div -- �S�ݓXHHT�敪
      FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
            ,xxcmm_cust_accounts    xca -- �ڋq�ǉ����
      WHERE  hca.cust_account_id     = xca.customer_id       -- �ڋqID
      AND    hca.customer_class_code = cv_cust_class_code_1  -- �ڋq�敪(���_)
      AND    hca.status              = cv_const_a            -- �X�e�[�^�X(�L��)
      AND    hca.account_number      = gv_belong_base_code   -- �ڋq�R�[�h(�������_�ƈ�v)
      ;
    EXCEPTION
      -- �擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10272    -- �ڋq�ǉ����擾�G���[���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_base_code
                    ,iv_token_value1 => gv_belong_base_code -- �������_�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
    -- �R���J�����g���̓p�����[�^�o��(���O)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => xxccp_common_pkg.get_msg(
                 iv_application   => cv_msg_kbn_coi
                ,iv_name          => cv_msg_coi_10232    -- �R���J�����g���̓p�����[�^
                ,iv_token_name1   => cv_tkn_file_id
                ,iv_token_value1  => TO_CHAR(in_file_id) -- �t�@�C��ID
                ,iv_token_name2   => cv_tkn_format_ptn
                ,iv_token_value2  => iv_file_format      -- �t�H�[�}�b�g�p�^�[��
               )
    );
--
    -- �R���J�����g���̓p�����[�^�o��(�o��)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT,
      buff  => xxccp_common_pkg.get_msg(
                 iv_application   => cv_msg_kbn_coi
                ,iv_name          => cv_msg_coi_10232    -- �R���J�����g���̓p�����[�^
                ,iv_token_name1   => cv_tkn_file_id
                ,iv_token_value1  => TO_CHAR(in_file_id) -- �t�@�C��ID
                ,iv_token_name2   => cv_tkn_format_ptn
                ,iv_token_value2  => iv_file_format      -- �t�H�[�}�b�g�p�^�[��
                )
    );
    -- ��s���o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
      ,buff  => ''
    );
    -- ��s���o�́i�o�́j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : IF�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id     IN  NUMBER,       --   �t�@�C��ID
    iv_file_format IN  VARCHAR2,     --   �t�@�C���t�H�[�}�b�g
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_file_name        xxccp_mrp_file_ul_interface.file_name%TYPE;  -- �t�@�C����
    lt_file_upload_name fnd_lookup_values.description%TYPE;          -- �t�@�C���A�b�v���[�h����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�J���ϐ�������
    lt_file_name        := NULL; -- �t�@�C����
    lt_file_upload_name := NULL; -- �t�@�C���A�b�v���[�h����
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hIF�f�[�^���b�N
    -- ===============================
    BEGIN
      SELECT  xfu.file_name AS file_name -- �t�@�C����
        INTO  lt_file_name -- �t�@�C����
        FROM  xxccp_mrp_file_ul_interface  xfu -- �t�@�C���A�b�v���[�hIF
       WHERE  xfu.file_id = in_file_id -- �t�@�C��ID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ���b�N���擾�ł��Ȃ��ꍇ
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi
                      ,iv_name          => cv_msg_coi_10142 -- �t�@�C���A�b�v���[�hIF�e�[�u�����b�N�G���[���b�Z�[�W
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h���̏��擾
    -- ===============================
    BEGIN
      SELECT  flv.meaning AS file_upload_name -- �t�@�C���A�b�v���[�h����
        INTO  lt_file_upload_name -- �t�@�C���A�b�v���[�h����
        FROM  fnd_lookup_values flv -- �N�C�b�N�R�[�h
       WHERE  flv.lookup_type  = cv_type_upload_obj  -- �^�C�v
         AND  flv.lookup_code  = iv_file_format      -- �R�[�h
         AND  flv.enabled_flag = cv_const_y          -- �L���t���O(Y)
         AND  flv.language     = ct_lang             -- ����
         AND  NVL(flv.start_date_active, gd_process_date) <= gd_process_date  -- �L���J�n��
         AND  NVL(flv.end_date_active, gd_process_date)   >= gd_process_date  -- �L���I����
      ;
    EXCEPTION
      -- �t�@�C���A�b�v���[�h���̂��擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_cos
                      ,iv_name          => cv_msg_cos_11293 -- �t�@�C���A�b�v���[�h���̎擾�G���[���b�Z�[�W
                      ,iv_token_name1   => cv_tkn_key_data
                      ,iv_token_value1  => iv_file_format   -- �t�H�[�}�b�g�p�^�[��
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- �擾�����t�@�C�����A�t�@�C���A�b�v���[�h���̂��o��
    -- ===============================
    -- �t�@�C�������o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi
                 ,iv_name          => cv_msg_coi_00028 -- �t�@�C�����o�̓��b�Z�[�W
                 ,iv_token_name1   => cv_tkn_file_name
                 ,iv_token_value1  => lt_file_name     -- �t�@�C����
                )
    );
    -- �t�@�C�������o�́i�o�́j
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
     ,buff    => xxccp_common_pkg.get_msg(
                   iv_application   => cv_msg_kbn_coi
                  ,iv_name          => cv_msg_coi_00028 -- �t�@�C�����o�̓��b�Z�[�W
                  ,iv_token_name1   => cv_tkn_file_name
                  ,iv_token_value1  => lt_file_name     -- �t�@�C����
                 )
    );
--
    -- �t�@�C���A�b�v���[�h���̂��o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi
                 ,iv_name          => cv_msg_coi_10611    -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                 ,iv_token_name1   => cv_tkn_file_upld_name
                 ,iv_token_value1  => lt_file_upload_name -- �t�@�C���A�b�v���[�h����
                )
    );
    -- �t�@�C���A�b�v���[�h���̂��o�́i�o�́j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi
                 ,iv_name          => cv_msg_coi_10611    -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                 ,iv_token_name1   => cv_tkn_file_upld_name
                 ,iv_token_value1  => lt_file_upload_name -- �t�@�C���A�b�v���[�h����
                )
    );
--
    -- ��s���o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
      ,buff  => ''
    );
    -- ��s���o�́i�o�́j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hIF�f�[�^���擾
    -- ===============================
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id            -- �t�@�C��ID
     ,ov_file_data => gt_file_line_data_tab -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���ʊ֐��G���[�A�܂��͒��o�s����1�s�ȏ�Ȃ������ꍇ
    IF ( (lv_retcode <> cv_status_normal)
      OR (gt_file_line_data_tab.COUNT < 1) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_10635 -- �f�[�^���o�G���[���b�Z�[�W
                    ,iv_token_name1   => cv_tkn_table_name
                    ,iv_token_value1  => cv_tkn_coi_10634 -- �t�@�C���A�b�v���[�hIF
                    ,iv_token_name2   => cv_tkn_key_data
                    ,iv_token_value2  => NULL
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώی�����ݒ�
    -- ===============================
    gn_target_cnt := gt_file_line_data_tab.COUNT;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : �A�b�v���[�h�t�@�C�����ڕ���(A-3)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_file_if_loop_cnt    IN  NUMBER,   --   IF���[�v�J�E���^
    ov_errbuf              OUT VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_rec_data     VARCHAR2(32765); -- ���R�[�h�f�[�^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- ���[�J���ϐ�������
    -- ===============================
    lv_rec_data  := NULL; -- ���R�[�h�f�[�^
--
    -- ===============================
    -- ���ڐ��`�F�b�N
    -- ===============================
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) <> ( cn_c_header_all - 1 ) )
    THEN
      -- ���ڐ��s��v�̏ꍇ
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_10670 -- CSV�A�b�v���[�h�s�ԍ�
                    ,iv_token_name1   => cv_tkn_line_num
                    ,iv_token_value1  => in_file_if_loop_cnt -- ���[�v�J�E���^
                   ) ||
                   xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_cos
                    ,iv_name          => cv_msg_cos_11295 -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
                    ,iv_token_name1   => cv_tkn_data
                    ,iv_token_value1  => lv_rec_data      -- ���_�ԑq�փf�[�^
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �������[�v
    -- ===============================
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header_all LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                                    iv_char     => gt_file_line_data_tab(in_file_if_loop_cnt)
                                   ,iv_delim    => cv_csv_delimiter
                                   ,in_part_num => i
                                  );
    END LOOP data_split_loop;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : �Ó����`�F�b�N�����ڒl���o(A-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    in_if_loop_cnt IN  NUMBER,   -- IF���[�v�J�E���^
    ov_errbuf      OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_item'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_baracya_type_0      VARCHAR2(1)  := '0';            -- �o�����敪:0�i���̑��j
    cv_num_format_case     VARCHAR2(9)  := 'FM9999999';    -- ���l�����i�P�[�X���j
    cv_num_format_qty      VARCHAR2(12) := 'FM9999990.00'; -- ���l�����i�{���j
    
--
    -- *** ���[�J���ϐ� ***
    ln_select_count        NUMBER;  -- ���o����
    lt_item_status         mtl_system_items_b.inventory_item_status_code%TYPE;    -- �i�ڃX�e�[�^�X
    lt_cust_order_flg      mtl_system_items_b.customer_order_enabled_flag%TYPE;   -- �ڋq�󒍉\�t���O
    lt_transaction_enable  mtl_system_items_b.mtl_transactions_enabled_flag%TYPE; -- ����\
    lt_stock_enabled_flg   mtl_system_items_b.stock_enabled_flag%TYPE;            -- �݌ɕۗL�\�t���O
    lt_return_enable       mtl_system_items_b.returnable_flag%TYPE;               -- �ԕi�\
    lt_sales_class         ic_item_mst_b.attribute26%TYPE;                        -- ����Ώۋ敪
    lt_baracha_div         xxcmm_system_items_b.baracha_div%TYPE;                 -- �o�����敪
    ld_disable_date        DATE;                                                  -- ������
    lb_org_acct_period_flg BOOLEAN;                                               -- ��v���ԃI�[�v���t���O
    lv_emp_base_code       per_all_assignments_f.ass_attribute5%TYPE;             -- �������_�R�[�h
    lv_result_aff_out      VARCHAR2(1);                                           -- AFF����L���`�F�b�N���ʁi�o�ɑ��j
    lv_result_aff_in       VARCHAR2(1);                                           -- AFF����L���`�F�b�N���ʁi���ɑ��j
    lt_start_date_active   fnd_flex_values.start_date_active%TYPE;                -- AFF����K�p�J�n��
    lt_in_warehouse_flag   mtl_secondary_inventories.attribute14%TYPE;            -- ���ɑ��q�ɊǗ��Ώۋ敪
    lt_outside_subinv_div  mtl_secondary_inventories.attribute5%TYPE;             -- �o�ɑ��I���Ώ�
    lt_inside_subinv_div   mtl_secondary_inventories.attribute5%TYPE;             -- ���ɑ��I���Ώ�
    lt_out_subinv_kbn      mtl_secondary_inventories.attribute1%TYPE;             -- �o�ɑ��ۊǏꏊ�敪
    lt_in_subinv_kbn       mtl_secondary_inventories.attribute1%TYPE;             -- ���ɑ��ۊǏꏊ�敪
    lt_out_cust_code       mtl_secondary_inventories.attribute4%TYPE;             -- �o�ɑ��ڋq�R�[�h
    lt_in_cust_code        mtl_secondary_inventories.attribute4%TYPE;             -- ���ɑ��ڋq�R�[�h
    lt_cust_base_code      xxcmm_cust_accounts.sale_base_code%TYPE;               -- �Ǌ����_�R�[�h
    lt_cust_status         hz_parties.duns_number_c%TYPE;                         -- �ڋq�X�e�[�^�X
    lt_cust_low_type       xxcmm_cust_accounts.business_low_type%TYPE;            -- �Ƒԏ�����
    lt_cust_mng_base_code  xxcmm_cust_accounts.management_base_code%TYPE;         -- �Ǘ������_
    lt_emp_mng_base_code   xxcmm_cust_accounts.management_base_code%TYPE;         -- �Ǘ������_�i�c�ƈ��j
    lv_kuragae_div         hz_cust_accounts.attribute6%TYPE;                      -- �q�֑Ώۉۋ敪
    lv_out_err_flag        VARCHAR2(1);  -- �o�ɑ��G���[�t���O
    lv_in_err_flag         VARCHAR2(1);  -- ���ɑ��G���[�t���O
    ln_number_check_case   NUMBER;  -- ���l�`�F�b�N�p�ϐ��i�P�[�X���j
    ln_number_check_qty    NUMBER;  -- ���l�`�F�b�N�p�ϐ��i�{���j
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- ���[�J���ϐ�������
    -- ===============================
    ln_select_count        := 0;      -- ���o����
    lt_item_status         := NULL;   -- �i�ڃX�e�[�^�X
    lt_cust_order_flg      := NULL;   -- �ڋq�󒍉\�t���O
    lt_transaction_enable  := NULL;   -- ����\
    lt_stock_enabled_flg   := NULL;   -- �݌ɕۗL�\�t���O
    lt_return_enable       := NULL;   -- �ԕi�\
    lt_sales_class         := NULL;   -- ����Ώۋ敪
    lt_baracha_div         := NULL;   -- �o�����敪
    ld_disable_date        := NULL;   -- ������
    lb_org_acct_period_flg := FALSE;  -- ��v���ԃI�[�v���t���O
    lv_emp_base_code       := NULL;   -- �������_�R�[�h
    lv_result_aff_out      := NULL;   -- AFF����L���`�F�b�N���ʁi�o�ɑ��j
    lv_result_aff_in       := NULL;   -- AFF����L���`�F�b�N���ʁi���ɑ��j
    lt_start_date_active   := NULL;   -- AFF����K�p�J�n��
    lt_in_warehouse_flag   := NULL;   -- ���ɑ��q�ɊǗ��Ώۋ敪
    lt_outside_subinv_div  := NULL;   -- �o�ɑ��I���Ώ�
    lt_inside_subinv_div   := NULL;   -- ���ɑ��I���Ώ�
    lt_out_subinv_kbn      := NULL;   -- �o�ɑ��ۊǏꏊ�敪
    lt_in_subinv_kbn       := NULL;   -- ���ɑ��ۊǏꏊ�敪
    lt_out_cust_code       := NULL;   -- �o�ɑ��ڋq�R�[�h
    lt_in_cust_code        := NULL;   -- ���ɑ��ڋq�R�[�h
    lt_cust_base_code      := NULL;   -- �Ǌ����_�R�[�h
    lt_cust_status         := NULL;   -- �ڋq�X�e�[�^�X
    lt_cust_low_type       := NULL;   -- �Ƒԏ�����
    lt_cust_mng_base_code  := NULL;   -- �Ǘ������_
    lt_emp_mng_base_code   := NULL;   -- �Ǘ������_�i�c�ƈ��j
    lv_kuragae_div         := NULL;   -- �q�֑Ώۉۋ敪
    lv_out_err_flag        := cv_flag_normal_0; -- �o�ɑ��G���[�t���O
    lv_in_err_flag         := cv_flag_normal_0; -- ���ɑ��G���[�t���O
    ln_number_check_case   := NULL;   -- ���l�`�F�b�N�p�ϐ��i�P�[�X���j
    ln_number_check_qty    := NULL;   -- ���l�`�F�b�N�p�ϐ��i�{���j
--
    -- ===============================
    -- CSV�A�b�v���[�h�s�ԍ����擾
    -- ===============================
    gv_line_num := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_10670 -- CSV�A�b�v���[�h�s�ԍ�
                    ,iv_token_name1   => cv_tkn_line_num
                    ,iv_token_value1  => in_if_loop_cnt   -- ���[�v�J�E���^
                   );
--
    -- ==============================
    -- �K�{�`�F�b�N
    -- ==============================
    -- ���_�R�[�h
    IF ( g_if_data_tab(cn_c_base_code) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- �K�{���ڃG���[
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10502 -- ���_�R�[�h
                      );
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- �`�[���t
    IF ( g_if_data_tab(cn_c_invoice_date) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- �K�{���ڃG���[
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10673 -- �`�[���t
                      );
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- �o�ɑ��R�[�h
    IF ( g_if_data_tab(cn_c_outside_code) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- �K�{���ڃG���[
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10674 -- �o�ɑ��R�[�h
                      );
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- ���ɑ��R�[�h
    IF ( g_if_data_tab(cn_c_inside_code) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- �K�{���ڃG���[
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10675 -- ���ɑ��R�[�h
                     );
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- �i�ڃR�[�h
    IF ( g_if_data_tab(cn_c_item_code) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- �K�{���ڃG���[
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10677 -- �i�ڃR�[�h
                      );
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- �P�[�X��
    IF ( g_if_data_tab(cn_c_case_quantity) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- �K�{���ڃG���[
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10586 -- �P�[�X��
                      );
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- �{��
    IF ( g_if_data_tab(cn_c_quantity) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- �K�{���ڃG���[
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10678 -- �{��
                      );
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- ===============================
    -- ���_�Z�L�����e�B�`�F�b�N
    -- ===============================
    -- ���_�R�[�h��NULL�łȂ��ꍇ�̂݃`�F�b�N
    IF ( g_if_data_tab(cn_c_base_code) IS NOT NULL ) THEN
      -- �S�ݓXHHT�敪��NULL�̏ꍇ
      IF ( gt_dept_hht_div IS NULL ) THEN
        SELECT COUNT(1) AS select_count -- ���o����
        INTO   ln_select_count -- ���o����
        FROM   xxcos_login_base_info_v xlbiv -- ���O�C�����[�U�����_�r���[
        WHERE  xlbiv.base_code = g_if_data_tab(cn_c_base_code)  -- ���_�R�[�h
        ;
--
        -- ���o������0���̏ꍇ�̓G���[
        IF ( ln_select_count = 0 ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10666  -- ���_�Z�L�����e�B�`�F�b�N�G���[���b�Z�[�W�i��ʋ��_�j
                           ,iv_token_name1   => cv_tkn_dept_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_base_code)  -- ���_�R�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
--
      -- �S�ݓXHHT�敪��'1'�i���_���j�̏ꍇ
      ELSIF ( gt_dept_hht_div = cv_dept_hht_div_1 ) THEN
        SELECT COUNT(1)  AS select_count -- ���o����
        INTO   ln_select_count -- ���o����
        FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
              ,xxcmm_cust_accounts    xca -- �ڋq�ǉ����
        WHERE  hca.cust_account_id      = xca.customer_id        -- �ڋqID
        AND    hca.customer_class_code  = cv_cust_class_code_1   -- �ڋq�敪(���_)
        AND    hca.status               = cv_const_a             -- �X�e�[�^�X(�L��)
        AND    hca.account_number       = gv_belong_base_code    -- �ڋq�R�[�h(�������_�ƈ�v)
        AND    xca.management_base_code = g_if_data_tab(cn_c_base_code) -- �Ǘ������_�R�[�h(���_�R�[�h�ƈ�v)
        ;
--
        -- ���o������0���̏ꍇ�̓G���[
        IF ( ln_select_count = 0 ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10693  -- ���_�Z�L�����e�B�`�F�b�N�G���[���b�Z�[�W�i�Ǘ������_�j
                           ,iv_token_name1   => cv_tkn_dept_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_base_code)  -- ���_�R�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
--
      -- �S�ݓXHHT�敪����L�ȊO�̏ꍇ
      ELSE
        SELECT COUNT(1)  AS select_count -- ���o����
        INTO   ln_select_count -- ���o����
        FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
        WHERE  hca.customer_class_code = cv_cust_class_code_1  -- �ڋq�敪(���_)
        AND    hca.status              = cv_const_a            -- �X�e�[�^�X(�L��)
        AND    hca.account_number      = gv_belong_base_code           -- �ڋq�R�[�h�i�������_�ƈ�v�j
        AND    hca.account_number      = g_if_data_tab(cn_c_base_code) -- �ڋq�R�[�h�i���_�R�[�h�ƈ�v�j
        ;
--
        -- ���o������0���̏ꍇ�̓G���[
        IF ( ln_select_count = 0 ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10694  -- ���_�Z�L�����e�B�`�F�b�N�G���[���b�Z�[�W�i�������_�j
                           ,iv_token_name1   => cv_tkn_dept_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_base_code)  -- ���_�R�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
      END IF;
    END IF;
--
    -- ===============================
    -- �i�ڑÓ����`�F�b�N
    -- ===============================
    -- �i�ڃR�[�h��NULL�łȂ��ꍇ�̓`�F�b�N
    IF ( g_if_data_tab(cn_c_item_code) IS NOT NULL ) THEN
      BEGIN
        -- �i�ڏ��擾
        SELECT msib.inventory_item_status_code    AS inventory_item_status_code      -- �i�ڃX�e�[�^�X
              ,msib.customer_order_enabled_flag   AS customer_order_enabled_flag     -- �ڋq�󒍉\�t���O
              ,msib.mtl_transactions_enabled_flag AS mtl_transactions_enabled_flag   -- ����\
              ,msib.stock_enabled_flag            AS stock_enabled_flag              -- �݌ɕۗL�\�t���O
              ,msib.returnable_flag               AS returnable_flag                 -- �ԕi�\
              ,iimb.attribute26                   AS sales_class                     -- ����Ώۋ敪
              ,msib.inventory_item_id             AS inventory_item_id               -- �i��ID
              ,msib.primary_uom_code              AS primary_uom_code                -- ��P�ʃR�[�h
              ,TO_NUMBER(iimb.attribute11)        AS case_in_qty                     -- ����
              ,NVL(xsib.baracha_div,cv_baracya_type_0) AS baracha_div                -- �o�����敪
        INTO   lt_item_status            -- �i�ڃX�e�[�^�X
              ,lt_cust_order_flg         -- �ڋq�󒍉\�t���O
              ,lt_transaction_enable     -- ����\
              ,lt_stock_enabled_flg      -- �݌ɕۗL�\�t���O
              ,lt_return_enable          -- �ԕi�\
              ,lt_sales_class            -- ����Ώۋ敪
              ,gt_inventory_item_id      -- �i��ID
              ,gt_primary_uom_code       -- ��P�ʃR�[�h
              ,gt_case_in_qty            -- ����
              ,lt_baracha_div            -- �o�����敪
        FROM   mtl_system_items_b msib   -- Disc�i�ڃ}�X�^
              ,ic_item_mst_b      iimb   -- OPM�i�ڃ}�X�^
              ,xxcmm_system_items_b xsib -- Disc�i�ڃA�h�I���}�X�^
        WHERE  msib.segment1          = g_if_data_tab(cn_c_item_code) -- �i�ڃR�[�h
        AND    msib.organization_id   = gn_inv_org_id  -- �݌ɑg�DID
        AND    iimb.item_no           = msib.segment1  -- �i�ڃR�[�h
        AND    iimb.item_no           = xsib.item_code -- �i�ڃR�[�h
        ;
      EXCEPTION
        -- �i�ڏ�񂪎擾�ł��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10227 -- �i�ڑ��݃`�F�b�N�G���[���b�Z�[�W
                         ,iv_token_name1   => cv_tkn_item_code
                         ,iv_token_value1  => g_if_data_tab(cn_c_item_code)  -- �i�ڃR�[�h
                        );
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gv_err_flag := cv_flag_err_1;
      END;
--
      -- �i�ڏ�񂪎擾�ł����ꍇ
      IF ( gt_inventory_item_id IS NOT NULL ) THEN
        -- ������NULL�܂���0�ȉ��̏ꍇ
        IF( (gt_case_in_qty IS NULL)
          OR ((gt_case_in_qty IS NOT NULL) AND (gt_case_in_qty <= 0) ))
        THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10680 -- �����擾�G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_item_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_item_code)  -- �i�ڃR�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
--
        -- �i�ڃX�e�[�^�X���L���łȂ��ꍇ
        IF ( lt_item_status = cv_status_inactive   -- �i�ڃX�e�[�^�X
          OR  lt_cust_order_flg     <> cv_const_y  -- �ڋq�󒍉\�t���O
          OR  lt_transaction_enable <> cv_const_y  -- ����\
          OR  lt_stock_enabled_flg  <> cv_const_y  -- �݌ɕۗL�\�t���O
          OR  lt_return_enable      <> cv_const_y  -- �ԕi�\
        )
        THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10228 -- �i�ڃX�e�[�^�X�L���`�F�b�N�G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_item_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_item_code)  -- �i�ڃR�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
--
        -- ����Ώۋ敪�̃`�F�b�N
        IF ( (lt_sales_class <> cv_sales_class_1)
          OR (lt_sales_class IS NULL) )
        THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10229 -- �i�ڔ���Ώۋ敪�L���`�F�b�N�G���[���b�Z�[�W
                             ,iv_token_name1   => cv_tkn_item_code
                             ,iv_token_value1  => g_if_data_tab(cn_c_item_code)  -- �i�ڃR�[�h
                            );
            -- �G���[���b�Z�[�W���o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gv_err_flag := cv_flag_err_1;
        END IF;
--
        -- ��P�ʂ̑Ó����`�F�b�N
        -- ��P�ʂ̖������擾
        xxcoi_common_pkg.get_uom_disable_info(
           iv_unit_code          => gt_primary_uom_code   -- ��P�ʃR�[�h
          ,od_disable_date       => ld_disable_date       -- ������
          ,ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W
          ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h
          ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- ���������擾�ł��Ȃ������ꍇ
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10318    -- ��P�ʑ��݃`�F�b�N�G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_primary_uom
                           ,iv_token_value1  => gt_primary_uom_code -- ��P�ʃR�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
        -- ��P�ʂ��L���łȂ��ꍇ
        IF ( TRUNC( NVL( ld_disable_date, SYSDATE+1 ) ) <= TRUNC( SYSDATE ) ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10230    -- ��P�ʗL���`�F�b�N�G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_primary_uom
                           ,iv_token_value1  => gt_primary_uom_code -- ��P�ʃR�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
      END IF;
    END IF;
--
    -- �P�[�X���A�{�����ݒ肳��Ă���ꍇ�̓`�F�b�N
    IF ( g_if_data_tab(cn_c_case_quantity) IS NOT NULL
      AND  g_if_data_tab(cn_c_quantity)    IS NOT NULL )
    THEN
      -- ===============================
      -- ���l�`���`�F�b�N
      -- ===============================
      -- �P�[�X��
      BEGIN
        ln_number_check_case := TO_NUMBER(g_if_data_tab(cn_c_case_quantity),cv_num_format_case);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10707  -- ���l�`���G���[���b�Z�[�W�i�P�[�X���j
                        );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
      END;
--
      -- �{��
      BEGIN
        ln_number_check_qty := TO_NUMBER(g_if_data_tab(cn_c_quantity),cv_num_format_qty);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10708  -- ���l�`���G���[���b�Z�[�W�i�{���j
                        );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
      END;
--
      -- ���l�`���G���[�i�{���j���������Ă��Ȃ��ꍇ
      IF ( ln_number_check_qty IS NOT NULL ) THEN
        -- ===============================
        -- �����_�`�F�b�N
        -- ===============================
        -- �i�ڂ̃o�����敪���u0�i���̑��j�v�̏ꍇ
        IF ( lt_baracha_div = cv_baracya_type_0 ) THEN
          -- �����_�ȉ��ɐ��l���w�肳�ꂽ�ꍇ�̓G���[
          IF ( MOD( ln_number_check_qty , 1) <> 0 ) THEN
            ln_number_check_qty := NULL;
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10267  -- ���ʐ������G���[���b�Z�[�W
                            );
            -- �G���[���b�Z�[�W���o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gv_err_flag := cv_flag_err_1;
          END IF;
        END IF;
--
        -- ���l�G���[���������Ă��Ȃ��ꍇ
        IF ( ln_number_check_case IS NOT NULL
          AND ln_number_check_qty IS NOT NULL )
        THEN
          -- ===============================
          -- ���{���`�F�b�N
          -- ===============================
          -- ���{�����v�Z
          gt_total_qty := (gt_case_in_qty * ln_number_check_case)
                            + ln_number_check_qty;
          -- ���{����0�̏ꍇ�̓G���[
          IF ( gt_total_qty = 0 ) THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10426  -- �����ʃG���[���b�Z�[�W
                            );
            -- �G���[���b�Z�[�W���o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gv_err_flag := cv_flag_err_1;
          END IF;
        END IF;
      END IF;
    END IF;
--
    -- ===============================
    -- �`�[���t�`�F�b�N
    -- ===============================
    -- �`�[���t��NULL�łȂ��ꍇ�̓`�F�b�N
    IF ( g_if_data_tab(cn_c_invoice_date) IS NOT NULL) THEN
      -- �t�H�[�}�b�g�`�F�b�N
      BEGIN
        gd_invoice_date :=  TO_DATE(g_if_data_tab(cn_c_invoice_date),cv_date_format_ymd);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10699  -- �`�[���t�`���G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_invoice_date
                           ,iv_token_value1  => g_if_data_tab(cn_c_invoice_date) --�`�[���t
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
          -- �ȍ~�̃`�F�b�N�ŃG���[�ƂȂ�Ȃ��悤�Ɩ����t��ݒ�
          gd_invoice_date := gd_process_date;
      END;
--
      -- �������`�F�b�N
      IF ( gd_invoice_date > gd_process_date ) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10042  -- �`�[���t���������b�Z�[�W
                        );
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gv_err_flag := cv_flag_err_1;
      ELSE
        -- �݌ɉ�v���ԃ`�F�b�N
        -- ��v���Ԃ��擾
        xxcoi_common_pkg.org_acct_period_chk(
           in_organization_id => gn_inv_org_id                     -- �݌ɑg�DID
          ,id_target_date     => gd_invoice_date                   -- �`�[���t
          ,ob_chk_result      => lb_org_acct_period_flg            -- �`�F�b�N����
          ,ov_errbuf          => lv_errbuf
          ,ov_retcode         => lv_retcode
          ,ov_errmsg          => lv_errmsg
        );
        -- �݌ɉ�v���ԃX�e�[�^�X�̎擾�Ɏ��s�����ꍇ
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_00026    -- �݌ɉ�v���ԃX�e�[�^�X�擾�G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_target_date
                           ,iv_token_value1  => TO_CHAR(gd_invoice_date,cv_date_format_ymd)     -- �`�[���t
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
--
        -- �݌ɉ�v���Ԃ��N���[�Y�̏ꍇ
        IF ( lb_org_acct_period_flg = FALSE ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10231    -- �݌ɉ�v���ԃ`�F�b�N�G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_invoice_date
                           ,iv_token_value1  => TO_CHAR(gd_invoice_date,cv_date_format_ymd) --�`�[���t
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
        END IF;
      END IF;
    END IF;
--
    -- ===============================
    -- �c�ƈ����_�`�F�b�N
    -- ===============================
    -- �c�ƈ��R�[�h��NULL�łȂ��ꍇ�̓`�F�b�N
    IF ( g_if_data_tab(cn_c_employee_num) IS NOT NULL ) THEN
      xxcoi_common_pkg.get_belonging_base2(
         in_employee_code  => g_if_data_tab(cn_c_employee_num)   -- �c�ƈ��R�[�h
        ,id_target_date    => gd_invoice_date                    -- �`�[���t
        ,ov_base_code      => lv_emp_base_code                   -- �������_�R�[�h
        ,ov_errbuf         => lv_errbuf
        ,ov_retcode        => lv_retcode
        ,ov_errmsg         => lv_errmsg
      );
      -- �������_�R�[�h�̎擾�Ɏ��s�����ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10697    -- �c�ƈ��������_�擾�G���[���b�Z�[�W
                         ,iv_token_name1   => cv_tkn_employee_num
                         ,iv_token_value1  => g_if_data_tab(cn_c_employee_num)  --�c�ƈ��R�[�h
                        );
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gv_err_flag := cv_flag_err_1;
      END IF;
--
      -- �������_�̊Ǘ������_���擾
      BEGIN
        SELECT xca.management_base_code  AS cust_mng_base_code  -- �Ǘ������_�R�[�h
        INTO   lt_emp_mng_base_code  -- �Ǘ������_�R�[�h
        FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
              ,xxcmm_cust_accounts    xca -- �ڋq�ǉ����
        WHERE  hca.cust_account_id      = xca.customer_id        -- �ڋqID
        AND    hca.customer_class_code  = cv_cust_class_code_1   -- �ڋq�敪(���_)
        AND    hca.status               = cv_const_a             -- �X�e�[�^�X(�L��)
        AND    hca.account_number       = lv_emp_base_code       -- �ڋq�R�[�h(�c�ƈ��̏������_�ƈ�v)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
      -- ���_�R�[�h�Ɖc�ƈ��̏������_�R�[�h�܂��͊Ǘ������_�R�[�h���s��v�̏ꍇ
      IF ( g_if_data_tab(cn_c_base_code) <> lv_emp_base_code
        AND g_if_data_tab(cn_c_base_code) <> NVL(lt_emp_mng_base_code,cv_base_dummy)) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10698  -- �����i�Ǘ����j���_�s��v�G���[���b�Z�[�W
                         ,iv_token_name1   => cv_tkn_dept_code
                         ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- ���_�R�[�h
                         ,iv_token_name2   => cv_tkn_dept_code1
                         ,iv_token_value2  => lv_emp_base_code              -- �������_�R�[�h
                         ,iv_token_name3   => cv_tkn_dept_code2
                         ,iv_token_value3  => lt_emp_mng_base_code          -- �Ǘ������_�R�[�h
                        );
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gv_err_flag := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ===============================
    -- ���o�ɃR�[�h�`�F�b�N
    -- ===============================
    -- ���_�R�[�h�A�o�ɑ��i���ɑ��j�R�[�h��NULL�łȂ��ꍇ�̓`�F�b�N
    IF ( g_if_data_tab(cn_c_base_code)     IS NOT NULL
      AND g_if_data_tab(cn_c_outside_code) IS NOT NULL 
      AND g_if_data_tab(cn_c_inside_code)  IS NOT NULL )
    THEN
      -- ===============================
      -- �q�ɂ��瑼���_�̏ꍇ
      -- ===============================
      IF ( LENGTH(g_if_data_tab(cn_c_outside_code)) = 2
        AND LENGTH(g_if_data_tab(cn_c_inside_code)) = 4 )
      THEN
--
        -- ===============================
        -- �o�ɑ��R�[�h�Ó����`�F�b�N
        -- ===============================
        -- �ϐ�������
        ln_select_count := 0;
--
        -- �o�ɑ��ۊǏꏊ�����擾
        SELECT COUNT(1)  AS select_count -- ���o����
        INTO  ln_select_count -- ���o����
        FROM  xxcoi_subinventory_info_v xsiv -- �ۊǏꏊ���r���[
        WHERE xsiv.subinventory_class IN (cv_subinv_kbn_1,cv_subinv_kbn_4) -- �ۊǏꏊ�敪(1:�q�ɂ܂���4:���X)
        AND   gd_process_date <= NVL(xsiv.disable_date-1,gd_process_date)  -- ������
        AND   xsiv.store_code = g_if_data_tab(cn_c_outside_code)           -- �q�ɃR�[�h(�o�ɑ��R�[�h�ƈ�v)
        AND   xsiv.base_code  IN (SELECT hca.account_number  AS base_code -- ���_�R�[�h
                                  FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
                                        ,xxcmm_cust_accounts    xca -- �ڋq�ǉ����
                                  WHERE  hca.cust_account_id      = xca.customer_id        -- �ڋqID
                                  AND    hca.customer_class_code  = cv_cust_class_code_1   -- �ڋq�敪(���_)
                                  AND    hca.status               = cv_const_a             -- �X�e�[�^�X(�L��)
                                  AND    (hca.account_number       = g_if_data_tab(cn_c_base_code) -- �ڋq�R�[�h
                                           OR xca.management_base_code = g_if_data_tab(cn_c_base_code)) -- �Ǘ������_�R�[�h
                                  )
        ;
--
        -- ���o������0���̏ꍇ�̓G���[
        IF ( ln_select_count = 0 ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10695  -- �o�ɑ��R�[�h�i�q�Ɂj���݃G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_outside_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- �o�ɑ��R�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
          lv_out_err_flag := cv_flag_err_1;
        END IF;
--
        -- ===============================
        -- ���ɑ��R�[�h�Ó����`�F�b�N
        -- ===============================
        -- ���_�ԑq�փf�[�^. ���_�R�[�h�Ɠ��ɑ��R�[�h����v����ꍇ
        IF ( g_if_data_tab(cn_c_base_code) = g_if_data_tab(cn_c_inside_code) ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10685  -- ���ɑ��R�[�h�����_�G���[���b�Z�[�W
                           ,iv_token_name1   => cv_tkn_dept_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_base_code)   -- ���_�R�[�h
                           ,iv_token_name2   => cv_tkn_inside_code
                           ,iv_token_value2  => g_if_data_tab(cn_c_inside_code) -- ���ɑ��R�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
          lv_in_err_flag := cv_flag_err_1;
--
        -- �G���[���������Ȃ������ꍇ
        ELSE
          -- �ϐ�������
          ln_select_count := 0;
--
          -- ���ɑ����_�����擾
          SELECT COUNT(1)  AS select_count -- ���o����
          INTO   ln_select_count -- ���o����
          FROM   hz_cust_accounts  hca -- �ڋq�}�X�^
          WHERE  hca.customer_class_code = cv_cust_class_code_1 -- �ڋq�敪(���_)
          AND    hca.attribute6          = cv_kuragae_div_1     -- �q�֑Ώۉۋ敪(Y:�q�։�)
          AND    hca.status              = cv_const_a           -- �X�e�[�^�X(�L��)
          AND    hca.account_number      = g_if_data_tab(cn_c_inside_code)  -- �ڋq�R�[�h(���ɑ��R�[�h�ƈ�v)
          ;
--
          -- ���o������0���̏ꍇ�̓G���[
          IF ( ln_select_count = 0 ) THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10687  -- ���ɑ��R�[�h�i���_�j�����G���[���b�Z�[�W
                             ,iv_token_name1   => cv_tkn_inside_code
                             ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- ���ɑ��R�[�h
                            );
            -- �G���[���b�Z�[�W���o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gv_err_flag := cv_flag_err_1;
            lv_in_err_flag := cv_flag_err_1;
          END IF;
        END IF;
--
        -- ===============================
        -- ���ڒl�̐ݒ�
        -- ===============================
        -- �G���[���������Ȃ������ꍇ
        IF ( lv_out_err_flag = cv_flag_normal_0 
          AND lv_in_err_flag = cv_flag_normal_0 ) THEN
          gt_invoice_type    := cv_invoice_type_9;     -- �`�[�敪�F'9'�i�����_�֏o�Ɂj
          gt_department_flag := cv_department_flag_99; -- �S�ݓX�t���O�F'99'�i�_�~�[�j
        END IF;
--
      -- ===============================
      -- �����_����a����̏ꍇ
      -- ===============================
      ELSIF ( LENGTH(g_if_data_tab(cn_c_outside_code)) = 4
           AND LENGTH(g_if_data_tab(cn_c_inside_code)) = 9 )
      THEN
--
        -- ===============================
        -- ���s���[�U�Z�L�����e�B�`�F�b�N
        -- ===============================
        IF ( gt_dept_hht_div IS NULL ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10681  -- �S�ݓX�p������s�G���[���b�Z�[�W
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
          lv_out_err_flag := cv_flag_err_1;
--
        -- �G���[���������Ȃ������ꍇ�͌㑱�̃`�F�b�N���s��
        ELSE
          -- ===============================
          -- �o�ɑ��R�[�h�Ó����`�F�b�N
          -- ===============================
          -- ���_�ԑq�փf�[�^. ���_�R�[�h�Əo�ɑ��R�[�h����v����ꍇ
          IF ( g_if_data_tab(cn_c_base_code) = g_if_data_tab(cn_c_outside_code) ) THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10684  -- �o�ɑ��R�[�h�����_�G���[���b�Z�[�W
                             ,iv_token_name1   => cv_tkn_dept_code
                             ,iv_token_value1  => g_if_data_tab(cn_c_base_code)   -- ���_�R�[�h
                             ,iv_token_name2   => cv_tkn_outside_code
                             ,iv_token_value2  => g_if_data_tab(cn_c_outside_code) -- �o�ɑ��R�[�h
                            );
            -- �G���[���b�Z�[�W���o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gv_err_flag := cv_flag_err_1;
            lv_out_err_flag := cv_flag_err_1;
--
          -- �G���[���������Ȃ������ꍇ
          ELSE
            -- �ϐ�������
            ln_select_count := 0;
--
            -- �o�ɑ����_�����擾
            SELECT COUNT(1)  AS select_count -- ���o����
            INTO   ln_select_count -- ���o����
            FROM   hz_cust_accounts  hca -- �ڋq�}�X�^
            WHERE  hca.customer_class_code = cv_cust_class_code_1 -- �ڋq�敪
            AND    hca.attribute6          = cv_kuragae_div_1     -- �q�֑Ώۉۋ敪
            AND    hca.status              = cv_const_a           -- �X�e�[�^�X
            AND    hca.account_number      = g_if_data_tab(cn_c_outside_code)  -- �o�ɑ��R�[�h
            ;
--
            -- ���o������0���̏ꍇ�̓G���[
            IF ( ln_select_count = 0 ) THEN
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10686  -- �o�ɑ��R�[�h�i���_�j�����G���[���b�Z�[�W
                               ,iv_token_name1   => cv_tkn_outside_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- �o�ɑ��R�[�h
                              );
              -- �G���[���b�Z�[�W���o��
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- �G���[�t���O���X�V
              gv_err_flag := cv_flag_err_1;
              lv_out_err_flag := cv_flag_err_1;
            END IF;
          END IF;
--
          -- ===============================
          -- ���ɑ��R�[�h�Ó����`�F�b�N
          -- ===============================
          -- �Ǌ����_�̎擾
          BEGIN
            SELECT CASE WHEN 
                          TO_CHAR(gd_invoice_date, cv_date_format_ym)
                            = TO_CHAR(gd_process_date, cv_date_format_ym)
                        THEN
                          xca.sale_base_code
                        ELSE
                          xca.past_sale_base_code
                        END                        AS base_code     -- �Ǌ����_�R�[�h
                  ,hp.duns_number_c                AS cust_status   -- �ڋq�X�e�[�^�X
                  ,xca.business_low_type           AS cust_low_type -- �Ƒԏ�����
            INTO   lt_cust_base_code -- �Ǌ����_�R�[�h
                  ,lt_cust_status    -- �ڋq�X�e�[�^�X
                  ,lt_cust_low_type  -- �Ƒԏ�����
            FROM   hz_cust_accounts    hca -- �ڋq�}�X�^
                  ,xxcmm_cust_accounts xca -- �ڋq�ǉ����
                  ,hz_parties          hp  -- �p�[�e�B�}�X�^
            WHERE  hca.cust_account_id     = xca.customer_id       -- �ڋqID
            AND    hca.party_id            = hp.party_id           -- �p�[�e�BID
            AND    hca.customer_class_code = cv_cust_class_code_10 -- �ڋq�敪(�ڋq)
            AND    hca.status              = cv_const_a            -- �X�e�[�^�X(�L��)
            AND    hca.account_number      = g_if_data_tab(cn_c_inside_code) -- �ڋq�R�[�h(���ɑ��R�[�h�ƈ�v)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �擾�ł��Ȃ��ꍇ�̓G���[
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10214  -- �Ǌ����_�擾�G���[
                               ,iv_token_name1   => cv_tkn_cust_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- ���ɑ��R�[�h
                              );
              -- �G���[���b�Z�[�W���o��
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- �G���[�t���O���X�V
              gv_err_flag := cv_flag_err_1;
              lv_in_err_flag := cv_flag_err_1;
          END;
--
          -- �Ǌ����_���擾�ł����ꍇ�͌㑱�`�F�b�N���s��
          IF ( lv_in_err_flag = cv_flag_normal_0 ) THEN
            -- �Ǌ����_��NULL�̏ꍇ�̓G���[
            IF ( lt_cust_base_code IS NULL ) THEN
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10215  -- �Ǌ����_���ݒ�G���[
                               ,iv_token_name1   => cv_tkn_cust_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- ���ɑ��R�[�h
                              );
              -- �G���[���b�Z�[�W���o��
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- �G���[�t���O���X�V
              gv_err_flag := cv_flag_err_1;
              lv_in_err_flag := cv_flag_err_1;
            ELSE
--
              -- �ڋq�X�e�[�^�X��'30'(���F��)�A'40'(�ڋq)�A'50'�i�x�~�j�ȊO�̏ꍇ�̓G���[
              IF ( lt_cust_status <> cv_cust_status_30
                AND lt_cust_status <> cv_cust_status_40 
                AND lt_cust_status <> cv_cust_status_50 )
              THEN
                lv_errmsg := gv_line_num
                             || xxccp_common_pkg.get_msg(
                                  iv_application   => cv_msg_kbn_coi
                                 ,iv_name          => cv_msg_coi_10216  -- �ڋq�X�e�[�^�X�G���[
                                 ,iv_token_name1   => cv_tkn_cust_code
                                 ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- ���ɑ��R�[�h
                                );
                -- �G���[���b�Z�[�W���o��
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT,
                  buff  => lv_errmsg
                );
                -- �G���[�t���O���X�V
                gv_err_flag := cv_flag_err_1;
                lv_in_err_flag := cv_flag_err_1;
              END IF;
--
              -- �Ƒԏ����ނ�'21'(�C���V���b�v)�A'22'(���В��c)�ȊO�̏ꍇ�̓G���[
              IF ( lt_cust_low_type <> cv_cust_low_type_21
                AND lt_cust_low_type <> cv_cust_low_type_22)
              THEN
                lv_errmsg := gv_line_num
                             || xxccp_common_pkg.get_msg(
                                  iv_application   => cv_msg_kbn_coi
                                 ,iv_name          => cv_msg_coi_10692  -- �Ƒԏ����ރG���[���b�Z�[�W
                                 ,iv_token_name1   => cv_tkn_cust_code
                                 ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- ���ɑ��R�[�h
                                );
                -- �G���[���b�Z�[�W���o��
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT,
                  buff  => lv_errmsg
                );
                -- �G���[�t���O���X�V
                gv_err_flag := cv_flag_err_1;
                lv_in_err_flag := cv_flag_err_1;
              END IF;
--
              -- A-1�Ŏ擾�����S�ݓXHHT�敪���f1�f�̏ꍇ
              IF ( gt_dept_hht_div = cv_dept_hht_div_1 ) THEN
                -- �Ǌ����_�����擾
                BEGIN
                  SELECT xca.management_base_code  AS cust_mng_base_code  -- �Ǘ������_�R�[�h
                        ,hca.attribute6            AS kuragae_div         -- �q�֑Ώۉۋ敪
                  INTO   lt_cust_mng_base_code  -- �Ǘ������_�R�[�h
                        ,lv_kuragae_div         -- �q�֑Ώۉۋ敪
                  FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
                        ,xxcmm_cust_accounts    xca -- �ڋq�ǉ����
                  WHERE  hca.cust_account_id      = xca.customer_id        -- �ڋqID
                  AND    hca.customer_class_code  = cv_cust_class_code_1   -- �ڋq�敪(���_)
                  AND    hca.status               = cv_const_a             -- �X�e�[�^�X(�L��)
                  AND    hca.account_number       = lt_cust_base_code      -- �ڋq�R�[�h(�Ǌ����_�ƈ�v)
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10696  -- �Ǘ������_�擾�G���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_cust_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- ���ɑ��R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                END;
--
                -- �Ǌ����_��񂪎擾�ł����ꍇ
                IF ( lv_in_err_flag = cv_flag_normal_0 ) THEN
                  -- ���_�ԑq�փf�[�^.���_�R�[�h�ƊǗ������_�R�[�h����v���Ȃ��ꍇ
                  IF ( g_if_data_tab(cn_c_base_code) <> lt_cust_mng_base_code ) THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10689  -- ���ɑ��Ǘ������_�s��v�G���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_dept_code1
                                     ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- ���_�R�[�h
                                     ,iv_token_name2   => cv_tkn_dept_code2
                                     ,iv_token_value2  => lt_cust_mng_base_code         -- �Ǘ������_�R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                  END IF;
--
                  -- �q�֑Ώۋ敪��'1'�ȊO�̏ꍇ
                  IF ( lv_kuragae_div <> cv_kuragae_div_1
                    OR lv_kuragae_div IS NULL )
                  THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10683  -- ���ɑ��q�֑ΏۉۃG���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_inside_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_inside_code) -- ���ɑ��R�[�h
                                     ,iv_token_name2   => cv_tkn_dept_code
                                     ,iv_token_value2  => lt_cust_base_code               -- �Ǌ����_�R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                  END IF;
                END IF;
--
              -- A-1�Ŏ擾�����S�ݓXHHT�敪���f2�f�̏ꍇ
              ELSE
                -- �Ǌ����_�����擾
                BEGIN
                  SELECT hca.attribute6  AS kuragae_div  -- �q�֑Ώۉۋ敪
                  INTO   lv_kuragae_div  -- �q�֑Ώۉۋ敪
                  FROM   hz_cust_accounts  hca -- �ڋq�}�X�^
                  WHERE  hca.customer_class_code  = cv_cust_class_code_1   -- �ڋq�敪(���_)
                  AND    hca.status               = cv_const_a             -- �X�e�[�^�X(�L��)
                  AND    hca.account_number       = lt_cust_base_code      -- �ڋq�R�[�h�i�Ǌ����_�ƈ�v�j
                  AND    hca.account_number       = g_if_data_tab(cn_c_base_code) -- �ڋq�R�[�h�i���_�R�[�h�ƈ�v�j
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10691  -- ���ɑ��Ǌ����_�s��v�G���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_dept_code1
                                     ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- ���_�R�[�h
                                     ,iv_token_name2   => cv_tkn_dept_code2
                                     ,iv_token_value2  => lt_cust_base_code             -- �Ǌ����_�R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                END;
--
                -- �Ǌ����_��񂪎擾�ł����ꍇ
                IF ( lv_in_err_flag = cv_flag_normal_0 ) THEN
                  -- �q�֑Ώۋ敪��'1'�ȊO�̏ꍇ
                  IF ( lv_kuragae_div <> cv_kuragae_div_1
                    OR lv_kuragae_div IS NULL )
                  THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10683  -- ���ɑ��q�֑ΏۉۃG���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_inside_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_inside_code) -- ���ɑ��R�[�h
                                     ,iv_token_name2   => cv_tkn_dept_code
                                     ,iv_token_value2  => lt_cust_base_code               -- �Ǌ����_�R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
--
        -- ===============================
        -- ���ڒl�̐ݒ�
        -- ===============================
        -- �G���[���������Ȃ������ꍇ
        IF ( lv_out_err_flag = cv_flag_normal_0
          AND lv_in_err_flag = cv_flag_normal_0 ) THEN
          gt_invoice_type    := cv_invoice_type_4;    -- �`�[�敪�F'4'�i�q�ɂ���a����j
          gt_department_flag := cv_department_flag_5; -- �S�ݓX�t���O�F'5'�i�����_����a����j
        END IF;
--
      -- ===============================
      -- �a���悩�瑼���_�̏ꍇ
      -- ===============================
      ELSIF ( LENGTH(g_if_data_tab(cn_c_outside_code)) = 9
           AND LENGTH(g_if_data_tab(cn_c_inside_code)) = 4 )
      THEN
        -- ===============================
        -- ���s���[�U�Z�L�����e�B�`�F�b�N
        -- ===============================
        IF ( gt_dept_hht_div IS NULL ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10681  -- �S�ݓX�p������s�G���[���b�Z�[�W
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
          lv_in_err_flag  := cv_flag_err_1;
--
        -- �G���[���������Ȃ������ꍇ�͌㑱�̃`�F�b�N���s��
        ELSE
          -- ===============================
          -- ���ɑ��R�[�h�Ó����`�F�b�N
          -- ===============================
          -- ���_�ԑq�փf�[�^. ���_�R�[�h�Ɠ��ɑ��R�[�h����v����ꍇ
          IF ( g_if_data_tab(cn_c_base_code) = g_if_data_tab(cn_c_inside_code) ) THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10685  -- ���ɑ��R�[�h�����_�G���[���b�Z�[�W
                             ,iv_token_name1   => cv_tkn_dept_code
                             ,iv_token_value1  => g_if_data_tab(cn_c_base_code)    -- ���_�R�[�h
                             ,iv_token_name2   => cv_tkn_inside_code
                             ,iv_token_value2  => g_if_data_tab(cn_c_inside_code) -- ���ɑ��R�[�h
                            );
            -- �G���[���b�Z�[�W���o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- �G���[�t���O���X�V
            gv_err_flag := cv_flag_err_1;
            lv_in_err_flag := cv_flag_err_1;
--
          -- �G���[���������Ȃ������ꍇ
          ELSE
            -- �ϐ�������
            ln_select_count := 0;
--
            -- ���ɑ����_�����擾
            SELECT COUNT(1)  AS select_count -- ���o����
            INTO   ln_select_count -- ���o����
            FROM   hz_cust_accounts  hca -- �ڋq�}�X�^
            WHERE  hca.customer_class_code = cv_cust_class_code_1 -- �ڋq�敪
            AND    hca.attribute6          = cv_kuragae_div_1     -- �q�֑Ώۉۋ敪
            AND    hca.status              = cv_const_a           -- �X�e�[�^�X
            AND    hca.account_number      = g_if_data_tab(cn_c_inside_code)  -- �ڋq�R�[�h
            ;
--
            -- ���o������0���̏ꍇ�̓G���[
            IF ( ln_select_count = 0 ) THEN
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10687  -- ���ɑ��R�[�h�i���_�j�����G���[���b�Z�[�W
                               ,iv_token_name1   => cv_tkn_inside_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- ���ɑ��R�[�h
                              );
              -- �G���[���b�Z�[�W���o��
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- �G���[�t���O���X�V
              gv_err_flag := cv_flag_err_1;
              lv_in_err_flag := cv_flag_err_1;
            END IF;
          END IF;
--
          -- ===============================
          -- �o�ɑ��R�[�h�Ó����`�F�b�N
          -- ===============================
          -- �Ǌ����_�̎擾
          BEGIN
            SELECT CASE WHEN
                          TO_CHAR( gd_invoice_date, cv_date_format_ym)
                            = TO_CHAR(gd_process_date, cv_date_format_ym)
                        THEN
                          xca.sale_base_code
                        ELSE
                          xca.past_sale_base_code
                        END                        AS base_code     -- �Ǌ����_�R�[�h
                  ,hp.duns_number_c                AS cust_status   -- �ڋq�X�e�[�^�X
                  ,xca.business_low_type           AS cust_low_type -- �Ƒԏ�����
            INTO   lt_cust_base_code -- �Ǌ����_�R�[�h
                  ,lt_cust_status    -- �ڋq�X�e�[�^�X
                  ,lt_cust_low_type  -- �Ƒԏ�����
            FROM   hz_cust_accounts    hca -- �ڋq�}�X�^
                  ,xxcmm_cust_accounts xca -- �ڋq�ǉ����
                  ,hz_parties          hp  -- �p�[�e�B�}�X�^
            WHERE  hca.cust_account_id     = xca.customer_id       -- �ڋqID
            AND    hca.party_id            = hp.party_id           -- �p�[�e�BID
            AND    hca.customer_class_code = cv_cust_class_code_10 -- �ڋq�敪(�ڋq)
            AND    hca.status              = cv_const_a            -- �X�e�[�^�X(�L��)
            AND    hca.account_number      = g_if_data_tab(cn_c_outside_code) -- �ڋq�R�[�h(�o�ɑ��R�[�h�ƈ�v)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �擾�ł��Ȃ��ꍇ�̓G���[
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10214  -- �Ǌ����_�擾�G���[
                               ,iv_token_name1   => cv_tkn_cust_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- �o�ɑ��R�[�h
                              );
              -- �G���[���b�Z�[�W���o��
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- �G���[�t���O���X�V
              gv_err_flag := cv_flag_err_1;
              lv_out_err_flag := cv_flag_err_1;
          END;
--
          -- �Ǌ����_��񂪎擾�ł����͌㑱�`�F�b�N���s��
          IF ( lv_out_err_flag = cv_flag_normal_0 ) THEN
            -- �Ǌ����_��NULL�̏ꍇ�̓G���[
            IF ( lt_cust_base_code IS NULL ) THEN
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10215  -- �Ǌ����_���ݒ�G���[
                               ,iv_token_name1   => cv_tkn_cust_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- �o�ɑ��R�[�h
                              );
              -- �G���[���b�Z�[�W���o��
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- �G���[�t���O���X�V
              gv_err_flag := cv_flag_err_1;
              lv_out_err_flag := cv_flag_err_1;
            ELSE
--
              -- �ڋq�X�e�[�^�X��'30'(���F��)�A'40'(�ڋq)�A'50'�i�x�~�j�ȊO�̏ꍇ�̓G���[
              IF ( lt_cust_status <> cv_cust_status_30
                AND lt_cust_status <> cv_cust_status_40 
                AND lt_cust_status <> cv_cust_status_50 )
              THEN
                lv_errmsg := gv_line_num
                             || xxccp_common_pkg.get_msg(
                                  iv_application   => cv_msg_kbn_coi
                                 ,iv_name          => cv_msg_coi_10216  -- �ڋq�X�e�[�^�X�G���[
                                 ,iv_token_name1   => cv_tkn_cust_code
                                 ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- �o�ɑ��R�[�h
                                );
                -- �G���[���b�Z�[�W���o��
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT,
                  buff  => lv_errmsg
                );
                -- �G���[�t���O���X�V
                gv_err_flag := cv_flag_err_1;
                lv_out_err_flag := cv_flag_err_1;
              END IF;
--
              -- �Ƒԏ����ނ�'21'(�C���V���b�v)�A'22'(���В��c)�ȊO�̏ꍇ�̓G���[
              IF ( lt_cust_low_type <> cv_cust_low_type_21
                AND lt_cust_low_type <> cv_cust_low_type_22)
              THEN
                lv_errmsg := gv_line_num
                             || xxccp_common_pkg.get_msg(
                                  iv_application   => cv_msg_kbn_coi
                                 ,iv_name          => cv_msg_coi_10692  -- �Ƒԏ����ރG���[���b�Z�[�W
                                 ,iv_token_name1   => cv_tkn_cust_code
                                 ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- �o�ɑ��R�[�h
                                );
                -- �G���[���b�Z�[�W���o��
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT,
                  buff  => lv_errmsg
                );
                -- �G���[�t���O���X�V
                gv_err_flag := cv_flag_err_1;
                lv_out_err_flag := cv_flag_err_1;
              END IF;
--
              -- A-1�Ŏ擾�����S�ݓXHHT�敪���f1�f�̏ꍇ
              IF ( gt_dept_hht_div = cv_dept_hht_div_1 ) THEN
                -- �Ǌ����_�����擾
                BEGIN
                  SELECT xca.management_base_code  AS cust_mng_base_code  -- �Ǘ������_�R�[�h
                        ,hca.attribute6            AS kuragae_div         -- �q�֑Ώۉۋ敪
                  INTO   lt_cust_mng_base_code  -- �Ǘ������_�R�[�h
                        ,lv_kuragae_div         -- �q�֑Ώۉۋ敪
                  FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
                        ,xxcmm_cust_accounts    xca -- �ڋq�ǉ����
                  WHERE  hca.cust_account_id      = xca.customer_id        -- �ڋqID
                  AND    hca.customer_class_code  = cv_cust_class_code_1   -- �ڋq�敪(���_)
                  AND    hca.status               = cv_const_a             -- �X�e�[�^�X(�L��)
                  AND    hca.account_number       = lt_cust_base_code      -- �ڋq�R�[�h(�Ǌ����_�ƈ�v)
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10696  -- �Ǘ������_�擾�G���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_cust_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- �o�ɑ��R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                END;
--
                -- �Ǌ����_��񂪎擾�ł����ꍇ
                IF ( lv_out_err_flag = cv_flag_normal_0 ) THEN
                  -- ���_�ԑq�փf�[�^.���_�R�[�h�ƊǗ������_�R�[�h����v���Ȃ��ꍇ
                  IF ( g_if_data_tab(cn_c_base_code) <> lt_cust_mng_base_code ) THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10688  -- �o�ɑ��Ǘ������_�s��v�G���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_dept_code1
                                     ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- ���_�R�[�h
                                     ,iv_token_name2   => cv_tkn_dept_code2
                                     ,iv_token_value2  => lt_cust_mng_base_code         -- �Ǘ������_�R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                  END IF;
--
                  -- �q�֑Ώۋ敪��'1'�ȊO�̏ꍇ
                  IF ( lv_kuragae_div <> cv_kuragae_div_1
                    OR lv_kuragae_div IS NULL )
                  THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10682  -- �o�ɑ��q�֑ΏۉۃG���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_outside_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_outside_code) -- �o�ɑ��R�[�h
                                     ,iv_token_name2   => cv_tkn_dept_code
                                     ,iv_token_value2  => lt_cust_base_code                -- �Ǌ����_�R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                  END IF;
                END IF;
--
              -- A-1�Ŏ擾�����S�ݓXHHT�敪���f2�f�̏ꍇ
              ELSE
                -- �Ǌ����_�����擾
                BEGIN
                  SELECT hca.attribute6  AS kuragae_div  -- �q�֑Ώۉۋ敪
                  INTO   lv_kuragae_div  -- �q�֑Ώۉۋ敪
                  FROM   hz_cust_accounts  hca -- �ڋq�}�X�^
                  WHERE  hca.customer_class_code  = cv_cust_class_code_1   -- �ڋq�敪(���_)
                  AND    hca.status               = cv_const_a             -- �X�e�[�^�X(�L��)
                  AND    hca.account_number       = lt_cust_base_code      -- �ڋq�R�[�h�i�Ǌ����_�ƈ�v�j
                  AND    hca.account_number       = g_if_data_tab(cn_c_base_code) -- �ڋq�R�[�h�i���_�R�[�h�ƈ�v�j
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10690  -- �o�ɑ��Ǌ����_�s��v�G���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_dept_code1
                                     ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- ���_�R�[�h
                                     ,iv_token_name2   => cv_tkn_dept_code2
                                     ,iv_token_value2  => lt_cust_base_code             -- �Ǌ����_�R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                END;
--
                -- �Ǌ����_��񂪎擾�ł����ꍇ
                IF ( lv_out_err_flag = cv_flag_normal_0 ) THEN
                  -- �q�֑Ώۋ敪��'1'�ȊO�̏ꍇ
                  IF ( lv_kuragae_div <> cv_kuragae_div_1
                    OR lv_kuragae_div IS NULL )
                  THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10682  -- �o�ɑ��q�֑ΏۉۃG���[���b�Z�[�W
                                     ,iv_token_name1   => cv_tkn_outside_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_outside_code) -- �o�ɑ��R�[�h
                                     ,iv_token_name2   => cv_tkn_dept_code
                                     ,iv_token_value2  => lt_cust_base_code               -- �Ǌ����_�R�[�h
                                    );
                    -- �G���[���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- �G���[�t���O���X�V
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
--
        -- ===============================
        -- ���ڒl�̐ݒ�
        -- ===============================
        -- �G���[���������Ȃ������ꍇ
        IF ( lv_out_err_flag = cv_flag_normal_0 
          AND lv_in_err_flag = cv_flag_normal_0 ) THEN
          gt_invoice_type    := cv_invoice_type_5;    -- �`�[�敪�F'5'�i�a���悩��q�Ɂj
          gt_department_flag := cv_department_flag_6; -- �S�ݓX�t���O�F'6'�i�a���恨�����_�j
        END IF;
--
      -- ===============================
      -- ���̑��̎���̏ꍇ
      -- ===============================
      ELSE
        -- �ΏۊO����G���[
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10669    -- �ΏۊO����G���[���b�Z�[�W
                         ,iv_token_name1   => cv_tkn_outside_code
                         ,iv_token_value1  => g_if_data_tab(cn_c_outside_code) -- �o�ɑ��R�[�h
                         ,iv_token_name2   => cv_tkn_inside_code
                         ,iv_token_value2  => g_if_data_tab(cn_c_inside_code)  -- ���ɑ��R�[�h
                        );
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gv_err_flag := cv_flag_err_1;
        lv_out_err_flag := cv_flag_err_1;
        lv_in_err_flag  := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ===============================
    -- �ۊǏꏊ���擾
    -- ===============================
    -- ����܂ł̃`�F�b�N�łŃG���[���������Ȃ������ꍇ
    IF ( gv_err_flag = cv_flag_normal_0 ) THEN
      -- ���ʊ֐��uHHT�ۊǏꏊ�R�[�h�ϊ��v�Ăяo��
      xxcoi_common_pkg.convert_subinv_code(
        ov_errbuf                      => lv_errbuf                               -- �G���[���b�Z�[�W
       ,ov_retcode                     => lv_retcode                              -- ���^�[���E�R�[�h(0:����A1:�G���[)
       ,ov_errmsg                      => lv_errmsg                               -- ���[�U�[�E�G���[���b�Z�[�W
       ,iv_record_type                 => cv_record_type_30                       -- ���R�[�h���
       ,iv_invoice_type                => gt_invoice_type                         -- �`�[�敪
       ,iv_department_flag             => gt_department_flag                      -- �S�ݓX�t���O
       ,iv_base_code                   => g_if_data_tab(cn_c_base_code)           -- ���_�R�[�h
       ,iv_outside_code                => g_if_data_tab(cn_c_outside_code)        -- �o�ɑ��R�[�h
       ,iv_inside_code                 => g_if_data_tab(cn_c_inside_code)         -- ���ɑ��R�[�h
       ,id_transaction_date            => gd_invoice_date                         -- �����
       ,in_organization_id             => gn_inv_org_id                           -- �݌ɑg�DID
       ,iv_hht_form_flag               => NULL                                    -- HHT������͉�ʃt���O
       ,ov_outside_subinv_code         => gt_out_subinv_code                      -- �o�ɑ��ۊǏꏊ�R�[�h
       ,ov_inside_subinv_code          => gt_in_subinv_code                       -- ���ɑ��ۊǏꏊ�R�[�h
       ,ov_outside_base_code           => gt_out_base_code                        -- �o�ɑ����_�R�[�h
       ,ov_inside_base_code            => gt_in_base_code                         -- ���ɑ����_�R�[�h
       ,ov_outside_subinv_code_conv    => gt_out_subinv_code_conv                 -- �o�ɑ��ۊǏꏊ�ϊ��敪
       ,ov_inside_subinv_code_conv     => gt_in_subinv_code_conv                  -- ���ɑ��ۊǏꏊ�ϊ��敪
       ,ov_outside_business_low_type   => gt_out_business_low_type                -- �o�ɑ��Ƒԏ�����
       ,ov_inside_business_low_type    => gt_in_business_low_type                 -- ���ɑ��Ƒԏ�����
       ,ov_outside_cust_code           => gt_out_cust_code                        -- �o�ɑ��ڋq�R�[�h
       ,ov_inside_cust_code            => gt_in_cust_code                         -- ���ɑ��ڋq�R�[�h
       ,ov_hht_program_div             => gt_hht_program_div                      -- ���o�ɃW���[�i�������敪
       ,ov_item_convert_div            => gt_item_convert_div                     -- ���i�U�֋敪
       ,ov_stock_uncheck_list_div      => gt_stock_uncheck_list_div               -- ���ɖ��m�F���X�g�Ώۋ敪
       ,ov_stock_balance_list_div      => gt_stock_balance_list_div               -- ���ɍ��يm�F���X�g�Ώۋ敪
       ,ov_consume_vd_flag             => gt_consume_vd_flag                      -- ����VD��[�Ώۃt���O
       ,ov_outside_subinv_div          => lt_outside_subinv_div                   -- �o�ɑ��I���Ώ�
       ,ov_inside_subinv_div           => lt_inside_subinv_div                    -- ���ɑ��I���Ώ�
      );
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �L�[���Ƀ��[�U�[�E�G���[���b�Z�[�W��ǉ����ďo��
        lv_errmsg := gv_line_num
                     || lv_errmsg;
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gv_err_flag := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ===============================
    -- AFF����L���`�F�b�N
    -- ===============================
    -- �o�ɑ��ۊǏꏊ�R�[�h��AFF����L���`�F�b�N
    IF ( gt_out_subinv_code IS NOT NULL ) THEN
      lv_result_aff_out := xxcoi_common_pkg.chk_aff_active(
        in_organization_id => gn_inv_org_id                      -- �݌ɑg�DID
       ,iv_base_code       => NULL                               -- ���_�R�[�h
       ,iv_subinv_code     => gt_out_subinv_code                 -- �o�ɑ��ۊǏꏊ�R�[�h
       ,id_target_date     => gd_invoice_date                    -- �Ώۓ�
      );
      -- �`�F�b�N���ʂ�NG�̏ꍇ
      IF ( lv_result_aff_out = cv_const_n ) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10420  -- �o�ɑ�AFF����G���[���b�Z�[�W
                        );
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gv_err_flag := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ���ɑ��ۊǏꏊ�R�[�h��AFF����L���`�F�b�N
    IF ( gt_in_subinv_code IS NOT NULL ) THEN
      lv_result_aff_in := xxcoi_common_pkg.chk_aff_active(
        in_organization_id => gn_inv_org_id                      -- �݌ɑg�DID
       ,iv_base_code       => NULL                               -- ���_�R�[�h
       ,iv_subinv_code     => gt_in_subinv_code                  -- ���ɑ��ۊǏꏊ�R�[�h
       ,id_target_date     => gd_invoice_date                    -- �Ώۓ�
      );
      -- �`�F�b�N���ʂ�NG�̏ꍇ
      IF ( lv_result_aff_in = cv_const_n ) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10421  -- ���ɑ�AFF����G���[���b�Z�[�W
                        );
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- �G���[�t���O���X�V
        gv_err_flag := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ===============================
    -- �q�ɊǗ��Ώۋ敪�擾
    -- ===============================
    -- �o�ɑ��ۊǏꏊ�̑q�ɊǗ��Ώۋ敪���擾���܂�
    IF ( gt_out_subinv_code IS NOT NULL ) THEN
      BEGIN
        SELECT msi.attribute14 AS warehouse_flag -- �q�ɊǗ��Ώۋ敪
        INTO   gt_out_warehouse_flag -- �o�ɑ��q�ɊǗ��Ώۋ敪
        FROM   mtl_secondary_inventories msi -- �ۊǏꏊ�}�X�^
        WHERE  gd_invoice_date <= NVL(msi.disable_date - 1, gd_invoice_date) -- ������
        AND    msi.organization_id          = gn_inv_org_id      -- �݌ɑg�DID
        AND    msi.secondary_inventory_name = gt_out_subinv_code -- �ۊǏꏊ�R�[�h
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �擾�ł��Ȃ��ꍇ
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10508   -- �o�ɑ��q�ɊǗ��Ώۋ敪�擾�G���[
                           ,iv_token_name1   => cv_tkn_sub_inv_code
                           ,iv_token_value1  => gt_out_subinv_code -- �o�ɑ��ۊǏꏊ�R�[�h
                          );
          -- �G���[���b�Z�[�W���o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- �G���[�t���O���X�V
          gv_err_flag := cv_flag_err_1;
      END;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_hht_inv_tran
   * Description      : HHT���o�Ɉꎞ�\�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE ins_hht_inv_tran(
    in_if_loop_cnt IN  NUMBER,      -- IF���[�v�J�E���^
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hht_inv_tran'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- �V�[�P���X�l���擾
    -- ===============================
    SELECT  xxcoi_hht_inv_transactions_s01.NEXTVAL -- ���o�Ɉꎞ�\ID�V�[�P���X
    INTO    gt_transaction_id -- ���o�Ɉꎞ�\ID
    FROM    DUAL;
--
    SELECT  xxcoi_invoice_no_s01.NEXTVAL -- �`�[�ԍ��V�[�P���X
    INTO    gt_invoice_no -- �`�[�ԍ�
    FROM    DUAL;
--
    -- �`�[�ԍ���ҏW
    gt_invoice_no := cv_const_e || LTRIM(TO_CHAR(gt_invoice_no,cv_invoice_num_0));
--
    -- ===============================
    -- HHT���o�Ɉꎞ�\�֓o�^
    -- ===============================
    INSERT INTO xxcoi_hht_inv_transactions(
      transaction_id                              -- ���o�Ɉꎞ�\ID
     ,interface_id                                -- �C���^�[�t�F�[�XID
     ,form_header_id                              -- ��ʓ��͗p�w�b�_ID
     ,base_code                                   -- ���_�R�[�h
     ,record_type                                 -- ���R�[�h���
     ,employee_num                                -- �c�ƈ��R�[�h
     ,invoice_no                                  -- �`�[��
     ,item_code                                   -- �i�ڃR�[�h�i�i���R�[�h�j
     ,case_quantity                               -- �P�[�X��
     ,case_in_quantity                            -- ����
     ,quantity                                    -- �{��
     ,invoice_type                                -- �`�[�敪
     ,base_delivery_flag                          -- ���_�ԑq�փt���O
     ,outside_code                                -- �o�ɑ��R�[�h
     ,inside_code                                 -- ���ɑ��R�[�h
     ,invoice_date                                -- �`�[���t
     ,column_no                                   -- �R������
     ,unit_price                                  -- �P��
     ,hot_cold_div                                -- H/C
     ,department_flag                             -- �S�ݓX�t���O
     ,interface_date                              -- ��M����
     ,other_base_code                             -- �����_�R�[�h
     ,outside_subinv_code                         -- �o�ɑ��ۊǏꏊ
     ,inside_subinv_code                          -- ���ɑ��ۊǏꏊ
     ,outside_base_code                           -- �o�ɑ����_
     ,inside_base_code                            -- ���ɑ����_
     ,total_quantity                              -- ���{��
     ,inventory_item_id                           -- �i��ID
     ,primary_uom_code                            -- ��P��
     ,outside_subinv_code_conv_div                -- �o�ɑ��ۊǏꏊ�ϊ��敪
     ,inside_subinv_code_conv_div                 -- ���ɑ��ۊǏꏊ�ϊ��敪
     ,outside_business_low_type                   -- �o�ɑ��Ƒԋ敪
     ,inside_business_low_type                    -- ���ɑ��Ƒԋ敪
     ,outside_cust_code                           -- �o�ɑ��ڋq�R�[�h
     ,inside_cust_code                            -- ���ɑ��ڋq�R�[�h
     ,hht_program_div                             -- ���o�ɃW���[�i�������敪
     ,consume_vd_flag                             -- ����VD��[�Ώۃt���O
     ,item_convert_div                            -- ���i�U�֋敪
     ,stock_uncheck_list_div                      -- ���ɖ��m�F���X�g�Ώۋ敪
     ,stock_balance_list_div                      -- ���ɍ��يm�F���X�g�Ώۋ敪
     ,status                                      -- �����X�e�[�^�X
     ,column_if_flag                              -- �R�����ʓ]���σt���O
     ,column_if_date                              -- �R�����ʓ]����
     ,sample_if_flag                              -- ���{�]���σt���O
     ,sample_if_date                              -- ���{�]����
     ,output_flag                                 -- �o�͍σt���O
     ,last_update_date                            -- �ŏI�X�V��
     ,last_updated_by                             -- �ŏI�X�V��
     ,creation_date                               -- �쐬��
     ,created_by                                  -- �쐬��
     ,last_update_login                           -- �ŏI�X�V���[�U
     ,request_id                                  -- �v��ID
     ,program_application_id                      -- �v���O�����A�v���P�[�V����ID
     ,program_id                                  -- �v���O����ID
     ,program_update_date                         -- �v���O�����X�V��
    )
    VALUES(
      gt_transaction_id                                                -- ���o�Ɉꎞ�\ID
     ,in_if_loop_cnt                                                   -- �C���^�[�t�F�[�XID
     ,NULL                                                             -- ��ʓ��͗p�w�b�_ID
     ,g_if_data_tab(cn_c_base_code)                                    -- ���_�R�[�h
     ,cv_record_type_30                                                -- ���R�[�h���
     ,g_if_data_tab(cn_c_employee_num)                                 -- �c�ƈ��R�[�h
     ,gt_invoice_no                                                    -- �`�[��
     ,g_if_data_tab(cn_c_item_code)                                    -- �i�ڃR�[�h�i�i���R�[�h�j
     ,g_if_data_tab(cn_c_case_quantity)                                -- �P�[�X��
     ,gt_case_in_qty                                                   -- ����
     ,g_if_data_tab(cn_c_quantity)                                     -- �{��
     ,gt_invoice_type                                                  -- �`�[�敪
     ,cv_base_deliv_flag_0                                             -- ���_�ԑq�փt���O
     ,g_if_data_tab(cn_c_outside_code)                                 -- �o�ɑ��R�[�h
     ,g_if_data_tab(cn_c_inside_code)                                  -- ���ɑ��R�[�h
     ,gd_invoice_date                                                  -- �`�[���t
     ,NULL                                                             -- �R������
     ,cn_unit_price                                                    -- �P��
     ,NULL                                                             -- H/C
     ,gt_department_flag                                               -- �S�ݓX�t���O
     ,SYSDATE                                                          -- ��M����
     ,DECODE(gt_out_subinv_code_conv,cv_const_e,gt_out_base_code
                                               ,gt_in_base_code)       -- �����_�R�[�h
     ,gt_out_subinv_code                                               -- �o�ɑ��ۊǏꏊ
     ,gt_in_subinv_code                                                -- ���ɑ��ۊǏꏊ
     ,gt_out_base_code                                                 -- �o�ɑ����_
     ,gt_in_base_code                                                  -- ���ɑ����_
     ,gt_total_qty                                                     -- ���{��
     ,gt_inventory_item_id                                             -- �i��ID
     ,gt_primary_uom_code                                              -- ��P��
     ,gt_out_subinv_code_conv                                          -- �o�ɑ��ۊǏꏊ�ϊ��敪
     ,gt_in_subinv_code_conv                                           -- ���ɑ��ۊǏꏊ�ϊ��敪
     ,gt_out_business_low_type                                         -- �o�ɑ��Ƒԋ敪
     ,gt_in_business_low_type                                          -- ���ɑ��Ƒԋ敪
     ,gt_out_cust_code                                                 -- �o�ɑ��ڋq�R�[�h
     ,gt_in_cust_code                                                  -- ���ɑ��ڋq�R�[�h
     ,gt_hht_program_div                                               -- ���o�ɃW���[�i�������敪
     ,gt_consume_vd_flag                                               -- ����VD��[�Ώۃt���O
     ,gt_item_convert_div                                              -- ���i�U�֋敪
     ,gt_stock_uncheck_list_div                                        -- ���ɖ��m�F���X�g�Ώۋ敪
     ,gt_stock_balance_list_div                                        -- ���ɍ��يm�F���X�g�Ώۋ敪
     ,cv_status_0                                                      -- �����X�e�[�^�X
     ,cv_const_n                                                       -- �R�����ʓ]���σt���O
     ,NULL                                                             -- �R�����ʓ]����
     ,cv_const_n                                                       -- ���{�]���σt���O
     ,NULL                                                             -- ���{�]����
     ,cv_const_n                                                       -- �o�͍σt���O
     ,SYSDATE                                                          -- �ŏI�X�V��
     ,cn_last_updated_by                                               -- �ŏI�X�V��
     ,SYSDATE                                                          -- �쐬��
     ,cn_created_by                                                    -- �쐬��
     ,cn_last_update_login                                             -- �ŏI�X�V���[�U
     ,cn_request_id                                                    -- �v��ID
     ,cn_program_application_id                                        -- �v���O�����A�v���P�[�V����ID
     ,cn_program_id                                                    -- �v���O����ID
     ,cd_program_update_date                                           -- �v���O�����X�V��
    );
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_hht_inv_tran;
--
  /**********************************************************************************
   * Procedure Name   : ins_lot_trx_temp
   * Description      : ���b�g�ʎ��TEMP�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE ins_lot_trx_temp(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lot_trx_temp'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_lot_trx_id  xxcoi_lot_transactions_temp.transaction_id%TYPE; -- ���b�g��TEMP���ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�J���ϐ�������
    lt_lot_trx_id := NULL;
--
    -- ===============================
    -- ���b�g�ʎ��TEMP�쐬
    -- ===============================
    xxcoi_common_pkg.cre_lot_trx_temp(
      in_trx_set_id       => NULL                                      -- ����Z�b�gID
     ,iv_parent_item_code => g_if_data_tab(cn_c_item_code)             -- �e�i�ڃR�[�h
     ,iv_child_item_code  => NULL                                      -- �q�i�ڃR�[�h
     ,iv_lot              => NULL                                      -- ���b�g(�ܖ�����)
     ,iv_diff_sum_code    => NULL                                      -- �ŗL�L��
     ,iv_trx_type_code    => cv_tran_type_code_20                      -- ����^�C�v�R�[�h
     ,id_trx_date         => gd_invoice_date                           -- �����
     ,iv_slip_num         => gt_invoice_no                             -- �`�[No
     ,in_case_in_qty      => gt_case_in_qty                            -- ����
     ,in_case_qty         => g_if_data_tab(cn_c_case_quantity)         -- �P�[�X��
     ,in_singly_qty       => g_if_data_tab(cn_c_quantity)              -- �o����
     ,in_summary_qty      => gt_total_qty                              -- �������
     ,iv_base_code        => g_if_data_tab(cn_c_base_code)             -- ���_�R�[�h
     ,iv_subinv_code      => gt_out_subinv_code                        -- �ۊǏꏊ�R�[�h
     ,iv_tran_subinv_code => gt_in_subinv_code                         -- �]����ۊǏꏊ�R�[�h
     ,iv_tran_loc_code    => NULL                                      -- �]���惍�P�[�V�����R�[�h
     ,iv_inout_code       => cv_inout_code_22                          -- ���o�ɃR�[�h
     ,iv_source_code      => cv_pkg_name                               -- �\�[�X�R�[�h
     ,iv_relation_key     => gt_transaction_id                         -- �R�t���L�[
     ,on_trx_id           => lt_lot_trx_id                             -- ���b�g��TEMP���ID
     ,ov_errbuf           => lv_errbuf                                 -- �G���[���b�Z�[�W
     ,ov_retcode          => lv_retcode                                -- ���^�[���E�R�[�h(0:����A2:�G���[)
     ,ov_errmsg           => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_msg_coi_10510   -- ���b�g�ʎ��TEMP�쐬�G���[
                       ,iv_token_name1  => cv_tkn_base_code
                       ,iv_token_value1 => g_if_data_tab(cn_c_base_code) -- ���_�R�[�h
                       ,iv_token_name2  => cv_tkn_record_type
                       ,iv_token_value2 => cv_record_type_30             -- ���R�[�h���
                       ,iv_token_name3  => cv_tkn_invoice_type
                       ,iv_token_value3 => gt_invoice_type               -- �`�[�敪
                       ,iv_token_name4  => cv_tkn_dept_flag
                       ,iv_token_value4 => gt_department_flag            -- �S�ݓX�t���O
                       ,iv_token_name5  => cv_tkn_invoice_no
                       ,iv_token_value5 => gt_invoice_no                 -- �`�[�ԍ�
                       ,iv_token_name6  => cv_tkn_column_no
                       ,iv_token_value6 => NULL                          -- �R����No
                       ,iv_token_name7  => cv_tkn_item_code
                       ,iv_token_value7 => g_if_data_tab(cn_c_item_code) -- �i�ڃR�[�h
                      );
--
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_lot_trx_temp;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : IF�f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_if_data(
    in_file_id       IN  NUMBER,       --   �t�@�C��ID
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_if_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�@�C���A�b�v���[�hIF�f�[�^�폜
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface  xfu -- �t�@�C���A�b�v���[�hIF
      WHERE xfu.file_id = in_file_id; -- �t�@�C��ID
    EXCEPTION
      WHEN OTHERS THEN
      -- �폜�Ɏ��s�����ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10633, -- �f�[�^�폜�G���[���b�Z�[�W
                       iv_token_name1   => cv_tkn_table_name,
                       iv_token_value1  => cv_tkn_coi_10634, -- �t�@�C���A�b�v���[�hIF
                       iv_token_name2   => cv_tkn_key_data,
                       iv_token_value2  => NULL
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER,       --   �t�@�C��ID
    iv_file_format  IN   VARCHAR2,     --   �t�@�C���t�H�[�}�b�g
    ov_errbuf       OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT  VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    -- ���[�v���̃J�E���g
    ln_file_if_loop_cnt  NUMBER; -- �t�@�C��IF���[�v�J�E���^
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt        := 0;    -- �Ώی���
    gn_hht_inv_tran_cnt  := 0;    -- HHT���o�Ɉꎞ�\�o�^����
    gn_lot_trx_temp_cnt  := 0;    -- ���b�g�ʎ��TEMP�o�^����
    gn_error_cnt         := 0;    -- �G���[����
    gn_warn_cnt          := 0;    -- �X�L�b�v����
    gv_inv_org_code      := NULL; -- �݌ɑg�D�R�[�h
    gn_inv_org_id        := NULL; -- �݌ɑg�DID
    gv_belong_base_code  := NULL; -- �������_�R�[�h
    gt_dept_hht_div      := NULL; -- �S�ݓXHHT�敪
    gd_process_date      := NULL; -- �Ɩ����t
    gv_line_num          := NULL; -- CSV�A�b�v���[�h�s�ԍ�
    gv_validate_err_flag := cv_flag_normal_0; -- �Ó����G���[�t���O
--
    -- ���[�J���ϐ��̏�����
    ln_file_if_loop_cnt := 0; -- �t�@�C��IF���[�v�J�E���^
--
    -- ============================================
    -- A-1�D��������
    -- ============================================
    init(
       in_file_id        -- �t�@�C��ID
      ,iv_file_format    -- �t�@�C���t�H�[�}�b�g
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�DIF�f�[�^�擾
    -- ============================================
    get_if_data(
       in_file_id        -- �t�@�C��ID
      ,iv_file_format    -- �t�@�C���t�H�[�}�b�g
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���A�b�v���[�hIF���[�v
    <<file_if_loop>>
    FOR ln_file_if_loop_cnt IN 1 .. gt_file_line_data_tab.COUNT LOOP
      -- �O���[�o���ϐ�������
      gd_invoice_date           := NULL;  -- �`�[���t
      gt_inventory_item_id      := NULL;  -- �i��ID
      gt_primary_uom_code       := NULL;  -- ��P�ʃR�[�h
      gt_case_in_qty            := NULL;  -- ����
      gt_total_qty              := NULL;  -- ���{��
      gt_invoice_type           := NULL;  -- �`�[�敪
      gt_department_flag        := NULL;  -- �S�ݓX�t���O
      gt_out_base_code          := NULL;  -- �o�ɑ����_�R�[�h
      gt_in_base_code           := NULL;  -- ���ɑ����_�R�[�h
      gt_out_warehouse_flag     := NULL;  -- �o�ɑ��q�ɊǗ��Ώۋ敪
      gt_out_subinv_code_conv   := NULL;  -- �o�ɑ��ۊǏꏊ�ϊ��敪
      gt_in_subinv_code_conv    := NULL;  -- ���ɑ��ۊǏꏊ�ϊ��敪
      gt_out_business_low_type  := NULL;  -- �o�ɑ��Ƒԏ�����
      gt_in_business_low_type   := NULL;  -- ���ɑ��Ƒԏ�����
      gt_out_cust_code          := NULL;  -- �o�ɑ��ڋq�R�[�h
      gt_in_cust_code           := NULL;  -- ���ɑ��ڋq�R�[�h
      gt_hht_program_div        := NULL;  -- ���o�ɃW���[�i�������敪
      gt_item_convert_div       := NULL;  -- ���i�U�֋敪
      gt_stock_uncheck_list_div := NULL;  -- ���ɖ��m�F���X�g�Ώۋ敪
      gt_stock_balance_list_div := NULL;  -- ���ɍ��يm�F���X�g�Ώۋ敪
      gt_consume_vd_flag        := NULL;  -- ����VD��[�Ώۃt���O
      gt_transaction_id         := NULL;  -- ���o�Ɉꎞ�\ID
      gt_invoice_no             := NULL;  -- �`�[No
      gv_err_flag               := cv_flag_normal_0;  -- �G���[�t���O
--
      -- ============================================
      -- A-3�D�A�b�v���[�h�t�@�C�����ڕ���
      -- ============================================
      divide_item(
         ln_file_if_loop_cnt -- IF���[�v�J�E���^
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- A-4�D�Ó����`�F�b�N�����ڒl���o
      -- ============================================
      validate_item(
         ln_file_if_loop_cnt -- IF���[�v�J�E���^
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �Ó����G���[�̏ꍇ�̓G���[�������J�E���g
      IF ( gv_err_flag = cv_flag_err_1 ) THEN
        gn_error_cnt := gn_error_cnt + 1;
      ELSE
      -- �Ó����G���[���������Ă��Ȃ��ꍇ�̓e�[�u���o�^���������s
        -- ============================================
        -- A-5�DHHT���o�Ɉꎞ�\�o�^
        -- ============================================
        ins_hht_inv_tran(
           ln_file_if_loop_cnt -- IF���[�v�J�E���^
          ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        ELSE
          -- ����I���̏ꍇ��HHT���o�Ɉꎞ�\�o�^�������J�E���g
          gn_hht_inv_tran_cnt := gn_hht_inv_tran_cnt + 1;
        END IF;
--
        -- �o�ɑ��ۊǏꏊ���q�ɊǗ��Ώۂ̏ꍇ
        IF ( gt_out_warehouse_flag = cv_const_y ) THEN
          -- ============================================
          -- A-6�D���b�g�ʎ��TEMP�o�^
          -- ============================================
          ins_lot_trx_temp(
             lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          ELSE
            -- ����I���̏ꍇ�̓��b�g�ʎ��TEMP�o�^�������J�E���g
            gn_lot_trx_temp_cnt := gn_lot_trx_temp_cnt + 1;
          END IF;
        END IF;
      END IF;
--
    END LOOP file_if_loop;
--
    -- �G���[���R�[�h�����݂���ꍇ
    IF ( gn_error_cnt <> 0 ) THEN
      gv_validate_err_flag := cv_flag_err_1; -- �Ó����G���[�t���O:Y
      ov_retcode := cv_status_error; -- �I���X�e�[�^�X:�G���[
    END IF;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_file_id       IN    VARCHAR2,        --   1.�t�@�C��ID(�K�{)
    iv_file_format   IN    VARCHAR2         --   2.�t�@�C���t�H�[�}�b�g(�K�{)
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
--
    cv_prg_name_del    CONSTANT VARCHAR2(100) := 'delete_if_data';   -- �v���O������(IF�f�[�^�폜)
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_retcode_if_del  VARCHAR2(1);     -- ���^�[���E�R�[�h�iIF�f�[�^�폜�j
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_file_type_out
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       TO_NUMBER(iv_file_id) -- 1.�t�@�C��ID
      ,iv_file_format        -- 2.�t�@�C���t�H�[�}�b�g
      ,lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ����I���ȊO�̏ꍇ�A���[���o�b�N�𔭍s
      ROLLBACK;
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ============================================
    -- A-7�DIF�f�[�^�폜
    -- ============================================
    -- ����I��/�ُ�I���Ɋւ�炸�폜
    delete_if_data(
       TO_NUMBER(iv_file_id) -- �t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode_if_del -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �폜�Ɏ��s�����ꍇ
    IF ( lv_retcode_if_del <> cv_status_normal ) THEN
      -- �폜�G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- A-6�܂ł̏���������I���̏ꍇ
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ���[���o�b�N
        ROLLBACK;
        -- �I���X�e�[�^�X���G���[�ɐݒ�
        lv_retcode := cv_status_error;
      END IF;
    ELSE
      -- �폜�����������ꍇ�̓R�~�b�g
      COMMIT;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================
    -- �G���[���̏o�͌����ݒ�
    -- ===============================================
    -- �Ó����G���[�̏ꍇ
    IF ( gv_validate_err_flag = cv_flag_err_1 ) THEN
      gn_hht_inv_tran_cnt := 0; -- HHT���o�Ɉꎞ�\�o�^����
      gn_lot_trx_temp_cnt := 0; -- ���b�g�ʎ��TEMP�o�^����
      gn_warn_cnt         := ( gn_target_cnt - gn_error_cnt ); -- �X�L�b�v����
    -- ���̑��G���[�̏ꍇ
    ELSIF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt       := 0; -- �Ώی���
      gn_hht_inv_tran_cnt := 0; -- HHT���o�Ɉꎞ�\�o�^����
      gn_lot_trx_temp_cnt := 0; -- ���b�g�ʎ��TEMP�o�^����
      gn_error_cnt        := 1; -- �G���[����
      gn_warn_cnt         := 0; -- �X�L�b�v����
    END IF;
--
    -- ===============================================================
    -- ���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --HHT���o�Ɉꎞ�\�o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10671
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_hht_inv_tran_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���b�g�ʎ��TEMP�o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10672
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_lot_trx_temp_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���ʂ̃��O���b�Z�[�W�̏o�͏I��
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�I�����b�Z�[�W�̐ݒ�A�o��
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOI003A18C;
/
