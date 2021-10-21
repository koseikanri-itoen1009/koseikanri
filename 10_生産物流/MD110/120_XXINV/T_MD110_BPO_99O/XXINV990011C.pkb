CREATE OR REPLACE PACKAGE BODY xxinv990011c
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : xxinv990011(body)
 * Description      : �o�׈˗��i�˗��������̔ԁj�̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h   T_MD050_BPO_990
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              �֘A�f�[�^�擾 (O-1)
 *  get_upload_data_proc   �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (O-2)
 *  check_proc             �w�b�_/���בÓ����`�F�b�N (O-3)
 *  set_data_proc          �o�^�f�[�^�ݒ� (O-4)
 *  insert_header_proc     �w�b�_�f�[�^�o�^ (O-5)
 *  insert_details_proc    ���׃f�[�^�o�^ (O-6)
 *  submit_request         �ڋq��������̏o�׈˗������쐬�N�� (O-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/09/28    1.0   SCSK ��        �V�K�쐬
 *  2021/10/19    1.1   SCSK ��        [E_�{�ғ�_17407] �o�׈˗��A�b�v���[�h�̐V�K�J�� �ǉ��Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  cv_status_normal CONSTANT VARCHAR2(1) := '0';
  cv_status_warn   CONSTANT VARCHAR2(1) := '1';
  cv_status_error  CONSTANT VARCHAR2(1) := '2';
  cv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  cv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  cv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
  no_data_if_expt           EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxinv990011'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_app_name_xxinv  CONSTANT VARCHAR2(5)   := 'XXINV';
  cv_app_name_xxcmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_app_name_xxwsh  CONSTANT VARCHAR2(5)   := 'XXWSH';
--
  -- ���b�Z�[�W�ԍ�
  cv_c_msg_99o_025   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10025'; -- �v���t�@�C���擾�G���[
  cv_c_msg_99o_032   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ���b�N�G���[
  cv_c_msg_99o_008   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- �Ώۃf�[�^�Ȃ�
  cv_c_msg_99o_024   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10024'; -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
  cv_c_msg_99o_238   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10238'; -- ���_�G���[
  cv_c_msg_99o_239   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10239'; -- �����S���m�F�˗��敪�G���[
--
  cv_c_msg_99o_101   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- �t�@�C����
  cv_c_msg_99o_103   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- �A�b�v���[�h����
  cv_c_msg_99o_104   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- �t�@�C���A�b�v���[�h����
--
  cv_c_msg_99o_220   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10220'; -- �t�H�[�}�b�g�p�^�[��
  cv_c_msg_99o_221   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10221'; -- �p�[�W�Ώۊ���:�o�׈˗�
  cv_c_msg_99o_222   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10222'; -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��
--
  -- �w�b�_���ږ�
  cv_c_msg_99o_223   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10223'; -- �z����
  cv_c_msg_99o_224   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10224'; -- �o�׌�
  cv_c_msg_99o_225   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10225'; -- �o�ד�
  cv_c_msg_99o_226   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10226'; -- ����
  cv_c_msg_99o_227   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10227'; -- ���͋��_
  cv_c_msg_99o_228   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10228'; -- �Ǌ����_
  cv_c_msg_99o_229   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10229'; -- �˗��敪
  cv_c_msg_99o_230   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10230'; -- PO#�i���̂P�j
  cv_c_msg_99o_231   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10231'; -- ���Ԏw��From
  cv_c_msg_99o_232   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10232'; -- ���Ԏw��To
  cv_c_msg_99o_233   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10233'; -- �E�v
  cv_c_msg_99o_234   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10234'; -- �p���b�g�������
  cv_c_msg_99o_235   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10235'; -- �����S���m�F�˗��敪
  -- ���׍��ږ�
  cv_c_msg_99o_236   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10236'; -- �i��
  cv_c_msg_99o_237   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10237'; -- ����
--
  -- �g�[�N��
  cv_c_tkn_ng_profile          CONSTANT VARCHAR2(10)   := 'NAME';
  cv_c_tkn_table               CONSTANT VARCHAR2(15)   := 'TABLE';
  cv_c_tkn_item                CONSTANT VARCHAR2(15)   := 'ITEM';
  cv_c_tkn_value               CONSTANT VARCHAR2(15)   := 'VALUE';
  cv_c_tkn_kyoten              CONSTANT VARCHAR2(15)   := 'KYOTEN';
  -- �v���t�@�C��
  cv_c_parge_term_003          CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_003';
  cv_c_user                    CONSTANT VARCHAR2(15)   := 'USER_ID';
  -- �N�C�b�N�R�[�h �^�C�v
  cv_c_lookup_type             CONSTANT VARCHAR2(17)   := 'XXINV_FILE_OBJECT';
  -- �Ώ�DB��
--
  cv_c_file_id_name             CONSTANT VARCHAR2(20)   := 'FILE_ID';
--
  -- *** �w�b�_���ڌ��� ***
  cn_c_party_site_code_l        CONSTANT NUMBER         := 9;   -- �z����
  cn_c_location_code_l          CONSTANT NUMBER         := 4;   -- �o�׌�
  cn_c_input_sales_branch_l     CONSTANT NUMBER         := 4;   -- ���͋��_
  cn_c_head_sales_branch_l      CONSTANT NUMBER         := 4;   -- �Ǌ����_
  cn_c_ordered_class_l          CONSTANT NUMBER         := 1;   -- �˗��敪
-- Ver1.1 Mod Start
--  cn_c_cust_po_number_l         CONSTANT NUMBER         := 9;   -- PO#�i����1�j
  cn_c_cust_po_number_l         CONSTANT NUMBER         := 16;   -- PO#�i����1�j
-- Ver1.1 Mod End
  cn_c_arrival_time_l           CONSTANT NUMBER         := 4;   -- ���Ԏw��From/To
-- Ver1.1 Mod Start
--  cn_c_shipping_instructions_l  CONSTANT NUMBER         := 40;  -- �E�v
  cn_c_shipping_instructions_l  CONSTANT NUMBER         := 60;  -- �E�v
-- Ver1.1 Mod End
  cn_c_collected_pallet_qty_l   CONSTANT NUMBER         := 3;   -- �p���b�g�������
  cn_c_collected_pallet_qty_d   CONSTANT NUMBER         := 0;   -- �p���b�g��������i�����_�ȉ��j
  cn_c_confirm_request_class_l  CONSTANT NUMBER         := 1;   -- �����S���m�F�˗��敪
  -- *** ���׍��ڌ��� ***
  cn_c_orderd_item_code_l       CONSTANT NUMBER         := 7;   -- �i��
  cn_c_orderd_quantity_l        CONSTANT NUMBER         := 11;  -- ����
  cn_c_orderd_quantity_d        CONSTANT NUMBER         := 3;   -- ���ʁi�����_�ȉ��j
--
  -- �f�[�^�敪
  cv_c_data_type_wsh            CONSTANT VARCHAR2(2)    := '10';  -- �o�׈˗�
--
  cv_c_comma                    CONSTANT VARCHAR2(1)    := ',';      -- �J���}
  cv_c_space                    CONSTANT VARCHAR2(1)    := ' ';      -- �X�y�[�X
  cv_c_err_msg_space            CONSTANT VARCHAR2(6)    := '      '; -- �X�y�[�X�i6byte�j
--
  cv_0                          CONSTANT VARCHAR2(1)    := '0';
  cv_1                          CONSTANT VARCHAR2(1)    := '1';
  cv_start_date                 CONSTANT VARCHAR2(10)   := '19000101';
  cv_end_date                   CONSTANT VARCHAR2(10)   := '99991231';
  cv_rrrrmmdd                   CONSTANT VARCHAR2(10)   := 'RRRRMMDD';
--
  cv_z                          CONSTANT VARCHAR2(1)    := 'Z';
  cn_9999                       CONSTANT NUMBER         := 9999;
  cv_rrrr_mm_dd                 CONSTANT VARCHAR2(15)   := 'RRRR/MM/DD';
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    party_site_code               VARCHAR2(32767), -- �z����
    location_code                 VARCHAR2(32767), -- �o�׌�
    schedule_ship_date            VARCHAR2(32767), -- �o�ד�
    schedule_arrival_date         VARCHAR2(32767), -- ����
    input_sales_branch            VARCHAR2(32767), -- ���͋��_
    head_sales_branch             VARCHAR2(32767), -- �Ǌ����_
    ordered_class                 VARCHAR2(32767), -- �˗��敪
    cust_po_number                VARCHAR2(32767), -- PO#�i���̂P�j
    arrival_time_from             VARCHAR2(32767), -- ���Ԏw��From
    arrival_time_to               VARCHAR2(32767), -- ���Ԏw��To
    shipping_instructions         VARCHAR2(32767), -- �E�v
    collected_pallet_qty          VARCHAR2(32767), -- �p���b�g�������
    confirm_request_class         VARCHAR2(32767), -- �����S���m�F�˗��敪
    orderd_item_code              VARCHAR2(32767), -- �i��
    orderd_quantity               VARCHAR2(32767), -- ����
    line                          VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message                   VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^�i�w�b�_�j
  TYPE header_id_type              IS TABLE OF  
      xxwsh_shipping_headers_if.header_id%TYPE             INDEX BY BINARY_INTEGER;  -- �w�b�_ID
  TYPE party_site_code_type        IS TABLE OF 
      xxwsh_shipping_headers_if.party_site_code%TYPE       INDEX BY BINARY_INTEGER;  -- �o�א�
  TYPE location_code_type          IS TABLE OF 
      xxwsh_shipping_headers_if.location_code%TYPE         INDEX BY BINARY_INTEGER;  -- �o�׌�
  TYPE schedule_ship_date_type     IS TABLE OF 
      xxwsh_shipping_headers_if.schedule_ship_date%TYPE    INDEX BY BINARY_INTEGER;  -- �o�ח\���
  TYPE schedule_arrival_date_type  IS TABLE OF 
      xxwsh_shipping_headers_if.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;  -- ���ח\���
  TYPE input_sales_branch_type     IS TABLE OF 
      xxwsh_shipping_headers_if.input_sales_branch%TYPE    INDEX BY BINARY_INTEGER;  -- ���͋��_
  TYPE head_sales_branch_type      IS TABLE OF 
      xxwsh_shipping_headers_if.head_sales_branch%TYPE     INDEX BY BINARY_INTEGER;  -- �Ǌ����_
  TYPE ordered_class_type          IS TABLE OF 
      xxwsh_shipping_headers_if.ordered_class%TYPE         INDEX BY BINARY_INTEGER;  -- �˗��敪
  TYPE cust_po_number_type         IS TABLE OF 
      xxwsh_shipping_headers_if.cust_po_number%TYPE        INDEX BY BINARY_INTEGER;  -- �ڋq����
  TYPE arrival_time_from_type      IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_from%TYPE     INDEX BY BINARY_INTEGER;  -- ���׎���From
  TYPE arrival_time_to_type      IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_to%TYPE       INDEX BY BINARY_INTEGER;  -- ���׎���To
  TYPE shipping_instructions_type  IS TABLE OF 
      xxwsh_shipping_headers_if.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;  -- �o�׎w��
  TYPE collected_pallet_qty_type      IS TABLE OF 
      xxwsh_shipping_headers_if.collected_pallet_qty%TYPE  INDEX BY BINARY_INTEGER;  -- �p���b�g�������
  TYPE confirm_request_class_type  IS TABLE OF 
      xxwsh_shipping_headers_if.confirm_request_class%TYPE INDEX BY BINARY_INTEGER;  -- �����S���m�F�˗��敪
  TYPE order_source_ref_type       IS TABLE OF 
      xxwsh_shipping_headers_if.order_source_ref%TYPE      INDEX BY BINARY_INTEGER;  -- �󒍃\�[�X�Q��
--
  gt_header_id_tab              header_id_type;             -- �w�b�_ID
  gt_party_site_code_tab        party_site_code_type;       -- �o�א�
  gt_location_code_tab          location_code_type;         -- �o�׌�
  gt_schedule_ship_date_tab     schedule_ship_date_type;    -- �o�ח\���
  gt_schedule_arrival_date_tab  schedule_arrival_date_type; -- ���ח\���
  gt_input_sales_branch_tab     input_sales_branch_type;    -- ���͋��_
  gt_head_sales_branch_tab      head_sales_branch_type;     -- �Ǌ����_
  gt_ordered_class_tab          ordered_class_type;         -- �˗��敪
  gt_cust_po_number_tab         cust_po_number_type;        -- �ڋq����
  gt_arrival_time_from_tab      arrival_time_from_type;     -- ���׎���From
  gt_arrival_time_to_tab        arrival_time_to_type;       -- ���׎���To
  gt_shipping_instructions_tab  shipping_instructions_type; -- �o�׎w��
  gt_collected_pallet_qty_tab   collected_pallet_qty_type;  -- �p���b�g�������
  gt_confirm_request_class_tab  confirm_request_class_type; -- �����S���m�F�˗��敪
  gt_order_source_ref_tab       order_source_ref_type;      -- �󒍃\�[�X�Q��
--
  -- �o�^�pPL/SQL�\�^�i���ׁj
  TYPE line_header_id_type              IS TABLE OF
      xxwsh_shipping_lines_if.header_id%TYPE                  INDEX BY BINARY_INTEGER;  -- ����ID
  TYPE line_id_type                     IS TABLE OF
      xxwsh_shipping_lines_if.line_id%TYPE                    INDEX BY BINARY_INTEGER;  -- �w�b�_ID
  TYPE orderd_item_code_type            IS TABLE OF
      xxwsh_shipping_lines_if.orderd_item_code%TYPE           INDEX BY BINARY_INTEGER;  -- �󒍕i��
  TYPE orderd_quantity_type             IS TABLE OF
      xxwsh_shipping_lines_if.orderd_quantity%TYPE            INDEX BY BINARY_INTEGER;  -- ����
--
  gt_line_header_id_tab                 line_header_id_type;              -- ����ID
  gt_line_id_tab                        line_id_type;                     -- �w�b�_ID
  gt_orderd_item_code_tab               orderd_item_code_type;            -- �󒍕i��
  gt_orderd_quantity_tab                orderd_quantity_type;             -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_header_count           NUMBER;           -- �w�b�_�f�[�^����
  gn_line_count             NUMBER;           -- ���׃f�[�^����
--
  gd_sysdate                DATE;             -- �V�X�e�����t
  gn_user_id                NUMBER;           -- ���[�UID
  gn_login_id               NUMBER;           -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;           -- �v��ID
  gn_prog_appl_id           NUMBER;           -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id        NUMBER;           -- �R���J�����g�E�v���O����ID
--
  gn_xxinv_parge_term       NUMBER;           -- �p�[�W�Ώۊ���
  gv_file_name              VARCHAR2(256);    -- �t�@�C����
  gv_file_up_name           VARCHAR2(256);    -- �t�@�C���A�b�v���[�h����
  gn_created_by             NUMBER(15);       -- �쐬��
  gd_creation_date          DATE;             -- �쐬��
  gv_check_proc_retcode     VARCHAR2(1);      -- �Ó����`�F�b�N�X�e�[�^�X
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾 (O-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format  IN  VARCHAR2,     -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
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
    lv_parge_term       VARCHAR2(100);    -- �v���t�@�C���i�[�ꏊ
    lv_format_type      VARCHAR2(30);     -- �t�H�[�}�b�g�p�^�[��
    lv_parge_term_name  VARCHAR2(30);     -- �p�[�W�Ώۊ���:�o�׈˗�
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
    -- �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    lv_parge_term := FND_PROFILE.VALUE(cv_c_parge_term_003);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_parge_term IS NULL) THEN
      lv_parge_term_name := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name_xxinv
                             ,iv_name         => cv_c_msg_99o_221    -- �p�[�W�Ώۊ���:�o�׈˗�
                            );
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxinv
                    ,iv_name         => cv_c_msg_99o_025
                    ,iv_token_name1  => cv_c_tkn_ng_profile
                    ,iv_token_value1 => lv_parge_term_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�`�F�b�N
    BEGIN
      -- TO_NUMBER�ł��Ȃ���΃G���[
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
        lv_parge_term_name := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_221    -- �p�[�W�Ώۊ���:�o�׈˗�
                              );
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxinv
                      ,iv_name         => cv_c_msg_99o_025
                      ,iv_token_name1  => cv_c_tkn_ng_profile
                      ,iv_token_value1 => lv_parge_term_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̎擾
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- �N�C�b�N�R�[�hVIEW
      WHERE   xlvv.lookup_type = cv_c_lookup_type       -- �^�C�v
      AND     xlvv.lookup_code = in_file_format         -- �R�[�h
      AND     ROWNUM           = 1;
    EXCEPTION
      --*** �f�[�^�擾�G���[ ***
      WHEN NO_DATA_FOUND THEN
        lv_format_type := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name_xxinv
                             ,iv_name         => cv_c_msg_99o_220    -- �t�H�[�}�b�g�p�^�[��
                            );
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxinv
                      ,iv_name         => cv_c_msg_99o_008
                      ,iv_token_name1  => cv_c_tkn_item
                      ,iv_token_value1 => lv_format_type
                      ,iv_token_name2  => cv_c_tkn_value
                      ,iv_token_value2 => in_file_format
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (O-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id    IN  NUMBER,       --   �t�@�C���h�c
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data_proc'; -- �v���O������
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
    lv_line               VARCHAR2(32767);    -- ���s�R�[�h���̏��
    ln_col                NUMBER;             -- �J����
    lb_col                BOOLEAN  := TRUE;   -- �J�����쐬�p��
    ln_length             NUMBER;             -- �����ۊǗp
    lv_xxinv_mrp_file_ul  VARCHAR2(50);       -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;  -- �s�e�[�u���i�[�̈�
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
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_name,    -- �t�@�C����
           xmf.created_by,   -- �쐬��
           xmf.creation_date -- �쐬��
    INTO   gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- **************************************************
    -- *** �t�@�C���A�b�v���[�h�C���^�[�t�F�[�X�f�[�^�擾
    -- **************************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,         -- �t�@�C���h�c
      lt_file_line_data,  -- �ϊ���VARCHAR2�f�[�^
      lv_errbuf,          -- �G���[�E���b�Z�[�W             --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h               --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �^�C�g���s�݂̂̏ꍇ
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxinv
                    ,iv_name         => cv_c_msg_99o_008
                    ,iv_token_name1  => cv_c_tkn_item
                    ,iv_token_value1 => cv_c_file_id_name
                    ,iv_token_name2  => cv_c_tkn_value
                    ,iv_token_value2 => in_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    -- **************************************************
    -- *** �擾�����f�[�^���s���̃��[�v�i2�s�ڂ���j
    -- **************************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �s���ɍ�Ɨ̈�Ɋi�[
      lv_line := lt_file_line_data(ln_index);
--
      -- 1�s�̓��e�� line �Ɋi�[
      fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- �J�����ԍ�������
      ln_col := 0;    --�J����
      lb_col := TRUE; --�J�����쐬�p��
--
      -- **************************************************
      -- *** 1�s���J���}���ɕ���
      -- **************************************************
      <<comma_loop>>
      LOOP
        --lv_line�̒�����0�Ȃ�I��
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- �J�����ԍ����J�E���g
        ln_col := ln_col + 1;
--
        -- �J���}�̈ʒu���擾
        ln_length := INSTR(lv_line, cv_c_comma);
        -- �J���}���Ȃ�
        IF (ln_length = 0) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        -- �J���}������
        ELSE
          ln_length := ln_length -1;
          lb_col    := TRUE;
        END IF;
--
        -- CSV�`�������ڂ��ƂɃ��R�[�h�Ɋi�[
        IF     (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).party_site_code           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).location_code             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).schedule_ship_date        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).schedule_arrival_date     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).input_sales_branch        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).head_sales_branch         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).ordered_class             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).cust_po_number            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).arrival_time_from         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).arrival_time_to           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).shipping_instructions     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).collected_pallet_qty      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN
          fdata_tbl(gn_target_cnt).confirm_request_class     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN
          fdata_tbl(gn_target_cnt).orderd_item_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 15) THEN
          fdata_tbl(gn_target_cnt).orderd_quantity           := SUBSTR(lv_line, 1, ln_length);
        END IF;
--
        -- str�͍���擾�����s�������i�J���}�͂̂������߁Aln_length + 2�j
        IF (lb_col = TRUE) THEN
          lv_line := SUBSTR(lv_line, ln_length + 2);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
--
      END LOOP comma_loop;
    END LOOP line_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;
--
    --*** ���b�N�擾�G���[ ***
    WHEN check_lock_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_xxinv_mrp_file_ul := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_222    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��
                              );
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxinv
                    ,iv_name         => cv_c_msg_99o_032
                    ,iv_token_name1  => cv_c_tkn_table
                    ,iv_token_value1 => lv_xxinv_mrp_file_ul
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    --*** �f�[�^�擾�G���[ ***
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxinv
                    ,iv_name         => cv_c_msg_99o_008
                    ,iv_token_name1  => cv_c_tkn_item
                    ,iv_token_value1 => cv_c_file_id_name
                    ,iv_token_name2  => cv_c_tkn_value
                    ,iv_token_value2 => in_file_id
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : �w�b�_/���בÓ����`�F�b�N (O-3)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- �v���O������
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
--
    lv_line_feed  VARCHAR2(1);      -- ���s�R�[�h
--
    -- �����ڐ�
    ln_c_col      CONSTANT NUMBER  := 15;
--
    -- *** ���[�J���ϐ� ***
    lv_log_data                 VARCHAR2(32767);  --  LOG�f�[�^���ޔ�p
    lv_party_site_code          VARCHAR2(20);     --  �z����
    lv_location_code            VARCHAR2(20);     --  �o�׌�
    lv_ship_date                VARCHAR2(20);     --  �o�ד�
    lv_arrival_date             VARCHAR2(20);     --  ����
    lv_input_sales_branch       VARCHAR2(20);     --  ���͋��_
    lv_head_sales_branch        VARCHAR2(20);     --  �Ǌ����_
    lv_ordered_class            VARCHAR2(20);     --  �˗��敪
    lv_cust_po_number           VARCHAR2(20);     --  PO#�i���̂P�j
    lv_arrival_time_from        VARCHAR2(20);     --  ���Ԏw��From
    lv_arrival_time_to          VARCHAR2(20);     --  ���Ԏw��To
    lv_shipping_instructions    VARCHAR2(20);     --  �E�v
    lv_collected_pallet_qty     VARCHAR2(20);     --  �p���b�g�������
    lv_confirm_request_class    VARCHAR2(20);     --  �����S���m�F�˗��敪
    lv_orderd_item_code         VARCHAR2(20);     --  �i��
    lv_orderd_quantity          VARCHAR2(20);     --  ����
    ln_input_sales_cnt          NUMBER DEFAULT 0; -- ���͋��_�`�F�b�N�p
    ln_head_sales_cnt           NUMBER DEFAULT 0; -- �Ǌ����_�`�F�b�N�p
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ������
    gv_check_proc_retcode := cv_status_normal; -- �Ó����`�F�b�N�X�e�[�^�X
    lv_line_feed := CHR(10);                   -- ���s�R�[�h
--
    -- **************************************************
    -- *** �擾�������R�[�h���ɍ��ڃ`�F�b�N���s���B
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- **************************************************
      -- *** ���ڐ��`�F�b�N
      -- **************************************************
      -- �i�s�S�̂̒����|�s����J���}�𔲂����������J���}�̐��j 
      --       <> �i�����ȍ��ڐ��|�P�������ȃJ���}�̐��j
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0) 
          - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,cv_c_comma,NULL)),0)) <> (ln_c_col - 1)) 
      THEN
--
        fdata_tbl(ln_index).err_message := cv_c_err_msg_space
                                           || cv_c_err_msg_space
                                           || xxcmn_common_pkg.get_msg(cv_app_name_xxinv,
                                                                       cv_c_msg_99o_024)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** ���ڃ`�F�b�N�i�w�b�_�^���ׁj
        -- **************************************************
        -- ==============================
        -- �z����
        -- ==============================
        lv_party_site_code := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_app_name_xxinv
                                 ,iv_name         => cv_c_msg_99o_223  -- �z����
                              );
        xxcmn_common3_pkg.upload_item_check(lv_party_site_code,
                                            fdata_tbl(ln_index).party_site_code,
                                            cn_c_party_site_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- �o�׌�
        -- ==============================
        lv_location_code := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_224    -- �o�׌�
                            );
        xxcmn_common3_pkg.upload_item_check(lv_location_code,
                                            fdata_tbl(ln_index).location_code,
                                            cn_c_location_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- �o�ד�
        -- ==============================
        lv_ship_date := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name_xxinv
                           ,iv_name         => cv_c_msg_99o_225    -- �o�ד�
                        );
        xxcmn_common3_pkg.upload_item_check(lv_ship_date,
                                            fdata_tbl(ln_index).schedule_ship_date,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- ����
        -- ==============================
        lv_arrival_date := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_226    -- ����
                            );
        xxcmn_common3_pkg.upload_item_check(lv_arrival_date,
                                            fdata_tbl(ln_index).schedule_arrival_date,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- ���͋��_
        -- ==============================
        lv_input_sales_branch := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_227    -- ���͋��_
                            );
        xxcmn_common3_pkg.upload_item_check(lv_input_sales_branch,
                                            fdata_tbl(ln_index).input_sales_branch,
                                            cn_c_input_sales_branch_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        -- �v���V�[�W���[����I��
        ELSIF (lv_retcode = cv_status_normal) THEN
          -- �������`�F�b�N
          BEGIN
            SELECT COUNT(1) 
            INTO   ln_input_sales_cnt
            FROM   fnd_user fu
                  ,per_all_people_f papf
                  ,per_all_assignments_f paaf
                  ,xxcmn_locations_v xlv
                  ,xxcmn_cust_accounts_v xcav
            WHERE fu.user_id = fnd_profile.VALUE( cv_c_user )
              AND fu.employee_id = papf.person_id
              AND papf.person_id = paaf.person_id
              AND NVL( papf.effective_start_date, TO_DATE( cv_start_date, cv_rrrrmmdd )) <= TRUNC( SYSDATE )
              AND NVL( papf.effective_end_date, TO_DATE( cv_end_date, cv_rrrrmmdd )) >= TRUNC( SYSDATE )
              AND NVL( paaf.effective_start_date, TO_DATE( cv_start_date, cv_rrrrmmdd )) <= TRUNC( SYSDATE )
              AND NVL( paaf.effective_end_date, TO_DATE( cv_end_date, cv_rrrrmmdd )) >= TRUNC( SYSDATE )
              AND paaf.location_id = xlv.location_id
              AND xlv.location_code = xcav.party_number
              AND xcav.customer_class_code = '1'
              AND xcav.party_number = fdata_tbl(ln_index).input_sales_branch
            ;
            IF (ln_input_sales_cnt = 0) THEN
              lv_retcode := cv_status_warn;
              lv_errmsg := cv_c_err_msg_space
                            || cv_c_err_msg_space
                            || xxcmn_common_pkg.get_msg(
                                 iv_application  => cv_app_name_xxinv
                                ,iv_name         => cv_c_msg_99o_238       -- ���_�G���[
                                ,iv_token_name1  => cv_c_tkn_item
                                ,iv_token_value1 => lv_input_sales_branch  -- ���͋��_
                                ,iv_token_name2  => cv_c_tkn_kyoten
                                ,iv_token_value2 => fdata_tbl(ln_index).input_sales_branch);
              fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                  || lv_errmsg
                                                  || lv_line_feed;
            END IF;
          END;
        END IF;
--
        -- ==============================
        -- �Ǌ����_
        -- ==============================
        lv_head_sales_branch := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_app_name_xxinv
                                 ,iv_name         => cv_c_msg_99o_228    -- �Ǌ����_
                                );
        xxcmn_common3_pkg.upload_item_check(lv_head_sales_branch,
                                            fdata_tbl(ln_index).head_sales_branch,
                                            cn_c_head_sales_branch_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        -- �v���V�[�W���[����I��
        ELSIF (lv_retcode = cv_status_normal) THEN
          -- �������`�F�b�N
          BEGIN
            SELECT COUNT(1)
            INTO   ln_head_sales_cnt
            FROM   xxwsh_head_branch_rf_dept_v xhbrd
            WHERE  xhbrd.user_id = FND_PROFILE.VALUE( cv_c_user )
              AND  xhbrd.party_number = fdata_tbl(ln_index).head_sales_branch
            ;
            IF (ln_head_sales_cnt = 0) THEN
              lv_retcode := cv_status_warn;
              lv_errmsg := cv_c_err_msg_space
                            || cv_c_err_msg_space
                            || xxcmn_common_pkg.get_msg(
                                 iv_application  => cv_app_name_xxinv
                                ,iv_name         => cv_c_msg_99o_238      -- ���_�G���[
                                ,iv_token_name1  => cv_c_tkn_item
                                ,iv_token_value1 => lv_head_sales_branch  -- �Ǌ����_
                                ,iv_token_name2  => cv_c_tkn_kyoten
                                ,iv_token_value2 => fdata_tbl(ln_index).head_sales_branch);
              fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                  || lv_errmsg
                                                  || lv_line_feed;
            END IF;
          END;
        END IF;
--
        -- ==============================
        --  �˗��敪
        -- ==============================
        lv_ordered_class := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_229    -- �˗��敪
                            );
        xxcmn_common3_pkg.upload_item_check(lv_ordered_class,
                                            fdata_tbl(ln_index).ordered_class,
                                            cn_c_ordered_class_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- PO#�i���̂P�j
        -- ==============================
        lv_cust_po_number := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_230    -- PO#�i���̂P�j
                            );
        xxcmn_common3_pkg.upload_item_check(lv_cust_po_number,
                                            fdata_tbl(ln_index).cust_po_number,
                                            cn_c_cust_po_number_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- ���Ԏw��From
        -- ==============================
        lv_arrival_time_from := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_231    -- ���Ԏw��From
                            );
        xxcmn_common3_pkg.upload_item_check(lv_arrival_time_from,
                                            fdata_tbl(ln_index).arrival_time_from,
                                            cn_c_arrival_time_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- ���Ԏw��To
        -- ==============================
        lv_arrival_time_to := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_232    -- ���Ԏw��To
                            );
        xxcmn_common3_pkg.upload_item_check(lv_arrival_time_to,
                                            fdata_tbl(ln_index).arrival_time_to,
                                            cn_c_arrival_time_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- �E�v
        -- ==============================
        lv_shipping_instructions := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_233    -- �E�v
                            );
        xxcmn_common3_pkg.upload_item_check(lv_shipping_instructions,
                                            fdata_tbl(ln_index).shipping_instructions,
                                            cn_c_shipping_instructions_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  �p���b�g�������
        -- ==============================
        lv_collected_pallet_qty := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_234    -- �p���b�g�������
                            );
        xxcmn_common3_pkg.upload_item_check(lv_collected_pallet_qty,
                                            fdata_tbl(ln_index).collected_pallet_qty,
                                            cn_c_collected_pallet_qty_l,
                                            cn_c_collected_pallet_qty_d,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- �����S���m�F�˗��敪
        -- ==============================
        lv_confirm_request_class := xxccp_common_pkg.get_msg(
                                      iv_application  => cv_app_name_xxinv
                                     ,iv_name         => cv_c_msg_99o_235    -- �����S���m�F�˗��敪
                                    );
        xxcmn_common3_pkg.upload_item_check(lv_confirm_request_class,
                                            fdata_tbl(ln_index).confirm_request_class,
                                            cn_c_confirm_request_class_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        -- �v���V�[�W���[����I��
        ELSIF (lv_retcode = cv_status_normal) THEN
          -- �������`�F�b�N
          IF (fdata_tbl(ln_index).confirm_request_class IS NULL OR
              fdata_tbl(ln_index).confirm_request_class = cv_0 OR
              fdata_tbl(ln_index).confirm_request_class = cv_1) THEN
                NULL;
          ELSE
            lv_retcode := cv_status_warn;
            lv_errmsg := cv_c_err_msg_space
                          || cv_c_err_msg_space
                          || xxcmn_common_pkg.get_msg(
                               iv_application  => cv_app_name_xxinv
                              ,iv_name         => cv_c_msg_99o_239);  -- �����S���m�F�˗��敪�G���[
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          END IF;
        END IF;
--
        -- ==============================
        -- �i��
        -- ==============================
        lv_orderd_item_code := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_236    -- �i��
                            );
        xxcmn_common3_pkg.upload_item_check(lv_orderd_item_code,
                                            fdata_tbl(ln_index).orderd_item_code,
                                            cn_c_orderd_item_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- ����
        -- ==============================
        lv_orderd_quantity := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_237    -- ����
                            );
        xxcmn_common3_pkg.upload_item_check(lv_orderd_quantity,
                                            fdata_tbl(ln_index).orderd_quantity,
                                            cn_c_orderd_quantity_l,
                                            cn_c_orderd_quantity_d,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- **************************************************
      -- *** �G���[����
      -- **************************************************
      -- �`�F�b�N�G���[����̏ꍇ
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** �f�[�^���o�͏����i�s�� + SPACE + �s�S�̂̃f�[�^�j
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || cv_c_space || fdata_tbl(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(fdata_tbl(ln_index).err_message, lv_line_feed));
        -- �Ó����`�F�b�N�X�e�[�^�X
        gv_check_proc_retcode := cv_status_error;
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
--
      END IF;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc (O-4)
   * Description      : �o�^�f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- �v���O������
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
     cv_6              CONSTANT VARCHAR2(1) := '6';      -- �̔Ԕԍ��敪�i�˗�No.�j
--
    -- *** ���[�J���ϐ� ***
    ln_header_id      NUMBER;   -- �w�b�_ID
    ln_line_id        NUMBER;   -- ����ID
    lv_seq_no         xxwsh_shipping_headers_if.order_source_ref%TYPE;  -- �󒍃\�[�X�Q��
--
    -- �w�b�_���ڔ�r�p
    lt_party_site_code_bk          xxwsh_shipping_headers_if.party_site_code%TYPE;       -- �z����
    lt_location_code_bk            xxwsh_shipping_headers_if.location_code%TYPE;         -- �o�׌�
    lt_ship_date_bk                xxwsh_shipping_headers_if.schedule_ship_date%TYPE;    -- �o�ד�
    lt_arrival_date_bk             xxwsh_shipping_headers_if.schedule_arrival_date%TYPE; -- ����
    lt_input_sales_branch_bk       xxwsh_shipping_headers_if.input_sales_branch%TYPE;    -- ���͋��_
    lt_head_sales_branch_bk        xxwsh_shipping_headers_if.head_sales_branch%TYPE;     -- �Ǌ����_
    lt_ordered_class_bk            xxwsh_shipping_headers_if.ordered_class%TYPE;         -- �˗��敪
    lt_cust_po_number_bk           xxwsh_shipping_headers_if.cust_po_number%TYPE;        -- PO#�i���̂P�j
    lt_arrival_time_from_bk        xxwsh_shipping_headers_if.arrival_time_from%TYPE;     -- ���Ԏw��From
    lt_arrival_time_to_bk          xxwsh_shipping_headers_if.arrival_time_to%TYPE;       -- ���Ԏw��To
    lt_shipping_instructions_bk    xxwsh_shipping_headers_if.shipping_instructions%TYPE; -- �E�v
    lt_collected_pallet_qty_bk     xxwsh_shipping_headers_if.collected_pallet_qty%TYPE;  -- �p���b�g�������
    lt_confirm_request_class_bk    xxwsh_shipping_headers_if.confirm_request_class%TYPE; -- �����S���m�F�˗��敪
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
    -- ����������
    gn_line_count     := 0;
    gn_header_count   := 0;
--
    -- ���[�J���ϐ�������
    ln_header_id                 := NULL;
    ln_line_id                   := NULL;
    lt_party_site_code_bk        := NULL;
    lt_location_code_bk          := NULL;
    lt_ship_date_bk              := NULL;
    lt_arrival_date_bk           := NULL;
    lt_input_sales_branch_bk     := NULL;
    lt_head_sales_branch_bk      := NULL;
    lt_ordered_class_bk          := NULL;
    lt_cust_po_number_bk         := NULL;
    lt_arrival_time_from_bk      := NULL;
    lt_arrival_time_to_bk        := NULL;
    lt_shipping_instructions_bk  := NULL;
    lt_collected_pallet_qty_bk   := NULL;
    lt_confirm_request_class_bk  := NULL;
--
    -- **************************************************
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- �w�b�_���ڂ��O�s�ƂЂƂł��قȂ�ꍇ�A�w�b�_�o�^
      IF (NVL(fdata_tbl(ln_index).party_site_code,cv_z)       <> NVL(lt_party_site_code_bk,cv_z)         OR
          NVL(fdata_tbl(ln_index).location_code,cv_z)         <> NVL(lt_location_code_bk,cv_z)           OR
          NVL(FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_ship_date, cv_rrrr_mm_dd), FND_DATE.STRING_TO_DATE(cv_start_date,cv_rrrr_mm_dd))
            <> NVL(lt_ship_date_bk, FND_DATE.STRING_TO_DATE(cv_start_date,cv_rrrr_mm_dd))      OR
          NVL(FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_arrival_date, cv_rrrr_mm_dd), FND_DATE.STRING_TO_DATE(cv_start_date,cv_rrrr_mm_dd))
            <> NVL(lt_arrival_date_bk, FND_DATE.STRING_TO_DATE(cv_start_date,cv_rrrr_mm_dd))   OR
          NVL(fdata_tbl(ln_index).input_sales_branch,cv_z)    <> NVL(lt_input_sales_branch_bk,cv_z)      OR
          NVL(fdata_tbl(ln_index).head_sales_branch,cv_z)     <> NVL(lt_head_sales_branch_bk,cv_z)       OR
          NVL(fdata_tbl(ln_index).ordered_class,cv_z)         <> NVL(lt_ordered_class_bk,cv_z)           OR
          NVL(fdata_tbl(ln_index).cust_po_number,cv_z)        <> NVL(lt_cust_po_number_bk,cv_z)          OR
          NVL(fdata_tbl(ln_index).arrival_time_from,cv_z)     <> NVL(lt_arrival_time_from_bk,cv_z)       OR
          NVL(fdata_tbl(ln_index).arrival_time_to,cv_z)       <> NVL(lt_arrival_time_to_bk,cv_z)         OR
          NVL(fdata_tbl(ln_index).shipping_instructions,cv_z) <> NVL(lt_shipping_instructions_bk,cv_z)   OR
          NVL(fdata_tbl(ln_index).collected_pallet_qty,cn_9999)  <> NVL(lt_collected_pallet_qty_bk,cn_9999) OR
          NVL(fdata_tbl(ln_index).confirm_request_class,cv_0) <> NVL(lt_confirm_request_class_bk,cv_0))  THEN
--
        -- �w�b�_���� �C���N�������g
        gn_header_count  := gn_header_count + 1;
--
        -- �w�b�_ID�̔�
        SELECT xxwsh_shipping_headers_if_s1.NEXTVAL 
        INTO ln_header_id 
        FROM dual;
--
        -- �󒍃\�[�X�Q�Ɓi�˗�No.�j������
        lv_seq_no         := NULL;
        -- �󒍃\�[�X�Q�Ɓi�˗�No.�j�̔�
        xxcmn_common_pkg.get_seq_no(
          cv_6                  -- �̔Ԃ���ԍ���\���敪
         ,lv_seq_no             -- �̔Ԃ����Œ蒷12���̔ԍ�
         ,lv_errbuf             -- �G���[�E���b�Z�[�W
         ,lv_retcode            -- ���^�[���E�R�[�h
         ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- �w�b�_���
        gt_header_id_tab(gn_header_count)             := ln_header_id;                              -- �w�b�_ID
        gt_party_site_code_tab(gn_header_count)       := fdata_tbl(ln_index).party_site_code;       -- �o�א�
        gt_location_code_tab(gn_header_count)         := fdata_tbl(ln_index).location_code;         -- �o�׌�
        gt_schedule_ship_date_tab(gn_header_count) 
                 := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_ship_date, cv_rrrr_mm_dd);    -- �o�ח\���
        gt_schedule_arrival_date_tab(gn_header_count) 
                 := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_arrival_date, cv_rrrr_mm_dd); -- ���ח\���
        gt_input_sales_branch_tab(gn_header_count)    := fdata_tbl(ln_index).input_sales_branch;    -- ���͋��_
        gt_head_sales_branch_tab(gn_header_count)     := fdata_tbl(ln_index).head_sales_branch;     -- �Ǌ����_
        gt_ordered_class_tab(gn_header_count)         := fdata_tbl(ln_index).ordered_class;         -- �˗��敪
        gt_cust_po_number_tab(gn_header_count)        := fdata_tbl(ln_index).cust_po_number;        -- �ڋq����
        gt_arrival_time_from_tab(gn_header_count)     := fdata_tbl(ln_index).arrival_time_from;     -- ���׎���From
        gt_arrival_time_to_tab(gn_header_count)       := fdata_tbl(ln_index).arrival_time_to;       -- ���׎���To
        gt_shipping_instructions_tab(gn_header_count) := fdata_tbl(ln_index).shipping_instructions; -- �o�׎w��
        gt_collected_pallet_qty_tab(gn_header_count)  := fdata_tbl(ln_index).collected_pallet_qty;  -- �p���b�g�������
        gt_confirm_request_class_tab(gn_header_count) := fdata_tbl(ln_index).confirm_request_class; -- �����S���m�F�˗��敪
        gt_order_source_ref_tab(gn_header_count)      := lv_seq_no;                                 -- �󒍃\�[�X�Q��
--
      END IF;
      -- ���דo�^
      -- ���׌��� �C���N�������g
      gn_line_count   := gn_line_count + 1;
--
      -- ����ID�̔�
      SELECT xxwsh_shipping_lines_if_s1.NEXTVAL
      INTO ln_line_id 
      FROM dual;
--
      -- ���׏��
      gt_line_id_tab(gn_line_count)            := ln_line_id;                                       -- ����ID
      gt_line_header_id_tab(gn_line_count)     := ln_header_id;                                     -- �w�b�_ID
      gt_orderd_item_code_tab(gn_line_count)   := fdata_tbl(ln_index).orderd_item_code;             -- �󒍕i��
      gt_orderd_quantity_tab(gn_line_count)    := TO_NUMBER(fdata_tbl(ln_index).orderd_quantity);   -- ����
--
      -- ��r�p�Ƀw�b�_���ڐݒ�
      lt_party_site_code_bk       := fdata_tbl(ln_index).party_site_code;                     -- �o�א�
      lt_location_code_bk         := fdata_tbl(ln_index).location_code;                       -- �o�׌�
      lt_ship_date_bk  
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_ship_date, cv_rrrr_mm_dd);    -- �o�ד�
      lt_arrival_date_bk  
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_arrival_date, cv_rrrr_mm_dd); -- ����
      lt_input_sales_branch_bk    := fdata_tbl(ln_index).input_sales_branch;                  -- ���͋��_
      lt_head_sales_branch_bk     := fdata_tbl(ln_index).head_sales_branch;                   -- �Ǌ����_
      lt_ordered_class_bk         := fdata_tbl(ln_index).ordered_class;                       -- �˗��敪
      lt_cust_po_number_bk        := fdata_tbl(ln_index).cust_po_number;                      -- �ڋq����
      lt_arrival_time_from_bk     := fdata_tbl(ln_index).arrival_time_from;                   -- ���Ԏw��From
      lt_arrival_time_to_bk       := fdata_tbl(ln_index).arrival_time_to;                     -- ���Ԏw��To
      lt_shipping_instructions_bk := fdata_tbl(ln_index).shipping_instructions;               -- �E�v
      lt_collected_pallet_qty_bk  := fdata_tbl(ln_index).collected_pallet_qty;                -- �p���b�g�������
      lt_confirm_request_class_bk := fdata_tbl(ln_index).confirm_request_class;               -- �����S���m�F�˗��敪
--
    END LOOP fdata_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_header_proc
   * Description      : �w�b�_�f�[�^�o�^ (O-5)
   ***********************************************************************************/
  PROCEDURE insert_header_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_header_proc'; -- �v���O������
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
    -- **************************************************
    -- *** �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_header_count
      INSERT INTO xxwsh_shipping_headers_if
      (   header_id                                 -- �w�b�_ID
        , order_type                                -- �󒍃^�C�v
        , ordered_date                              -- �󒍓�
        , party_site_code                           -- �o�א�
        , shipping_instructions                     -- �o�׎w��
        , cust_po_number                            -- �ڋq����
        , order_source_ref                          -- �󒍃\�[�X�Q��
        , schedule_ship_date                        -- �o�ח\���
        , schedule_arrival_date                     -- ���ח\���
        , used_pallet_qty                           -- �p���b�g�g�p����
        , collected_pallet_qty                      -- �p���b�g�������
        , location_code                             -- �o�׌�
        , input_sales_branch                        -- ���͋��_
        , head_sales_branch                         -- �Ǌ����_
        , arrival_time_from                         -- ���׎���From
        , arrival_time_to                           -- ���׎���To
        , data_type                                 -- �f�[�^�^�C�v
        , freight_carrier_code                      -- �^���Ǝ�
        , shipping_method_code                      -- �z���敪
        , delivery_no                               -- �z��No
        , shipped_date                              -- �o�ד�
        , arrival_date                              -- ���ד�
        , eos_data_type                             -- EOS�f�[�^���
        , tranceration_number                       -- �`���p�}��
        , ship_to_location                          -- ���ɑq��
        , rm_class                                  -- �q�֕ԕi�敪
        , ordered_class                             -- �˗��敪
        , report_post_code                          -- �񍐕���
        , line_number                               -- ����ԍ�
        , confirm_request_class                     -- �����S���m�F�˗��敪
        , created_by                                -- �쐬��
        , creation_date                             -- �쐬��
        , last_updated_by                           -- �ŏI�X�V��
        , last_update_date                          -- �ŏI�X�V��
        , last_update_login                         -- �ŏI�X�V���O�C��
        , request_id                                -- �v��ID
        , program_application_id                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                -- �R���J�����g�E�v���O����ID
        , program_update_date                       -- �v���O�����X�V��
      ) VALUES (
          gt_header_id_tab(item_cnt)                -- �w�b�_ID
        , NULL                                      -- �󒍃^�C�v
        , NULL                                      -- �󒍓�
        , gt_party_site_code_tab(item_cnt)          -- �o�א�
        , gt_shipping_instructions_tab(item_cnt)    -- �o�׎w��
        , gt_cust_po_number_tab(item_cnt)           -- �ڋq����
        , gt_order_source_ref_tab(item_cnt)         -- �󒍃\�[�X�Q��
        , gt_schedule_ship_date_tab(item_cnt)       -- �o�ח\���
        , gt_schedule_arrival_date_tab(item_cnt)    -- ���ח\���
        , NULL                                      -- �p���b�g�g�p����
        , gt_collected_pallet_qty_tab(item_cnt)     -- �p���b�g�������
        , gt_location_code_tab(item_cnt)            -- �o�׌�
        , gt_input_sales_branch_tab(item_cnt)       -- ���͋��_
        , gt_head_sales_branch_tab(item_cnt)        -- �Ǌ����_
        , gt_arrival_time_from_tab(item_cnt)        -- ���׎���From
        , gt_arrival_time_to_tab(item_cnt)          -- ���׎���To
        , cv_c_data_type_wsh                        -- �f�[�^�^�C�v
        , NULL                                      -- �^���Ǝ�
        , NULL                                      -- �z���敪
        , NULL                                      -- �z��No
        , NULL                                      -- �o�ד�
        , NULL                                      -- ���ד�
        , NULL                                      -- EOS�f�[�^���
        , NULL                                      -- �`���p�}��
        , NULL                                      -- ���ɑq��
        , NULL                                      -- �q�֕ԕi�敪
        , gt_ordered_class_tab(item_cnt)            -- �˗��敪
        , NULL                                      -- �񍐕���
        , NULL                                      -- ����ԍ�
        , NVL(gt_confirm_request_class_tab(item_cnt),cv_0) -- �����S���m�F�˗��敪
        , gn_user_id                                -- �쐬��
        , gd_sysdate                                -- �쐬��
        , gn_user_id                                -- �ŏI�X�V��
        , gd_sysdate                                -- �ŏI�X�V��
        , gn_login_id                               -- �ŏI�X�V���O�C��
        , gn_conc_request_id                        -- �v��ID
        , gn_prog_appl_id                           -- �ݶ��āE��۸��т̱��ع����ID
        , gn_conc_program_id                        -- �R���J�����g�E�v���O����ID
        , gd_sysdate                                -- �v���O�����ɂ��X�V��
      );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END insert_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_details_proc
   * Description      : ���׃f�[�^�o�^ (O-6)
   ***********************************************************************************/
  PROCEDURE insert_details_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_details_proc'; -- �v���O������
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
    -- **************************************************
    -- *** �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_line_count
      INSERT INTO xxwsh_shipping_lines_if
      (   line_id                                   -- ����ID
        , header_id                                 -- �w�b�_ID
        , line_number                               -- ���הԍ�
        , orderd_item_code                          -- �󒍕i��
        , case_quantity                             -- �P�[�X��
        , orderd_quantity                           -- ����
        , shiped_quantity                           -- �o�׎��ѐ���
        , designated_production_date                -- ������(�C���^�t�F�[�X�p)
        , original_character                        -- �ŗL�L��(�C���^�t�F�[�X�p)
        , use_by_date                               -- �ܖ�����(�C���^�t�F�[�X�p)
        , detailed_quantity                         -- ���󐔗�(�C���^�t�F�[�X�p)
        , ship_to_quantity                          -- ���Ɏ��ѐ���
        , reserved_status                           -- �ۗ��X�e�[�^�X
        , lot_no                                    -- ���b�gNo
        , created_by                                -- �쐬��
        , creation_date                             -- �쐬��
        , last_updated_by                           -- �ŏI�X�V��
        , last_update_date                          -- �ŏI�X�V��
        , last_update_login                         -- �ŏI�X�V���O�C��
        , request_id                                -- �v��ID
        , program_application_id                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                -- �R���J�����g�E�v���O����ID
        , program_update_date                       -- �v���O�����X�V��
      ) VALUES (
          gt_line_id_tab(item_cnt)                  -- ����ID
        , gt_line_header_id_tab(item_cnt)           -- �w�b�_ID
        , NULL                                      -- ���הԍ�
        , gt_orderd_item_code_tab(item_cnt)         -- �󒍕i��
        , NULL                                      -- �P�[�X��
        , gt_orderd_quantity_tab(item_cnt)          -- ����
        , NULL                                      -- �o�׎��ѐ���
        , NULL                                      -- ������(�C���^�t�F�[�X�p)
        , NULL                                      -- �ŗL�L��(�C���^�t�F�[�X�p)
        , NULL                                      -- �ܖ�����(�C���^�t�F�[�X�p)
        , NULL                                      -- ���󐔗�(�C���^�t�F�[�X�p)
        , NULL                                      -- ���Ɏ��ѐ���
        , NULL                                      -- �ۗ��X�e�[�^�X
        , NULL                                      -- ���b�gNo
        , gn_user_id                                -- �쐬��
        , gd_sysdate                                -- �쐬��
        , gn_user_id                                -- �ŏI�X�V��
        , gd_sysdate                                -- �ŏI�X�V��
        , gn_login_id                               -- �ŏI�X�V���O�C��
        , gn_conc_request_id                        -- �v��ID
        , gn_prog_appl_id                           -- �ݶ��āE��۸��т̱��ع����ID
        , gn_conc_program_id                        -- �R���J�����g�E�v���O����ID
        , gd_sysdate                                -- �v���O�����ɂ��X�V��
      );
--
      -- ���������J�E���g
      gn_normal_cnt := gn_line_count;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END insert_details_proc;
--
  /**********************************************************************************
   * Procedure Name   : submit_request
   * Description      : �ڋq��������̏o�׈˗������쐬�N�� (O-7)
   **********************************************************************************/
  PROCEDURE submit_request(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submit_request'; -- �v���O������
    cv_program     CONSTANT VARCHAR2(15)  := 'XXWSH400002C'; -- �R���J�����g�F�ڋq��������̏o�׈˗������쐬
    cb_sub_request CONSTANT BOOLEAN       := FALSE;
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
  -- ���͋��_/�Ǌ����_�擾�p
    TYPE submit_request_rec IS RECORD(
      input_sales_branch        xxwsh_shipping_headers_if.input_sales_branch%TYPE
     ,head_sales_branch         xxwsh_shipping_headers_if.head_sales_branch%TYPE
    );
  -- ���͋��_/�Ǌ����_�擾�p
    TYPE submit_request_ttype  IS TABLE OF submit_request_rec INDEX BY BINARY_INTEGER;
      submit_request_tab        submit_request_ttype;
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_request_id NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR submit_request_cur
    IS
      SELECT xshi.input_sales_branch input_sales_branch -- ���͋��_
            ,xshi.head_sales_branch  head_sales_branch  -- �Ǌ����_
      FROM   xxwsh_shipping_headers_if  xshi            -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
      WHERE  xshi.request_id = gn_conc_request_id
      GROUP BY xshi.input_sales_branch
              ,xshi.head_sales_branch
      ;
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
    --�J�[�\���I�[�v��
    OPEN  submit_request_cur;
    FETCH submit_request_cur BULK COLLECT INTO submit_request_tab;
    CLOSE submit_request_cur;
--
    <<submit_request_loop>>
    FOR i IN 1..submit_request_tab.COUNT LOOP
      ln_request_id := fnd_request.submit_request(
                         application  => cv_app_name_xxwsh,
                         program      => cv_program,
                         description  => NULL,
                         start_time   => NULL,
                         sub_request  => cb_sub_request,
                         argument1    => submit_request_tab( i ).input_sales_branch, -- ���͋��_
                         argument2    => submit_request_tab( i ).head_sales_branch   -- �Ǌ����_
                       );
      --�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
    END LOOP submit_request_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
      IF (submit_request_cur%ISOPEN)THEN
        CLOSE submit_request_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END submit_request;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,       --   �t�@�C���h�c
    in_file_format IN  VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain';      -- �v���O������
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
--
    lv_out_rep VARCHAR2(1000);  -- ���|�[�g�o��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- �Ó����`�F�b�N�X�e�[�^�X ������
    gv_check_proc_retcode := cv_status_normal;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �֘A�f�[�^�擾 (O-1)
    -- ===============================
    init_proc(
      in_file_format,    -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (O-2)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- �t�@�C���h�c
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W START  ###################################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(cv_app_name_xxinv,
                                              cv_c_msg_99o_101,
                                              cv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(cv_app_name_xxinv,
                                              cv_c_msg_99o_103,
                                              cv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(cv_app_name_xxinv,
                                              cv_c_msg_99o_104,
                                              cv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W END   ###################################
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾���ʂ𔻒�
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    END IF;
--
--
    -- ===============================
    -- �Ó����`�F�b�N (O-3)
    -- ===============================
    check_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
--
    -- �Ó����`�F�b�N�ŃG���[���Ȃ������ꍇ
    ELSIF (gv_check_proc_retcode = cv_status_normal) THEN
--
      -- ===============================
      -- �o�^�f�[�^�Z�b�g (O-4)
      -- ===============================
      set_data_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �w�b�_�o�^ (O-5)
      -- ===============================
      insert_header_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���דo�^ (O-6)
      -- ===============================
      insert_details_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���דo�^�ŃG���[���Ȃ������ꍇ
      IF (lv_retcode = cv_status_normal) THEN
--
        -- ===============================
        -- �ڋq��������̏o�׈˗������쐬�N�� (O-7)
        -- ===============================
        submit_request(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜 (O-8)
    -- ===============================
    xxcmn_common3_pkg.delete_fileup_proc(
      in_file_format,                 -- �t�H�[�}�b�g�p�^�[��
      gd_sysdate,                     -- �Ώۓ��t
      gn_xxinv_parge_term,            -- �p�[�W�Ώۊ���
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      -- �폜�����G���[����RollBack������ׁA�Ó����`�F�b�N�X�e�[�^�X��������
      gv_check_proc_retcode := cv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- �`�F�b�N�����G���[
    IF (gv_check_proc_retcode = cv_status_error) THEN
      -- �Œ�̃G���[���b�Z�[�W�̏o�͂����Ȃ��悤�ɂ���
      lv_errmsg := cv_c_space;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
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
  PROCEDURE main(
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id     IN  VARCHAR2,      --   �t�@�C���h�c
    in_file_format IN  VARCHAR2       --   �t�H�[�}�b�g�p�^�[��
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    -- ���b�Z�[�W
    cv_msg_xxcmn_00001 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001';
    cv_msg_xxcmn_00002 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002';
    cv_msg_xxcmn_10118 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118';
    cv_msg_xxcmn_00003 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003';
    cv_msg_xxcmn_10030 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030';
    cv_msg_xxcmn_00008 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';
    cv_msg_xxcmn_00009 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';
    cv_msg_xxcmn_00010 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';
    cv_msg_xxcmn_00011 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011';
    cv_msg_xxcmn_00012 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012';
--
    -- �g�[�N��
    cv_user            CONSTANT VARCHAR2(10) := 'USER';
    cv_conc            CONSTANT VARCHAR2(10) := 'CONC';
    cv_cnt             CONSTANT VARCHAR2(10) := 'CNT';
    cv_status          CONSTANT VARCHAR2(10) := 'STATUS';
--
    -- �N�C�b�N�R�[�h
    cv_cp_status_code  CONSTANT VARCHAR2(20) := 'CP_STATUS_CODE';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00001,cv_user,gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00002,cv_conc,gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_10118,
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00003);
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      TO_NUMBER(in_file_id),     -- �t�@�C���h�c
      in_file_format, -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_10030);
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00008,cv_cnt,TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00009,cv_cnt,TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00010,cv_cnt,TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00011,cv_cnt,TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = cv_cp_status_code
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            cv_status_normal,cv_sts_cd_normal,
                                            cv_status_warn,cv_sts_cd_warn,
                                            cv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00012,cv_status,gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) AND (gv_check_proc_retcode = cv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv990011c;
/
