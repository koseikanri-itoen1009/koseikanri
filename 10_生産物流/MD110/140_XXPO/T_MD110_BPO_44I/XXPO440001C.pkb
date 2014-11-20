CREATE OR REPLACE PACKAGE BODY xxpo440001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440001c(spec)
 * Description      : �L���o�Ɏw����
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_444)
 *                    �L���x�����[Issue1.0(T_MD070_BPO_44I)
 * Version          : 1.7
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 *  prc_create_out_data         PROCEDURE : �w�l�k�f�[�^�o�͏���
 *  prc_create_sql              PROCEDURE : �f�[�^���o����
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[���
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/19    1.0   Oracle���V����   �V�K�쐬
 *  2008/05/16    1.1   Oracle����Ǖ�   �����e�X�g�s��i�@�\ID�F440�A�s�ID�F5�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F6�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F7�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F8�j
 *  2008/05/19    1.2   Oracle����Ǖ�   �����e�X�g�s��i�@�\ID�F440�A�s�ID�F9�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F10�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F11�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F12�j
 *                                       �����e�X�g�s��i�@�\ID�F440�A�s�ID�F13�j
 *  2008/05/21    1.3   Oracle�c���S��   �����e�X�g�s��i�@�\ID�F440�A�s�ID�F19�j
 *  2008/06/19    1.4   Oracle�F�{�a�Y   �����e�X�g�s�
 *                                         1.���r���[�w�E����No.11�F�K�p���Ǘ����s���B
 *                                         2.���r���[�w�E����No.13�F����於�A�z���於��
 *                                           �܂�Ԃ����R���J�����g���ōs���B
 *  2008/06/23    1.5   Oracle�R�{���v   �ύX�v���Ή�No.42�A91
 *                                       �����ύX�v���Ή�No.160
 *  2008/09/19    1.6   Oracle�R����_   T_S_439�Ή�
 *  2008/10/22    1.7   Oracle�勴�F�Y   �w�E361�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  check_create_xml_expt        EXCEPTION;     -- �w�l�k�f�[�^�ҏW�ł̗�O
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================================================================================
  -- ���[�U�[�錾��
  -- ===============================================================================================
  -- ==================================================
  -- �O���[�o���萔
  -- ==================================================
  gc_pkg_name               CONSTANT VARCHAR2(20) := 'xxpo440001c' ;     -- �p�b�P�[�W��
  gc_report_id              CONSTANT VARCHAR2(20) := 'XXPO440001T' ;     -- ���[ID
  gc_application            CONSTANT VARCHAR2(5)  := 'XXCMN' ;           -- �A�v���P�[�V����
  gc_po_application         CONSTANT VARCHAR2(4)  := 'XXPO'  ;           -- XXPO�A�v���P�[�V����
  gc_err_code_no_data       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122';  -- �f�[�^�O�����b�Z�[�W
  gc_err_code_no_prof       CONSTANT VARCHAR2(15) := 'APP-XXPO-10005' ;  -- �v���t�@�C���擾�G���[
  gc_err_code_sikyuno_data  CONSTANT VARCHAR2(15) := 'APP-XXPO-10026';   -- APP-XXPO-10026
--
--
  ------------------------------
  -- �v���t�@�C����
  ------------------------------
  gc_prof_org_id          CONSTANT VARCHAR2(20) := 'ORG_ID' ;   -- �c�ƒP��
  gn_prof_org_id          oe_transaction_types_all.org_id%TYPE ;
--
  ------------------------------
  -- �Q�ƃ^�C�v
  ------------------------------
  -- �z���敪
  gc_lookup_ship_method_code  CONSTANT VARCHAR2(40) := 'XXCMN_SHIP_METHOD' ;
  -- ����敪
  gc_lookup_takeback_class    CONSTANT VARCHAR2(40) := 'XXWSH_TAKEBACK_CLASS' ;
  -- �^���敪
-- Ver1.1 Changed 2008/05/16
--  gc_xxwsh_freight_class      CONSTANT VARCHAR2(40) := 'XXWSH_FREIGHT_CLASS';
  gc_xxwsh_freight_class      CONSTANT VARCHAR2(40) := 'XXCMN_INCLUDE_EXCLUDE';
-- Ver1.1 Changed 2008/05/16
  -- ���׎���
  gc_xxwsh_arrival_time       CONSTANT VARCHAR2(40) := 'XXWSH_ARRIVAL_TIME';
  ------------------------------
  -- �Q�ƃR�[�h
  ------------------------------
  -- �p�����[�^�F�g�p�ړI
  gc_use_purpose_irai     CONSTANT VARCHAR2(1) := '1' ;    -- �˗�
  gc_use_purpose_shij     CONSTANT VARCHAR2(1) := '2' ;    -- �w��
  gc_use_purpose_henpin   CONSTANT VARCHAR2(1) := '3' ;    -- �ԕi
  -- �p�����[�^�F�L���Z�L�����e�B�敪
  gc_security_div_i       CONSTANT VARCHAR2(1) := '1' ;    -- �ɓ���
  gc_security_div_d       CONSTANT VARCHAR2(1) := '2' ;    -- �����
  gc_security_div_l       CONSTANT VARCHAR2(1) := '3' ;    -- �o�ɑq��(���m�u��)
  gc_security_div_lt      CONSTANT VARCHAR2(1) := '4' ;    -- �o�ɑq��(���m�u���ȊO)
  -- �󒍃J�e�S���F�o�׎x���敪
  gc_sp_class_ship        CONSTANT VARCHAR2(1) := '1' ;    -- �o�׈˗�
  gc_sp_class_prov        CONSTANT VARCHAR2(1) := '2' ;    -- �x���˗�
  gc_sp_class_move        CONSTANT VARCHAR2(1) := '3' ;    -- �ړ�
  -- �󒍃w�b�_�A�h�I���F�ŐV�t���O
  gc_yn_div_y             CONSTANT VARCHAR2(1) := 'Y' ;    -- YES
  -- �󒍃w�b�_���ׁF�폜�t���O
  gc_yn_div_n             CONSTANT VARCHAR2(1) := 'N' ;    -- NO
  -- �󒍃w�b�_�A�h�I���F�X�e�[�^�X
  gc_req_status_s_inp     CONSTANT VARCHAR2(2) := '05' ;   -- ���͒�
  gc_req_status_s_cmpa    CONSTANT VARCHAR2(2) := '06' ;   -- ���͊���
  gc_req_status_s_cmpb    CONSTANT VARCHAR2(2) := '07' ;   -- ��̍�
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2) := '08' ;   -- �o�׎��ьv���
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2) := '99' ;   -- ���
  -- �󒍃w�b�_�A�h�I���F�ʒm�X�e�[�^�X
  gc_notif_status_ok      CONSTANT VARCHAR2(2) := '40' ;   -- �m��ʒm��
  -- �󒍃^�C�v�F�o�׎x���敪
  gc_shipping_provide_s   CONSTANT VARCHAR2(2) := '05'  ;   -- �L���o��
  gc_shipping_provide_h   CONSTANT VARCHAR2(2) := '06'  ;   -- �L���ԕi
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;   -- �ړ�
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;   -- �x���w��
  gc_doc_type_prod        CONSTANT VARCHAR2(2) := '40' ;   -- ���Y�w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;   -- �w��
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;   -- �o�Ɏ���
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;   -- ���Ɏ���
  -- �n�o�l�i�ڃ}�X�^�F���b�g�Ǘ��敪
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;    -- ���b�g�Ǘ�����
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;    -- ���b�g�Ǘ��Ȃ�
  -- ���[�^�C�g��
  gc_report_name_irai     CONSTANT VARCHAR2(14) := '�L���o�Ɉ˗���' ;
  gc_report_name_shij     CONSTANT VARCHAR2(14) := '�L���o�Ɏw����' ;
  gc_report_name_henpin   CONSTANT VARCHAR2(14) := '�L���ԕi�w����' ;
--
  ------------------------------
  -- ���̑�
  ------------------------------
  gc_max_date_char        CONSTANT VARCHAR2(10) := '9999/12/31' ;
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
      use_purpose         VARCHAR2(1)    -- 01 : �g�p�ړI
     ,request_no          VARCHAR2(12)   -- 02 : �˗�No
     ,exec_user_dept      VARCHAR2(4)    -- 03 : �S������
     ,update_exec_user    VARCHAR2(15)   -- 04 : �X�V�S��
-- Ver1.2 Changed 2008/05/19
--     ,update_date_from    VARCHAR2(10)   -- 05 : �X�V���tFrom
--     ,update_date_to      VARCHAR2(10)   -- 06 : �X�V���tTo
     ,update_date_from    VARCHAR2(20)   -- 05 : �X�V���tFrom
     ,update_date_to      VARCHAR2(20)   -- 06 : �X�V���tTo
-- Ver1.2 Changed 2008/05/19
     ,vendor              VARCHAR2(4)    -- 07 : �����
     ,deliver_to          VARCHAR2(4)    -- 08 : �z����
     ,shipped_locat_code  VARCHAR2(4)    -- 09 : �o�ɑq��
     ,shipped_date_from   VARCHAR2(10)   -- 10 : �o�ɓ�From
     ,shipped_date_to     VARCHAR2(10)   -- 11 : �o�ɓ�To
     ,prod_class          VARCHAR2(1)    -- 12 : ���i�敪
     ,item_class          VARCHAR2(1)    -- 13 : �i�ڋ敪
     ,security_class      VARCHAR2(1)    -- 14 : �L���Z�L�����e�B�敪
    ) ;
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param                   rec_param_data ;   -- �p�����[�^
  gn_data_cnt                NUMBER DEFAULT 0 ; -- �����f�[�^�J�E���^
--
  gt_xml_data_table          XML_DATA ;         -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                 NUMBER DEFAULT 0 ; -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  gn_user_id                 fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;   -- ���O�C�����[�U�[�h�c
  gv_report_name             VARCHAR2(14)  ;   -- ���[�^�C�g��
--
  gn_created_by              NUMBER ;          -- �쐬��
  gn_last_updated_by         NUMBER ;          -- �ŏI�X�V��
  gn_last_update_login       NUMBER ;          -- �ŏI�X�V���O�C��
  gn_request_id              NUMBER ;          -- �v��ID
  gn_program_application_id  NUMBER ;          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gn_program_id              NUMBER ;          -- �R���J�����g�E�v���O����ID
  gv_sql                     VARCHAR2(32000) ; -- �f�[�^�擾�p�r�p�k
-- add start 1.7
  gn_type_id                 oe_transaction_types_all.transaction_type_id%TYPE; -- ����^�C�vID
-- add end 1.7
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ���[�U�[���^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml_data_user' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_out_data
   * Description      : �w�l�k�f�[�^�o�͏���
   ************************************************************************************************/
  PROCEDURE prc_create_out_data
    (
      ov_errbuf     OUT    VARCHAR2             -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT    VARCHAR2             -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT    VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_out_data' ; -- �v���O������
    cv_order          CONSTANT VARCHAR2(6)   := 'RETURN';               -- �󒍃J�e�S��
--2008/09/19 Add ��
    cn_type_id        CONSTANT NUMBER        := 1029;                   -- �󒍃^�C�vID(����)
--2008/09/19 Add ��
--
    -- ==================================================
    -- �J  �[  �\  ��  ��  ��
    -- ==================================================
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lv_sql                  VARCHAR2(32000) ;
    -- �u���C�N���f�p
    lv_tmp_request_no       VARCHAR2(12) DEFAULT '*' ;
    -- �z���敪�i�[�p
    lv_ship_method_code     VARCHAR2(2)  ;
    lv_ship_method_name     VARCHAR2(14) ;
    -- �^���敪�i�[�p
    lv_freight_charge_code  VARCHAR2(1)  ;
    lv_freight_charge_class VARCHAR2(20) ;
    -- ����敪
    lv_takeback_code        VARCHAR2(1) ;
    lv_takeback_class       VARCHAR2(10) ;
    -- ���׎���
    lv_arrival_time_from    VARCHAR2(5);
    lv_arrival_time_to      VARCHAR2(5);
    -- �����i�[�p
    lv_dept                 VARCHAR2(4) ;
    -- �X�֔ԍ�
    lv_dept_postal_code     VARCHAR2(8) ;
    -- �Z��
    lv_dept_address         VARCHAR2(30);
    -- �d�b�ԍ�
    lv_dept_tel_num         VARCHAR2(15);
    -- FAX�ԍ�
    lv_dept_fax_num         VARCHAR2(15);
     -- ����������
    lv_dept_formal_name     VARCHAR2(30);
    -- �����ҏW�p
    ln_quantity             NUMBER DEFAULT 0;
    -- �e�[�u����
    lv_tablename            VARCHAR2(20);
--
    -- ==================================================
    -- �q�����J�[�\���錾
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;       -- REF_CURSOR�p
    TYPE ret_value  IS RECORD
      (
        request_no                  xxwsh_order_headers_all.request_no%TYPE
       ,vendor_code                 xxcmn_vendors2_v.segment1%TYPE
       ,vendor_name                 xxcmn_vendors2_v.vendor_full_name%TYPE
       ,deliver_to_code             xxcmn_vendor_sites2_v.vendor_site_code%TYPE
       ,deliver_to_name             xxcmn_vendor_sites2_v.vendor_site_name%TYPE
       ,zip                         xxcmn_vendors2_v.zip%TYPE
       ,address1                    xxcmn_vendors2_v.address_line1%TYPE
       ,address2                    xxcmn_vendors2_v.address_line2%TYPE
       ,shipped_locat_code          xxcmn_item_locations2_v.segment1%TYPE
       ,shipped_locat_name          xxcmn_item_locations2_v.description%TYPE
       ,ship_date                   xxwsh_order_headers_all.schedule_ship_date%TYPE
       ,arrival_date                xxwsh_order_headers_all.schedule_arrival_date%TYPE
       ,takeback_class              xxwsh_order_headers_all.takeback_class%TYPE
       ,arrival_time_from           xxwsh_order_headers_all.arrival_time_from%TYPE
       ,arrival_time_to             xxwsh_order_headers_all.arrival_time_to%TYPE
       ,freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE
       ,party_number                xxcmn_parties2_v.party_number%TYPE
       ,party_short_name            xxcmn_parties2_v.party_short_name%TYPE
       ,shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE
       ,delivery_no                 xxwsh_order_headers_all.delivery_no%TYPE
       ,po_no                       xxwsh_order_headers_all.po_no%TYPE
-- 2008/06/23 v1.5 Y.Yamamoto ADD Start
       ,base_request_no             xxwsh_order_headers_all.base_request_no%TYPE
       ,complusion_output_code      xxcmn_carriers2_v.complusion_output_code%TYPE
-- 2008/06/23 v1.5 Y.Yamamoto ADD End
       ,shipping_instructions       xxwsh_order_headers_all.shipping_instructions%TYPE
       ,performance_management_dept xxwsh_order_headers_all.performance_management_dept%TYPE
       ,instruction_dept            xxwsh_order_headers_all.instruction_dept%TYPE
       ,item_no                     xxcmn_item_mst2_v.item_no%TYPE
       ,item_short_name             xxcmn_item_mst2_v.item_short_name%TYPE
       ,futai_code                  xxwsh_order_lines_all.futai_code%TYPE
       ,shipping_provide            oe_transaction_types_all.attribute11%TYPE
       ,lot_ctl                     xxcmn_item_mst2_v.lot_ctl%TYPE
       ,order_category_code         oe_transaction_types_all.order_category_code%TYPE
       ,uom_code                    xxwsh_order_lines_all.uom_code%TYPE
       ,quantity                    xxwsh_order_lines_all.based_request_quantity%TYPE
       ,lot_no                      ic_lots_mst.lot_no%TYPE
       ,product_date                ic_lots_mst.attribute1%TYPE
       ,use_by_date                 ic_lots_mst.attribute3%TYPE
       ,original_char               ic_lots_mst.attribute2%TYPE
--2008/09/19 Add ��
       ,order_type_id               xxwsh_order_headers_all.order_type_id%TYPE
--2008/09/19 Add ��
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
-- ====================================================
    -- �J�[�\���I�[�v��
    -- ====================================================
    OPEN lc_ref FOR gv_sql ;
    -- ====================================================
    -- ���X�g�O���[�v�J�n�^�O�i�˗�No�j
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--
      -- ----------------------------------------------------
      -- ���׃J�[�\���I�[�v��
      -- ----------------------------------------------------
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
      gn_data_cnt := gn_data_cnt + 1 ;
--
      -- ====================================================
      -- �p�����[�^���̎擾�r�p�k
      -- ====================================================
      --���׎���FROM
-- Ver1.1 Add 2008/05/16
      IF lr_ref.arrival_time_from IS NOT NULL THEN
        lv_tablename := '���׎���FROM';
-- Ver1.1 Add 2008/05/16
        SELECT xlv.meaning
        INTO   lv_arrival_time_from           -- ���׎���FROM
        FROM   xxcmn_lookup_values_v   xlv    -- �N�C�b�N�R�[�h���VIEW
        WHERE xlv.lookup_type = gc_xxwsh_arrival_time
        AND   xlv.lookup_code = lr_ref.arrival_time_from
        ;
-- Ver1.1 Add 2008/05/16
      END IF;
-- Ver1.1 Add 2008/05/16
      
      --���׎���To
-- Ver1.1 Add 2008/05/16
      IF lr_ref.arrival_time_to IS NOT NULL THEN
        lv_tablename := '���׎���To';
-- Ver1.1 Add 2008/05/16
        SELECT xlv.meaning
        INTO   lv_arrival_time_to             -- ���׎���FROM
        FROM   xxcmn_lookup_values_v   xlv    -- �N�C�b�N�R�[�h���VIEW
        WHERE xlv.lookup_type = gc_xxwsh_arrival_time
        AND   xlv.lookup_code = lr_ref.arrival_time_to
        ;
-- Ver1.1 Add 2008/05/16
      END IF;
-- Ver1.1 Add 2008/05/16
      
      --�z���敪����
-- Ver1.1 Add 2008/05/16
      IF lr_ref.shipping_method_code IS NOT NULL THEN
        lv_tablename := '�z���敪����';
-- Ver1.1 Add 2008/05/16
        SELECT xlv.lookup_code
              ,xlv.meaning
        INTO   lv_ship_method_code            -- �z���敪
              ,lv_ship_method_name            -- �z���敪����
        FROM   xxcmn_lookup_values_v   xlv    -- �N�C�b�N�R�[�h���VIEW
        WHERE xlv.lookup_type = gc_lookup_ship_method_code
        AND   xlv.lookup_code = lr_ref.shipping_method_code
        ;
-- Ver1.1 Add 2008/05/16
      END IF;
-- Ver1.1 Add 2008/05/16
--
      --����敪����
-- Ver1.1 Add 2008/05/16
      IF lr_ref.takeback_class IS NOT NULL THEN
        lv_tablename := '����敪����';
-- Ver1.1 Add 2008/05/16
        SELECT xlv.lookup_code
              ,xlv.meaning
        INTO   lv_takeback_code               -- ����敪
              ,lv_takeback_class              -- ����敪����
        FROM xxcmn_lookup_values_v   xlv      -- �N�C�b�N�R�[�h���VIEW
        WHERE xlv.lookup_type = gc_lookup_takeback_class
        AND   xlv.lookup_code = lr_ref.takeback_class
        ;
-- Ver1.1 Add 2008/05/16
      END IF;
-- Ver1.1 Add 2008/05/16
--
      --�^���敪
      SELECT xlv.lookup_code
            ,xlv.meaning
      INTO   lv_freight_charge_code         -- �^���敪
            ,lv_freight_charge_class        -- �^���敪����
      FROM xxcmn_lookup_values_v   xlv      -- �N�C�b�N�R�[�h���VIEW
      WHERE xlv.lookup_type = gc_xxwsh_freight_class
      AND   xlv.lookup_code = lr_ref.freight_charge_class
      ;
--
--
      -- �g�p�ړI���Q�F�w��
      IF( gr_param.use_purpose = gc_use_purpose_shij)THEN
        lv_dept := lr_ref.instruction_dept;--�w������
      ELSE
        lv_dept := lr_ref.performance_management_dept;--���ъǗ�����
     END IF;
--
      --�������擾
      xxcmn_common_pkg.get_dept_info(
                     iv_dept_cd          => lv_dept                      -- �����R�[�h
                    ,id_appl_date        => FND_DATE.CANONICAL_TO_DATE(gr_param.shipped_date_from)   -- �o�ɓ�
                    ,ov_postal_code      => lv_dept_postal_code          -- �X�֔ԍ�
                    ,ov_address          => lv_dept_address              -- �Z��
                    ,ov_tel_num          => lv_dept_tel_num              -- �d�b�ԍ�
                    ,ov_fax_num          => lv_dept_fax_num              -- FAX�ԍ�
                    ,ov_dept_formal_name => lv_dept_formal_name          -- ����������
                    ,ov_errbuf           => lv_errbuf                    -- �G���[�E���b�Z�[�W
                    ,ov_retcode          => lv_retcode                   -- ���^�[���E�R�[�h
                    ,ov_errmsg           => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
                    );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt ;
      END IF ;
--
      -- ====================================================
      -- �˗�NO�u���C�N
      -- ====================================================
      IF ( lr_ref.request_no <>lv_tmp_request_no  ) THEN
        -- ----------------------------------------------------
        -- �O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͕\�����Ȃ�
        IF ( lv_tmp_request_no <> '*' ) THEN
          -- ���X�g�O���[�v�I���^�O�i�i�ځj
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���X�g�O���[�v�I���^�O�i�i�ځj
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �O���[�v�I���^�O�i�˗�No�j
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_request' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_request' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- �˗��m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.request_no ;
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;

        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ship' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.vendor_code;
        -- ����於��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.4.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.vendor_name;
        IF (length(substrb(lr_ref.vendor_name,40,2)) = 1) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.vendor_name,1,39) || substrb(lr_ref.vendor_name,40,2);
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.vendor_name,1,40);
        END IF;
--mod end 1.4.2
--add start 1.4.2
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF (length(substrb(lr_ref.vendor_name,40,2)) = 1) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.vendor_name,42,20);
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.vendor_name,41,20);
        END IF;
--add end 1.4.2
        -- �z����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.deliver_to_code;
        -- �z���於��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.4.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.deliver_to_name;
        IF (length(substrb(lr_ref.deliver_to_name,40,2)) = 1) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.deliver_to_name,1,39) || substrb(lr_ref.deliver_to_name,40,2);
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.deliver_to_name,1,40);
        END IF;
--mod end 1.4.2
--add start 1.4.2
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF (length(substrb(lr_ref.deliver_to_name,40,2)) = 1) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.deliver_to_name,42,20);
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := substrb(lr_ref.deliver_to_name,41,20);
        END IF;
--add end 1.4.2
        -- �Z��1
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_address1';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.address1;
        -- �Z��2
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_address2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.address2;
        -- �o�ɑq�ɃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_locat_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.shipped_locat_code;
        -- �o�ɑq�ɖ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_locat_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.shipped_locat_name;
        -- �o�ɓ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(lr_ref.ship_date,'YYYY/MM/DD') ;
        -- ���ɓ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arvl_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(lr_ref.arrival_date,'YYYY/MM/DD') ;
        -- ����敪
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'takeback_class';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_takeback_code;
        -- ����敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'takeback_class_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_takeback_class;
        -- ���׎���From
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_time_from' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_arrival_time_from;
        -- ���׎���To
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_time_to';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_arrival_time_to;
        -- �^���敪
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_charge_class';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_freight_charge_code;
        -- �^���敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_charge_class_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_freight_charge_class;
-- 2008/06/23 v1.5 Y.Yamamoto Update Start
      -- �^���敪�������́A�����o�͋敪���u�Ώہv�̂Ƃ��ɁA�^����Џ����o�͂���B
      IF  (lr_ref.freight_charge_class   = '1')      -- �^���敪���Ώ�
       OR (lr_ref.complusion_output_code = '1') THEN -- �����o�͋敪���Ώ�
        -- �^����ЃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.party_number;
        -- �^����Ж���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.party_short_name;
      END IF;
-- 2008/06/23 v1.5 Y.Yamamoto Update End
        -- �z���敪�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_method_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_code ;
        -- �z���敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_method_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_name ;
        -- �z���m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.delivery_no ;
        -- �����m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.po_no;
-- 2008/06/23 v1.5 Y.Yamamoto ADD Start
        -- ���˗��m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'base_request_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.base_request_no;
-- 2008/06/23 v1.5 Y.Yamamoto ADD End
        -- �E�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_instructions';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.shipping_instructions;
--
        -- �X�֔ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'postcode';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.zip;
        -- ���t���Z��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'address';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_address;
        -- �d�b�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tel_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_tel_num;
        -- FAX�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fax_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_fax_num;
        -- ����������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
-- Ver1.2 Changed 2008/05/19
--        gt_xml_data_table(gl_xml_idx).tag_name  := 'lv_dept_formal_name';
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dept';
-- Ver1.2 Changed 2008/05/19
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_formal_name;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_tmp_request_no := lr_ref.request_no ;
--
      END IF ;
--
      -- ====================================================
      -- ���׏��o��
      -- ====================================================
--
      -- ----------------------------------------------------
      -- �����̕ҏW
      -- ----------------------------------------------------
-- mod start 1.7
--2008/09/19 Mod ��
/*
      --�󒍃^�C�v���ԕi�̏ꍇ
      IF (lr_ref.order_category_code = cv_order) THEN
*/
      --�󒍃^�C�vID�������̏ꍇ
--      IF (lr_ref.order_type_id = cn_type_id) THEN
      IF (lr_ref.order_type_id = gn_type_id) THEN
--2008/09/19 Mod ��
-- mod end 1.7
        ln_quantity      := ABS(lr_ref.quantity) * -1;
      ELSE
        ln_quantity      := ABS(lr_ref.quantity);
      END IF;
      -- ----------------------------------------------------
      -- �O���[�v�J�n�^�O�i���ׁj
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- �f�[�^�^�O�o��
      -- ----------------------------------------------------
--
      -- �i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_no;
      -- �i�ږ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_short_name;
      -- �t�уR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.futai_code;
      -- ----------------------------------------------------
      -- ���b�g���̕ҏW
      -- ----------------------------------------------------
      -- �p�����[�^�g�p�ړI���˗��̏ꍇ
      IF (gr_param.use_purpose = gc_use_purpose_irai) THEN
          -- ���b�g�m��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- ������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- �ܖ�����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- �ŗL�L��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
      -- ���b�g�Ǘ��i�O
      ELSIF (lr_ref.lot_ctl = gc_lot_ctl_n ) THEN
          -- ���b�g�m��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- ������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- �ܖ�����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- �ŗL�L��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
      ELSE
        -- ���b�g�m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_no;
        -- ������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.product_date;
        -- �ܖ�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.use_by_date;
        -- �ŗL�L��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.original_char;
      END IF;
--      
      -- ����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'orderd_quantity' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_quantity;
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_um' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.uom_code;
--
      -- ----------------------------------------------------
      -- �O���[�v�I���^�O�i���ׁj
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- �O���[�v�I���^�O�o��
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���X�g�O���[�v�I���^�O�i�o�Ɂj
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �O���[�v�I���^�O�i�˗�No�j
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_request' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O�i�˗��j
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �J�[�\���N���[�Y
    -- ====================================================
    CLOSE lc_ref ;
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                             --*** ���݃`�F�b�N��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gc_po_application,         -- �A�v���P�[�V�����Z�k���FXXPO
                            gc_err_code_sikyuno_data,  -- ���b�Z�[�W�FAPP-XXPO-10026 APP-XXPO-10026
                            'TABLE',   -- �g�[�N���F�e�[�u����
                            lv_tablename
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_out_data ;
--
--
  /************************************************************************************************
   * Procedure Name   : prc_create_sql
   * Description      : �f�[�^���o����
   ************************************************************************************************/
  PROCEDURE prc_create_sql
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_sql' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_where_1    VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�d�k�d�b�s�吶��
    -- ====================================================
    lv_select := ' SELECT'
      ||' xoha.request_no                  AS request_no'                  --�˗�No
      ||',xvv.segment1                     AS vendor_code'                 --�����R�[�h
      ||',xvv.vendor_full_name             AS vendor_name'                 --����於��
      ||',xvsv.vendor_site_code            AS deliver_to_code'             --�z����R�[�h
      ||',xvsv.vendor_site_name            AS deliver_to_name'             --�z���於��
      ||',xvsv.zip                         AS zip'                         --�X�֔ԍ�
      ||',xvsv.address_line1               AS address1'                    --�Z��1
      ||',xvsv.address_line2               AS address2'                    --�Z��2
-- Ver1.2 Changed 2008/05/19
--      ||',xssv.segment1                    AS shipped_locat_code'          --�o�ɑq�ɃR�[�h
      ||',xilv.segment1                    AS shipped_locat_code'          --�o�ɑq�ɃR�[�h
-- Ver1.2 Changed 2008/05/19
      ||',xilv.description                 AS shipped_locat_name'          --�o�ɑq��
      ||',xoha.schedule_ship_date          AS ship_date'                   --�o�ɓ�
      ||',xoha.schedule_arrival_date       AS arrival_date'                --���ɓ�
      ||',xoha.takeback_class              AS takeback_class'              --����敪
      ||',xoha.arrival_time_from           AS arrival_time_from'           --���׎���From
      ||',xoha.arrival_time_to             AS arrival_time_to'             --���׎���To
      ||',xoha.freight_charge_class        AS freight_charge_class'        --�^���敪
      ||',xxcv.party_number                AS party_number'                --�^�����
      ||',xxcv.party_short_name            AS party_short_name'            --�^����Ж���
      ||',xoha.shipping_method_code        AS shipping_method_code'        --�z���敪
      ||',xoha.delivery_no                 AS delivery_no'                 --�z��No
      ||',xoha.po_no                       AS po_no'                       --����No
-- 2008/06/23 v1.5 Y.Yamamoto ADD Start
      ||',xoha.base_request_no             AS base_request_no'             --���˗�No
      ||',xxcv.complusion_output_code      AS complusion_output_code'      --�����o�͋敪
-- 2008/06/23 v1.5 Y.Yamamoto ADD End
      ||',xoha.shipping_instructions       AS shipping_instructions'       --�E�v
      ||',xoha.performance_management_dept AS performance_management_dept' --���ъǗ�����
      ||',xoha.instruction_dept            AS instruction_dept'            --�w������
      ||',ximv.item_no                     AS item_no'                     --�i�ڃR�[�h
      ||',ximv.item_short_name             AS item_short_name'             --�i�ږ���
      ||',xola.futai_code                  AS futai_code'                  --�t�уR�[�h
      ||',otta.attribute11                 AS shipping_provide'            --�o�׎x���󕥃J�e�S��
      ||',ximv.lot_ctl                     AS lot_ctl'                     --���b�g�Ǘ��敪
      ||',otta.order_category_code         AS order_category_code'         --�󒍃J�e�S��
      ||',xola.uom_code                    AS uom_code'                    --�P��
       ;
    -- �p�����[�^�g�p�ړI���P�F�˗�
    IF (gr_param.use_purpose = gc_use_purpose_irai) THEN
      lv_select := lv_select
        ||',xola.based_request_quantity    AS quantity'                    --���_�˗�����
        ||',0                              AS lot_no'                      --���b�g�ԍ�
        ||',''1900/01/01''                 AS product_date'                --������
        ||',''1900/01/01''                 AS use_by_date'                 --�ܖ�����
        ||',''A''                          AS original_char'               --�ŗL�L��
        ;
    -- �p�����[�^�g�p�ړI���Q�F�w���܂��́A�R�F�ԕi
    ELSIF ((gr_param.use_purpose = gc_use_purpose_shij)
      OR   (gr_param.use_purpose = gc_use_purpose_henpin))
    THEN
        lv_select := lv_select
          || ',xmld.actual_quantity       AS quantity'                     --���ѐ���
          ||',ilm.lot_no                  AS lot_no'                       --���b�g�ԍ�
          ||',ilm.attribute1              AS product_date'                 --������
          ||',ilm.attribute3              AS use_by_date'                  --�ܖ�����
          ||',ilm.attribute2              AS original_char'                --�ŗL�L��
          ;
    END IF;
--2008/09/19 Add ��
    lv_select := lv_select
      ||',xoha.order_type_id              AS order_type_id';               -- �󒍃^�C�vID
--2008/09/19 Add ��
--
    -- ====================================================
    -- �e�q�n�l�吶��
    -- ====================================================
    lv_from   := ' FROM'
      ||' oe_transaction_types_all   otta '-- �󒍃^�C�v
      ||',xxwsh_order_headers_all    xoha '-- �󒍃w�b�_�A�h�I��
      ||',xxwsh_order_lines_all      xola '-- �󒍖��׃A�h�I��
      ||',xxcmn_vendor_sites2_v      xvsv '-- �d����T�C�gView
      ||',xxcmn_item_mst2_v          ximv '-- OPM�i�ڏ��View
      ||',xxcmn_item_categories4_v   xicv '-- OPM�i�ڃJ�e�S������View
      ||',xxcmn_vendors2_v           xvv  '-- �d������view
      ||',xxcmn_item_locations2_v    xilv '-- OPM�ۊǏꏊ���view
      ||',xxcmn_carriers2_v          xxcv '-- �^���Ǝҏ��view
      ||',xxpo_security_supply_v     xssv '-- �L���x���Z�L�����e�BVIEW
      ;
    -- �p�����[�^�g�p�ړI���P�F�˗��ȊO
    IF (gr_param.use_purpose <> gc_use_purpose_irai) THEN
      lv_from := lv_from
        || ',xxinv_mov_lot_details   xmld '-- �ړ����b�g�ڍ�
        || ',ic_lots_mst             ilm  '-- OPM���b�g�}�X�^
        ;
    END IF;
--
    -- ====================================================
    -- �v�g�d�q�d�吶��
    -- ====================================================
    lv_where := 'WHERE'
      ||'      xoha.order_type_id            = otta.transaction_type_id'            -- �󒍃^�C�v
      ||' AND  otta.org_id                   = '''|| gn_prof_org_id   ||''''        -- �c�ƒP��
      ||' AND  otta.attribute1               = '''|| gc_sp_class_prov ||''''        -- �o�׎x���敪
      ||' AND  xoha.latest_external_flag     = '''|| gc_yn_div_y      ||''''        -- �ŐV�t���O
      ||' AND  xoha.vendor_id                = xvv.vendor_id'                       -- �d����ID
--add start 1.4.1
      --�K�p���Ǘ�(�d������view)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- �p�����[�^.�o�ɓ�From
      ||'   BETWEEN xvv.start_date_active'                                          -- �K�p�J�n��
      ||'   AND NVL(xvv.end_date_active,'                                           -- �K�p�I����
      ||'     FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
--add end 1.4.1
      ||' AND  xoha.vendor_site_id           = xvsv.vendor_site_id'                 -- �d����T�C�gID
--add start 1.4.1
      --�K�p���Ǘ�(�d����T�C�gview)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- �p�����[�^.�o�ɓ�From
      ||'   BETWEEN xvsv.start_date_active'                                         -- �K�p�J�n��
      ||'   AND NVL(xvsv.end_date_active,'                                          -- �K�p�I����
      ||'     FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
--add end 1.4.1
-- Ver1.1 Changed 2008/05/16
--      ||' AND  xoha.deliver_to_id            = xilv.inventory_location_id'          -- �ۊǏꏊID
--      ||' AND  xoha.career_id                = xxcv.party_id'                       -- �p�[�e�BID
      ||' AND  xoha.deliver_from_id          = xilv.inventory_location_id'          -- �ۊǏꏊID
      ||' AND  xoha.career_id                = xxcv.party_id(+) '                       -- �p�[�e�BID
-- Ver1.1 Changed 2008/05/16
--add start 1.4.1
      --�K�p���Ǘ�(OPM�ۊǏꏊ���view)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- �p�����[�^.�o�ɓ�From
      ||'   BETWEEN xilv.date_from'                                                 -- �K�p�J�n��
      ||'   AND NVL(xilv.date_to,'                                                  -- �K�p�I����
      ||'     FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
      --�K�p���Ǘ�(�^���Ǝҏ��view)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- �p�����[�^.�o�ɓ�From
      ||'   BETWEEN xxcv.start_date_active(+)'                                         -- �K�p�J�n��
      ||'   AND NVL(xxcv.end_date_active(+),'                                          -- �K�p�I����
      ||'      FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
--add end 1.4.1
      ||' AND  xoha.request_no
                 = NVL('''|| gr_param.request_no||''',xoha.request_no)'             -- �p�����[�^�˗�No
      ||' AND  xoha.instruction_dept
                 = NVL('''|| gr_param.exec_user_dept ||''',xoha.instruction_dept)'  -- �p�����[�^�S������
      ||' AND  xoha.last_updated_by
                 = NVL('''|| gr_param.update_exec_user||''',xoha.last_updated_by)'  -- �p�����[�^�X�V��
      ||' AND  xoha.last_update_date'                                               -- �ŏI�X�V��
      ||' BETWEEN FND_DATE.CANONICAL_TO_DATE('''||gr_param.update_date_from ||''')' -- �p�����[�^�X�V����FROM
      ||'     AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.update_date_to   ||''')' -- �p�����[�^�X�V����To
      ||' AND  xoha.vendor_code = NVL('''|| gr_param.vendor||''',xoha.vendor_code)' -- �p�����[�^�����
      ||' AND  xoha.vendor_site_code
                  = NVL('''|| gr_param.deliver_to||''',xoha.vendor_site_code)'      -- �p�����[�^�z����
      ||' AND  xoha.deliver_from     
                  =NVL( '''|| gr_param.shipped_locat_code ||''',xoha.deliver_from)' -- �p�����[�^�o�ɑq��
      ||' AND  xoha.schedule_ship_date'                                             -- �o�ח\���
      ||' BETWEEN FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- �p�����[�^�o�ɓ�From
      ||'     AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_to   ||''')'-- �p�����[�^�o�ɓ�To
      ||' AND  xoha.order_header_id          = xola.order_header_id'               -- �󒍃w�b�_�A�h�I��ID
      ||' AND  xola.delete_flag              = '''|| gc_yn_div_n ||''''            -- �폜�t���O
      ||' AND  xola.shipping_item_code       = ximv.item_no'                       -- OPM�i�ڃ}�X�^����
      ||' AND  ximv.item_id                  = xicv.item_id'                       -- �i��ID
--add start 1.4.1
      --�K�p���Ǘ�(OPM�i�ڏ��View)
      ||' AND FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'-- �p�����[�^.�o�ɓ�From
      ||'   BETWEEN ximv.start_date_active'                                         -- �K�p�J�n��
      ||'   AND NVL(ximv.end_date_active,'                                          -- �K�p�I����
      ||'     FND_DATE.CANONICAL_TO_DATE('''||gr_param.shipped_date_from ||''')'
      ||'   )'
--add end 1.4.1
      ||' AND  xicv.prod_class_code
                  = NVL('''|| gr_param.prod_class||''', xicv.prod_class_code )'    -- �p�����[�^�����D���i�敪
      ||' AND  xicv.item_class_code
                  = NVL('''|| gr_param.item_class||''', xicv.item_class_code )'    -- �p�����[�^�����D�i�ڋ敪
      ||' AND  xssv.user_id                ='''|| gn_user_id ||''''                -- ���O�C�����[�UID �Z�L�����e�BVIEW
      ||' AND  xssv.security_class         ='''|| gr_param.security_class||''''    -- �p�����[�^�Z�L�����e�B�敪
      ||' AND  xoha.vendor_code       = NVL(xssv.vendor_code,xoha.vendor_code)'    -- �����
      ||' AND  xoha.vendor_site_code
                           = NVL(xssv.vendor_site_code,xoha.vendor_site_code)'     -- �����T�C�g
      ||' AND  xoha.deliver_from            = NVL(xssv.segment1,xoha.deliver_from)'-- �o�ɑq�ɃR�[�h
      ;
    -- �p�����[�^�g�p�ړI���Q�F�w��
    IF (gr_param.use_purpose = gc_use_purpose_shij) THEN
      lv_where := lv_where
        ||' AND xola.order_line_id = xmld.mov_line_id'                 -- �ړ����b�g�ڍ�
        ||' AND xmld.document_type_code ='''|| gc_doc_type_prov ||'''' -- �����^�C�v �x���w��
        ||' AND xmld.record_type_code   ='''|| gc_rec_type_inst ||'''' -- ���R�[�h�^�C�v �w��
        ||' AND xmld.lot_id             = ilm.lot_id'                  -- ���b�gID
-- Ver1.1 Add 2008/05/16
        ||' AND xmld.item_id             = ilm.item_id'                  -- �i��ID
-- Ver1.1 Add 2008/05/16
        ;
    -- �p�����[�^�g�p�ړI���R�F�ԕi
    ELSIF (gr_param.use_purpose = gc_use_purpose_henpin) THEN
      lv_where := lv_where
        ||' AND xola.order_line_id      = xmld.mov_line_id '               -- �ړ����b�g�ڍ�
        ||' AND xmld.document_type_code ='''|| gc_doc_type_prov ||''''     -- �����^�C�v �x���w��
        ||' AND xmld.record_type_code   ='''|| gc_rec_type_stck ||''''     -- ���R�[�h�^�C�v �o�Ɏ���
        ||' AND xmld.lot_id             = ilm.lot_id '                     -- ���b�gID
-- Ver1.1 Add 2008/05/16
        ||' AND xmld.item_id             = ilm.item_id'                  -- �i��ID
-- Ver1.1 Add 2008/05/16
        ||' AND xoha.req_status         ='''|| gc_req_status_s_cmpc  ||''''-- �X�e�[�^�X�@�o�׎��ьv���
        ||' AND otta.attribute11        ='''|| gc_shipping_provide_h ||''''-- �o�׎x���󕥃J�e�S��
        ;
    END IF;
--
-- Ver1.3 Mod 2008/05/20
/**
    --�p�����[�^�g�p�ړI��1:�˗��A2�F�w��
    IF ((gr_param.use_purpose = gc_use_purpose_irai)
      OR(gr_param.use_purpose = gc_use_purpose_shij))
    THEN
      lv_where := lv_where
        || ' AND xoha.req_status'                               -- �󒍃X�e�[�^�X
        || ' BETWEEN '''|| gc_req_status_s_cmpb ||''''          -- ��̍�
        || '     AND '''|| gc_req_status_p_ccl  ||''''          -- ���
        || ' AND otta.attribute11 = '''|| gc_shipping_provide_s ||''''-- �o�׎x���󕥃J�e�S��
        ;
    END
**/
    --�p�����[�^�g�p�ړI��1:�˗�
    IF (gr_param.use_purpose = gc_use_purpose_irai) THEN
      lv_where := lv_where
        || ' AND xoha.req_status'                               -- �󒍃X�e�[�^�X
        || ' BETWEEN '''|| gc_req_status_s_cmpa ||''''          -- ���͊�����
        || '     AND '''|| gc_req_status_p_ccl  ||''''          -- ���
        || ' AND otta.attribute11 = '''|| gc_shipping_provide_s ||''''-- �o�׎x���󕥃J�e�S��
        ;
    --�p�����[�^�g�p�ړI��1:�˗��A2�F�w��
    ELSIF (gr_param.use_purpose = gc_use_purpose_shij) THEN
      lv_where := lv_where
        || ' AND xoha.req_status'                               -- �󒍃X�e�[�^�X
        || ' BETWEEN '''|| gc_req_status_s_cmpb ||''''          -- ��̍�
        || '     AND '''|| gc_req_status_p_ccl  ||''''          -- ���
        || ' AND otta.attribute11 = '''|| gc_shipping_provide_s ||''''-- �o�׎x���󕥃J�e�S��
        ;
    END IF;
-- Ver1.3 Mod 2008/05/20
--
    --�g�p�ړI��2�F�w��
    IF( gr_param.use_purpose = gc_use_purpose_shij)THEN
      --�L���Z�L�����e�B�敪���u�P�F�ɓ����A�R�F�o�ɑq��(���m�u��)�v
      IF(( gr_param.security_class = gc_security_div_i)
        OR(gr_param.security_class = gc_security_div_l))
      THEN
        lv_where := lv_where
          || ' AND xola.quantity = xola.reserved_quantity'
          ;
      --�L���Z�L�����e�B�敪���u�Q�F�����(�L����)�A�S�F�o�ɑq��(���m�u���ȊO)�v
      ELSIF(( gr_param.security_class = gc_security_div_d)
        OR  ( gr_param.security_class = gc_security_div_lt))
      THEN
        lv_where := lv_where
          || ' AND xoha.notif_status ='''|| gc_notif_status_ok||'''' -- �ʒm�X�e�[�^�X�@40�F�m��ʒm��
          ;
      END IF;
    END IF;
--
--
    -- ====================================================
    -- ORDER BY�吶��
    -- ====================================================
    lv_order_by := ' ORDER BY'
      || ' xoha.request_no'
      || ',xvv.segment1'
      || ',xvsv.vendor_site_code'
      || ',xilv.segment1'
      || ',xoha.schedule_ship_date'
      || ',xola.order_line_number'
    ;
--
    gv_sql := lv_select || lv_from || lv_where || lv_order_by;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_sql ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�ҏW
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
--
    -- ====================================================
    -- �w�l�k�f�[�^�o�͏���
    -- ====================================================
    prc_create_out_data
      (
        ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE check_create_xml_expt ;
    END IF ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
    -- �w�l�k�f�[�^�ҏW�̗�O
    WHEN check_create_xml_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    IF ( ic_type = 'D' ) THEN
-- Ver1.5 Mod 2008/07/11
--      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
-- Ver1.5 Mod 2008/07/11
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_use_purpose        IN     VARCHAR2         -- 01 : �g�p�ړI
     ,iv_request_no         IN     VARCHAR2         -- 02 : �˗�No
     ,iv_exec_user_dept     IN     VARCHAR2         -- 03 : �S������
     ,iv_update_exec_user   IN     VARCHAR2         -- 04 : �X�V�S��
     ,iv_update_date_from   IN     VARCHAR2         -- 05 : �X�V���tFrom
     ,iv_update_date_to     IN     VARCHAR2         -- 06 : �X�V���tTo
     ,iv_vendor             IN     VARCHAR2         -- 07 : �����
     ,iv_deliver_to         IN     VARCHAR2         -- 08 : �z����
     ,iv_shipped_locat_code IN     VARCHAR2         -- 09 : �o�ɑq��
     ,iv_shipped_date_from  IN     VARCHAR2         -- 10 : �o�ɓ�From
     ,iv_shipped_date_to    IN     VARCHAR2         -- 11 : �o�ɓ�To
     ,iv_prod_class         IN     VARCHAR2         -- 12 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         -- 13 : �i�ڋ敪
     ,iv_security_class     IN     VARCHAR2         -- 14 : �L���Z�L�����e�B�敪
     ,ov_errbuf             OUT    VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT    VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT    VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
    lv_err_code             VARCHAR2(15);
--
    get_parm_value_expt     EXCEPTION ;     --�p�����[�^�l�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.use_purpose         := iv_use_purpose;              -- 01 : �g�p�ړI
    gr_param.request_no          := iv_request_no;               -- 02 : �˗�No
    gr_param.exec_user_dept      := iv_exec_user_dept;           -- 03 : �S������
    gr_param.update_exec_user    := iv_update_exec_user;         -- 04 : �X�V�S��
-- Ver1.2 Changed 2008/05/19
--    gr_param.update_date_from    := SUBSTR(iv_update_date_from ,1 ,10); -- 05 : �X�V���tFrom
--    gr_param.update_date_to      := SUBSTR(iv_update_date_to ,1 ,10);   -- 06 : �X�V���tTo
    gr_param.update_date_from    := NVL(iv_update_date_from
                                      , FND_PROFILE.VALUE( 'XXCMN_MIN_DATE' ) || ' 00:00:00');  -- 05 : �X�V���tFrom
    gr_param.update_date_to      := NVL(iv_update_date_to
                                      , FND_PROFILE.VALUE( 'XXCMN_MAX_DATE' ) || ' 23:59:59');  -- 06 : �X�V���tTo
-- Ver1.2 Changed 2008/05/19
    gr_param.vendor              := iv_vendor;                   -- 07 : �����
    gr_param.deliver_to          := iv_deliver_to;               -- 08 : �z����
    gr_param.shipped_locat_code  := iv_shipped_locat_code;       -- 09 : �o�ɑq��
-- Ver1.2 Changed 2008/05/19
--    gr_param.shipped_date_from   := SUBSTR(iv_shipped_date_from , 1 ,10); -- 10 : �o�ɓ�From
--    gr_param.shipped_date_to     := SUBSTR(iv_shipped_date_to , 1,10);    -- 11 : �o�ɓ�To
    gr_param.shipped_date_from   := SUBSTR(NVL(iv_shipped_date_from , FND_PROFILE.VALUE( 'XXCMN_MIN_DATE' ))
                                           , 1 ,10); -- 10 : �o�ɓ�From
    gr_param.shipped_date_to     := SUBSTR(NVL(iv_shipped_date_to , FND_PROFILE.VALUE( 'XXCMN_MIN_DATE' ))
                                           , 1,10);    -- 11 : �o�ɓ�To
-- Ver1.2 Changed 2008/05/19
    gr_param.prod_class          := iv_prod_class;               -- 12 : ���i�敪
    gr_param.item_class          := iv_item_class;               -- 13 : �i�ڋ敪
    gr_param.security_class      := iv_security_class;           -- 14 : �L���Z�L�����e�B�敪
--
    -- -----------------------------------------------------
    -- ���O�C�����ޔ��i�v�g�n�J�����p�j
    -- -----------------------------------------------------
    gn_created_by             := FND_GLOBAL.USER_ID ;           -- �쐬��
    gn_last_updated_by        := FND_GLOBAL.USER_ID ;           -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID ;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID ;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID ;      -- �b�o�E�A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID ;   -- �R���J�����g�E�v���O����ID
--
-- add start 1.7
    -- -----------------------------------------------------
    -- �ԕi�������ݒ�
    -- -----------------------------------------------------
    SELECT xottv.transaction_type_id
    INTO   gn_type_id
    FROM   xxwsh_oe_transaction_types_v xottv
    WHERE  xottv.shipping_shikyu_class = '2'
    AND    xottv.ship_sikyu_rcv_pay_ctg = '06'
    AND    xottv.order_category_code = 'ORDER';
-- add end 1.7
--
    -- -----------------------------------------------------
    -- ���[�^�C�g���ݒ�
    -- -----------------------------------------------------
    -- �˗��̏ꍇ
    IF ( gr_param.use_purpose = gc_use_purpose_irai ) THEN
      gv_report_name := gc_report_name_irai ;  --�L���o�Ɉ˗���
    -- �w���̏ꍇ
    ELSIF( gr_param.use_purpose = gc_use_purpose_shij ) THEN
      gv_report_name := gc_report_name_shij ;  --�L���o�Ɏw����
    ELSE
      gv_report_name := gc_report_name_henpin ;--�L���ԕi�w����
    END IF ;
--
    -- -----------------------------------------------------
    -- �c�ƒP�ʎ擾
    -- -----------------------------------------------------
    gn_prof_org_id := FND_PROFILE.VALUE( gc_prof_org_id ) ;
    IF ( gn_prof_org_id IS NULL ) THEN
      lv_err_code := gc_err_code_no_prof ;
      RAISE get_parm_value_expt ;
    END IF ;
--
    -- =====================================================
    -- �f�[�^�擾�r�p�k����
    -- =====================================================
    prc_create_sql
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���O�C�����[�U�[���o��
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �w�l�k�t�@�C���f�[�^�ҏW
    -- =====================================================
    -- --------------------------------------------------
    -- ���X�g�O���[�v�J�n�^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ���[�^�C�g��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_name ;
--
    -- --------------------------------------------------
    -- �w�l�k�f�[�^�ҏW�������Ăяo���B
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- ���X�g�O���[�v�I���^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- ���[�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- �O�����b�Z�[�W�̎擾
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- ���b�Z�[�W�̐ݒ�
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_locat>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_request>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_request>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_locat>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- �w�l�k�o��
      -- --------------------------------------------------
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
        -- �ҏW�����f�[�^���^�O�ɕϊ�
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_parm_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_po_application
                     ,iv_name           => lv_err_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ###################################
--
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- ���ԃe�[�u�����[���o�b�N
      -- ==================================================
      ROLLBACK ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- ���ԃe�[�u�����[���o�b�N
      -- ==================================================
      ROLLBACK ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- ���ԃe�[�u�����[���o�b�N
      -- ==================================================
      ROLLBACK ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf                OUT     VARCHAR2   -- �G���[���b�Z�[�W
     ,retcode               OUT     VARCHAR2   -- �G���[�R�[�h
     ,iv_use_purpose         IN     VARCHAR2   -- 01 : �g�p�ړI
     ,iv_request_no          IN     VARCHAR2   -- 02 : �˗�No
     ,iv_exec_user_dept      IN     VARCHAR2   -- 03 : �S������
     ,iv_update_exec_user    IN     VARCHAR2   -- 04 : �X�V�S��
     ,iv_update_date_from    IN     VARCHAR2   -- 05 : �X�V���tFrom
     ,iv_update_date_to      IN     VARCHAR2   -- 06 : �X�V���tTo
     ,iv_vendor              IN     VARCHAR2   -- 07 : �����
     ,iv_deliver_to          IN     VARCHAR2   -- 08 : �z����
     ,iv_shipped_locat_code  IN     VARCHAR2   -- 09 : �o�ɑq��
     ,iv_shipped_date_from   IN     VARCHAR2   -- 10 : �o�ɓ�From
     ,iv_shipped_date_to     IN     VARCHAR2   -- 11 : �o�ɓ�To
     ,iv_prod_class          IN     VARCHAR2   -- 12 : ���i�敪
     ,iv_item_class          IN     VARCHAR2   -- 13 : �i�ڋ敪
     ,iv_security_class      IN     VARCHAR2   -- 14 : �L���Z�L�����e�B�敪
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ;  -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;   --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;      --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
    get_parm_value_expt     EXCEPTION ;        --   �p�����[�^�l�擾�G���[
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain
      (
        iv_use_purpose        => iv_use_purpose                            -- 01 : �g�p�ړI
       ,iv_request_no         => iv_request_no                             -- 02 : �˗�No
       ,iv_exec_user_dept     => iv_exec_user_dept                         -- 03 : �S������
       ,iv_update_exec_user   => iv_update_exec_user                       -- 04 : �X�V�S��
       ,iv_update_date_from   => iv_update_date_from                       -- 05 : �X�V���tFrom
       ,iv_update_date_to     => iv_update_date_to                         -- 06 : �X�V���tTo
       ,iv_vendor             => iv_vendor                                 -- 07 : �����
       ,iv_deliver_to         => iv_deliver_to                             -- 08 : �z����
       ,iv_shipped_locat_code => iv_shipped_locat_code                     -- 09 : �o�ɑq��
       ,iv_shipped_date_from  => iv_shipped_date_from                      -- 10 : �o�ɓ�From
       ,iv_shipped_date_to    => NVL(iv_shipped_date_to, gc_max_date_char) -- 11 : �o�ɓ�To
       ,iv_prod_class         => iv_prod_class                             -- 12 : ���i�敪
       ,iv_item_class         => iv_item_class                             -- 13 : �i�ڋ敪
       ,iv_security_class     => iv_security_class                         -- 14 : �L���Z�L�����e�B�敪
       ,ov_errbuf             => lv_errbuf                                 -- �G���[�E���b�Z�[�W
       ,ov_retcode            => lv_retcode                                -- ���^�[���E�R�[�h
       ,ov_errmsg             => lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo440001c ;
/
