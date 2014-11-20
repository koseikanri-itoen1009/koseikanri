CREATE OR REPLACE PACKAGE BODY APPS.XXCSO020A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A04C(body)
 * Description      : SP�ꌈ��ʂ���̗v���ɏ]���āASP�ꌈ��ʂœ��͂��ꂽ���Ŕ����˗���
 *                    �쐬���܂��B
 * MD.050           : MD050_CSO_020_A04_���̋@�i�Y��j�����˗��f�[�^�A�g�@�\
 *
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  start_proc             ��������(A-1)
 *  get_sp_dec_head_info   �r�o�ꌈ�w�b�_�e�[�u���擾����(A-2)
 *  get_employee_info      �]�ƈ����擾����(A-3)
 *  get_item_info          �i�ڏ��擾����(A-4)
 *  get_vendor_info        ���Ϗ��擾����(A-5)
 *  get_inv_org_id         ������g�D�h�c�擾����(A-6)
 *  get_code_comb_id       ��p����Ȗڂh�c�擾����(A-7)
 *  reg_po_req_interface   �w���˗�I/F�e�[�u���o�^����(A-8)
 *  reg_vendor             �����˗��w�b�_�E���דo�^����(A-9)
 *  confirm_reg_vendor     �����˗��w�b�_�E���דo�^�����m�F����(A-10)
 *  get_customer_info      �ڋq���擾����(A-11)
 *  get_po_req_line_id     �w���˗����ׂh�c�擾����(A-12)
 *  get_temp_info_terget   ���e���v���[�g�o�^�Ώۍ��ڏ��擾����(A-13)
 *  reg_temp_info          ���e���v���[�g�o�^����(A-14)
 *  submain                ���C�������v���V�[�W��
 *  main                   ���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-18    1.0   Kazuo.Satomura   �V�K�쐬
 *  2009-02-19          Kazuo.Satomura   ��Q�Ή�
 *                                       �E�i�ڏ��擾�̎��A����̏ꍇ�i�ڂ��擾�ł��Ȃ�
 *                                         ��Q���C��
 *                                       �E�r�o�ꌈ�̋@��R�[�h�����A�ԍ��փ}�b�s���O
 *                                       �E�r�o�ꌈ�̋@��R�[�h����댯���ނh�c���擾���A
 *                                         �}�b�s���O
 *                                       �E�ڋq���擾�̏����ɂr�o�ꌈ�ڋq�敪��ǉ�
 *  2009-02-27          Kazuo.Satomura   ��Q�Ή�(��QNO39,40,41)
 *                                       �E���Ϗ�񌟍��̏�����L�����t�ƃX�e�[�^�X��ǉ�
 *                                       �E�@��R�[�h�������͂̏ꍇ�͊댯���ނh�c���擾��
 *                                         �Ȃ��悤�C��
 *                                       �E�]�ƈ����擾�̏��������O�C�����[�U�[�h�c�֕�
 *                                         �X
 *  2009-03/23    1.1   Kazuo.Satomura   �V�X�e���e�X�g��Q�Ή�(��Q�ԍ�T1_0095,100,104)
 *                                       �E�o�C���[�h�c�����O�C���]�ƈ��h�c���猩�σw�b�_
 *                                         �̃G�[�W�F���g�h�c�֕ύX
 *                                       �E���ό������̏�����L���J�n���`�L���I��������
 *                                         �J�n���`�I�����֕ύX
 *                                       �E�����掖�Ə��h�c�A�����掖�Ə��R�[�h�A������v
 *                                         ���҂h�c�����O�C���̃��[�U�[�h�c����擾
 *  2009-04-03    1.2   Kazuo.Satomura   �V�X�e���e�X�g��Q�Ή�(��Q�ԍ�T1_0109)
 *  2009-04-07    1.3   Kazuo.Satomura   �V�X�e���e�X�g��Q�Ή�(��Q�ԍ�T1_0355)
 *  2009-05-01    1.4   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-01    1.5   Kazuo.Satomura   0001138�Ή�
 *                                       �E�w���˗�I/F�e�[�u���̃o�b�`�h�c�Ɏ���h�c��ݒ�
 *                                       �E�w���˗��C���|�[�g�����̑��p�����[�^�Ɏ���h�c
 *                                         ��ݒ�
 *  2010-01-08    1.6   Kazuyo.Hosoi     E_�{�ғ�_01017�Ή�
 *****************************************************************************************/
  --
  --#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
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
  gn_target_cnt    NUMBER; -- �Ώی���
  gn_normal_cnt    NUMBER; -- ���팏��
  gn_error_cnt     NUMBER; -- �G���[����
  gn_warn_cnt      NUMBER; -- �X�L�b�v����
  --
  --################################  �Œ蕔 END   ##################################
  --
  --##########################  �Œ苤�ʗ�O�錾�� START  ###########################
  --
  --*** ���������ʗ�O ***
  global_process_expt EXCEPTION;
  --
  --*** ���ʊ֐���O ***
  global_api_expt EXCEPTION;
  --
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCSO020A04C';                                    -- �p�b�P�[�W��
  cv_sales_appl_short_name CONSTANT VARCHAR2(5)   := 'XXCSO';                                           -- �c�Ɨp�A�v���P�[�V�����Z�k��
  cv_flag_yes              CONSTANT VARCHAR2(1)   := 'Y';                                               -- �t���OY
  cv_flag_no               CONSTANT VARCHAR2(1)   := 'N';                                               -- �t���ON
  cv_date_format1          CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';                           -- ���t�t�H�[�}�b�g
  cv_date_format2          CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD';                                      -- ���t�t�H�[�}�b�g
  cv_year_format           CONSTANT VARCHAR2(21)  := 'YYYY';                                            -- ���t�t�H�[�}�b�g�i�N�j
  cv_month_format          CONSTANT VARCHAR2(21)  := 'MM';                                              -- ���t�t�H�[�}�b�g�i���j
  cv_day_format            CONSTANT VARCHAR2(21)  := 'DD';                                              -- ���t�t�H�[�}�b�g�i���j
  cd_sysdate               CONSTANT DATE          := SYSDATE;                                           -- �V�X�e�����t
  cd_process_date          CONSTANT DATE          := xxccp_common_pkg2.get_process_date;                -- �Ɩ��������t
  cv_lang                  CONSTANT VARCHAR2(2)   := USERENV('LANG');                                   -- ����
  cn_org_id                CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ���O�C���g�D�h�c
  cv_price_type            CONSTANT VARCHAR2(9)   := 'QUOTATION';                                       -- ���i�^�C�v
  --
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011'; -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00325'; -- �p�����[�^�K�{�G���[
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00329'; -- �f�[�^�擾�G���[
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00330'; -- �f�[�^�o�^�G���[
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00383'; -- �V�[�P���X�擾�G���[
  cv_tkn_number_06 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00456'; -- �R���J�����g�N���G���[
  cv_tkn_number_07 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00457'; -- �R���J�����g�I���m�F�G���[
  cv_tkn_number_08 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00458'; -- �R���J�����g�ُ�I���G���[
  cv_tkn_number_09 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00459'; -- �R���J�����g�x���I���G���[
  cv_tkn_number_10 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00465'; -- �w���˗��o�^�G���[
  cv_tkn_number_11 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496'; -- �p�����[�^�o��
  cv_tkn_number_12 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00548'; -- ���ϕ����G���[
  /* 2009.04.03 K.Satomura T1_0109�Ή� START */
  cv_tkn_number_13 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00337'; -- �f�[�^�X�V�G���[
  /* 2009.04.03 K.Satomura T1_0109�Ή� END */
  --
  -- �g�[�N���R�[�h
  cv_tkn_param_name    CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_value         CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_key_name      CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_id        CONSTANT VARCHAR2(20) := 'KEY_ID';
  cv_tkn_table         CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_key           CONSTANT VARCHAR2(20) := 'KEY';
  cv_tkn_error_message CONSTANT VARCHAR2(20) := 'ERROR_MESSAGE';
  cv_tkn_sequence      CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_proc_name     CONSTANT VARCHAR2(20) := 'PROC_NAME';
  cv_tkn_request_id    CONSTANT VARCHAR2(20) := 'REQUEST_ID';
  cv_tkn_err_msg       CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_item          CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_api_name      CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_api_msg       CONSTANT VARCHAR2(20) := 'API_MSG';
  cv_tkn_action        CONSTANT VARCHAR2(20) := 'ACTION';
  --
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1  CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg2  CONSTANT VARCHAR2(200) := 'cd_process_date = ';
  cv_debug_msg3  CONSTANT VARCHAR2(200) := '<< ���̓p�����[�^ >>';
  cv_debug_msg4  CONSTANT VARCHAR2(200) := 'it_sp_decision_header_id = ';
  cv_debug_msg5  CONSTANT VARCHAR2(200) := '<< �r�o�ꌈ�w�b�_�e�[�u�� >>';
  cv_debug_msg6  CONSTANT VARCHAR2(200) := 'sp_decision_number     = ';
  cv_debug_msg7  CONSTANT VARCHAR2(200) := 'approval_complete_date = ';
  cv_debug_msg8  CONSTANT VARCHAR2(200) := 'application_code       = ';
  cv_debug_msg9  CONSTANT VARCHAR2(200) := 'app_base_code          = ';
  cv_debug_msg10 CONSTANT VARCHAR2(200) := 'newold_type            = ';
  cv_debug_msg11 CONSTANT VARCHAR2(200) := 'maker_code             = ';
  cv_debug_msg12 CONSTANT VARCHAR2(200) := 'install_date           = ';
  cv_debug_msg14 CONSTANT VARCHAR2(200) := '<< �]�ƈ���� >>';
  cv_debug_msg15 CONSTANT VARCHAR2(200) := 'user_name       = ';
  cv_debug_msg16 CONSTANT VARCHAR2(200) := 'person_id       = ';
  cv_debug_msg17 CONSTANT VARCHAR2(200) := 'employee_number = ';
  cv_debug_msg18 CONSTANT VARCHAR2(200) := '<< �i�ڏ�� >>';
  cv_debug_msg19 CONSTANT VARCHAR2(200) := 'category_id = ';
  cv_debug_msg27 CONSTANT VARCHAR2(200) := '<< ������� >>';
  cv_debug_msg28 CONSTANT VARCHAR2(200) := 'vendor_id             = ';
  cv_debug_msg26 CONSTANT VARCHAR2(200) := 'item_description      = ';
  cv_debug_msg23 CONSTANT VARCHAR2(200) := 'unit_meas_lookup_code = ';
  cv_debug_msg22 CONSTANT VARCHAR2(200) := 'unit_price            = ';
  cv_debug_msg30 CONSTANT VARCHAR2(200) := 'quantity              = ';
  cv_debug_msg32 CONSTANT VARCHAR2(200) := '<< �������� >>';
  cv_debug_msg29 CONSTANT VARCHAR2(200) := 'ship_to_location_id       = ';
  cv_debug_msg31 CONSTANT VARCHAR2(200) := 'ship_to_location_code     = ';
  cv_debug_msg59 CONSTANT VARCHAR2(200) := 'ship_to_person_id         = ';
  cv_debug_msg33 CONSTANT VARCHAR2(200) := 'inventory_organization_id = ';
  cv_debug_msg34 CONSTANT VARCHAR2(200) := '<< ��p����Ȗڂh�c >>';
  cv_debug_msg35 CONSTANT VARCHAR2(200) := 'code_combination_id = ';
  cv_debug_msg36 CONSTANT VARCHAR2(200) := '<< ����h�c(�C���^�[�t�F�[�X�\�[�X�h�c) >>';
  cv_debug_msg37 CONSTANT VARCHAR2(200) := 'transaction_id = ';
  cv_debug_msg38 CONSTANT VARCHAR2(200) := '<< �v���h�c >>';
  cv_debug_msg39 CONSTANT VARCHAR2(200) := 'ln_request_id = ';
  cv_debug_msg40 CONSTANT VARCHAR2(200) := '<< �ڋq��� >>';
  cv_debug_msg41 CONSTANT VARCHAR2(200) := 'account_number             = ';
  cv_debug_msg42 CONSTANT VARCHAR2(200) := 'party_name                 = ';
  cv_debug_msg43 CONSTANT VARCHAR2(200) := 'organization_name_phonetic = ';
  cv_debug_msg44 CONSTANT VARCHAR2(200) := 'postal_code                = ';
  cv_debug_msg45 CONSTANT VARCHAR2(200) := 'state                      = ';
  cv_debug_msg46 CONSTANT VARCHAR2(200) := 'city                       = ';
  cv_debug_msg47 CONSTANT VARCHAR2(200) := 'address1                   = ';
  cv_debug_msg48 CONSTANT VARCHAR2(200) := 'address2                   = ';
  cv_debug_msg49 CONSTANT VARCHAR2(200) := 'address3                   = ';
  cv_debug_msg50 CONSTANT VARCHAR2(200) := 'address_lines_phonetic     = ';
  cv_debug_msg51 CONSTANT VARCHAR2(200) := 'sale_base_code             = ';
  cv_debug_msg52 CONSTANT VARCHAR2(200) := '<< �����˗����ׂh�c >>';
  cv_debug_msg53 CONSTANT VARCHAR2(200) := 'requisition_line_id = ';
  cv_debug_msg54 CONSTANT VARCHAR2(200) := '<< ���e���v���[�g >>';
  cv_debug_msg55 CONSTANT VARCHAR2(200) := 'requisition_line_id = ';
  cv_debug_msg56 CONSTANT VARCHAR2(200) := 'attribute_name      = ';
  cv_debug_msg57 CONSTANT VARCHAR2(200) := 'attribute_value     = ';
  cv_debug_msg58 CONSTANT VARCHAR2(200) := 'un_number              = ';
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �}�X�^�o�^���p�\����
  TYPE g_mst_regist_info_rtype IS RECORD(
    -- �r�o�ꌈ�w�b�_���
     sp_decision_number     xxcso_sp_decision_headers.sp_decision_number%TYPE     -- �r�o�ꌈ���ԍ�
    ,approval_complete_date xxcso_sp_decision_headers.approval_complete_date%TYPE -- ���F������
    ,application_code       xxcso_sp_decision_headers.application_code%TYPE       -- �\���҃R�[�h
    ,app_base_code          xxcso_sp_decision_headers.app_base_code%TYPE          -- �\�����_�R�[�h
    ,newold_type            xxcso_sp_decision_headers.newold_type%TYPE            -- �V�䋌��敪
    ,maker_code             xxcso_sp_decision_headers.maker_code%TYPE             -- ���[�J�[�R�[�h
    ,un_number              xxcso_sp_decision_headers.un_number%TYPE              -- �@��R�[�h
    ,install_date           xxcso_sp_decision_headers.install_date%TYPE           -- �ݒu��
    -- �]�ƈ����
    ,user_name       xxcso_employees_v2.user_name%TYPE       -- ���[�U�[��
    ,person_id       xxcso_employees_v2.person_id%TYPE       -- �]�ƈ��h�c
    ,employee_number xxcso_employees_v2.employee_number%TYPE -- �]�ƈ��ԍ�
    -- �i�ڏ��
    ,category_id     mtl_categories_b.category_id%TYPE        -- �i�ڂh�c
    -- �������
    ,po_header_id          po_headers.po_header_id%TYPE        -- ���σw�b�_�[�h�c
    ,agent_id              po_headers.agent_id%TYPE            -- �G�[�W�F���g�h�c
    ,vendor_id             po_headers.vendor_id%TYPE           -- �d����h�c
    ,line_num              po_lines.line_num%TYPE              -- ���הԍ�
    ,item_description      po_lines.item_description%TYPE      -- �i�ړK�p
    ,unit_meas_lookup_code po_lines.unit_meas_lookup_code%TYPE -- �P��
    ,unit_price            po_lines.unit_price%TYPE            -- ���i
    ,quantity              po_lines.quantity%TYPE              -- ����
    -- ��������
    ,ship_to_location_id       xxcso_locations_v.location_id%TYPE -- �����掖�Ə��h�c
    ,ship_to_location_code     xxcso_locations_v.dept_code%TYPE   -- �����掖�Ə��R�[�h
    ,ship_to_person_id         xxcso_employees_v2.person_id%TYPE  -- ������v���҂h�c
    ,inventory_organization_id NUMBER                             -- ������g�D�h�c
    -- ��p����Ȗڂh�c
    ,code_combination_id per_employees_current_x.default_code_combination_id%TYPE -- ��p����Ȗڂh�c
    -- �ڋq���
    ,account_number             hz_cust_accounts.account_number%TYPE       -- �ڋq�R�[�h
    ,party_name                 hz_parties.party_name%TYPE                 -- �ڋq��
    ,organization_name_phonetic hz_parties.organization_name_phonetic%TYPE -- �ڋq���J�i
    ,postal_code                hz_locations.postal_code%TYPE              -- �X�֔ԍ�
    ,state                      hz_locations.state%TYPE                    -- �s���{��
    ,city                       hz_locations.city%TYPE                     -- �s�E��
    ,address1                   hz_locations.address1%TYPE                 -- �Z���P
    ,address2                   hz_locations.address2%TYPE                 -- �Z���Q
    ,address3                   hz_locations.address3%TYPE                 -- �Z���R
    ,address_lines_phonetic     hz_locations.address_lines_phonetic%TYPE   -- �d�b�ԍ�
    ,sale_base_code             xxcmm_cust_accounts.sale_base_code%TYPE    -- ���㋒�_�R�[�h
    -- �����˗����ׂh�c
    ,requisition_line_id po_requisition_lines_all.requisition_line_id%TYPE -- �����˗����ׂh�c
  );
  --
  /**********************************************************************************
   * Procedure Name   : start_proc
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE start_proc(
     it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                             -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                             -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_proc'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_tkn_value_sp_dec_hed_id CONSTANT VARCHAR2(30) := '�r�o�ꌈ�w�b�_�h�c';
    cv_tkn_value_processdate   CONSTANT VARCHAR2(30) := '�Ɩ����t'; 
    --
    -- *** ���[�J���ϐ� ***
    lv_msg_from VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ===========================
    -- �N���p�����[�^���b�Z�[�W�o��
    -- ===========================
    -- ��s�̑}��
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => ''
    );
    --
    lv_msg_from := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_11           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_param_name          -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_tkn_value_sp_dec_hed_id -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_value               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => it_sp_decision_header_id   -- �g�[�N���l2
                   );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => lv_msg_from
    );
    --
    -- ======================
    -- �Ɩ����t�`�F�b�N
    -- ======================
    IF (cd_process_date IS NULL) THEN
      -- �Ɩ����t�������͂̏ꍇ�G���[
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item              -- �g�[�N�R�[�h1
                     ,iv_token_value1 => cv_tkn_value_processdate -- �g�[�N���l1
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG START ***
    -- �Ɩ����t�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || TO_CHAR(cd_process_date, 'YYYY/MM/DD') || CHR(10) || ''
    );
    -- *** DEBUG_LOG END ***
    --
    -- ======================
    -- ���̓p�����[�^�`�F�b�N
    -- ======================
    IF (it_sp_decision_header_id IS NULL) THEN
      -- �r�o�ꌈ�w�b�_�h�c�������͂̏ꍇ�G���[
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_02           -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_param_name          -- �g�[�N�R�[�h1
                     ,iv_token_value1 => cv_tkn_value_sp_dec_hed_id -- �g�[�N���l1
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG START ***
    -- ���̓p�����[�^�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || it_sp_decision_header_id || CHR(10) || ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END start_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_sp_dec_head_info
   * Description      : �r�o�ꌈ�w�b�_�e�[�u���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_sp_dec_head_info(
     it_sp_decision_header_id IN            xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,iot_mst_regist_info_rec  IN OUT NOCOPY g_mst_regist_info_rtype                              -- �}�X�^�o�^���
    ,ov_errbuf                OUT    NOCOPY VARCHAR2                                             -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT    NOCOPY VARCHAR2                                             -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT    NOCOPY VARCHAR2                                             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_sp_dec_head_info'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_value_sp_dec_head    CONSTANT VARCHAR2(50) := '�r�o�ꌈ�w�b�_�e�[�u��';
    cv_tkn_value_sp_dec_head_id CONSTANT VARCHAR2(50) := '�r�o�ꌈ�w�b�_�h�c';
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
    -- ==============================
    -- �r�o�ꌈ�w�b�_�e�[�u���擾����
    -- ==============================
    BEGIN
      SELECT xsd.sp_decision_number     sp_decision_number     -- �r�o�ꌈ���ԍ�
            ,xsd.approval_complete_date approval_complete_date -- ���F������
            ,xsd.application_code       application_code       -- �\���҃R�[�h
            ,xsd.app_base_code          app_base_code          -- �\�����_�R�[�h
            ,xsd.newold_type            newold_type            -- �V�䋌��敪
            ,xsd.maker_code             maker_code             -- ���[�J�[�R�[�h
            ,xsd.un_number              un_number              -- �@��R�[�h
            ,xsd.install_date           install_date           -- �ݒu��
      INTO   iot_mst_regist_info_rec.sp_decision_number     -- �r�o�ꌈ���ԍ�
            ,iot_mst_regist_info_rec.approval_complete_date -- ���F������
            ,iot_mst_regist_info_rec.application_code       -- �\���҃R�[�h
            ,iot_mst_regist_info_rec.app_base_code          -- �\�����_�R�[�h
            ,iot_mst_regist_info_rec.newold_type            -- �V�䋌��敪
            ,iot_mst_regist_info_rec.maker_code             -- ���[�J�[�R�[�h
            ,iot_mst_regist_info_rec.un_number              -- �@��R�[�h
            ,iot_mst_regist_info_rec.install_date           -- �ݒu��
      FROM   xxcso_sp_decision_headers xsd -- �r�o�ꌈ�w�b�_�e�[�u��
      WHERE  xsd.sp_decision_header_id = it_sp_decision_header_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head    -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_head_id -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => it_sp_decision_header_id    -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- �r�o�ꌈ�w�b�_�e�[�u�������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg6  || iot_mst_regist_info_rec.sp_decision_number                              || CHR(10) ||
                 cv_debug_msg7  || TO_CHAR(iot_mst_regist_info_rec.approval_complete_date,cv_date_format1) || CHR(10) ||
                 cv_debug_msg8  || iot_mst_regist_info_rec.application_code                                || CHR(10) ||
                 cv_debug_msg9  || iot_mst_regist_info_rec.app_base_code                                   || CHR(10) ||
                 cv_debug_msg10 || iot_mst_regist_info_rec.newold_type                                     || CHR(10) ||
                 cv_debug_msg11 || iot_mst_regist_info_rec.maker_code                                      || CHR(10) ||
                 cv_debug_msg12 || TO_CHAR(iot_mst_regist_info_rec.install_date, cv_date_format1)          || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_sp_dec_head_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_employee_info
   * Description      : �]�ƈ����擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_employee_info(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- �}�X�^�o�^���
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_employee_info'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_value_employee CONSTANT VARCHAR2(50) := '�]�ƈ��}�X�^(�ŐV)�r���[';
    cv_tkn_value_user_id  CONSTANT VARCHAR2(50) := '���[�U�[�h�c';
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ============================
    -- �]�ƈ����擾
    -- ============================
    BEGIN
      SELECT xev.user_name       user_name       -- ���[�U�[��
            ,xev.person_id       person_id       -- �]�ƈ��h�c
            ,xev.employee_number employee_number -- �]�ƈ��ԍ�
      INTO   iot_mst_regist_info_rec.user_name       -- ���[�U�[��
            ,iot_mst_regist_info_rec.person_id       -- �]�ƈ��h�c
            ,iot_mst_regist_info_rec.employee_number -- �]�ƈ��ԍ�
      FROM   xxcso_employees_v2 xev -- �]�ƈ��}�X�^(�ŐV)�r���[
      WHERE  xev.user_id = cn_created_by
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_employee    -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_user_id     -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cn_created_by            -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- �]�ƈ��������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg14  || CHR(10) ||
                 cv_debug_msg15  || iot_mst_regist_info_rec.user_name       || CHR(10) ||
                 cv_debug_msg16  || iot_mst_regist_info_rec.person_id       || CHR(10) ||
                 cv_debug_msg17  || iot_mst_regist_info_rec.employee_number || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
     -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_employee_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : �i�ڏ��擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_info(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- �}�X�^�o�^���
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_item_info'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_lookup_type_cate_type CONSTANT VARCHAR2(50) := 'XXCSO1_PO_CATEGORY_TYPE';
    cv_msg_sep               CONSTANT VARCHAR2(2)  := '�E';
    cv_newold_type_old       CONSTANT VARCHAR2(1)  := '2'; -- �V�䋌��敪=2
    --
    -- �g�[�N���p�萔
    cv_tkn_value_item_info CONSTANT VARCHAR2(50) := '�i�ڏ��';
    cv_tkn_value_key_name  CONSTANT VARCHAR2(50) := '�V�䋌��敪�E���[�J�[�R�[�h';
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ============================
    -- �i�ڏ��擾
    -- ============================
    BEGIN
      SELECT mcb.category_id category_id -- �J�e�S���h�c
      INTO   iot_mst_regist_info_rec.category_id -- �J�e�S���h�c
      FROM   fnd_lookup_values_vl flv
            ,mtl_categories_b     mcb
      WHERE  flv.lookup_type                                    =  cv_lookup_type_cate_type
      AND    flv.attribute3                                     =  iot_mst_regist_info_rec.newold_type
      AND    NVL(flv.attribute2, fnd_api.g_miss_char)           =  DECODE(iot_mst_regist_info_rec.newold_type
                                                                         ,cv_newold_type_old, fnd_api.g_miss_char
                                                                         ,iot_mst_regist_info_rec.maker_code)
      AND    flv.enabled_flag                                   =  cv_flag_yes
      AND    TRUNC(NVL(flv.start_date_active, cd_process_date)) <= TRUNC(cd_process_date)
      AND    TRUNC(NVL(flv.end_date_active, cd_process_date))   >= TRUNC(cd_process_date)
      AND    flv.meaning                                        =  mcb.segment1
      AND    mcb.enabled_flag                                   =  cv_flag_yes
      AND    TRUNC(NVL(mcb.start_date_active, cd_process_date)) <= TRUNC(cd_process_date)
      AND    TRUNC(NVL(mcb.end_date_active, cd_process_date))   >= TRUNC(cd_process_date)
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03                    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_item_info              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_key_name               -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iot_mst_regist_info_rec.newold_type ||
                                           cv_msg_sep                          ||
                                           iot_mst_regist_info_rec.maker_code  -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- �i�ڏ������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg18 || CHR(10) ||
                 cv_debug_msg19 || iot_mst_regist_info_rec.category_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_item_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_vendor_info
   * Description      : ���Ϗ��擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_vendor_info(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- �}�X�^�o�^���
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_vendor_info';  -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_quotation_class_code CONSTANT VARCHAR2(10) := 'CATALOG';
    cv_status_active        CONSTANT VARCHAR2(1)  := 'A';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_vendor_info CONSTANT VARCHAR2(50) := '���Ϗ��';
    cv_tkn_value_key_name    CONSTANT VARCHAR2(50) := '�J�e�S���h�c';
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
    -- ============================
    -- �������擾
    -- ============================
    BEGIN
      SELECT phe.po_header_id          po_header_id          -- ���σw�b�_�h�c
            ,phe.agent_id              agent_id              -- �G�[�W�F���g�h�c
            ,phe.vendor_id             vendor_id             -- �d����h�c
            ,pli.line_num              line_num              -- ���הԍ�
            ,pli.item_description      item_description      -- �i�ړK�p
            ,pli.unit_meas_lookup_code unit_meas_lookup_code -- �P��
            ,pli.unit_price            unit_price            -- ���i
            ,pli.quantity              quantity              -- ����
      INTO   iot_mst_regist_info_rec.po_header_id          -- ���σw�b�_�h�c
            ,iot_mst_regist_info_rec.agent_id              -- �G�[�W�F���g�h�c
            ,iot_mst_regist_info_rec.vendor_id             -- �d����h�c
            ,iot_mst_regist_info_rec.line_num              -- ���הԍ�
            ,iot_mst_regist_info_rec.item_description      -- �i�ړK�p
            ,iot_mst_regist_info_rec.unit_meas_lookup_code -- �P��
            ,iot_mst_regist_info_rec.unit_price            -- ���i
            ,iot_mst_regist_info_rec.quantity              -- ����
      FROM   po_headers   phe -- ���σw�b�_�r���[
            ,po_lines     pli -- ���ϖ��׃r���[
      WHERE  pli.category_id                     =  iot_mst_regist_info_rec.category_id
      AND    pli.po_header_id                    =  phe.po_header_id
      AND    phe.type_lookup_code                =  cv_price_type
      AND    phe.quotation_class_code            =  cv_quotation_class_code
      /* 2009.04.07 K.Satomura T1_0355�Ή� START */
      --AND    TRUNC(NVL(phe.start_date, SYSDATE)) <= TRUNC(cd_process_date)
      --AND    TRUNC(NVL(phe.end_date, SYSDATE))   >= TRUNC(cd_process_date)
      AND    TRUNC(NVL(phe.start_date, cd_process_date)) <= TRUNC(cd_process_date)
      AND    TRUNC(NVL(phe.end_date, cd_process_date))   >= TRUNC(cd_process_date)
      /* 2009.04.07 K.Satomura T1_0355�Ή� END */
      AND    phe.status_lookup_code              =  cv_status_active
      ;
      --
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_12                    -- ���b�Z�[�W�R�[�h
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03                    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_vendor_info            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_key_name               -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iot_mst_regist_info_rec.category_id -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- �����������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg27 || CHR(10) ||
                 cv_debug_msg28 || iot_mst_regist_info_rec.vendor_id             || CHR(10) ||
                 cv_debug_msg26 || iot_mst_regist_info_rec.item_description      || CHR(10) ||
                 cv_debug_msg23 || iot_mst_regist_info_rec.unit_meas_lookup_code || CHR(10) ||
                 cv_debug_msg22 || iot_mst_regist_info_rec.unit_price            || CHR(10) ||
                 cv_debug_msg30 || iot_mst_regist_info_rec.quantity              || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_vendor_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_inv_org_id
   * Description      : ������g�D���擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_inv_org_id(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- �}�X�^�o�^���
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_inv_org_id'; -- �v���O������
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
    -- �g�[�N���p�萔
    cv_tkn_value_iniv_info   CONSTANT VARCHAR2(30) := '��������';
    cv_tkn_value_iniv_org_id CONSTANT VARCHAR2(30) := '������g�D�h�c';
    cv_tkn_value_key_name1   CONSTANT VARCHAR2(30) := '���[�U�[�h�c';
    cv_tkn_value_key_name2   CONSTANT VARCHAR2(30) := '�o�א掖�Ə��h�c';
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
    -- ============================
    -- ��������擾
    -- ============================
    BEGIN
      SELECT xlv.location_id ship_to_location_id   -- �����掖�Ə��h�c
            ,xlv.dept_code   ship_to_location_code -- �����掖�Ə��R�[�h
            ,xev.person_id   ship_to_person_id     -- ������v���҂h�c
      INTO   iot_mst_regist_info_rec.ship_to_location_id
            ,iot_mst_regist_info_rec.ship_to_location_code
            ,iot_mst_regist_info_rec.ship_to_person_id
      FROM   xxcso_employees_v2 xev -- �]�ƈ��}�X�^�i�ŐV�j�r���[
            ,xxcso_locations_v  xlv -- ���Ə��}�X�^�i�ŐV�j�r���[
      WHERE  xev.user_id            = fnd_global.user_id
      AND    xev.work_base_code_new = xlv.dept_code
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_iniv_info   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_key_name1   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => fnd_global.user_id       -- �g�[�N���l3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ============================
    -- ������g�D�h�c�擾
    -- ============================
    BEGIN
      SELECT NVL(hlo.inventory_organization_id, fsp.inventory_organization_id) org_id -- ������g�D�h�c
      INTO   iot_mst_regist_info_rec.inventory_organization_id -- ������g�D�h�c
      FROM   hr_locations                 hlo -- ���Ə��}�X�^�r���[
            ,financials_system_parameters fsp -- �������׃r���[
      WHERE  hlo.location_id = iot_mst_regist_info_rec.ship_to_location_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03                            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_iniv_org_id                    -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_key_name2                      -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iot_mst_regist_info_rec.ship_to_location_id -- �g�[�N���l3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- ������������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg32 || CHR(10) ||
                 cv_debug_msg29 || iot_mst_regist_info_rec.ship_to_location_id       || CHR(10) ||
                 cv_debug_msg31 || iot_mst_regist_info_rec.ship_to_location_code     || CHR(10) ||
                 cv_debug_msg59 || iot_mst_regist_info_rec.ship_to_person_id         || CHR(10) ||
                 cv_debug_msg33 || iot_mst_regist_info_rec.inventory_organization_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_inv_org_id;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_code_comb_id
   * Description      : ��p����Ȗڂh�c�擾����(A-7)
   ***********************************************************************************/
  PROCEDURE get_code_comb_id(
     iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- �}�X�^�o�^���
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_code_comb_id';  -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- �g�[�N���p�萔
    cv_tkn_value_ccid     CONSTANT VARCHAR2(50) := '��p����Ȗڂh�c';
    cv_tkn_value_key_name CONSTANT VARCHAR2(50) := '�]�ƈ��ԍ�';
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
    -- ============================
    -- ��p����Ȗڂh�c�擾
    -- ============================
    BEGIN
      SELECT pec.default_code_combination_id default_code_combination_id -- �f�t�H���g��p����Ȗڂh�c
      INTO   iot_mst_regist_info_rec.code_combination_id -- ��p����Ȗڂh�c
      FROM   per_employees_current_x pec
      WHERE  pec.employee_num = iot_mst_regist_info_rec.employee_number
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03                        -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_ccid                       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_key_name                   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iot_mst_regist_info_rec.employee_number -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- ��p����Ȗڂh�c�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg34 || CHR(10) ||
                 cv_debug_msg35 || iot_mst_regist_info_rec.code_combination_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_code_comb_id;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_po_req_interface
   * Description      : �w���˗�I/F�e�[�u���o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE reg_po_req_interface(
     it_mst_regist_info_rec   IN         g_mst_regist_info_rtype                                  -- �}�X�^�o�^���
    ,ot_interface_source_code OUT NOCOPY po_requisitions_interface_all.interface_source_code%TYPE -- �C���^�[�t�F�[�X�\�[�X�h�c
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                                 -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                                 -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_po_req_interface'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_source_type_code      CONSTANT VARCHAR2(6)  := 'VENDOR';
    cv_destination_type_code CONSTANT VARCHAR2(7)  := 'EXPENSE';
    cv_authorization_status  CONSTANT VARCHAR2(10) := 'INCOMPLETE';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_un_number CONSTANT VARCHAR2(40) := '���A�ԍ��r���[';
    cv_tkn_value_key_name  CONSTANT VARCHAR2(40) := '�@��R�[�h�i���A�ԍ��j';
    cv_tkn_value_table     CONSTANT VARCHAR2(40) := '�w���˗�I/F�e�[�u��';
    cv_tkn_value_sequence  CONSTANT VARCHAR2(40) := '�w���˗�I/F�V�[�P���X';
    --
    -- *** ���[�J���ϐ� ***
    lt_hazard_class_id po_un_numbers_vl.hazard_class_id%TYPE;
    lt_transaction_id  po_requisitions_interface_all.transaction_id%TYPE;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ============================
    -- �@��敪�擾
    -- ============================
    IF (it_mst_regist_info_rec.un_number IS NOT NULL) THEN
      BEGIN
        SELECT pun.hazard_class_id hazard_class_id
        INTO   lt_hazard_class_id
        FROM   po_un_numbers_vl pun
        WHERE  pun.un_number = it_mst_regist_info_rec.un_number
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���̑��̃G���[�̏ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_03                    -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_action                       -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_un_number            -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_key_name                     -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_value_key_name               -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_key_id                       -- �g�[�N���R�[�h3
                         ,iv_token_value3 => it_mst_regist_info_rec.un_number -- �g�[�N���l3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    END IF;
    --
    -- ============================
    -- ����h�c�擾
    -- ============================
    BEGIN
      SELECT xxcso_po_rqistns_in_all_s01.NEXTVAL transaction_id
      INTO   lt_transaction_id
      FROM   DUAL
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- ���̑��̃G���[�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_sequence          -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_sequence    -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ============================
    -- �w���˗�I/F�e�[�u���o�^
    -- ============================
    BEGIN
      INSERT INTO po_requisitions_interface_all(
        /* 2009.08.21 K.Satomura 0001138�Ή� START */
        -- transaction_id              -- ����h�c
        --,process_flag                -- �����t���O
         process_flag                -- �����t���O
        /* 2009.08.21 K.Satomura 0001138�Ή� END */
        ,request_id                  -- �v���h�c
        ,program_id                  -- �v���O�����h�c
        ,program_application_id      -- �v���O�����A�v���P�[�V�����h�c
        ,program_update_date         -- �v���O�����X�V��
        ,last_updated_by             -- �ŏI�X�V��
        ,last_update_date            -- �ŏI�X�V��
        ,last_update_login           -- �ŏI�X�V���O�C��
        ,creation_date               -- �쐬��
        ,created_by                  -- �쐬��
        ,interface_source_code       -- �C���^�[�t�F�[�X�\�[�X�h�c
        ,source_type_code            -- �\�[�X�^�C�v�R�[�h
        ,destination_type_code       -- ������^�C�v
        ,item_description            -- �i�ړE�v
        ,quantity                    -- ����
        ,unit_price                  -- ���i
        ,authorization_status        -- �X�e�[�^�X
        /* 2009.08.21 K.Satomura 0001138�Ή� START */
        ,batch_id                    -- �o�b�`�h�c
        /* 2009.08.21 K.Satomura 0001138�Ή� END */
        ,preparer_id                 -- �쐬�҂h�c
        ,autosource_flag             -- �I�[�g�\�[�X�t���O
        ,header_description          -- �w�b�_�[�E�v
        ,urgent_flag                 -- �ً}�t���O
        ,charge_account_id           -- ��p����Ȗ�
        ,category_id                 -- �J�e�S���h�c
        ,unit_of_measure             -- �P��
        ,un_number                   -- ���A�ԍ�
        ,hazard_class_id             -- �댯����
        ,destination_organization_id -- ������g�D�h�c
        ,deliver_to_location_id      -- �����掖�Ə��h�c
        ,deliver_to_location_code    -- �����掖�Ə��R�[�h
        ,deliver_to_requestor_id     -- ������v���҂h�c
        ,suggested_buyer_id          -- SUGGESTED_BUYER_ID
        ,suggested_vendor_id         -- SUGGESTED_VENDOR_ID
        ,need_by_date                -- ��]�����
        ,preparer_name               -- �쐬�Җ�
        ,variance_account_id         -- �������z����h�c
        ,currency_unit_price         -- �ʉݒP��
        ,autosource_doc_header_id    -- �����\�[�X�����w�b�_
        ,autosource_doc_line_num     -- �����\�[�X�������הԍ�
        ,document_type_code          -- DOCUMENT_TYPE_CODE
        ,org_id                      -- ORG_ID
        ,tax_user_override_flag)     -- �ŋ��㏑���t���O
      VALUES(
        /* 2009.08.21 K.Satomura 0001138�Ή� START */
        -- lt_transaction_id                                -- ����h�c
        --,cv_flag_yes                                      -- �����t���O
         cv_flag_yes                                      -- �����t���O
        /* 2009.08.21 K.Satomura 0001138�Ή� END */
        ,cn_request_id                                    -- �v���h�c
        ,cn_program_id                                    -- �v���O�����h�c
        ,cn_program_application_id                        -- �v���O�����A�v���P�[�V�����h�c
        ,cd_program_update_date                           -- �v���O�����X�V��
        ,cn_last_updated_by                               -- �ŏI�X�V��
        ,cd_last_update_date                              -- �ŏI�X�V��
        ,cn_last_update_login                             -- �ŏI�X�V���O�C��
        ,cd_creation_date                                 -- �쐬��
        ,cn_created_by                                    -- �쐬��
        ,TO_CHAR(lt_transaction_id)                       -- �C���^�[�t�F�[�X�\�[�X�h�c
        ,cv_source_type_code                              -- �\�[�X�^�C�v�R�[�h
        ,cv_destination_type_code                         -- ������^�C�v
        ,it_mst_regist_info_rec.item_description          -- �i�ړE�v
        ,it_mst_regist_info_rec.quantity                  -- ����
        ,it_mst_regist_info_rec.unit_price                -- ���i
        ,cv_authorization_status                          -- �X�e�[�^�X
        /* 2009.08.21 K.Satomura 0001138�Ή� START */
        ,lt_transaction_id                                -- �o�b�`�h�c
        /* 2009.08.21 K.Satomura 0001138�Ή� END */
        ,it_mst_regist_info_rec.person_id                 -- �쐬�҂h�c
        ,cv_flag_no                                       -- �I�[�g�\�[�X�t���O
        ,it_mst_regist_info_rec.item_description          -- �w�b�_�[�E�v
        ,cv_flag_no                                       -- �ً}�t���O
        ,it_mst_regist_info_rec.code_combination_id       -- ��p����Ȗ�
        ,it_mst_regist_info_rec.category_id               -- �J�e�S���h�c
        ,it_mst_regist_info_rec.unit_meas_lookup_code     -- �P��
        ,it_mst_regist_info_rec.un_number                 -- ���A�ԍ�
        ,lt_hazard_class_id                               -- �댯����
        ,it_mst_regist_info_rec.inventory_organization_id -- ������g�D�h�c
        ,it_mst_regist_info_rec.ship_to_location_id       -- �����掖�Ə��h�c
        ,it_mst_regist_info_rec.ship_to_location_code     -- �����掖�Ə��R�[�h
        ,it_mst_regist_info_rec.ship_to_person_id         -- ������v���҂h�c
        ,it_mst_regist_info_rec.agent_id                  -- SUGGESTED_BUYER_ID
        ,it_mst_regist_info_rec.vendor_id                 -- SUGGESTED_VENDOR_ID
        ,cd_sysdate                                       -- ��]�����
        ,it_mst_regist_info_rec.user_name                 -- �쐬�Җ�
        ,it_mst_regist_info_rec.code_combination_id       -- �������z����h�c
        ,it_mst_regist_info_rec.unit_price                -- �ʉݒP��
        ,it_mst_regist_info_rec.po_header_id              -- �����\�[�X�����w�b�_
        ,it_mst_regist_info_rec.line_num                  -- �����\�[�X�������הԍ�
        ,cv_price_type                                    -- DOCUMENT_TYPE_CODE
        ,cn_org_id                                        -- ORG_ID
        ,cv_flag_no                                       -- �ŋ��㏑���t���O
      );
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_table       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- ����h�c�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg36 || CHR(10) ||
                 cv_debug_msg37 || lt_transaction_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
    ot_interface_source_code := TO_CHAR(lt_transaction_id);
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END reg_po_req_interface;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_vendor
   * Description      : �����˗��w�b�_�E���דo�^����(A-9)
   ***********************************************************************************/
  PROCEDURE reg_vendor(
     it_interface_source_code IN         po_requisitions_interface_all.interface_source_code%TYPE -- �C���^�[�t�F�[�X�\�[�X�h�c
    ,on_request_id            OUT NOCOPY NUMBER                                                   -- �v���h�c
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                                 -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                                 -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_vendor';  -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    cv_application CONSTANT VARCHAR2(2)  := 'PO';
    cv_program     CONSTANT VARCHAR2(20) := 'REQIMPORT';
    cv_argument6   CONSTANT VARCHAR2(2)  := 'N';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_proc_name CONSTANT VARCHAR2(100) := '�w���˗��C���|�[�g����';
    --
    -- *** ���[�J���ϐ� ***
    ln_request_id NUMBER;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ============================
    -- �����˗��w�b�_�E���דo�^����
    -- ============================
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_program
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       /* 2009.08.21 K.Satomura 0001138�Ή� START */
                       --,argument1   => NULL
                       ,argument1   => it_interface_source_code
                       /* 2009.08.21 K.Satomura 0001138�Ή� END */
                       ,argument2   => it_interface_source_code
                       ,argument3   => NULL
                       ,argument4   => NULL
                       ,argument5   => NULL
                       ,argument6   => cv_argument6
                     );
    --
    IF (ln_request_id = 0) THEN
      -- �v���h�c��0�̏ꍇ�G���[���b�Z�[�W���擾���܂��B
      fnd_message.retrieve(msgout => lv_errbuf);
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_06         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_proc_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h1
                     ,iv_token_value2 => lv_errbuf                -- �g�[�N���l1
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG START ***
    -- �v���h�c�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg38 || CHR(10) ||
                 cv_debug_msg39 || ln_request_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
    COMMIT;
    on_request_id := ln_request_id;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : confirm_reg_vendor
   * Description      : �����˗��w�b�_�E���דo�^�����m�F����(A-10)
   ***********************************************************************************/
  PROCEDURE confirm_reg_vendor(
     in_request_id IN         NUMBER   -- �v���h�c
    ,ov_errbuf     OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode    OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg     OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'confirm_reg_vendor';  -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_profile_option_name1 CONSTANT VARCHAR2(30) := 'XXCSO1_VENDOR_WAIT_TIME';
    cv_profile_option_name2 CONSTANT VARCHAR2(30) := 'XXCSO1_CONC_MAX_WAIT_TIME';
    /* 2009.04.03 K.Satomura T1_0109�Ή� START */
    cv_purchase_request     CONSTANT VARCHAR2(30) := 'POR';
    /* 2009.04.03 K.Satomura T1_0109�Ή� END */
    --
    -- ���s�t�F�[�Y
    cv_phase_complete CONSTANT VARCHAR2(20) := 'COMPLETE'; -- ����
    --
    -- �X�e�[�^�X
    cv_ret_status_normal CONSTANT VARCHAR2(20) := 'NORMAL'; -- ����I��
    --
    -- �g�[�N���p�萔
    cv_tkn_value_proc_name  CONSTANT VARCHAR2(50) := '�w���˗��C���|�[�g����';
    /* 2009.04.03 K.Satomura T1_0109�Ή� START */
    cv_tkn_value_req_header CONSTANT VARCHAR2(50) := '�w���˗��w�b�_';
    /* 2009.04.03 K.Satomura T1_0109�Ή� END */
    --
    -- *** ���[�J���ϐ� ***
    lb_return     BOOLEAN;
    lv_phase      VARCHAR2(5000);
    lv_status     VARCHAR2(5000);
    lv_dev_phase  VARCHAR2(5000);
    lv_dev_status VARCHAR2(5000);
    lv_message    VARCHAR2(5000);
    ln_work_count NUMBER;
    /* 2009.04.03 K.Satomura T1_0109�Ή� START */
    lt_requisition_header_id po_requisition_headers.requisition_header_id%TYPE;
    /* 2009.04.03 K.Satomura T1_0109�Ή� END */
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ================================
    -- �����˗��w�b�_�E���דo�^�����m�F
    -- ================================
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => in_request_id
                   ,interval   => fnd_profile.value(cv_profile_option_name1)
                   ,max_wait   => fnd_profile.value(cv_profile_option_name2)
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF NOT (lb_return) THEN
      -- �߂�l��FALSE�̏ꍇ
      fnd_message.retrieve(msgout => lv_errbuf);
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_07         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_proc_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h1
                     ,iv_token_value2 => lv_errbuf                -- �g�[�N���l1
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    IF (lv_dev_phase <> cv_phase_complete) THEN
      -- ���s�t�F�[�Y������ȊO�̏ꍇ
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_08         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_proc_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_proc_name         -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_dev_phase             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_proc_name         -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_dev_status            -- �g�[�N���l3
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    IF ((lv_dev_phase = cv_phase_complete)
      AND (lv_dev_status <> cv_ret_status_normal))
    THEN
      -- ���s�t�F�[�Y�����킩�A�X�e�[�^�X������ȊO�̏ꍇ
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_09         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_proc_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_request_id        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => in_request_id            -- �g�[�N���l2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ============================
    -- �����˗��w�b�_�E���דo�^�m�F
    -- ============================
    SELECT COUNT(1) count
    INTO   ln_work_count
    FROM   po_requisition_headers prh -- �����w�b�_�[�e�[�u��
    WHERE  prh.request_id = in_request_id
    ;
    --
    IF (ln_work_count <= 0) THEN
      -- �����˗��w�b�_���o�^����Ă��Ȃ��ꍇ
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10         -- ���b�Z�[�W�R�[�h
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    /* 2009.04.03 K.Satomura T1_0109�Ή� START */
    -- ======================
    -- �w���˗��w�b�_�X�V����
    -- ======================
    BEGIN
      SELECT requisition_header_id requisition_header_id -- �w���˗��w�b�_�h�c
      INTO   lt_requisition_header_id
      FROM   po_requisition_headers prh -- �w���˗��w�b�_�[�r���[
      WHERE  prh.request_id = in_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10         -- ���b�Z�[�W�R�[�h
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    BEGIN
      UPDATE po_requisition_headers_all prh -- �w���˗��w�b�_�[�e�[�u��
      SET    prh.apps_source_code = cv_purchase_request
      WHERE  prh.requisition_header_id = lt_requisition_header_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_13         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_req_header  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    /* 2009.04.03 K.Satomura T1_0109�Ή� END */
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END confirm_reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_customer_info
   * Description      : �ڋq���擾����(A-11)
   ***********************************************************************************/
  PROCEDURE get_customer_info(
     it_sp_decision_header_id IN            xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,iot_mst_regist_info_rec  IN OUT NOCOPY g_mst_regist_info_rtype                              -- �}�X�^�o�^���
    ,ov_errbuf                OUT    NOCOPY VARCHAR2                                             -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT    NOCOPY VARCHAR2                                             -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT    NOCOPY VARCHAR2                                             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_customer_info'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sp_dec_cust_class_install CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '1';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_customer_info  CONSTANT VARCHAR2(50) := '�ڋq���';
    cv_tkn_value_sp_dec_head_id CONSTANT VARCHAR2(50) := '�r�o�ꌈ�w�b�_�h�c';
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
    -- ================================
    -- �ڋq���擾
    -- ================================
    BEGIN
      SELECT hca.account_number             account_number             -- �ڋq�R�[�h
            ,hpa.party_name                 party_name                 -- �ڋq��
            ,hpa.organization_name_phonetic organization_name_phonetic -- �ڋq���J�i
            ,hlo.postal_code                postal_code                -- �X�֔ԍ�
            ,hlo.state                      state                      -- �s���{��
            ,hlo.city                       city                       -- �s�E��
            ,hlo.address1                   address1                   -- �Z���P
            ,hlo.address2                   address2                   -- �Z���Q
            ,hlo.address3                   address3                   -- �Z���R
            ,hlo.address_lines_phonetic     address_lines_phonetic     -- �d�b�ԍ�
            ,xca.sale_base_code             sale_base_code             -- ���㋒�_�R�[�h
      INTO   iot_mst_regist_info_rec.account_number             -- �ڋq�R�[�h
            ,iot_mst_regist_info_rec.party_name                 -- �ڋq��
            ,iot_mst_regist_info_rec.organization_name_phonetic -- �ڋq���J�i
            ,iot_mst_regist_info_rec.postal_code                -- �X�֔ԍ�
            ,iot_mst_regist_info_rec.state                      -- �s���{��
            ,iot_mst_regist_info_rec.city                       -- �s�E��
            ,iot_mst_regist_info_rec.address1                   -- �Z���P
            ,iot_mst_regist_info_rec.address2                   -- �Z���Q
            ,iot_mst_regist_info_rec.address3                   -- �Z���R
            ,iot_mst_regist_info_rec.address_lines_phonetic     -- �d�b�ԍ�
            ,iot_mst_regist_info_rec.sale_base_code             -- ���㋒�_�R�[�h
      FROM   xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
            ,hz_cust_accounts        hca -- �ڋq�}�X�^
            /* 2010.01.08 K.Hosoi E_�{�ғ�_01017�Ή� START */
            ,hz_cust_acct_sites      hcas -- �ڋq�T�C�g�}�X�^
            /* 2010.01.08 K.Hosoi E_�{�ғ�_01017�Ή� END */
            ,hz_parties              hpa -- �p�[�e�B�}�X�^
            ,hz_party_sites          hps -- �p�[�e�B�T�C�g�}�X�^
            ,hz_locations            hlo -- �ڋq���Ə��}�X�^
            ,xxcmm_cust_accounts     xca -- �ڋq�A�h�I���}�X�^
      WHERE xsd.sp_decision_header_id      = it_sp_decision_header_id
      AND   xsd.sp_decision_customer_class = cv_sp_dec_cust_class_install
      AND   xsd.customer_id                = hca.cust_account_id
      AND   hca.party_id                   = hpa.party_id
      AND   hpa.party_id                   = hps.party_id
      /* 2010.01.08 K.Hosoi E_�{�ғ�_01017�Ή� START */
      AND   hca.cust_account_id            = hcas.cust_account_id
      AND   hcas.party_site_id             = hps.party_site_id
      /* 2010.01.08 K.Hosoi E_�{�ғ�_01017�Ή� END */
      AND   hps.location_id                = hlo.location_id
      AND   xca.customer_id                = hca.cust_account_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_customer_info  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_head_id -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => it_sp_decision_header_id    -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- �ڋq�������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg40 || CHR(10) ||
                 cv_debug_msg41 || iot_mst_regist_info_rec.account_number             || CHR(10) ||
                 cv_debug_msg42 || iot_mst_regist_info_rec.party_name                 || CHR(10) ||
                 cv_debug_msg43 || iot_mst_regist_info_rec.organization_name_phonetic || CHR(10) ||
                 cv_debug_msg44 || iot_mst_regist_info_rec.postal_code                || CHR(10) ||
                 cv_debug_msg45 || iot_mst_regist_info_rec.state                      || CHR(10) ||
                 cv_debug_msg46 || iot_mst_regist_info_rec.city                       || CHR(10) ||
                 cv_debug_msg47 || iot_mst_regist_info_rec.address1                   || CHR(10) ||
                 cv_debug_msg48 || iot_mst_regist_info_rec.address2                   || CHR(10) ||
                 cv_debug_msg49 || iot_mst_regist_info_rec.address3                   || CHR(10) ||
                 cv_debug_msg50 || iot_mst_regist_info_rec.address_lines_phonetic     || CHR(10) ||
                 cv_debug_msg51 || iot_mst_regist_info_rec.sale_base_code             || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_customer_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_po_req_line_id
   * Description      : �w���˗����ׂh�c�擾����(A-12)
   ***********************************************************************************/
  PROCEDURE get_po_req_line_id(
     in_request_id           IN     NUMBER                         -- �v���h�c
    ,iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype -- �}�X�^�o�^���
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_po_req_line_id'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_value_po_req_line  CONSTANT VARCHAR2(50) := '�w���˗����׃e�[�u��';
    cv_tkn_value_request_id   CONSTANT VARCHAR2(50) := '�v���h�c';
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
    -- ================================
    -- �w���˗����ׂh�c�擾
    -- ================================
    BEGIN
      SELECT prl.requisition_line_id -- �w���˗����ׂh�c
      INTO   iot_mst_regist_info_rec.requisition_line_id -- �w���˗����ׂh�c
      FROM   po_requisition_lines prl
      WHERE  prl.request_id = in_request_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_po_req_line -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_request_id  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => in_request_id            -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- �w���˗����ׂh�c�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg52 || CHR(10) ||
                 cv_debug_msg53 || iot_mst_regist_info_rec.requisition_line_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_po_req_line_id;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_temp_info
   * Description      : ���e���v���[�g�o�^����(A-14)
   ***********************************************************************************/
  PROCEDURE reg_temp_info(
     it_attribute_code       IN            por_template_attributes_v.attribute_code%TYPE -- �A�g���r���[�g�R�[�h
    ,it_attribute_name       IN            por_template_attributes_v.attribute_name%TYPE -- �A�g���r���[�g��
    ,iot_mst_regist_info_rec IN OUT NOCOPY g_mst_regist_info_rtype                       -- �}�X�^�o�^���
    ,ov_errbuf               OUT    NOCOPY VARCHAR2                                      -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2                                      -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2                                      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_temp_info'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_attribute_name01 CONSTANT VARCHAR2(50) := 'SP_DECISION_NUMBER';        -- �r�o�ꌈ���ԍ�
    cv_attribute_name02 CONSTANT VARCHAR2(50) := 'SP_DECISION_APPROVAL_DATE'; -- �r�o�挈���F��
    cv_attribute_name03 CONSTANT VARCHAR2(50) := 'APPROVAL_BASE';             -- �\�����_
    cv_attribute_name04 CONSTANT VARCHAR2(50) := 'APPLICANT';                 -- �\����
    cv_attribute_name05 CONSTANT VARCHAR2(50) := 'INSTALL_AT_CUSTOMER_CODE';  -- �ݒu��ڋq�R�[�h
    cv_attribute_name06 CONSTANT VARCHAR2(50) := 'INSTALL_AT_CUSTOMER_NAME';  -- �ݒu��ڋq��
    cv_attribute_name07 CONSTANT VARCHAR2(50) := 'INSTALL_AT_CUSTOMER_KANA';  -- �ݒu��ڋq���J�i
    cv_attribute_name08 CONSTANT VARCHAR2(50) := 'INSTALL_AT_ZIP';            -- �ݒu��X�֔ԍ�
    cv_attribute_name09 CONSTANT VARCHAR2(50) := 'INSTALL_AT_PREFECTURES';    -- �ݒu��s���{��
    cv_attribute_name10 CONSTANT VARCHAR2(50) := 'INSTALL_AT_CITY';           -- �ݒu��s�撬��
    cv_attribute_name11 CONSTANT VARCHAR2(50) := 'INSTALL_AT_ADDR1';          -- �ݒu��Z���P
    cv_attribute_name12 CONSTANT VARCHAR2(50) := 'INSTALL_AT_ADDR2';          -- �ݒu��Z���Q
    cv_attribute_name13 CONSTANT VARCHAR2(50) := 'INSTALL_AT_AREA_CODE';      -- �ݒu��Z���R
    cv_attribute_name14 CONSTANT VARCHAR2(50) := 'INSTALL_AT_PHONE';          -- �d�b�ԍ�
    cv_attribute_name15 CONSTANT VARCHAR2(50) := 'WORK_HOPE_YEAR';            -- ��Ɗ�]�N
    cv_attribute_name16 CONSTANT VARCHAR2(50) := 'SOLD_CHARGE_BASE';          -- ����S�����_
    cv_attribute_name17 CONSTANT VARCHAR2(50) := 'WORK_HOPE_MONTH';           -- ��Ɗ�]��
    cv_attribute_name18 CONSTANT VARCHAR2(50) := 'WORK_HOPE_DAY';             -- ��Ɗ�]��
    --
    -- �g�[�N���p�萔
    cv_tkn_value_table   CONSTANT VARCHAR2(100) := '���e���v���[�g(�A�g���r���[�g�� = )' || it_attribute_name || ')';
    cv_tkn_value_item_id CONSTANT VARCHAR2(50)  := '�i�ځi�J�e�S���j�h�c';
    --
    -- *** ���[�J���ϐ� ***
    lt_attribute_value por_template_info.attribute_value%TYPE;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    lt_attribute_value := NULL;
    --
    -- ================================
    -- ���e���v���[�g�o�^
    -- ================================
    CASE it_attribute_name
      WHEN cv_attribute_name01 THEN
        -- �r�o�ꌈ���ԍ�
        lt_attribute_value := iot_mst_regist_info_rec.sp_decision_number;
        --
      WHEN cv_attribute_name02 THEN
        -- �r�o�挈���F��
        lt_attribute_value := TO_CHAR(iot_mst_regist_info_rec.approval_complete_date, cv_date_format2);
        --
      WHEN cv_attribute_name03 THEN
        -- �\�����_
        lt_attribute_value := iot_mst_regist_info_rec.app_base_code;
        --
      WHEN cv_attribute_name04 THEN
        -- �\����
        lt_attribute_value := iot_mst_regist_info_rec.application_code;
        --
      WHEN cv_attribute_name05 THEN
        -- �ݒu��ڋq�R�[�h
        lt_attribute_value := iot_mst_regist_info_rec.account_number;
        --
      WHEN cv_attribute_name06 THEN
        -- �ݒu��ڋq��
        lt_attribute_value := iot_mst_regist_info_rec.party_name;
        --
      WHEN cv_attribute_name07 THEN
        -- �ݒu��ڋq���J�i
        lt_attribute_value := iot_mst_regist_info_rec.organization_name_phonetic;
        --
      WHEN cv_attribute_name08 THEN
        -- �ݒu��X�֔ԍ�
        lt_attribute_value := iot_mst_regist_info_rec.postal_code;
        --
      WHEN cv_attribute_name09 THEN
        -- �ݒu��s���{��
        lt_attribute_value := iot_mst_regist_info_rec.state;
        --
      WHEN cv_attribute_name10 THEN
        -- �ݒu��s�撬��
        lt_attribute_value := iot_mst_regist_info_rec.city;
        --
      WHEN cv_attribute_name11 THEN
        -- �ݒu��Z���P
        lt_attribute_value := iot_mst_regist_info_rec.address1;
        --
      WHEN cv_attribute_name12 THEN
        -- �ݒu��Z���Q
        lt_attribute_value := iot_mst_regist_info_rec.address2;
        --
      WHEN cv_attribute_name13 THEN
        -- �ݒu��Z���R
        lt_attribute_value := iot_mst_regist_info_rec.address3;
        --
      WHEN cv_attribute_name14 THEN
        -- �d�b�ԍ�
        lt_attribute_value := iot_mst_regist_info_rec.address_lines_phonetic;
        --
      WHEN cv_attribute_name15 THEN
        -- ��Ɗ�]�N
        lt_attribute_value := TO_CHAR(iot_mst_regist_info_rec.install_date, cv_year_format);
        --
      WHEN cv_attribute_name16 THEN
        -- ����S�����_
        lt_attribute_value := iot_mst_regist_info_rec.sale_base_code;
        --
      WHEN cv_attribute_name17 THEN
        -- ��Ɗ�]��
        lt_attribute_value := TO_CHAR(iot_mst_regist_info_rec.install_date, cv_month_format);
        --
      WHEN cv_attribute_name18 THEN
        -- ��Ɗ�]��
        lt_attribute_value := TO_CHAR(iot_mst_regist_info_rec.install_date, cv_day_format);
        --
      ELSE
        -- ��L�ȊO�̏ꍇ
        lt_attribute_value := NULL;
        --
    END CASE;
    --
    BEGIN
      INSERT INTO por_template_info(
         requisition_line_id  -- �����˗����ׂh�c
        ,attribute_code       -- �A�g���r���[�g�R�[�h
        ,attribute_value      -- �A�g���r���[�g�l
        ,created_by           -- �쐬��
        ,creation_date        -- �쐬��
        ,last_updated_by      -- �ŏI�X�V��
        ,last_update_date     -- �ŏI�X�V��
        ,last_update_login)   -- �ŏI�X�V���O�C��
      VALUES(
         iot_mst_regist_info_rec.requisition_line_id -- �����˗����ׂh�c
        ,it_attribute_code                           -- �A�g���r���[�g�R�[�h
        ,lt_attribute_value                          -- �A�g���r���[�g�l
        ,cn_created_by                               -- �쐬��
        ,cd_creation_date                            -- �쐬��
        ,cn_last_updated_by                          -- �ŏI�X�V��
        ,cd_last_update_date                         -- �ŏI�X�V��
        ,cn_last_update_login                        -- �ŏI�X�V���O�C��
      );
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_table       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- ���e���v���[�g�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg54 || CHR(10) ||
                 cv_debug_msg55 || iot_mst_regist_info_rec.requisition_line_id || CHR(10) ||
                 cv_debug_msg56 || it_attribute_name || CHR(10) ||
                 cv_debug_msg57 || lt_attribute_value || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END reg_temp_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_temp_info_terget
   * Description      : ���e���v���[�g�o�^�Ώۍ��ڏ��擾����(A-13)
   ***********************************************************************************/
  PROCEDURE get_temp_info_terget(
     in_request_id            IN     NUMBER                         -- �v���h�c
    ,iot_mst_regist_info_rec  IN OUT NOCOPY g_mst_regist_info_rtype -- �}�X�^�o�^���
    ,ov_errbuf                OUT    NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode               OUT    NOCOPY VARCHAR2                -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                OUT    NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_temp_info_terget'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_value_temp_info CONSTANT VARCHAR2(50) := '���e���v���[�g';
    cv_tkn_value_item_id   CONSTANT VARCHAR2(50) := '�i�ځi�J�e�S���j�h�c';
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR temp_info_cur
    IS
      SELECT ptv.attribute_code attribute_code -- �A�g���r���[�g�R�[�h
            ,ptv.attribute_name attribute_name -- �A�g���r���[�g��
      FROM   por_template_assoc_v      pta -- �e���v���[�g�֘A�r���[
            ,por_template_attributes_v ptv -- �e���v���[�g�A�g���r���[�g�r���[
            ,por_templates_all_b       ptb -- �e���v���[�g�\�a
            ,por_templates_all_tl      ptt -- �e���v���[�g�\�s�k
      WHERE  pta.item_or_category_id = iot_mst_regist_info_rec.category_id
      AND    pta.region_code         = ptv.template_code
      AND    ptv.template_code       = ptb.template_code
      AND    ptb.template_code       = ptt.template_code
      AND    ptb.org_id              = cn_org_id
      AND    ptt.language            = cv_lang
      ;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ====================================
    -- ���e���v���[�g�o�^�Ώۍ��ڏ��擾
    -- ====================================
    BEGIN
      --
      <<temp_info_loop>>
      FOR lt_temp_info_rec IN temp_info_cur LOOP
        -- ============================================
        -- A-14.���e���v���[�g�o�^����
        -- ============================================
        reg_temp_info(
           it_attribute_code       => lt_temp_info_rec.attribute_code
          ,it_attribute_name       => lt_temp_info_rec.attribute_name
          ,iot_mst_regist_info_rec => iot_mst_regist_info_rec
          ,ov_errbuf               => lv_errbuf
          ,ov_retcode              => lv_retcode
          ,ov_errmsg               => lv_errmsg
        );
        --
      END LOOP temp_info_loop;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03                    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_temp_info              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_item_id                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iot_mst_regist_info_rec.category_id -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_temp_info_terget;
  --
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
    ,ov_errbuf                OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode               OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
    lt_mst_regist_info_rec   g_mst_regist_info_rtype;                                  -- �}�X�^�o�^���
    lt_interface_source_code po_requisitions_interface_all.interface_source_code%TYPE; -- �C���^�[�t�F�[�X�\�[�X�h�c
    ln_request_id            NUMBER;                                                   -- �w���˗��v���h�c
    --
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- *** ���[�J���E���R�[�h ***
    --
    -- *** ���[�J����O ***
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
    gn_target_cnt := 1;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    --
    -- ============
    -- A-1.��������
    -- ============
    start_proc(
       it_sp_decision_header_id => it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===================================
    -- A-2. �r�o�ꌈ�w�b�_�e�[�u���擾����
    -- ===================================
    get_sp_dec_head_info(
       it_sp_decision_header_id => it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      ,iot_mst_regist_info_rec  => lt_mst_regist_info_rec   -- �}�X�^�o�^���
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ==========================
    -- A-3.�]�ƈ����擾����
    -- ==========================
    get_employee_info(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
      ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ============================================
    -- A-4.�i�ڏ��擾����
    -- ============================================
    get_item_info(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
      ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ======================
    -- A-5.���Ϗ��擾����
    -- ======================
    get_vendor_info(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
      ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ==========================
    -- A-6.������g�D�h�c�擾����
    -- ==========================
    get_inv_org_id(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
      ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ============================
    -- A-7.��p����Ȗڂh�c�擾����
    -- ============================
    get_code_comb_id(
       iot_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
      ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===============================
    -- A-8.�w���˗�I/F�e�[�u���o�^����
    -- ===============================
    reg_po_req_interface(
       it_mst_regist_info_rec   => lt_mst_regist_info_rec   -- �}�X�^�o�^���
      ,ot_interface_source_code => lt_interface_source_code -- �C���^�[�t�F�[�X�\�[�X�h�c
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ================================
    -- A-9.�����˗��w�b�_�E���דo�^����
    -- ================================
    reg_vendor(
       it_interface_source_code => lt_interface_source_code -- �C���^�[�t�F�[�X�\�[�X�h�c
      ,on_request_id            => ln_request_id            -- �v���h�c
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- =========================================
    -- A-10.�����˗��w�b�_�E���דo�^�����m�F����
    -- =========================================
    confirm_reg_vendor(
       in_request_id => ln_request_id -- �v���h�c
      ,ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- =========================================
    -- A-11.�ڋq���擾����
    -- =========================================
    get_customer_info(
       it_sp_decision_header_id => it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      ,iot_mst_regist_info_rec  => lt_mst_regist_info_rec   -- �}�X�^�o�^���
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- =========================================
    -- A-12.�w���˗����ׂh�c�擾����
    -- =========================================
    get_po_req_line_id(
       in_request_id           => ln_request_id          -- �v���h�c
      ,iot_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
      ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- =============================================
    -- A-13.���e���v���[�g�o�^�Ώۍ��ڏ��擾����
    -- =============================================
    get_temp_info_terget(
       in_request_id           => ln_request_id          -- �v���h�c
      ,iot_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
      ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W --# �Œ� #
      ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h   --# �Œ� #
      ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    gn_normal_cnt := gn_normal_cnt + 1;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** ���������ʗ�O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf                   OUT NOCOPY VARCHAR2                                             -- �G���[���b�Z�[�W #�Œ�#
    ,retcode                  OUT NOCOPY VARCHAR2                                             -- �G���[�R�[�h     #�Œ�#
    ,it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
  )
  --
  --###########################  �Œ蕔 START   ###########################
  --
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
    --
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
      --
    END IF;
    --
    --###########################  �Œ蕔 END   #############################
    --
    gn_target_cnt := gn_target_cnt + 1;
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       it_sp_decision_header_id => it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      ,ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
       -- �G���[�o��
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
       );
       --
       fnd_file.put_line(
          which  => fnd_file.log
         ,buff   => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf --�G���[���b�Z�[�W
       );
       --
    END IF;
    --
    -- =======================
    -- A-x.�I������
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
      --
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
      --
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- �X�e�[�^�X�Z�b�g
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    --
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      --
    END IF;
    --
  EXCEPTION
    --
    --###########################  �Œ蕔 START   #####################################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
  END main;
  --
  --###########################  �Œ蕔 END   #######################################################
  --
END XXCSO020A04C;
/
