CREATE OR REPLACE PACKAGE BODY      XXCMM004A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A12C(body)
 * Description      : �i�ڃ}�X�^IF�o�́iHHT�j
 *                      �c�ƕi�ڂƂ��ēo�^���ꂽ�i�ځi�J�e�S���}�X�^�̏��i���i�敪��2:���i�j�݂̂𒊏o���A
 *                      HHT������CSV�t�@�C����񋟂��܂��B
 * MD.050           : �i�ڃ}�X�^IF�o�́iHHT�j CMM_004_A12
 * Version          : Draft2H
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            ��������(A-1)
 *
 *  submain              ���C�������v���V�[�W��
 *                          �Eproc_init
 *                       �i�ڏ��̎擾(A-2)
 *                       �i�ڃ}�X�^�iHHT�j�o�͏���(A-3)
 *
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                          �Esubmain
 *                       �I������(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/25    1.0   R.Takigawa       main�V�K�쐬
 *  2009/01/28    1.1   R.Takigawa       �Ώۃf�[�^�Ȃ��G���[���폜
 *                                       �X�V���������̌������C��
 *                                       �i�ڋ@�\�萔���ʉ�
 *  2009/01/30    1.2   R.Takigawa       �G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��
 *  2009/02/05    1.3   R.Takigawa       TE070�s��C��
 *  2009/02/10    1.4   R.Takigawa       �o�͌��ʁA���O�ɑΏۊ��Ԃ̕\��
 *  2009/02/10    1.5   R.Takigawa       �擪�Q��(00)���J�b�g(�i�ڃR�[�h)
 *  2009/02/16    1.6   K.Ito            OUTBOUND�pCSV�t�@�C���쐬�ꏊ�A�t�@�C�������ʉ�
 *                                       �t�@�C�������o�͂���悤�ɏC��
 *                                       �R���J�����g�p�����[�^�̒l�Z�b�g�ύX(XXCMN_S_10_DATE -> XXCMN_YYYYMMDD) �p�����[�^���ʂɎ����b���O
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error              CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --WHO�J����
  cn_created_by                CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date             CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by           CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date          CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login         CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id    CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date       CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                  CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                  CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                   VARCHAR2(2000);
  gv_sep_msg                   VARCHAR2(2000);
  gv_exec_user                 VARCHAR2(100);
  gv_conc_name                 VARCHAR2(30);
  gv_conc_status               VARCHAR2(30);
  gn_target_cnt                NUMBER;                    -- �Ώی���
  gn_normal_cnt                NUMBER;                    -- ���팏��
  gn_error_cnt                 NUMBER;                    -- �G���[����
  gn_warn_cnt                  NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt          EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt              EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt       EXCEPTION;
  global_check_lock_expt       EXCEPTION;                 -- ���b�N�擾�G���[
  --
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(30)  := 'XXCMM004A12C';        -- �p�b�P�[�W��
-- Ver1.6 Mod 20090216 START
  cv_appl_name_xxcmm    CONSTANT VARCHAR2(5)   := 'XXCMM';               -- �A�v���P�[�V�����Z�k��
--  cv_app_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';               -- �A�v���P�[�V�����Z�k��
-- Ver1.6 Mod 20090216 END
  -- ���b�Z�[�W
-- Ver1.1
--  cv_msg_xxcmm_00001    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';    -- �Ώۃf�[�^�Ȃ�
-- End1.1
  cv_msg_xxcmm_00002    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';    -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00019    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';    -- �Ώۊ��Ԏw��G���[
--
-- Ver1.6 Add 20090216
  cv_msg_xxcmm_00022    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';    -- CSV�t�@�C�����m�[�g
--
-- Ver1.4 Add �Ώۊ��Ԃ̕\�� 2009/2/10
  cv_msg_xxcmm_00473    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00473';    -- ���̓p�����[�^
-- End1.4
-- Ver1.3 Mod CSV�t�@�C�����݃G���[�̕ύX 2009/2/5
  --cv_msg_xxcmm_00484    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00484';    -- CSV�t�@�C�����݃G���[
  cv_msg_xxcmm_00490    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00490';    -- CSV�t�@�C�����݃G���[
-- End1.3
  cv_msg_xxcmm_00487    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00487';    -- �t�@�C���I�[�v���G���[
  cv_msg_xxcmm_00488    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00488';    -- �t�@�C���������݃G���[
  cv_msg_xxcmm_00489    CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00489';    -- �t�@�C���N���[�Y�G���[
--
  -- �g�[�N��
  cv_tkn_profile        CONSTANT VARCHAR2(10)  := 'NG_PROFILE';          -- �g�[�N���F�v���t�@�C����
  cv_tkn_sqlerrm        CONSTANT VARCHAR2(10)  := 'SQLERRM';             -- �g�[�N���FSQL�G���[
  cv_tkn_start_date     CONSTANT VARCHAR2(10)  := 'START_DATE';          -- �g�[�N���F�Ώۊ��Ԏw��G���[�i�J�n�j
  cv_tkn_last_date      CONSTANT VARCHAR2(10)  := 'LAST_DATE';           -- �g�[�N���F�Ώۊ��Ԏw��G���[�i�I���j
-- Ver1.4 Add �Ώۊ��Ԃ̕\�� 2009/2/10
  cv_tkn_name           CONSTANT VARCHAR2(10)  := 'NAME';                -- �g�[�N���FNAME
  cv_tkn_value          CONSTANT VARCHAR2(10)  := 'VALUE';               -- �g�[�N���FVALUE
-- Ver1.6 Add 20090216
  cv_tkn_file_name      CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- �g�[�N���FSQL�G���[
--
  -- ���͍���
  cv_inp_date_from      CONSTANT VARCHAR2(30)  := '�Ώۊ��ԊJ�n';        -- �Ώۊ��ԊJ�n
  cv_inp_date_to        CONSTANT VARCHAR2(30)  := '�Ώۊ��ԏI��';        -- �Ώۊ��ԏI��
-- End1.4
-- Ver1.1
--  cv_date_format_all    CONSTANT VARCHAR2(20)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_format_all    CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
-- End                                                                   -- �X�V��������
  cv_date_fmt_ymd       CONSTANT VARCHAR2(10)  := 'YYYYMMDD';            -- ���t����
-- Ver1.4 Add �Ώۊ��Ԃ̕\�� 2009/2/10
  cv_date_fmt_std         CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                         -- ���t����
-- End1.4
-- Ver1.6 Mod 20090216
  cv_csv_fl_name        CONSTANT VARCHAR2(30)  := 'XXCMM1_004A12_OUT_FILE';
--  cv_csv_fl_name        CONSTANT VARCHAR2(30)  := 'XXCMM1_004A12_CSV_FILE_FIL';
                                                                         -- �i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C����
-- Ver1.6 Mod 20090216
  cv_csv_fl_dir         CONSTANT VARCHAR2(30)  := 'XXCMM1_HHT_OUT_DIR';
--  cv_csv_fl_dir         CONSTANT VARCHAR2(30)  := 'XXCMM1_004A12_CSV_FILE_DIR';
                                                                         -- �i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C���o�͐�
  cv_user_csv_fl_name   CONSTANT VARCHAR2(100) := '�i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C����';
                                                                         -- �i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C����
  cv_user_csv_fl_dir    CONSTANT VARCHAR2(100) := '�i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C���o�͐�';
                                                                         -- �i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C���o�͐�
  cv_dqu                CONSTANT VARCHAR2(1)   := '"';
  cv_sep                CONSTANT VARCHAR2(1)   := ',';
  cn_tax_rate           CONSTANT NUMBER(4,2)   := 0;                     -- ����ŗ�
  cv_tax_div            CONSTANT VARCHAR2(1)   := '0';                   -- �ŋ敪
-- Ver1.5 Mod �擪�Q��(00)���J�b�g(�i�ځA�e�R�[�h) 2009/2/12
  cv_item_code_cut      CONSTANT VARCHAR2(2)   := '00';                  -- �擪�Q��(00)
-- End
  cv_hon_product_class  CONSTANT VARCHAR2(12)  := '�{�Џ��i�敪';        -- �{�Џ��i�敪
  cv_item_product_class CONSTANT VARCHAR2(12)  := '���i���i�敪';        -- ���i���i�敪
  cv_csv_mode           CONSTANT VARCHAR2(1)   := 'w';                   -- csv�t�@�C���I�[�v�����̃��[�h
  cv_product_div        CONSTANT VARCHAR2(1)   := '2';                   -- ���i(2)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --
  -- �i�ڃ}�X�^IF�o�́iHHT�j���C�A�E�g
  TYPE xxcmm004a12c_rtype IS RECORD
  (
     item_code                  ic_item_mst_b.item_no%TYPE                        -- �i�ڃR�[�h
    ,item_short_name            xxcmn_item_mst_b.item_short_name%TYPE             -- ����
    ,baracha_div                xxcmm_system_items_b.baracha_div%TYPE             -- �o�����敪
    ,sell_start_date            VARCHAR2(240)                                     -- �����J�n���yYYYYMMDD�z
    ,opt_cost_new               VARCHAR2(240)                                     -- �c�ƌ����i�V�j
    ,price_new                  VARCHAR2(240)                                     -- �艿�i�V�j
    ,tax_rate                   NUMBER(4,2)                                       -- ����ŗ�
    ,num_of_cases               VARCHAR2(240)                                     -- �P�[�X����
    ,hon_product_class          mtl_categories.segment1%TYPE                      -- �{�Џ��i�敪
    ,vessel_group               xxcmm_system_items_b.vessel_group%TYPE            -- �e��Q
    ,palette_max_cs_qty         xxcmn_item_mst_b.palette_max_cs_qty%TYPE          -- �z��
    ,palette_max_step_qty       xxcmn_item_mst_b.palette_max_step_qty%TYPE        -- �p���b�g����ő�i��
    ,item_status                xxcmm_system_items_b.item_status%TYPE             -- �i�ڃX�e�[�^�X
    ,tax_div                    VARCHAR2(1)                                       -- �ŋ敪
    ,sales_div                  VARCHAR2(240)                                     -- ����Ώۋ敪
    ,jan_code                   VARCHAR2(240)                                     -- JAN�R�[�h
    ,case_jan_code              xxcmm_system_items_b.case_jan_code%TYPE           -- �P�[�XJAN�R�[�h
    ,parent_item_code           ic_item_mst_b.item_no%TYPE                        -- �e���i�R�[�h
    ,search_update_date         xxcmm_system_items_b.search_update_date%TYPE      -- �����ΏۍX�V��
  );
--
  -- �i�ڃ}�X�^IF�o�́iHHT�j���C�A�E�g �e�[�u���^�C�v
  TYPE xxcmm004a12c_ttype IS TABLE OF xxcmm004a12c_rtype INDEX BY BINARY_INTEGER;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
    gd_process_date                    DATE;                  -- �Ɩ����t
    gv_csv_file_dir                    VARCHAR2(1000);        -- �i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C���o�͐�̎擾
    gv_file_name                       VARCHAR2(30);          -- �i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C����
    gf_file_hand                       UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
    --
    gd_date_from                       DATE;                  -- �Ώۊ��ԁi�J�n�j
    gd_date_to                         DATE;                  -- �Ώۊ��ԁi�I���j
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
     iv_date_from  IN  VARCHAR2             --   �ŏI�X�V���i�J�n�j
    ,iv_date_to    IN  VARCHAR2             --   �ŏI�X�V���i�I���j
    ,ov_errbuf     OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
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
    lv_step                            VARCHAR2(100);         -- �X�e�b�v
    lv_message_token                   VARCHAR2(100);         -- ���b�Z�[�W�g�[�N��
    lb_fexists                         BOOLEAN;               -- �t�@�C�����ݔ��f
    ln_file_length                     NUMBER;                -- �t�@�C���̕�����
    lbi_block_size                     BINARY_INTEGER;        -- �u���b�N�T�C�Y
    --
-- Ver1.6 Del 20090216
---- Ver1.4 Add �Ώۊ��Ԃ̕\�� 2009/2/10
--    lv_date_output                     VARCHAR2(100);         -- �Ώۊ��ԕ\��
---- End1.4
    ld_date_from                       DATE;                  -- �Ώۊ��ԁi�J�n�j
    ld_date_to                         DATE;                  -- �Ώۊ��ԁi�I���j
-- Ver1.6 Add 20090216
    lv_prm_date                        VARCHAR2(1000);        -- �p�����[�^�o�͗p�ϐ�
    lv_csv_file                        VARCHAR2(1000);        -- csv�t�@�C����
    --
    -- *** ���[�U�[��`��O ***
    object_term_expt                   EXCEPTION;             -- �Ώۊ��Ԏw��G���[
    profile_expt                       EXCEPTION;             -- �v���t�@�C���擾��O
    csv_file_exst_expt                 EXCEPTION;             -- CSV�t�@�C�����݃G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --A-1 ��������
    --==============================================================
    --==============================================================
    --A-1.1 �Ɩ����t�擾
    --==============================================================
    lv_step := 'A-1.1';
    lv_message_token := '�Ɩ����t�̎擾';
    gd_process_date  := xxccp_common_pkg2.get_process_date;
    --
    --==============================================================
    --A-1.2 �Ώۊ��ԃ`�F�b�N
    --==============================================================
    lv_step := 'A-1.2';
    lv_message_token := '�Ώۊ��ԃ`�F�b�N';
    ld_date_from := NVL( FND_DATE.CANONICAL_TO_DATE( iv_date_from ), gd_process_date );      -- �Ώۊ��ԁi�J�n�j
    ld_date_to   := NVL( FND_DATE.CANONICAL_TO_DATE( iv_date_to   ), gd_process_date );      -- �Ώۊ��ԁi�I���j
    --
-- Ver1.6 Mod 20090216 START
---- Ver1.4 Add �Ώۊ��Ԃ̕\�� 2009/2/10
--    -- �Ώۊ��ԊJ�n
--    lv_errmsg := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_appl_name_xxcmm,
--                   iv_name         => cv_msg_xxcmm_00473,
--                   iv_token_name1  => cv_tkn_name,
--                   iv_token_value1 => cv_inp_date_from,
--                   iv_token_name2  => cv_tkn_value,
---- Ver1.5 ���̓p�����[�^�̕\�� 2009/2/13
----                   iv_token_value2 => TO_CHAR( ld_date_from, cv_date_fmt_std )
--                   iv_token_value2 => TO_CHAR( FND_DATE.CANONICAL_TO_DATE( iv_date_from ), cv_date_fmt_std )
---- End1.5
--                 );
--    -- �o�͕\��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => lv_errmsg
--    );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.LOG,
--      buff   => lv_errmsg
--    );
--    -- �Ώۊ��ԏI��
--    lv_errmsg := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_appl_name_xxcmm,
--                   iv_name         => cv_msg_xxcmm_00473,
--                   iv_token_name1  => cv_tkn_name,
--                   iv_token_value1 => cv_inp_date_to,
--                   iv_token_name2  => cv_tkn_value,
---- Ver1.5 ���̓p�����[�^�̕\�� 2009/2/13
----                   iv_token_value2 => TO_CHAR( ld_date_to, cv_date_fmt_std )
--                   iv_token_value2 => TO_CHAR( FND_DATE.CANONICAL_TO_DATE( iv_date_to ), cv_date_fmt_std )
---- End1.5
--                 );
--    -- �o�͕\��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => lv_errmsg
--    );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.LOG,
--      buff   => lv_errmsg
--    );
---- End1.4
    -- �Ώۊ��ԊJ�n
    lv_prm_date := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm,
                     iv_name         => cv_msg_xxcmm_00473,
                     iv_token_name1  => cv_tkn_name,
                     iv_token_value1 => cv_inp_date_from,
                     iv_token_name2  => cv_tkn_value,
                     iv_token_value2 => TO_CHAR( FND_DATE.CANONICAL_TO_DATE( iv_date_from ), cv_date_fmt_std )
                   );
    -- �Ώۊ��ԊJ�n�o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_prm_date
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    --
    -- �Ώۊ��ԏI��
    lv_prm_date := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm,
                     iv_name         => cv_msg_xxcmm_00473,
                     iv_token_name1  => cv_tkn_name,
                     iv_token_value1 => cv_inp_date_to,
                     iv_token_name2  => cv_tkn_value,
                     iv_token_value2 => TO_CHAR( FND_DATE.CANONICAL_TO_DATE( iv_date_to ), cv_date_fmt_std )
                   );
    -- �Ώۊ��ԏI���o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_prm_date
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
-- Ver1.6 Mod 20090216 END
    --
    IF ( ld_date_from > ld_date_to ) THEN
      RAISE object_term_expt;
    END IF;
    --
    gd_date_from := ld_date_from;                  -- �Ώۊ��ԁi�J�n�j
    gd_date_to   := ld_date_to;                    -- �Ώۊ��ԁi�I���j
    --
    --==============================================================
    --A-1.3 �v���t�@�C���̎擾
    --==============================================================
    lv_step := 'A-1.3a';
    -- �i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C�����̎擾
    gv_file_name := FND_PROFILE.VALUE( cv_csv_fl_name );
    -- �擾�G���[��
    IF ( gv_file_name IS NULL ) THEN
      lv_message_token := cv_user_csv_fl_name;
      RAISE profile_expt;
    END IF;
    --
-- Ver1.6 Mod 20090216 START
    lv_csv_file := xxccp_common_pkg.get_msg(                                    -- �A�b�v���[�h���̂̏o��
                    iv_application  => cv_appl_name_xxcmm                       -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_msg_xxcmm_00022                       -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_file_name                         -- �g�[�N���R�[�h1
                   ,iv_token_value1 => gv_file_name                             -- �g�[�N���l1
                  );
    -- �t�@�C�����o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_csv_file
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
-- Ver1.6 Mod 20090216 END
    --
    lv_step := 'A-1.3b';
    -- �i�ڃ}�X�^�iHHT�j�A�g�pCSV�t�@�C���o�͐�̎擾
    gv_csv_file_dir := FND_PROFILE.VALUE( cv_csv_fl_dir );
    -- �擾�G���[��
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_message_token := cv_user_csv_fl_dir;
      RAISE profile_expt;
    END IF;
    --
    --==============================================================
    --A-1.4 CSV�t�@�C�����݃`�F�b�N
    --==============================================================
    lv_step := 'A-1.4';
    lv_message_token := 'CSV�t�@�C�����݃`�F�b�N';
    -- CSV�t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(
       location    => gv_csv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_fexists
      ,file_length => ln_file_length
      ,block_size  => lbi_block_size
    );
    -- �t�@�C�����ݎ�
    IF ( lb_fexists = TRUE ) THEN
      RAISE csv_file_exst_expt;
    END IF;
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    --*** �Ώۊ��Ԏw��G���[ ***
    WHEN object_term_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00019            -- ���b�Z�[�W�FAPP-XXCMM1-00019 �Ώۊ��Ԏw��G���[
-- Ver1.4 Del 2009/2/10
/*
                     ,iv_token_name1  => cv_tkn_start_date             -- �g�[�N���R�[�h1�FSTART_DATE
                     ,iv_token_value1 => TO_CHAR( ld_date_from
                                                 ,cv_date_fmt_ymd )    -- �g�[�N���l1    �F�Ώۊ��ԁi�J�n�j�yld_date_from�z
                     ,iv_token_name2  => cv_tkn_last_date              -- �g�[�N���R�[�h2�FLAST_DATE
                     ,iv_token_value2 => TO_CHAR( ld_date_to
                                                 ,cv_date_fmt_ymd )    -- �g�[�N���l2    �F�Ώۊ��ԁi�I���j�yld_date_to�z
*/
-- End1.4
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00002            -- ���b�Z�[�W�FAPP-XXCMM1-00002 �v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_profile                -- �g�[�N���FNG_PROFILE
                     ,iv_token_value1 => lv_message_token              -- �v���t�@�C����
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** CSV�t�@�C�����݃G���[ ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
-- Ver1.3 Mod CSVCSV�t�@�C�����݃G���[�̕ύX 2009/2/5
--                     ,iv_name         => cv_msg_xxcmm_00484            -- ���b�Z�[�W�FAPP-XXCMM1-00484 CSV�t�@�C�����݃G���[
                     ,iv_name         => cv_msg_xxcmm_00490            -- ���b�Z�[�W�FAPP-XXCMM1-00490 CSV�t�@�C�����݃G���[
-- End
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_date_from   IN     VARCHAR2         --   �ŏI�X�V���i�J�n�j
    ,iv_date_to     IN     VARCHAR2         --   �ŏI�X�V���i�I���j
    ,ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                          VARCHAR2(5000);        -- �G���[�E���b�Z�[�W
    lv_retcode                         VARCHAR2(1);           -- ���^�[���E�R�[�h
    lv_errmsg                          VARCHAR2(5000);        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                            VARCHAR2(100);         -- �X�e�b�v
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[���[�J���ϐ�
    -- ===============================
-- Ver1.2
    lv_sqlerrm                         VARCHAR2(5000);        -- �G���[�E���b�Z�[�W
-- End
    lv_message_token                   VARCHAR2(100);         -- ���b�Z�[�W�g�[�N��
    ln_data_index                      NUMBER;                -- �f�[�^�p����
    lv_out_csv_line                    VARCHAR2(1000);        -- �o�͍s
    lv_hon_product_class               VARCHAR2(1);           -- �{�Џ��i�敪
    --
    -- �i�ڃ}�X�^�iHHT�j���J�[�\��
    --lv_step := 'A-2.1a';
    CURSOR csv_item_cur
    IS
      SELECT      xoiv.item_id                                               -- �i��ID
                 ,xoiv.item_no                                               -- �i�ڃR�[�h
--Ver1.3 Mod
--                 ,TO_CHAR( FND_DATE.CANONICAL_TO_DATE( xoiv.sell_start_date ), cv_date_fmt_ymd )
--                             AS sell_start_date                              -- �����J�n��
                 ,xoiv.sell_start_date                                       -- �����J�n��
--End1.3
                 ,xoiv.price_new                                             -- �艿�i�V�j
                 ,xoiv.jan_code                                              -- JAN�R�[�h
                 ,xoiv.opt_cost_new                                          -- �c�ƌ����i�V�j
                 ,xoiv.sales_div                                             -- ����Ώۋ敪
                 ,xoiv.num_of_cases                                          -- �P�[�X����
                 ,xoiv.item_short_name                                       -- ����
                 ,xoiv.palette_max_cs_qty                                    -- �z��
                 ,xoiv.palette_max_step_qty                                  -- �p���b�g����ő�i��
                 ,xoiv.parent_item_id                                        -- �e�i��ID
                 ,xoiv.baracha_div                                           -- �o�����敪
                 ,xoiv.vessel_group                                          -- �e��Q
                 ,xoiv.case_jan_code                                         -- �P�[�XJAN�R�[�h
--Ver1.3 Add
                 ,parent_iimb.item_no        AS parent_item_code             -- �e���i�R�[�h
--End1.3
                 ,xoiv.item_status                                           -- �i�ڃX�e�[�^�X
                 ,xoiv.search_update_date                                    -- �����ΏۍX�V��
      FROM        xxcmm_opmmtl_items_v    xoiv                               --
                 ,ic_item_mst_b           parent_iimb                        -- OPM�i�ځi�e�i�ځj
                 ,gmi_item_categories     gic_sales                          -- OPM�i�ڃJ�e�S�������i���i���i�敪�j
                 ,mtl_category_sets_vl    mcsv_sales                         -- �J�e�S���Z�b�g�r���[�i���i���i�敪�j
                 ,mtl_categories_vl       mcv_sales                          -- �J�e�S���r���[�i���i���i�敪�j
      WHERE       xoiv.item_id                 = gic_sales.item_id           -- ���i���i�敪
      AND         gic_sales.category_set_id    = mcsv_sales.category_set_id  -- ���i���i�敪
      AND         gic_sales.category_id        = mcv_sales.category_id       -- ���i���i�敪
      AND         mcsv_sales.category_set_name = cv_item_product_class       -- ���i���i�敪
      AND         mcv_sales.segment1           = cv_product_div              -- �J�e�S���D���i���i�敪���Q�i���i�j
-- Ver1.4 Mod �e�i�ڂ��ݒ肳��Ă��Ȃ��i�ڂ𒊏o�ΏۂƂ���悤�C�� 2009/2/10
--      AND         xoiv.parent_item_id          = parent_iimb.item_id         -- �e�i��ID���i��ID
      AND         xoiv.parent_item_id          = parent_iimb.item_id(+)      -- �e�i��ID���i��ID
-- End
      AND         xoiv.search_update_date     >= gd_date_from                -- �����ΏۍX�V�� >= ���̓p�����[�^�̍ŏI�X�V���i�J�n�j
      AND         xoiv.search_update_date     <= gd_date_to                  -- �����ΏۍX�V�� <= ���̓p�����[�^�̍ŏI�X�V���i�I���j
      AND         xoiv.start_date_active      <= gd_date_to + 1              -- �K�p�J�n��     <= ���̓p�����[�^�̍ŏI�X�V���i�I���j�{1��
      AND         xoiv.end_date_active        >= gd_date_to + 1              -- �K�p�I����     >= ���̓p�����[�^�̍ŏI�X�V���i�I���j�{1��
      ORDER BY    xoiv.item_no;
    --
    l_csv_item_tab                     xxcmm004a12c_ttype;                  -- ���iIF�o�̓f�[�^
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    sub_proc_expt                      EXCEPTION;       -- �T�u�v���O�����G���[
    file_open_expt                     EXCEPTION;       -- �t�@�C���I�[�v���G���[
    file_output_expt                   EXCEPTION;       -- �t�@�C���������݃G���[
    file_close_expt                    EXCEPTION;       -- �t�@�C���N���[�Y�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    -- ===============================================
    -- proc_init�̌Ăяo���i����������proc_init�ōs���j
    -- ===============================================
    proc_init(
       iv_date_from   => iv_date_from    -- �ŏI�X�V���i�J�n�j
      ,iv_date_to     => iv_date_to      -- �ŏI�X�V���i�I���j
      ,ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --
    -----------------------------------
    -- A-2.�i�ڏ��̎擾
    -----------------------------------
    lv_step := 'A-2.1b';
    ln_data_index := 0;
    --
    --
    <<csv_item_loop>>
    FOR l_csv_item_rec IN csv_item_cur LOOP
      --
      ln_data_index := ln_data_index + 1;
      --
      BEGIN
        -- �{�Џ��i�敪�̎擾
        SELECT      mcv_hon.segment1  AS hon_product_class                     -- �{�Џ��i�敪
        INTO        lv_hon_product_class                                       -- �{�Џ��i�敪
        FROM        gmi_item_categories     gic_hon                            -- OPM�i�ڃJ�e�S�������i�{�Џ��i�敪�j
                   ,mtl_category_sets_vl    mcsv_hon                           -- �J�e�S���Z�b�g�r���[�i�{�Џ��i�敪�j
                   ,mtl_categories_vl       mcv_hon                            -- �J�e�S���r���[�i�{�Џ��i�敪�j
        WHERE       mcsv_hon.category_set_name   = cv_hon_product_class        -- �{�Џ��i�敪
        AND         gic_hon.item_id              = l_csv_item_rec.item_id      -- �i��
        AND         gic_hon.category_set_id      = mcsv_hon.category_set_id    -- �J�e�S���Z�b�gID
        AND         gic_hon.category_id          = mcv_hon.category_id;        -- �J�e�S��ID
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_hon_product_class := '';
      END;
      --
      -- �z��ɐݒ�
-- Ver1.5 Mod �擪�Q��(00)���J�b�g(�i�ڃR�[�h) 2009/2/12
--      lv_step := 'A-2.item_code';
--      lv_message_token := '�i�ڃR�[�h';
--      l_csv_item_tab( ln_data_index ).item_code            := l_csv_item_rec.item_no;               -- �i�ڃR�[�h
      lv_step := 'A-2.item_code';
      lv_message_token := '�i�ڃR�[�h';
--      l_csv_item_tab( ln_data_index ).item_code            := TO_CHAR( TO_NUMBER( l_csv_item_rec.item_no , cv_number_fmt) );
                                                                                                    -- �i�ڃR�[�h
      IF SUBSTRB( l_csv_item_rec.item_no , 1 , 2 ) = cv_item_code_cut THEN
        l_csv_item_tab( ln_data_index ).item_code            := SUBSTRB( l_csv_item_rec.item_no , 3 );
      ELSE
        l_csv_item_tab( ln_data_index ).item_code            := l_csv_item_rec.item_no;
      END IF;
--End
      lv_step := 'A-2.item_short_name';
      lv_message_token := '����';
      l_csv_item_tab( ln_data_index ).item_short_name      := l_csv_item_rec.item_short_name;       -- ����
      lv_step := 'A-2.baracha_div';
      lv_message_token := '�o�����敪';
      l_csv_item_tab( ln_data_index ).baracha_div          := l_csv_item_rec.baracha_div;           -- �o�����敪
      lv_step := 'A-2.sell_start_date';
      lv_message_token := '�����J�n��';
--Ver1.3 �����J�n���̃t�H�[�}�b�g���w�� 2009/2/5
--      l_csv_item_tab( ln_data_index ).sell_start_date      := l_csv_item_rec.sell_start_date;       -- �����J�n���yYYYYMMDD�z
      l_csv_item_tab( ln_data_index ).sell_start_date      := TO_CHAR( l_csv_item_rec.sell_start_date , cv_date_fmt_ymd );       -- �����J�n���yYYYYMMDD�z
--End1.3
      lv_step := 'A-2.opt_cost_new';
      lv_message_token := '�c�ƌ����i�V�j';
      l_csv_item_tab( ln_data_index ).opt_cost_new         := TO_CHAR( l_csv_item_rec.opt_cost_new );
                                                                                                    -- �c�ƌ����i�V�j
      lv_step := 'A-2.price_new';
      lv_message_token := '�艿�i�V�j';
      l_csv_item_tab( ln_data_index ).price_new            := TO_CHAR( l_csv_item_rec.price_new );  -- �艿�i�V�j
      lv_step := 'A-2.tax_rate';
      lv_message_token := '����ŗ�';
      l_csv_item_tab( ln_data_index ).tax_rate             := cn_tax_rate;                          -- �����
      lv_step := 'A-2.num_of_cases';
      lv_message_token := '�P�[�X����';
      l_csv_item_tab( ln_data_index ).num_of_cases         := TO_CHAR( l_csv_item_rec.num_of_cases );
                                                                                                    -- �P�[�X����
--Ver1.3 Add �{�Џ��i�敪��ǉ�
      lv_step := 'A-2.parent_item_code';
      lv_message_token := '�{�Џ��i�敪';
      l_csv_item_tab( ln_data_index ).hon_product_class    := lv_hon_product_class;  -- �{�Џ��i�敪
--End1.3
      lv_step := 'A-2.vessel_group';
      lv_message_token := '�e��Q';
      l_csv_item_tab( ln_data_index ).vessel_group         := l_csv_item_rec.vessel_group;          -- �e��Q
      lv_step := 'A-2.palette_max_cs_qty';
      lv_message_token := '�z��';
      l_csv_item_tab( ln_data_index ).palette_max_cs_qty   := l_csv_item_rec.palette_max_cs_qty;    -- �z��
      lv_step := 'A-2.palette_max_step_qty';
      lv_message_token := '�p���b�g����ő�i��';
      l_csv_item_tab( ln_data_index ).palette_max_step_qty := l_csv_item_rec.palette_max_step_qty;  -- �p���b�g����ő�i��
      lv_step := 'A-2.item_status';
      lv_message_token := '�i�ڃX�e�[�^�X';
      l_csv_item_tab( ln_data_index ).item_status          := l_csv_item_rec.item_status;           -- �i�ڃX�e�[�^�X
      lv_step := 'A-2.tax_div';
      lv_message_token := '�ŋ敪';
      l_csv_item_tab( ln_data_index ).tax_div              := cv_tax_div;                           -- �ŋ敪
      lv_step := 'A-2.sales_div';
      lv_message_token := '����Ώۋ敪';
      l_csv_item_tab( ln_data_index ).sales_div            := l_csv_item_rec.sales_div;             -- ����Ώۋ敪
      lv_step := 'A-2.jan_code';
      lv_message_token := 'JAN�R�[�h';
      l_csv_item_tab( ln_data_index ).jan_code             := l_csv_item_rec.jan_code;              -- JAN�R�[�h
      lv_step := 'A-2.case_jan_code';
      lv_message_token := '�P�[�XJAN�R�[�h';
      l_csv_item_tab( ln_data_index ).case_jan_code        := l_csv_item_rec.case_jan_code;         -- �P�[�XJAN�R�[�h
--Ver1.3 Add �e���i�R�[�h��ǉ�
-- Ver1.5 Mod �擪�Q��(00)���J�b�g(�e�R�[�h) 2009/2/12
      lv_step := 'A-2.parent_item_code';
      lv_message_token := '�e���i�R�[�h';
--      l_csv_item_tab( ln_data_index ).parent_item_code     := l_csv_item_rec.parent_item_code;       -- �e���i�R�[�h
      IF SUBSTRB( l_csv_item_rec.item_no , 1 , 2 ) = cv_item_code_cut THEN
          l_csv_item_tab( ln_data_index ).parent_item_code            := SUBSTRB( l_csv_item_rec.parent_item_code , 3 );
      ELSE
        l_csv_item_tab( ln_data_index ).parent_item_code            := l_csv_item_rec.parent_item_code;
      END IF;
--End1.5
--End1.3
      lv_step := 'A-2.search_update_date';
      lv_message_token := '�X�V����';
      l_csv_item_tab( ln_data_index ).search_update_date   := l_csv_item_rec.search_update_date;    -- �����ΏۍX�V��
      --
    END LOOP csv_item_loop;
    --
    --
    -----------------------------------------------
    -- A-3.�i�ڃ}�X�^�iHHT�j�o�͏���
    -----------------------------------------------
    lv_step := 'A-3';
-- Ver1.1
/*
    IF ( ln_data_index = 0 ) THEN
      -- �Ώۃf�[�^�Ȃ�
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm
                     ,iv_name         => cv_msg_xxcmm_00001
                     );
      -- �o�͕\��
      lv_step := 'A-1.5';
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ���O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
    ELSE
*/
-- End
      -- CSV�t�@�C���I�[�v��
      lv_step := 'A-1.6';
      BEGIN
        gf_file_hand := UTL_FILE.FOPEN(  location  => gv_csv_file_dir  -- �o�͐�
                                        ,filename  => gv_file_name     -- CSV�t�@�C����
                                        ,open_mode => cv_csv_mode      -- ���[�h
                                       );
      EXCEPTION
        WHEN OTHERS THEN
-- Ver1.2
          lv_sqlerrm := SQLERRM;
-- End
          RAISE file_open_expt;
      END;
      -- �t�@�C���o��
      lv_step := 'A-3.1a';
      <<out_csv_loop>>
      FOR ln_index IN 1..l_csv_item_tab.COUNT LOOP
        --
        lv_out_csv_line := '';
        -- �i�ڃR�[�h
        lv_step := 'A-3.item_code';
        lv_out_csv_line := cv_dqu || l_csv_item_tab( ln_index ).item_code || cv_dqu;
        -- ����
        lv_step := 'A-3.item_short_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).item_short_name || cv_dqu;
        -- �o�����敪
-- Ver1.5 Mod 2009/2/12
        lv_step := 'A-3.baracha_div';
--        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
--          TO_CHAR( l_csv_item_tab( ln_index ).baracha_div || cv_dqu );
          l_csv_item_tab( ln_index ).baracha_div;
-- End1.5
        -- �����J�n���yYYYYMMDD�z
        lv_step := 'A-3.sell_start_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          l_csv_item_tab( ln_index ).sell_start_date;
        -- �c�ƌ����i�V�j
        lv_step := 'A-3.opt_cost_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep || l_csv_item_tab( ln_index ).opt_cost_new;
        -- �艿�i�V�j
        lv_step := 'A-3.price_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep || l_csv_item_tab( ln_index ).price_new;
        -- ����ŗ�
        lv_step := 'A-3.tax_rate';
        lv_out_csv_line := lv_out_csv_line || cv_sep || TO_CHAR( l_csv_item_tab( ln_index ).tax_rate );
        -- �P�[�X����
        lv_step := 'A-3.num_of_cases';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          l_csv_item_tab( ln_index ).num_of_cases;
        -- �{�Џ��i�敪
        lv_step := 'A-3.hon_product_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).hon_product_class || cv_dqu;
        -- �e��Q
        lv_step := 'A-3.vessel_group';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).vessel_group || cv_dqu;
        -- �z��
        lv_step := 'A-3.palette_max_cs_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          TO_CHAR( l_csv_item_tab( ln_index ).palette_max_cs_qty );
        -- �p���b�g����ő�i��
        lv_step := 'A-3.palette_max_step_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          TO_CHAR( l_csv_item_tab( ln_index ).palette_max_step_qty );
        -- �i�ڃX�e�[�^�X
        lv_step := 'A-3.item_status';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          TO_CHAR( l_csv_item_tab( ln_index ).item_status ) || cv_dqu;
        -- �ŋ敪
        lv_step := 'A-3.tax_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).tax_div || cv_dqu;
        -- ����Ώۋ敪
        lv_step := 'A-3.sales_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).sales_div || cv_dqu;
        -- JAN�R�[�h
        lv_step := 'A-3.jan_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).jan_code || cv_dqu;
        -- �P�[�XJAN�R�[�h
        lv_step := 'A-3.case_jan_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).case_jan_code || cv_dqu;
--Ver1.3 Add
        -- �e���i�R�[�h
        lv_step := 'A-3.parent_item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep || cv_dqu ||
          l_csv_item_tab( ln_index ).parent_item_code || cv_dqu;
--End1.3
        -- �X�V�����yYYYY/MM/DD HH:MM:SS�z
        lv_step := 'A-3.search_update_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
          TO_CHAR( l_csv_item_tab( ln_index ).search_update_date , cv_date_format_all );
        --
        -- CSV�t�@�C���o��
        lv_step := 'A-3.1b';
        BEGIN
          UTL_FILE.PUT_LINE( gf_file_hand, lv_out_csv_line );
        EXCEPTION
          WHEN OTHERS THEN
-- Ver1.2
            lv_sqlerrm := SQLERRM;
-- End
            RAISE file_output_expt;
        END;
        --
        -- �Ώی���
        gn_target_cnt := gn_target_cnt + 1;
        -- ��������
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      END LOOP out_csv_loop;
      --
      -----------------------------------------------
      -- A-4.�I������
      -----------------------------------------------
      -- �t�@�C���N���[�Y
      lv_step := 'A-4.1';
      --
      --�t�@�C���N���[�Y���s
      BEGIN
        UTL_FILE.FCLOSE( gf_file_hand );
      EXCEPTION
        WHEN OTHERS THEN
-- Ver1.2
            lv_sqlerrm := SQLERRM;
-- End
          RAISE file_close_expt;
      END;
      --
-- Ver1.1
/*
    END IF;
*/
-- End
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- *** �T�u�v���O������O�n���h�� ****
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --*** �t�@�C���I�[�v���G���[ ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00487             -- ���b�Z�[�W�FAPP-XXCMM1-00487 �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���R�[�h�FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �g�[�N���l�FSQLERRM
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End1.1
      ov_retcode := cv_status_error;
    --*** �t�@�C���������݃G���[ ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00488             -- ���b�Z�[�W�FAPP-XXCMM1-00488 �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���R�[�h�FSQLERRM
-- Ver1.3 Mod lv_sqlerrm��\��������悤�ɏC��
--                     ,iv_token_value1 => SQLERRM                        -- �g�[�N���l�FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �g�[�N���l�FSQLERRM
-- End1.3
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End1.1
      ov_retcode := cv_status_error;
    --*** �t�@�C���N���[�Y�G���[ ***
    WHEN file_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00489             -- ���b�Z�[�W�FAPP-XXCMM1-00489 �t�@�C���N���[�Y�G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���R�[�h�FSQLERRM
-- Ver1.3 Mod lv_sqlerrm��\��������悤�ɏC��
--                     ,iv_token_value1 => SQLERRM                        -- �g�[�N���l�FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �g�[�N���l�FSQLERRM
-- End1.3
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
        cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
        cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      gn_error_cnt := gn_target_cnt;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
        cv_msg_part||SQLERRM;
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
    errbuf         OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode        OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_date_from   IN     VARCHAR2         --   �ŏI�X�V���i�J�n�j
   ,iv_date_to     IN     VARCHAR2         --   �ŏI�X�V���i�I���j
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
  --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
    cv_log               CONSTANT VARCHAR2(100) := 'LOG';               -- ���O
    cv_output            CONSTANT VARCHAR2(100) := 'OUTPUT';            -- �A�E�g�v�b�g
    cv_app_name_xxccp    CONSTANT VARCHAR2(100) := 'XXCCP';             -- �A�v���P�[�V�����Z�k��
    cv_target_cnt_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_cnt_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_cnt_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_normal_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �x���I�����b�Z�[�W
    cv_token_name1       CONSTANT VARCHAR2(100) := 'COUNT';             -- ��������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf              VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                VARCHAR2(10);    -- �X�e�b�v
    lv_message_code        VARCHAR2(100);   -- ���b�Z�[�W�R�[�h
    --
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_date_from   => iv_date_from    -- �ŏI�X�V���i�J�n�j
      ,iv_date_to     => iv_date_to      -- �ŏI�X�V���i�I���j
      ,ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�G���[���b�Z�[�W
      );
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  --
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMM004A12C;
/
