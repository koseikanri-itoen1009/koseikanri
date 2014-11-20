CREATE OR REPLACE PACKAGE BODY XXINV990010C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXINV990010C(body)
 * Description      : �ړ��w���̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h   T_MD050_BPO_990
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �֘A�f�[�^�擾(L-1)
 *  get_upload_data        �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (L-2)
 *  validity_check         �Ó����`�F�b�N(L-3,4,5)
 *  set_data               �o�^�f�[�^�ݒ�
 *  insert_header          �w�b�_�f�[�^�o�^(L-6)
 *  insert_lines           ���׃f�[�^�o�^(L-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/02/24    1.0   SCS Y.Kanami     �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal  CONSTANT VARCHAR2(1)  := '0';
  gv_status_warn    CONSTANT VARCHAR2(1)  := '1';
  gv_status_error   CONSTANT VARCHAR2(1)  := '2';
--
  gv_sts_cd_normal  CONSTANT VARCHAR2(1)  := 'C';
  gv_sts_cd_warn    CONSTANT VARCHAR2(1)  := 'G';
  gv_sts_cd_error   CONSTANT VARCHAR2(1)  := 'E';
  gv_msg_part       CONSTANT VARCHAR2(3)  := ' : ';
  gv_msg_cont       CONSTANT VARCHAR2(3)  := '.';
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
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
  no_data_if_expt           EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name           CONSTANT VARCHAR2(100)  := 'XXINV990010C';     -- �p�b�P�[�W��
--
  gv_c_msg_kbn          CONSTANT VARCHAR2(5)    := 'XXINV';
--
  -- ���b�Z�[�W�ԍ�
  gv_c_msg_ng_profile   CONSTANT VARCHAR2(15)   := 'APP-XXINV-10025';  -- �v���t�@�C���擾�G���[
  gv_c_msg_ng_rock      CONSTANT VARCHAR2(15)   := 'APP-XXINV-10032';  -- ���b�N�G���[
  gv_c_msg_ng_data      CONSTANT VARCHAR2(15)   := 'APP-XXINV-10008';  -- �Ώۃf�[�^�Ȃ�
  gv_c_msg_ng_format    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10024';  -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
  gv_c_msg_ng_head_item CONSTANT VARCHAR2(15)   := 'APP-XXINV-10192';  -- ����w�b�_���ڃG���[
--
  gv_c_msg_file_name    CONSTANT VARCHAR2(15)   := 'APP-XXINV-00001';  -- �t�@�C����
  gv_c_msg_upload_date  CONSTANT VARCHAR2(15)   := 'APP-XXINV-00003';  -- �A�b�v���[�h����
  gv_c_msg_upload_name  CONSTANT VARCHAR2(15)   := 'APP-XXINV-00004';  -- �t�@�C���A�b�v���[�h����
--
  -- �g�[�N��
  gv_c_tkn_ng_profile   CONSTANT VARCHAR2(10)   := 'NAME';
  gv_c_tkn_table        CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_c_tkn_item         CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_c_tkn_value        CONSTANT VARCHAR2(15)   := 'VALUE';
--
  -- �v���t�@�C��
  gv_c_purge_term_010   CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_010';
  gv_c_purge_term_name  CONSTANT VARCHAR2(36)   := '�p�[�W�Ώۊ���:�ړ��w��';
--
  -- �N�C�b�N�R�[�h �^�C�v
  gv_c_lookup_type      CONSTANT VARCHAR2(17)   := 'XXINV_FILE_OBJECT';
  gv_c_format_type      CONSTANT VARCHAR2(20)   := '�t�H�[�}�b�g�p�^�[��';
--
  -- �Ώ�DB��
  gv_c_xxinv_mrp_file_ul_name   CONSTANT VARCHAR2(100)
                                                := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  -- ���̓p�����[�^
  gv_c_file_id_name             CONSTANT VARCHAR2(24) := 'FILE_ID';
  -- �w�b�_���ږ�
  gv_c_tmp_ship_number          CONSTANT VARCHAR2(20) := '���`�[�ԍ�';
  gv_c_product_flg              CONSTANT VARCHAR2(20) := '���i���ʋ敪';
  gv_c_instr_post_cd            CONSTANT VARCHAR2(20) := '�ړ��w�������R�[�h';
  gv_c_mov_type                 CONSTANT VARCHAR2(20) := '�ړ��^�C�v�R�[�h';
  gv_c_shipped_locat_cd         CONSTANT VARCHAR2(20) := '�o�Ɍ��R�[�h';
  gv_c_ship_to_locat_cd         CONSTANT VARCHAR2(20) := '���ɐ�R�[�h';
  gv_c_schedule_ship_date       CONSTANT VARCHAR2(20) := '�o�ɓ�';
  gv_c_schedule_arrival_date    CONSTANT VARCHAR2(20) := '����';
  gv_c_freight_charge_cls       CONSTANT VARCHAR2(20) := '�^���敪';
  gv_c_freight_carrier_cd       CONSTANT VARCHAR2(20) := '�^���Ǝ҃R�[�h';
  gv_c_weight_capacity_cls      CONSTANT VARCHAR2(20) := '�d�ʗe�ϋ敪';
  -- ���׍��ږ�
  gv_c_item_cd                  CONSTANT VARCHAR2(20) := '�i�ڃR�[�h';
  gv_c_designated_prod_date     CONSTANT VARCHAR2(20) := '�w�萻����';
  gv_c_first_instruct_qty       CONSTANT VARCHAR2(20) := '�w������';
--
  -- �w�b�_���ڌ���
  gn_c_tmp_ship_number_len      CONSTANT NUMBER       := 256; -- ���`�[�ԍ�
  gn_c_product_flg_len          CONSTANT NUMBER       := 1;   -- ���i���ʋ敪
  gn_c_instr_post_cd_len        CONSTANT NUMBER       := 4;   -- �ړ��w�������R�[�h
  gn_c_mov_type_len             CONSTANT NUMBER       := 1;   -- �ړ��^�C�v�R�[�h
  gn_c_shipped_locat_cd_len     CONSTANT NUMBER       := 4;   -- �o�Ɍ��R�[�h
  gn_c_ship_to_locat_cd_len     CONSTANT NUMBER       := 4;   -- ���ɐ�R�[�h
  gn_c_freight_charge_cls_len   CONSTANT NUMBER       := 1;   -- �^���敪
  gn_c_freight_carrier_cd_len   CONSTANT NUMBER       := 4;   -- �^���Ǝ҃R�[�h
  gn_c_weight_capacity_cls_len  CONSTANT NUMBER       := 1;   -- �d�ʗe�ϋ敪
  -- ���׍��ڌ���
  gn_c_item_cd_len              CONSTANT VARCHAR2(20) := 7;   -- �i�ڃR�[�h
--
  gv_c_period                   CONSTANT VARCHAR2(1)  := '.';      -- �s���I�h
  gv_c_comma                    CONSTANT VARCHAR2(1)  := ',';      -- �J���}
  gv_c_space                    CONSTANT VARCHAR2(1)  := ' ';      -- �X�y�[�X
  gv_c_err_msg_space            CONSTANT VARCHAR2(6)  := '      '; -- �X�y�[�X�i6byte�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �ړ��w���h�e���i�[�p���R�[�h
  TYPE file_data_rtype IS RECORD(
      temp_ship_no                VARCHAR2(32767) -- ���`�[�ԍ�
    , product_flg                 VARCHAR2(32767) -- ���i���ʋ敪
    , instr_post_cd               VARCHAR2(32767) -- �ړ��w�������R�[�h
    , mov_type                    VARCHAR2(32767) -- �ړ��^�C�v�R�[�h
    , shipped_locat_cd            VARCHAR2(32767) -- �o�Ɍ��R�[�h
    , ship_to_locat_cd            VARCHAR2(32767) -- ���ɐ�R�[�h
    , schedule_ship_date          VARCHAR2(32767) -- �o�ɓ�
    , schedule_arrival_date       VARCHAR2(32767) -- ����
    , freight_charge_cls          VARCHAR2(32767) -- �^���敪
    , freight_carrier_cd          VARCHAR2(32767) -- �^���Ǝ҃R�[�h
    , weight_capacity_cls         VARCHAR2(32767) -- �d�ʗe�ϋ敪
    , item_cd                     VARCHAR2(32767) -- �i�ڃR�[�h
    , designated_production_date  VARCHAR2(32767) -- �w�萻����
    , first_instruct_qty          VARCHAR2(32767) -- �w������
    , err_message                 VARCHAR2(32767) -- �G���[���b�Z�[�W(��������p)
    , line                        VARCHAR2(32767) -- �s���e(��������p)
  );
--
  -- �ړ��w���h�e���i�[�p�z��
  TYPE file_data_ttype IS TABLE OF file_data_rtype INDEX BY BINARY_INTEGER;
  g_file_data_tab file_data_ttype; 
--
  -- �o�^�pPL/SQL�\(�w�b�_)
  TYPE mov_hdr_if_id_type         IS TABLE OF
    xxinv_mov_instr_headers_if.mov_hdr_if_id%type INDEX BY BINARY_INTEGER;            -- �ړ��w�b�_IF_ID
  TYPE tmp_ship_number_type       IS TABLE OF
    xxinv_mov_instr_headers_if.temp_ship_num%type INDEX BY BINARY_INTEGER;            -- ���`�[�ԍ�
  TYPE mov_type_type              IS TABLE OF
    xxinv_mov_instr_headers_if.mov_type%type INDEX BY BINARY_INTEGER;                 -- �ړ��^�C�v
  TYPE instr_post_cd_type         IS TABLE OF
    xxinv_mov_instr_headers_if.instruction_post_code%type INDEX BY BINARY_INTEGER;    -- �w������
  TYPE shipped_locat_cd_type      IS TABLE OF
    xxinv_mov_instr_headers_if.shipped_locat_code%type INDEX BY BINARY_INTEGER;       -- �o�Ɍ��ۊǏꏊ
  TYPE ship_to_locat_cd_type      IS TABLE OF
    xxinv_mov_instr_headers_if.ship_to_locat_code%type INDEX BY BINARY_INTEGER;       -- ���ɐ�ۊǏꏊ
  TYPE schedule_ship_date_type    IS TABLE OF
    xxinv_mov_instr_headers_if.schedule_ship_date%type INDEX BY BINARY_INTEGER;       -- �o�ɗ\���
  TYPE schedule_arrival_date_type IS TABLE OF
    xxinv_mov_instr_headers_if.schedule_arrival_date%type INDEX BY BINARY_INTEGER;    -- ���ɗ\���
  TYPE freight_charge_cls_type    IS TABLE OF
    xxinv_mov_instr_headers_if.freight_charge_class%type INDEX BY BINARY_INTEGER;     -- �^���敪
  TYPE freight_carrier_cd_type    IS TABLE OF
    xxinv_mov_instr_headers_if.freight_carrier_code%type INDEX BY BINARY_INTEGER;     -- �^���Ǝ�
  TYPE weight_capacity_cls_type   IS TABLE OF
    xxinv_mov_instr_headers_if.weight_capacity_class%type INDEX BY BINARY_INTEGER;    -- �d�ʗe�ϋ敪
  TYPE product_flg_type           IS TABLE OF
    xxinv_mov_instr_headers_if.product_flg%type INDEX BY BINARY_INTEGER;              -- ���i���ʋ敪
--
  g_mov_hdr_if_id_tab         mov_hdr_if_id_type;         -- �ړ��w�b�_IF_ID
  g_tmp_ship_number_tab       tmp_ship_number_type;       -- ���`�[�ԍ�
  g_mov_type_tab              mov_type_type;              -- �ړ��^�C�v
  g_instr_post_cd_tab         instr_post_cd_type;         -- �w������
  g_shipped_locat_cd_tab      shipped_locat_cd_type;      -- �o�Ɍ��ۊǏꏊ
  g_ship_to_locat_cd_tab      ship_to_locat_cd_type;      -- ���ɐ�ۊǏꏊ
  g_schedule_ship_date_tab    schedule_ship_date_type;    -- �o�ɗ\���
  g_schedule_arrival_date_tab schedule_arrival_date_type; -- ���ɗ\���
  g_freight_charge_cls_tab    freight_charge_cls_type;    -- �^���敪
  g_freight_carrier_cd_tab    freight_carrier_cd_type;    -- �^���Ǝ�
  g_weight_capacity_cls_tab   weight_capacity_cls_type;   -- �d�ʗe�ϋ敪
  g_product_flg_tab           product_flg_type;           -- ���i���ʋ敪
--
  -- �o�^�pPL/SQL�\(����)
  TYPE mov_line_if_id_type        IS TABLE OF
    xxinv_mov_instr_lines_if.mov_line_if_id%type INDEX BY BINARY_INTEGER;             -- �ړ�����IF_ID
  TYPE mov_line_hdr_if_id_type         IS TABLE OF
    xxinv_mov_instr_lines_if.mov_hdr_if_id%type INDEX BY BINARY_INTEGER;              -- �ړ��w�b�_IF_ID
  TYPE item_cd_type               IS TABLE OF
    xxinv_mov_instr_lines_if.item_code%type INDEX BY BINARY_INTEGER;                  -- �i��
  TYPE designated_prod_date_type  IS TABLE OF
    xxinv_mov_instr_lines_if.designated_production_date%type INDEX BY BINARY_INTEGER; -- �w�萻����
  TYPE first_instruct_qty_type    IS TABLE OF
    xxinv_mov_instr_lines_if.first_instruct_qty%type INDEX BY BINARY_INTEGER;         -- ����w������
--
  g_mov_line_if_id_tab        mov_line_if_id_type;        -- �ړ�����IF_ID
  g_mov_line_hdr_if_id_tab    mov_line_hdr_if_id_type;    -- �ړ��w�b�_IF_ID
  g_item_cd_tab               item_cd_type;               -- �i��
  g_designated_prod_date_tab  designated_prod_date_type;  -- �w�萻����
  g_first_instruct_qty_tab    first_instruct_qty_type;    -- ����w������
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
  gn_prog_appl_id           NUMBER;           -- �R���J�����g�̃A�v���P�[�V����ID
  gn_conc_program_id        NUMBER;           -- �R���J�����g�E�v���O����ID
--
  gn_xxinv_purge_term       NUMBER;           -- �p�[�W�Ώۊ���
  gv_file_name              VARCHAR2(256);    -- �t�@�C����
  gv_file_up_name           VARCHAR2(256);    -- �t�@�C���A�b�v���[�h����
  gn_created_by             NUMBER(15);       -- �쐬��
  gd_creation_date          DATE;             -- �쐬��
  gv_check_proc_retcode     VARCHAR2(1);      -- �Ó����`�F�b�N�X�e�[�^�X
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �֘A�f�[�^�擾(L-1)
   ***********************************************************************************/
  PROCEDURE init(
      in_file_format  IN  VARCHAR2     -- �t�H�[�}�b�g�p�^�[��  
    , ov_errbuf       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_purge_term       VARCHAR2(100);    -- �v���t�@�C���i�[�ꏊ
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --------------------
    -- �V�X�e�����t�擾
    --------------------
    gd_sysdate := SYSDATE;
--
    ---------------------
    -- WHO�J�������擾
    ---------------------
    gn_user_id          := FND_GLOBAL.USER_ID;          -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;         -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- �R���J�����g�E�A�v���P�[�V����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �R���J�����g�E�v���O����ID
--
    --------------------------------------
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    --------------------------------------
    lv_purge_term := FND_PROFILE.VALUE(gv_c_purge_term_010);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_purge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( gv_c_msg_kbn
                                            , gv_c_msg_ng_profile
                                            , gv_c_tkn_ng_profile
                                            , gv_c_purge_term_name
                                            );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --------------------------
    -- �v���t�@�C���l�`�F�b�N
    --------------------------
    BEGIN
      -- ���l�ϊ��ł��Ȃ���΃G���[
      gn_xxinv_purge_term := TO_NUMBER(lv_purge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
        lv_errmsg := xxcmn_common_pkg.get_msg ( gv_c_msg_kbn
                                              , gv_c_msg_ng_profile
                                              , gv_c_tkn_ng_profile
                                              , gv_c_purge_term_name
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --------------------------------
    -- �t�@�C���A�b�v���[�h���̎擾
    --------------------------------
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv
      WHERE   xlvv.lookup_type = gv_c_lookup_type
      AND     xlvv.lookup_code = in_file_format
      AND     xlvv.start_date_active <= gd_sysdate
      AND     ((xlvv.end_date_active IS NULL)
              OR  (xlvv.end_date_active >= gd_sysdate))
      AND     ROWNUM           = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_ng_data,
                                              gv_c_tkn_item,
                                              gv_c_format_type,
                                              gv_c_tkn_value,
                                              in_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***  
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾(L-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
      in_file_id      IN  VARCHAR2     -- �t�@�C��ID
    , ov_errbuf       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    lv_line       VARCHAR2(32767);    -- ���s�R�[�h���̏��
    ln_col        NUMBER;             -- �J����
    lb_col        BOOLEAN  := TRUE;   -- �J�����쐬�p��
    ln_length     NUMBER;             -- �����ۊǗp
    ln_target_cnt NUMBER;             -- �ꎞ�\�i�[�p
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;  -- �s�e�[�u���i�[�̈�
--
    -- �ꎞ�\�i�[�p
    TYPE l_line_type                  IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
    TYPE l_record_id_type             IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE l_tmp_ship_number_type       IS TABLE OF VARCHAR2(512) INDEX BY BINARY_INTEGER;
    TYPE l_mov_type_type              IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_instr_post_cd_type         IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_shipped_locat_cd_type      IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_ship_to_locat_cd_type      IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_schedule_ship_date_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_schedule_arrival_date_type IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_freight_charge_cls_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_freight_carrier_cd_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_weight_capacity_cls_type   IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_product_flg_type           IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_mov_line_if_id_type        IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_mov_line_hdr_if_id_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_item_cd_type               IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_designated_prod_date_type  IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_first_instruct_qty_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
--
    l_tmp_ship_number_tab             l_tmp_ship_number_type;       -- ���`�[�ԍ�
    l_mov_type_tab                    l_mov_type_type;              -- �ړ��^�C�v
    l_instr_post_cd_tab               l_instr_post_cd_type;         -- �w������
    l_shipped_locat_cd_tab            l_shipped_locat_cd_type;      -- �o�Ɍ��ۊǏꏊ
    l_ship_to_locat_cd_tab            l_ship_to_locat_cd_type;      -- ���ɐ�ۊǏꏊ
    l_schedule_ship_date_tab          l_schedule_ship_date_type;    -- �o�ɗ\���
    l_schedule_arrival_date_tab       l_schedule_arrival_date_type; -- ���ɗ\���
    l_freight_charge_cls_tab          l_freight_charge_cls_type;    -- �^���敪
    l_freight_carrier_cd_tab          l_freight_carrier_cd_type;    -- �^���Ǝ�
    l_weight_capacity_cls_tab         l_weight_capacity_cls_type;   -- �d�ʗe�ϋ敪
    l_product_flg_tab                 l_product_flg_type;           -- ���i���ʋ敪
    l_mov_line_if_id_tab              l_mov_line_if_id_type;        -- �ړ�����IF_ID
    l_mov_line_hdr_if_id_tab          l_mov_line_hdr_if_id_type;    -- �ړ��w�b�_IF_ID
    l_item_cd_tab                     l_item_cd_type;               -- �i��
    l_designated_prod_date_tab        l_designated_prod_date_type;  -- �w�萻����
    l_first_instruct_qty_tab          l_first_instruct_qty_type;    -- ����w������
    l_line_tab                        l_line_type;                  -- �s���e
    l_record_id_tab                   l_record_id_type;             -- ���R�[�hID
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �ړ��w���C���^�t�F�[�X�ꎞ�\�擾
    CURSOR xxinv_tmp_mov_instr_if_cur IS
      SELECT  REPLACE(xtmif.temp_ship_num, 'NULL', '')                temp_ship_num               -- ���`�[�ԍ�
            , REPLACE(xtmif.product_flg, 'NULL', '')                  product_flg                 -- ���i���ʋ敪
            , REPLACE(xtmif.instruction_post_code, 'NULL', '')        instruction_post_code       -- �ړ��w�������R�[�h
            , REPLACE(xtmif.mov_type, 'NULL', '')                     mov_type                    -- �ړ��^�C�v�R�[�h
            , REPLACE(xtmif.shipped_locat_code, 'NULL', '')           shipped_locat_code          -- �o�Ɍ��R�[�h
            , REPLACE(xtmif.ship_to_locat_code, 'NULL', '')           ship_to_locat_code          -- ���ɐ�R�[�h
            , REPLACE(xtmif.schedule_ship_date, 'NULL', '')           schedule_ship_date          -- �o�ɓ�
            , REPLACE(xtmif.schedule_arrival_date, 'NULL', '')        schedule_arrival_date       -- ����
            , REPLACE(xtmif.freight_charge_class, 'NULL', '')         freight_charge_class        -- �^���敪
            , REPLACE(xtmif.freight_carrier_code, 'NULL', '')         freight_carrier_code        -- �^���Ǝ҃R�[�h
            , REPLACE(xtmif.weight_capacity_class, 'NULL', '')        weight_capacity_class       -- �d�ʗe�ϋ敪
            , REPLACE(xtmif.item_code, 'NULL', '')                    item_code                   -- �i�ڃR�[�h
            , REPLACE(xtmif.designated_production_date, 'NULL', '')   designated_production_date  -- �w�萻����
            , REPLACE(xtmif.first_instruct_qty, 'NULL', '')           first_instruct_qty          -- �w������
            , xtmif.line                                              line                        -- �s���e
      FROM  xxinv_tmp_mov_instr_if xtmif
      WHERE xtmif.file_id = in_file_id
      ORDER BY xtmif.temp_ship_num
             , xtmif.item_code
      ;             
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ϐ�������
    ln_target_cnt := 0;
--
    ------------------------------------
    -- �t�@�C���A�b�v���[�hIF�f�[�^�擾
    ------------------------------------
    -- �s���b�N����
    SELECT  xmf.file_name     -- �t�@�C����
          , xmf.created_by    -- �쐬��
          , xmf.creation_date -- �쐬��
    INTO    gv_file_name
          , gn_created_by
          , gd_creation_date
    FROM  xxinv_mrp_file_ul_interface xmf
    WHERE xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT
    ;
--
    -- �f�[�^�擾
    xxcmn_common3_pkg.blob_to_varchar2(
        in_file_id          -- �t�@�C��ID
      , lt_file_line_data   -- VARCHAR2�ϊ���f�[�^
      , lv_errbuf           -- �G���[�E���b�Z�[�W         (�Œ�)
      , lv_retcode          -- ���^�[���E�R�[�h           (�Œ�)
      , lv_errmsg           -- ���[�U�E�G���[�E���b�Z�[�W (�Œ�)
      );
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �^�C�g���s�̂݁A�܂���2�s�ڂ����s�݂̂̏ꍇ
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(  gv_c_msg_kbn
                                            , gv_c_msg_ng_data
                                            , gv_c_tkn_item
                                            , gv_c_file_id_name
                                            , gv_c_tkn_value
                                            , in_file_id
                                            );
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    ---------------------------------------------------
    -- PL/SQL�\�i�[����(2�s�ڈȍ~)
    ---------------------------------------------------
    <<line_loop>>
    FOR ln_index IN 2..lt_file_line_data.LAST LOOP
--
      -- �Ώی����J�E���g
      ln_target_cnt := ln_target_cnt + 1;
--
      -- �s���ɍ�Ɨ̈�Ɋi�[
      lv_line := lt_file_line_data(ln_index);
--
      -- �s���e��line�Ɋi�[
      l_line_tab(ln_target_cnt)       := lv_line;
--
      -- ���R�[�hID�i�[
      l_record_id_tab(ln_target_cnt)  := ln_target_cnt;
--
      -- �J�����ԍ�������
      ln_col  := 0;     -- �J����
      lb_col  := TRUE;  -- �J�����쐬�p��
--
      -------------------------------------
      -- �J���}���ɕ�������
      -------------------------------------
      <<comma_loop>>
      LOOP
--
        -- �Ō�̍��ڂ���̏ꍇ�I�����Ȃ�
        IF (ln_col = 13) AND (lv_line IS NULL) THEN
          NULL;
        ELSE
          -- lv_line�̒�����0�Ȃ�I��
          EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
        END IF;
--
        -- �J�����ԍ����J�E���g
        ln_col := ln_col + 1;
--
        -- �J���}�̈ʒu���擾
        ln_length := INSTR(lv_line, gv_c_comma);
--
        -- �J���}���Ȃ�
        IF (ln_length = 0) THEN
          IF (ln_col <= 13) THEN
            lb_col    := TRUE;
          ELSE
            ln_length := LENGTH(lv_line);
            lb_col    := FALSE;
          END IF;
        -- �J���}������
        ELSE
          ln_length := ln_length - 1;
          lb_col    := TRUE;
        END IF;
--
        -- PL/SQL�\�̊e���ڋy�шꎞ�\�p�z��Ɋi�[
        IF (ln_col = 1) THEN
          -- ���`�[�ԍ�
          l_tmp_ship_number_tab(ln_target_cnt)        := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 2) THEN
          -- ���i���ʋ敪
          l_product_flg_tab(ln_target_cnt)            := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 3) THEN
          -- �ړ��w�������R�[�h
          l_instr_post_cd_tab(ln_target_cnt)          := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 4) THEN
          -- �ړ��^�C�v�R�[�h
          l_mov_type_tab(ln_target_cnt)               := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 5) THEN
          -- �o�Ɍ��R�[�h
          l_shipped_locat_cd_tab(ln_target_cnt)       := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 6) THEN
          -- ���ɐ�R�[�h
          l_ship_to_locat_cd_tab(ln_target_cnt)       := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 7) THEN
          -- �o�ɓ�
          l_schedule_ship_date_tab(ln_target_cnt)     := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 8) THEN
          -- ����
          l_schedule_arrival_date_tab(ln_target_cnt)  := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 9) THEN
          -- �^���敪
          l_freight_charge_cls_tab(ln_target_cnt)     := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 10) THEN
          -- �^���Ǝ҃R�[�h
          l_freight_carrier_cd_tab(ln_target_cnt)     := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 11) THEN
          -- �d�ʗe�ϋ敪
          l_weight_capacity_cls_tab(ln_target_cnt)    := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 12) THEN
          -- �i�ڃR�[�h
          l_item_cd_tab(ln_target_cnt)                := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 13) THEN
          -- �w�萻����
          l_designated_prod_date_tab(ln_target_cnt)   := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 14) THEN
          -- �w������
          l_first_instruct_qty_tab(ln_target_cnt)     := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
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
--
    END LOOP line_loop;
--
    --------------------------------------
    -- �ړ��w���C���^�t�F�[�X�ꎞ�\�Ɋi�[
    --------------------------------------
    FORALL rec_cnt IN 1..ln_target_cnt
    INSERT INTO xxinv.xxinv_tmp_mov_instr_if(
        file_id                   
      , record_id                 
      , temp_ship_num             
      , product_flg               
      , instruction_post_code     
      , mov_type                  
      , shipped_locat_code        
      , ship_to_locat_code        
      , schedule_ship_date        
      , schedule_arrival_date     
      , freight_charge_class      
      , freight_carrier_code      
      , weight_capacity_class     
      , item_code                 
      , designated_production_date
      , first_instruct_qty        
      , line
    ) VALUES (
        in_file_id                            -- �t�@�C��ID
      , l_record_id_tab(rec_cnt)              -- ���R�[�hID
      , l_tmp_ship_number_tab(rec_cnt)        -- ���`�[�ԍ�
      , l_product_flg_tab(rec_cnt)            -- ���i���ʋ敪
      , l_instr_post_cd_tab(rec_cnt)          -- �w������
      , l_mov_type_tab(rec_cnt)               -- �ړ��^�C�v
      , l_shipped_locat_cd_tab(rec_cnt)       -- �o�Ɍ��ۊǏꏊ
      , l_ship_to_locat_cd_tab(rec_cnt)       -- ���ɐ�ۊǏꏊ
      , l_schedule_ship_date_tab(rec_cnt)     -- �o�ɗ\���
      , l_schedule_arrival_date_tab(rec_cnt)  -- ���ɗ\���
      , l_freight_charge_cls_tab(rec_cnt)     -- �^���敪
      , l_freight_carrier_cd_tab(rec_cnt)     -- �^���Ǝ�
      , l_weight_capacity_cls_tab(rec_cnt)    -- �d�ʗe�ϋ敪
      , l_item_cd_tab(rec_cnt)                -- �i��
      , l_designated_prod_date_tab(rec_cnt)   -- �w�萻����
      , l_first_instruct_qty_tab(rec_cnt)     -- ����w������
      , l_line_tab(rec_cnt)                   -- �s���e
    );
--
    --------------------------------------
    -- PL/SQL�\�Ɋi�[
    --------------------------------------
    <<set_data_loop>>
    FOR cur_rec IN xxinv_tmp_mov_instr_if_cur LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ���`�[�ԍ�
      g_file_data_tab(gn_target_cnt).temp_ship_no               := cur_rec.temp_ship_num;
      -- ���i���ʋ敪
      g_file_data_tab(gn_target_cnt).product_flg                := cur_rec.product_flg;
      -- �ړ��w�������R�[�h
      g_file_data_tab(gn_target_cnt).instr_post_cd              := cur_rec.instruction_post_code;
      -- �ړ��^�C�v�R�[�h
      g_file_data_tab(gn_target_cnt).mov_type                   := cur_rec.mov_type;
      -- �o�Ɍ��R�[�h
      g_file_data_tab(gn_target_cnt).shipped_locat_cd           := cur_rec.shipped_locat_code;
      -- ���ɐ�R�[�h
      g_file_data_tab(gn_target_cnt).ship_to_locat_cd           := cur_rec.ship_to_locat_code;
      -- �o�ɓ�
      g_file_data_tab(gn_target_cnt).schedule_ship_date         := cur_rec.schedule_ship_date;
      -- ����
      g_file_data_tab(gn_target_cnt).schedule_arrival_date      := cur_rec.schedule_arrival_date;
      -- �^���敪
      g_file_data_tab(gn_target_cnt).freight_charge_cls         := cur_rec.freight_charge_class;
      -- �^���Ǝ҃R�[�h
      g_file_data_tab(gn_target_cnt).freight_carrier_cd         := cur_rec.freight_carrier_code;
      -- �d�ʗe�ϋ敪
      g_file_data_tab(gn_target_cnt).weight_capacity_cls        := cur_rec.weight_capacity_class;
      -- �i�ڃR�[�h
      g_file_data_tab(gn_target_cnt).item_cd                    := cur_rec.item_code;
      -- �w�萻����
      g_file_data_tab(gn_target_cnt).designated_production_date := cur_rec.designated_production_date;
      -- �w������
      g_file_data_tab(gn_target_cnt).first_instruct_qty       := cur_rec.first_instruct_qty;
      -- �s���e
      g_file_data_tab(gn_target_cnt).line                       := cur_rec.line;
--
    END LOOP set_data_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(  gv_c_msg_kbn
                                            , gv_c_msg_ng_rock
                                            , gv_c_tkn_table
                                            , gv_c_xxinv_mrp_file_ul_name
                                            );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(  gv_c_msg_kbn
                                            , gv_c_msg_ng_data
                                            , gv_c_tkn_item
                                            , gv_c_file_id_name
                                            , gv_c_tkn_value
                                            , in_file_id
                                            );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : validity_check
   * Description      : �Ó����`�F�b�N(L-3,4,5)
   ***********************************************************************************/
  PROCEDURE validity_check(
      ov_errbuf       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validity_check'; -- �v���O������
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
    cn_c_col          CONSTANT NUMBER       := 14;  -- �����ڐ�
    cv_continues      CONSTANT VARCHAR2(1)  := '0'; -- �`�F�b�N�p��
    cv_skip           CONSTANT VARCHAR2(1)  := '1'; -- �`�F�b�N�X�L�b�v
    cn_first          CONSTANT NUMBER       := 1;   -- ���ڂ̍ŏ�
--
    -- *** ���[�J���ϐ� ***
    lv_line_feed                  VARCHAR2(1);      -- ���s�R�[�h
    lv_log_data                   VARCHAR2(32767);  -- LOG�f�[�^���ޔ�p
    ln_item_cnt                   NUMBER;           -- ����w�b�_�`�F�b�N�p
    -- ����w�b�_�`�F�b�N�p�ϐ�
    lv_pre_temp_ship_no           VARCHAR2(32767);  -- ���`�[�ԍ�
    lv_pre_product_flg            VARCHAR2(32767);  -- ���i���ʋ敪
    lv_pre_instr_post_cd          VARCHAR2(32767);  -- �ړ��w�������R�[�h
    lv_pre_mov_type               VARCHAR2(32767);  -- �ړ��^�C�v�R�[�h
    lv_pre_shipped_locat_cd       VARCHAR2(32767);  -- �o�Ɍ��R�[�h
    lv_pre_ship_to_locat_cd       VARCHAR2(32767);  -- ���ɐ�R�[�h
    lv_pre_schedule_ship_date     VARCHAR2(32767);  -- �o�ɓ�
    lv_pre_schedule_arrival_date  VARCHAR2(32767);  -- ����
    lv_pre_freight_charge_cls     VARCHAR2(32767);  -- �^���敪
    lv_pre_freight_carrier_cd     VARCHAR2(32767);  -- �^���Ǝ҃R�[�h
    lv_pre_weight_capacity_cls    VARCHAR2(32767);  -- �d�ʗe�ϋ敪
--
    lv_continues_flag             VARCHAR2(1);
    lv_header_item                VARCHAR2(32767);  -- �w�b�_�[����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ������
    gv_check_proc_retcode := gv_status_normal;  -- �Ó����`�F�b�N�X�e�[�^�X
    lv_line_feed          := CHR(10);           -- ���s�R�[�h
    -- ����w�b�_�`�F�b�N�p
    ln_item_cnt                   := 0;
    lv_pre_temp_ship_no           := NULL;
    lv_pre_product_flg            := NULL;
    lv_pre_instr_post_cd          := NULL;
    lv_pre_mov_type               := NULL;
    lv_pre_shipped_locat_cd       := NULL;
    lv_pre_ship_to_locat_cd       := NULL;
    lv_pre_schedule_ship_date     := NULL;
    lv_pre_schedule_arrival_date  := NULL;
    lv_pre_freight_charge_cls     := NULL;
    lv_pre_freight_carrier_cd     := NULL;
    lv_pre_weight_capacity_cls    := NULL;
    -- �����p���t���O
    lv_continues_flag             := cv_continues;  -- �p��
--
    -- ========================================
    --  �擾�������R�[�h���ɍ��ڃ`�F�b�N���s��
    -- ========================================
    <<check_loop>>
    FOR ln_index IN 1..g_file_data_tab.LAST LOOP
--
      -- ==================
      --  ���ڐ��`�F�b�N
      -- ==================
      -- (�s�S�̂̒����|�s����J���}�𔲂����������J���}�̐�) <> (�����ȍ��ڐ��|�P�������ȃJ���}�̐�)
      IF ((NVL(LENGTH(g_file_data_tab(ln_index).line), 0) 
          - NVL(LENGTH(REPLACE(g_file_data_tab(ln_index).line, gv_c_comma, NULL)), 0))
          <> (cn_c_col - 1))
      THEN
--
        g_file_data_tab(ln_index).err_message :=    gv_c_err_msg_space
                                                ||  gv_c_err_msg_space
                                                ||  xxcmn_common_pkg.get_msg( gv_c_msg_kbn
                                                                            , gv_c_msg_ng_format
                                                                            )
                                                ||  lv_line_feed;
      ELSE
--
        -- ====================
        --  ����w�b�_�`�F�b�N
        -- ====================
        -- ���`�[�ԍ�������
        IF  (lv_pre_temp_ship_no = g_file_data_tab(ln_index).temp_ship_no) THEN
--
          IF    (lv_pre_product_flg           = g_file_data_tab(ln_index).product_flg)
            AND (lv_pre_instr_post_cd         = g_file_data_tab(ln_index).instr_post_cd)
            AND (lv_pre_mov_type              = g_file_data_tab(ln_index).mov_type)
            AND (lv_pre_shipped_locat_cd      = g_file_data_tab(ln_index).shipped_locat_cd)
            AND (lv_pre_ship_to_locat_cd      = g_file_data_tab(ln_index).ship_to_locat_cd)
            AND (lv_pre_schedule_ship_date    = g_file_data_tab(ln_index).schedule_ship_date)
            AND (lv_pre_schedule_arrival_date = g_file_data_tab(ln_index).schedule_arrival_date)
            AND (lv_pre_freight_charge_cls    = g_file_data_tab(ln_index).freight_charge_cls)
            AND (
                  (lv_pre_freight_carrier_cd IS NULL AND g_file_data_tab(ln_index).freight_carrier_cd IS NULL)
                OR 
                  (lv_pre_freight_carrier_cd = g_file_data_tab(ln_index).freight_carrier_cd)
                )
            AND (lv_pre_weight_capacity_cls   = g_file_data_tab(ln_index).weight_capacity_cls)
          THEN
--
            -- �w�b�_���̑S�Ă̍��ڂ�����̏ꍇ
            -- �`�F�b�N�����p��
            lv_continues_flag := cv_continues;
--
          ELSE
--
            -- �w�b�_���̍��ڂ���ł��قȂ�ꍇ
            -- �`�F�b�N����SKIP
            lv_continues_flag := cv_skip;
--
            -- �o�͗p�ϐ���������
            lv_header_item  := NULL;
            ln_item_cnt     := 0;
--
            -- ���i���ʋ敪���قȂ�ꍇ
            IF (lv_pre_product_flg <> g_file_data_tab(ln_index).product_flg) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              lv_header_item := gv_c_product_flg;
--
            END IF;
--
            -- �ړ��w�������R�[�h���قȂ�ꍇ
            IF (lv_pre_instr_post_cd <> g_file_data_tab(ln_index).instr_post_cd) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_instr_post_cd;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_instr_post_cd;
--
              END IF;
--
            END IF;
--
            -- �ړ��^�C�v�R�[�h���قȂ�ꍇ
            IF (lv_pre_mov_type <> g_file_data_tab(ln_index).mov_type) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_mov_type;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma ||gv_c_mov_type;
--
              END IF;
--
            END IF;
--
            -- �o�Ɍ��R�[�h���قȂ�ꍇ
            IF (lv_pre_shipped_locat_cd <> g_file_data_tab(ln_index).shipped_locat_cd) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_shipped_locat_cd;
--
              ELSE  
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_shipped_locat_cd;
--
              END IF;
--
            END IF;
--
            -- ���ɐ�R�[�h���قȂ�ꍇ
            IF (lv_pre_ship_to_locat_cd <> g_file_data_tab(ln_index).ship_to_locat_cd) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_ship_to_locat_cd;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma ||gv_c_ship_to_locat_cd;
--
              END IF;
--
            END IF;
--
            -- �o�ɓ����قȂ�ꍇ
            IF (lv_pre_schedule_ship_date <> g_file_data_tab(ln_index).schedule_ship_date) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_schedule_ship_date;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_schedule_ship_date;
--
              END IF;
--
            END IF;
--
            -- �������قȂ�ꍇ
            IF (lv_pre_schedule_arrival_date <> g_file_data_tab(ln_index).schedule_arrival_date) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_schedule_arrival_date;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_schedule_arrival_date;
--
              END IF;
--
            END IF;
--
            -- �^���敪���قȂ�ꍇ
            IF (lv_pre_freight_charge_cls <> g_file_data_tab(ln_index).freight_charge_cls) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_freight_charge_cls;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_freight_charge_cls;
--
              END IF;
--
            END IF;
--
            -- �^���Ǝ҃R�[�h���قȂ�ꍇ
            IF (lv_pre_freight_carrier_cd <> g_file_data_tab(ln_index).freight_carrier_cd) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_freight_carrier_cd;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_freight_carrier_cd;
--
              END IF;
--
            END IF;
--
            -- �d�ʗe�ϋ敪���قȂ�ꍇ
            IF (lv_pre_weight_capacity_cls <> g_file_data_tab(ln_index).weight_capacity_cls) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_weight_capacity_cls;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_weight_capacity_cls;
--
              END IF;
--
            END IF;
--
            -- �G���[�o��
            g_file_data_tab(ln_index).err_message :=    gv_c_err_msg_space
                                                    ||  gv_c_err_msg_space
                                                    ||  xxcmn_common_pkg.get_msg(  gv_c_msg_kbn
                                                            , gv_c_msg_ng_head_item
                                                            , gv_c_tkn_item
                                                            , lv_header_item
                                                        )
                                                    ||  lv_line_feed
                                                   ;
--
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
--
          END IF;
--
        -- ���`�[�ԍ����قȂ�A�������͍ŏ��̃��R�[�h
        ELSIF ((lv_pre_temp_ship_no IS NULL) 
            OR (lv_pre_temp_ship_no <> g_file_data_tab(ln_index).temp_ship_no))
        THEN
--
          -- �`�F�b�N�p��
          lv_continues_flag := cv_continues;
--
        END IF;
--
        -- ����w�b�_�`�F�b�N�Ń`�F�b�N�p���ɂȂ����ꍇ
        -- �`�F�b�N�����p��
        IF (lv_continues_flag = cv_continues) THEN
--
          --------------
          -- ���`�[�ԍ�
          --------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_tmp_ship_number                    -- ���`�[�ԍ�
                                              , g_file_data_tab(ln_index).temp_ship_no  -- CSV�f�[�^
                                              , gn_c_tmp_ship_number_len                -- ���ڂ̒���
                                              , NULL                                    -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng            -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2           -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------
          -- ���i���ʋ敪
          ----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_product_flg                        -- ���i���ʋ敪
                                              , g_file_data_tab(ln_index).product_flg   -- CSV�f�[�^
                                              , gn_c_product_flg_len                    -- ���ڂ̒���
                                              , NULL                                    -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng            -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2           -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------------
          -- �ړ��w�������R�[�h
          ----------------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_instr_post_cd                        -- �ړ��w�������R�[�h
                                              , g_file_data_tab(ln_index).instr_post_cd   -- CSV�f�[�^
                                              , gn_c_instr_post_cd_len                    -- ���ڂ̒���
                                              , NULL                                      -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng              -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2             -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          --------------------
          -- �ړ��^�C�v�R�[�h
          --------------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_mov_type                       -- �ړ��^�C�v�R�[�h
                                              , g_file_data_tab(ln_index).mov_type  -- CSV�f�[�^
                                              , gn_c_mov_type_len                   -- ���ڂ̒���
                                              , NULL                                -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng        -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2       -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------
          -- �o�Ɍ��R�[�h
          ----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_shipped_locat_cd                       -- �o�Ɍ��R�[�h
                                              , g_file_data_tab(ln_index).shipped_locat_cd  -- CSV�f�[�^
                                              , gn_c_shipped_locat_cd_len                   -- ���ڂ̒���
                                              , NULL                                        -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng                -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2               -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------
          -- ���ɐ�R�[�h
          ----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_ship_to_locat_cd                       -- ���ɐ�R�[�h
                                              , g_file_data_tab(ln_index).ship_to_locat_cd  -- CSV�f�[�^
                                              , gn_c_ship_to_locat_cd_len                   -- ���ڂ̒���
                                              , NULL                                        -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng                -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2               -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ---------------
          -- �o�ɓ�
          ---------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_schedule_ship_date                       -- �o�ɓ�
                                              , g_file_data_tab(ln_index).schedule_ship_date  -- CSV�f�[�^
                                              , NULL                                          -- ���ڂ̒���
                                              , NULL                                          -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng                  -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_dat                 -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ---------------
          -- ����
          ---------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_schedule_arrival_date                      -- ����
                                              , g_file_data_tab(ln_index).schedule_arrival_date -- CSV�f�[�^
                                              , NULL                                            -- ���ڂ̒���
                                              , NULL                                            -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng                    -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_dat                   -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ---------------
          -- �^���敪
          ---------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_freight_charge_cls                       -- �^���敪
                                              , g_file_data_tab(ln_index).freight_charge_cls  -- CSV�f�[�^
                                              , gn_c_freight_charge_cls_len                   -- ���ڂ̒���
                                              , NULL                                          -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng                  -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2                 -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -------------------
          -- �^���Ǝ҃R�[�h
          -------------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_freight_carrier_cd                       -- �^���Ǝ҃R�[�h
                                              , g_file_data_tab(ln_index).freight_carrier_cd  -- CSV�f�[�^
                                              , gn_c_freight_carrier_cd_len                   -- ���ڂ̒���
                                              , NULL                                          -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ok                  -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2                 -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -----------------
          -- �d�ʗe�ϋ敪
          -----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_weight_capacity_cls                      -- �d�ʗe�ϋ敪
                                              , g_file_data_tab(ln_index).weight_capacity_cls -- CSV�f�[�^
                                              , gn_c_weight_capacity_cls_len                  -- ���ڂ̒���
                                              , NULL                                          -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng                  -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2                 -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------
          -- �i�ڃR�[�h
          ----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_item_cd                      -- �i�ڃR�[�h
                                              , g_file_data_tab(ln_index).item_cd -- CSV�f�[�^
                                              , gn_c_item_cd_len                  -- ���ڂ̒���
                                              , NULL                              -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng      -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_vc2     -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -------------------
          -- �w�萻����
          -------------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_designated_prod_date                             -- �w�萻����
                                              , g_file_data_tab(ln_index).designated_production_date  -- CSV�f�[�^
                                              , NULL                                                  -- ���ڂ̒���
                                              , NULL                                                  -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng                          -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_dat                         -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          --------------
          -- �w������
          --------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_first_instruct_qty                               -- �w������
                                              , g_file_data_tab(ln_index).first_instruct_qty          -- CSV�f�[�^
                                              , NULL                                                  -- ���ڂ̒���
                                              , NULL                                                  -- ���ڂ̒���(�����_)
                                              , xxcmn_common3_pkg.gv_null_ng                          -- �K�{(ng:�K�{�Aok:�C��)
                                              , xxcmn_common3_pkg.gv_attr_num                         -- ����
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        END IF;
--
      END IF;
--
      -- **************************************************
      -- *** �G���[����
      -- **************************************************
      -- �`�F�b�N�G���[����̏ꍇ
      IF (g_file_data_tab(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** �f�[�^���o�͏����i�s�� + SPACE + �s�S�̂̃f�[�^�j
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_c_space || g_file_data_tab(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(g_file_data_tab(ln_index).err_message, lv_line_feed));
        -- �Ó����`�F�b�N�X�e�[�^�X
        gv_check_proc_retcode := gv_status_error;
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
--
      -- �`�F�b�N�G���[�Ȃ��̏ꍇ
      ELSE
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
      -- ����w�b�_�`�F�b�N�p�Ƀf�[�^���i�[
      lv_pre_temp_ship_no           := g_file_data_tab(ln_index).temp_ship_no;
      lv_pre_product_flg            := g_file_data_tab(ln_index).product_flg;
      lv_pre_instr_post_cd          := g_file_data_tab(ln_index).instr_post_cd;
      lv_pre_mov_type               := g_file_data_tab(ln_index).mov_type;
      lv_pre_shipped_locat_cd       := g_file_data_tab(ln_index).shipped_locat_cd;
      lv_pre_ship_to_locat_cd       := g_file_data_tab(ln_index).ship_to_locat_cd;
      lv_pre_schedule_ship_date     := g_file_data_tab(ln_index).schedule_ship_date;
      lv_pre_schedule_arrival_date  := g_file_data_tab(ln_index).schedule_arrival_date;
      lv_pre_freight_charge_cls     := g_file_data_tab(ln_index).freight_charge_cls;
      lv_pre_freight_carrier_cd     := g_file_data_tab(ln_index).freight_carrier_cd;
      lv_pre_weight_capacity_cls    := g_file_data_tab(ln_index).weight_capacity_cls;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***  
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validity_check;
--
  /**********************************************************************************
   * Procedure Name   : set_data
   * Description      : �o�^�f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE set_data(
      ov_errbuf       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data'; -- �v���O������
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
    ln_header_id        NUMBER;           -- �w�b�_ID
    ln_line_id          NUMBER;           -- ����ID
    lv_pre_temp_ship_no VARCHAR2(32767);  -- ���`�[�ԍ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --------------------
    -- ����������
    --------------------
    gn_header_count :=  0;
    gn_line_count   :=  0;
--
    -----------------------
    -- ���[�J���ϐ�������
    -----------------------
    ln_header_id        :=  0;
    ln_line_id          :=  0;
    lv_pre_temp_ship_no :=  NULL;
--
    ------------------------
    -- �o�^�pPL/SQL�\�ҏW
    ------------------------
    <<data_loop>>
    FOR ln_index IN 1..g_file_data_tab.LAST LOOP
--
      --------------------
      -- �w�b�_���ڐݒ�
      --------------------
      -- �ŏ��̃��R�[�h�y�щ��`�[�ԍ����u���C�N�����ꍇ�A�w�b�_���ڂ�o�^����
      IF ((lv_pre_temp_ship_no IS NULL) 
          OR (lv_pre_temp_ship_no <> g_file_data_tab(ln_index).temp_ship_no)) 
      THEN
--
        -- �w�b�_�����C���N�������g
        gn_header_count := gn_header_count + 1;
--
        -- �w�b�_�̔�
        SELECT  xxinv_mov_instr_hdr_if_s1.NEXTVAL
        INTO    ln_header_id
        FROM    dual
        ;
--
        -- �w�b�_���ݒ�
        g_mov_hdr_if_id_tab(gn_header_count)         := ln_header_id;                                     -- �ړ��w�b�_IF_ID
        g_tmp_ship_number_tab(gn_header_count)       := g_file_data_tab(ln_index).temp_ship_no;           -- ���`�[�ԍ�
        g_mov_type_tab(gn_header_count)              := g_file_data_tab(ln_index).mov_type;               -- �ړ��^�C�v
        g_instr_post_cd_tab(gn_header_count)         := g_file_data_tab(ln_index).instr_post_cd;          -- �w������
        g_shipped_locat_cd_tab(gn_header_count)      := g_file_data_tab(ln_index).shipped_locat_cd;       -- �o�Ɍ��ۊǏꏊ
        g_ship_to_locat_cd_tab(gn_header_count)      := g_file_data_tab(ln_index).ship_to_locat_cd;       -- ���ɐ�ۊǏꏊ
        g_schedule_ship_date_tab(gn_header_count)    
          := FND_DATE.STRING_TO_DATE(g_file_data_tab(ln_index).schedule_ship_date, 'YYYY/MM/DD');         -- �o�ɗ\���
        g_schedule_arrival_date_tab(gn_header_count) 
          := FND_DATE.STRING_TO_DATE(g_file_data_tab(ln_index).schedule_arrival_date, 'YYYY/MM/DD');      -- ���ɗ\���
        g_freight_charge_cls_tab(gn_header_count)    := g_file_data_tab(ln_index).freight_charge_cls;     -- �^���敪
        g_freight_carrier_cd_tab(gn_header_count)    := g_file_data_tab(ln_index).freight_carrier_cd;     -- �^���Ǝ�
        g_weight_capacity_cls_tab(gn_header_count)   := g_file_data_tab(ln_index).weight_capacity_cls;    -- �d�ʗe�ϋ敪
        g_product_flg_tab(gn_header_count)           := g_file_data_tab(ln_index).product_flg;            -- ���i���ʋ敪
--
      END IF;
--
      -----------------
      -- ���׍��ڐݒ�
      -----------------
--
      -- ���׌����C���N�������g
      gn_line_count := gn_line_count + 1;
--
      -- ����ID�̔�
      SELECT  xxinv_mov_instr_line_if_s1.NEXTVAL
      INTO    ln_line_id
      FROM    dual
      ;
--
      -- ���׏��ݒ�
      g_mov_line_if_id_tab(gn_line_count)       := ln_line_id;                                              -- �ړ�����IF_ID
      g_mov_line_hdr_if_id_tab(gn_line_count)   := ln_header_id;                                            -- �ړ��w�b�_IF_ID
      g_item_cd_tab(gn_line_count)              := g_file_data_tab(ln_index).item_cd;                       -- �i��
      g_designated_prod_date_tab(gn_line_count) 
        := FND_DATE.STRING_TO_DATE(g_file_data_tab(ln_index).designated_production_date, 'YYYY/MM/DD');     -- �w�萻����
      g_first_instruct_qty_tab(gn_line_count)   := TO_NUMBER(g_file_data_tab(ln_index).first_instruct_qty); -- ����w������
--
      -- ���`�[�ԍ��𔻒�p�ϐ��Ɋi�[
      lv_pre_temp_ship_no := g_file_data_tab(ln_index).temp_ship_no;
--
    END LOOP data_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***  
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_header
   * Description      : �w�b�_�f�[�^�o�^(L-6)
   ***********************************************************************************/
  PROCEDURE insert_header(
      ov_errbuf       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_header'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -----------------------------------------------
    -- �ړ��w���w�b�_�C���^�t�F�[�X(�A�h�I��) �o�^
    -----------------------------------------------
    FORALL rec_cnt IN 1..gn_header_count
      INSERT INTO xxinv_mov_instr_headers_if(
          mov_hdr_if_id                         -- �ړ��w�b�_IF_ID
        , temp_ship_num                         -- ���`�[�ԍ�
        , mov_type                              -- �ړ��^�C�v
        , instruction_post_code                 -- �w������
        , shipped_locat_code                    -- �o�Ɍ��ۊǏꏊ
        , ship_to_locat_code                    -- ���ɐ�ۊǏꏊ
        , schedule_ship_date                    -- �o�ɗ\���
        , schedule_arrival_date                 -- ���ɗ\���
        , freight_charge_class                  -- �^���敪
        , freight_carrier_code                  -- �^���Ǝ�
        , weight_capacity_class                 -- �d�ʗe�ϋ敪
        , product_flg                           -- ���i���ʋ敪
        , created_by                            -- �쐬��
        , creation_date                         -- �쐬��
        , last_updated_by                       -- �ŏI�X�V��
        , last_update_date                      -- �ŏI�X�V��
        , last_update_login                     -- �ŏI�X�V���O�C��
        , request_id                            -- �v��ID
        , program_application_id                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                            -- �R���J�����g�E�v���O����ID
        , program_update_date                   -- �v���O�����X�V��
      ) VALUES (
          g_mov_hdr_if_id_tab(rec_cnt)          -- �ړ��w�b�_IF_ID
        , g_tmp_ship_number_tab(rec_cnt)        -- ���`�[�ԍ�
        , g_mov_type_tab(rec_cnt)               -- �ړ��^�C�v
        , g_instr_post_cd_tab(rec_cnt)          -- �w������
        , g_shipped_locat_cd_tab(rec_cnt)       -- �o�Ɍ��ۊǏꏊ
        , g_ship_to_locat_cd_tab(rec_cnt)       -- ���ɐ�ۊǏꏊ
        , g_schedule_ship_date_tab(rec_cnt)     -- �o�ɗ\���
        , g_schedule_arrival_date_tab(rec_cnt)  -- ���ɗ\���
        , g_freight_charge_cls_tab(rec_cnt)     -- �^���敪
        , g_freight_carrier_cd_tab(rec_cnt)     -- �^���Ǝ�
        , g_weight_capacity_cls_tab(rec_cnt)    -- �d�ʗe�ϋ敪
        , g_product_flg_tab(rec_cnt)            -- ���i���ʋ敪
        , gn_user_id                            -- �쐬��
        , gd_sysdate                            -- �쐬��
        , gn_user_id                            -- �ŏI�X�V��
        , gd_sysdate                            -- �ŏI�X�V��
        , gn_login_id                           -- �ŏI�X�V���O�C��
        , gn_conc_request_id                    -- �v��ID
        , gn_prog_appl_id                       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , gn_conc_program_id                    -- �R���J�����g�E�v���O����ID
        , gd_sysdate                            -- �v���O�����X�V��
      );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***  
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_header;
--
  /**********************************************************************************
   * Procedure Name   : insert_lines
   * Description      : ���׃f�[�^�o�^(L-7)
   ***********************************************************************************/
  PROCEDURE insert_lines(
      ov_errbuf       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_lines'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -----------------------------------------------
    -- �ړ��w�����׃C���^�t�F�[�X(�A�h�I��) �o�^
    -----------------------------------------------
    FORALL rec_cnt IN 1..gn_line_count
      INSERT INTO xxinv_mov_instr_lines_if(
          mov_line_if_id                        -- �ړ�����IF_ID
        , mov_hdr_if_id                         -- �ړ��w�b�_IF_ID
        , item_code                             -- �i��
        , designated_production_date            -- �w�萻����
        , first_instruct_qty                    -- ����w������
        , created_by                            -- �쐬��
        , creation_date                         -- �쐬��
        , last_updated_by                       -- �ŏI�X�V��
        , last_update_date                      -- �ŏI�X�V��
        , last_update_login                     -- �ŏI�X�V���O�C��
        , request_id                            -- �v��ID
        , program_application_id                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                            -- �R���J�����g�E�v���O����ID
        , program_update_date                   -- �v���O�����X�V��
      ) VALUES (
          g_mov_line_if_id_tab(rec_cnt)         -- �ړ�����IF_ID
        , g_mov_line_hdr_if_id_tab(rec_cnt)     -- �ړ��w�b�_IF_ID
        , g_item_cd_tab(rec_cnt)                -- �i��
        , g_designated_prod_date_tab(rec_cnt)   -- �w�萻����
        , g_first_instruct_qty_tab(rec_cnt)     -- ����w������
        , gn_user_id                            -- �쐬��
        , gd_sysdate                            -- �쐬��
        , gn_user_id                            -- �ŏI�X�V��
        , gd_sysdate                            -- �ŏI�X�V��
        , gn_login_id                           -- �ŏI�X�V���O�C��
        , gn_conc_request_id                    -- �v��ID
        , gn_prog_appl_id                       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , gn_conc_program_id                    -- �R���J�����g�E�v���O����ID
        , gd_sysdate                            -- �v���O�����X�V��
      );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***  
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_lines;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      in_file_id      IN  NUMBER      --   �t�@�C���h�c
    , in_file_format  IN  VARCHAR2    --   �t�H�[�}�b�g�p�^�[��
    , ov_errbuf       OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- �Ó����`�F�b�N�X�e�[�^�X ������
    gv_check_proc_retcode := gv_status_normal;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �֘A�f�[�^�擾�iL-1�j
    -- ===============================
    init(
        in_file_format  -- �t�H�[�}�b�g�p�^�[��
      , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾�iL-2�j
    -- ===================================================
    get_upload_data(
        in_file_id      -- �t�@�C��ID
      , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W START  ###################################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_file_name,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_upload_date,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_upload_name,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W END   ###################################
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾���ʂ𔻒�
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    END IF;
--
    -- =========================
    -- �Ó����`�F�b�N(L-3,4,5)
    -- =========================
    validity_check(
        lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
--
      RAISE global_process_expt;
--
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
      -- �Ó����`�F�b�N�ŃG���[�����������ꍇ
      -- ==================
      -- �o�^�f�[�^�ݒ�
      -- ==================
      set_data(
        lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =======================
      -- �w�b�_�f�[�^�o�^(L-6)
      -- =======================
      insert_header(
        lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ======================
      -- ���׃f�[�^�o�^(L-7)
      -- ======================
      insert_lines(
        lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===================================================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜(L-8)
    -- ===================================================
    xxcmn_common3_pkg.delete_fileup_proc(
        in_file_format        -- �t�H�[�}�b�g�p�^�[��
      , gd_sysdate            -- �Ώۓ��t
      , gn_xxinv_purge_term   -- �p�[�W�Ώۊ���
      , lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    IF (lv_retcode = gv_status_error) THEN
      -- �폜�����G���[����RollBack������ׁA�Ó����`�F�b�N�X�e�[�^�X��������
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- �ꎞ�\�f�[�^�폜(L-9)
    -- ===================================================
    DELETE FROM xxinv_tmp_mov_instr_if
    WHERE file_id = in_file_id
    ;
--
    -- �`�F�b�N�����G���[
    IF (gv_check_proc_retcode = gv_status_error) THEN
      -- �Œ�̃G���[���b�Z�[�W�̏o�͂����Ȃ��悤�ɂ���
      lv_errmsg := gv_c_space;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id      IN  VARCHAR2,      --   �t�@�C���h�c
    in_file_format  IN  VARCHAR2       --   �t�H�[�}�b�g�p�^�[��
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
    cv_prg_name         CONSTANT  VARCHAR2(100) :=  'main';             -- �v���O������
    cv_status_code      CONSTANT  VARCHAR2(14)  :=  'CP_STATUS_CODE';   -- �X�e�[�^�X�R�[�h
    cv_userenv          CONSTANT  VARCHAR2(4)   :=  userenv('LANG');    -- USERENV
    cv_msg_kbn          CONSTANT  VARCHAR2(5)   :=  'XXCMN';            -- ���b�Z�[�W
    cv_appl_id          CONSTANT  NUMBER        :=  0;                  -- �A�v���P�[�V����ID
--
    cv_msg_user_name    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00001';  -- ���[�U��
    cv_msg_conc_name    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00002';  -- �R���J�����g��
    cv_msg_start_time   CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-10118';  -- �N������
    cv_msg_separater    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00003';  -- �Z�p���[�^
    cv_msg_standard     CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-10030';  -- �R���J�����g��^���b�Z�[�W
    cv_msg_process_cnt  CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00008';  -- ��������
    cv_msg_success_cnt  CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00009';  -- ��������
    cv_msg_error_cnt    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00010';  -- �G���[����
    cv_msg_skip_cnt     CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00011';  -- �X�L�b�v����
    cv_msg_proc_status  CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00012';  -- �����X�e�[�^�X
--
    -- �g�[�N��
    cv_tkn_user         CONSTANT  VARCHAR2(4)   :=  'USER';
    cv_tkn_conc         CONSTANT  VARCHAR2(4)   :=  'CONC';
    cv_tkn_time         CONSTANT  VARCHAR2(4)   :=  'TIME';
    cv_tkn_count        CONSTANT  VARCHAR2(3)   :=  'CNT';
    cv_tkn_status       CONSTANT  VARCHAR2(6)   :=  'STATUS';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_user_name, cv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_conc_name, cv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_start_time,
                                           cv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_separater);
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        TO_NUMBER(in_file_id)   -- �t�@�C���h�c
      , in_file_format          -- �t�H�[�}�b�g�p�^�[��
      , lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_standard);
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
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_process_cnt, cv_tkn_count, TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_success_cnt, cv_tkn_count, TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_error_cnt, cv_tkn_count, TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_skip_cnt, cv_tkn_count, TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = cv_userenv
    AND    flv.view_application_id = cv_appl_id
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = cv_status_code
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_proc_status, cv_tkn_status,gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal)THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXINV990010C;
/
