CREATE OR REPLACE PACKAGE BODY XXCMM004A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A15C(body)
 * Description      : CSV�`���̃f�[�^�t�@�C������ADisc�i�ڃA�h�I���̍X�V���s���܂��B
 * MD.050           : �i�ڈꊇ�X�V CMM_004_A15
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_comp              �I������ (A-5)
 *  ins_data               �f�[�^�o�^ (A-4)
 *  validate_item          �f�[�^�Ó����`�F�b�N (A-3)
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾 (A-2)
                              �Evalidate_item
                              �Eins_data
 *  proc_init              �������� (A-1)
 *  submain                ���C�������v���V�[�W��
 *                            �Eproc_init
 *                            �Eget_if_data
 *                            �Eproc_comp
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/02/19    1.0   H.Futamura       �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;             --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;               --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;              --�ُ�:2
  --WHO�J����
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                             --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                                        --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                            --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;                     --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;                        --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;                     --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                                        --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCMM004A15C';                                  -- �p�b�P�[�W��
--
  -- ���b�Z�[�W
  cv_msg_xxcmm_00021     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';                              -- �t�@�C���A�b�v���[�h���̃m�[�g
  cv_msg_xxcmm_00022     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';                              -- CSV�t�@�C�����m�[�g
  cv_msg_xxcmm_00023     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';                              -- FILE_ID�m�[�g
  cv_msg_xxcmm_00024     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';                              -- �t�H�[�}�b�g�m�[�g
  cv_msg_xxcmm_00028     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';                              -- �f�[�^���ڐ��G���[
  cv_msg_xxcmm_00401     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00401';                              -- �p�����[�^NULL�G���[
  cv_msg_xxcmm_00403     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00403';                              -- �t�@�C�����ڃ`�F�b�N�G���[
  cv_msg_xxcmm_00418     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00418';                              -- �f�[�^�폜�G���[
  cv_msg_xxcmm_00435     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00435';                              -- �擾���s�G���[
  cv_msg_xxcmm_00439     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00439';                              -- �f�[�^���o�G���[
  cv_msg_xxcmm_00800     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00800';                              -- �}�X�^���݃`�F�b�N�G���[
  cv_msg_xxcmm_00801     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00801';                              -- �f�[�^���o�G���[
  cv_msg_xxcmm_00802     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00802';                              -- �f�[�^�X�V�G���[
  cv_msg_xxcmm_00803     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00803';                              -- ���b�N�擾�G���[
  cv_msg_xxcmm_30400     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30400';                              -- �t�H�[�}�b�g
  cv_msg_xxcmm_30401     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30401';                              -- �Ɩ����t
  cv_msg_xxcmm_30402     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30402';                              -- LOOKUP�\
  cv_msg_xxcmm_30403     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30403';                              -- Disc�i�ڃA�h�I��
  cv_msg_xxcmm_30404     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30404';                              -- �t�@�C���A�b�v���[�hIF
  cv_msg_xxcmm_30405     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30405';                              -- �i�ڃR�[�h
  cv_msg_xxcmm_30406     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30406';                              -- �i�ڈꊇ�X�V
  cv_msg_xxcmm_30407     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30407';                              -- ���j���[�A�������i�R�[�h
  cv_msg_xxcmm_30408     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30408';                              -- �i�ڃ}�X�^
  -- �g�[�N��
  cv_tkn_value           CONSTANT VARCHAR2(20)  := 'VALUE';                                         --
  cv_tkn_up_name         CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';                                   -- �t�@�C���A�b�v���[�h����
  cv_tkn_file_id         CONSTANT VARCHAR2(20)  := 'FILE_ID';                                       -- �t�@�C��ID
  cv_tkn_file_format     CONSTANT VARCHAR2(20)  := 'FORMAT';                                        -- �t�H�[�}�b�g
  cv_tkn_file_name       CONSTANT VARCHAR2(20)  := 'FILE_NAME';                                     -- �t�@�C����
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';                                         -- ��������
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                                         -- �e�[�u����
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';                                       -- �G���[���e
  cv_tkn_input_line_no   CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';                                 -- �C���^�t�F�[�X�̍s�ԍ�
  cv_tkn_input_item_code CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';                               -- �C���^�t�F�[�X�̕i�ڃR�[�h
  cv_tkn_input           CONSTANT VARCHAR2(20)  := 'INPUT';                                         -- ����
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';
  --
  cv_log                 CONSTANT VARCHAR2(5)   := 'LOG';                                           -- ���O
  cv_output              CONSTANT VARCHAR2(6)   := 'OUTPUT';                                        -- �A�E�g�v�b�g
  --
  cv_file_id             CONSTANT VARCHAR2(20)  := 'FILE_ID';                                       -- �t�@�C��ID
  cv_lookup_type_upload_obj
                         CONSTANT VARCHAR2(30)  := xxcmm_004common_pkg.cv_lookup_type_upload_obj;   -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_lookup_item_def     CONSTANT VARCHAR2(30)  := 'XXCMM1_004A15_ITEM_UPLOAD_DEF';                 -- �i�ڈꊇ�X�V�f�[�^���ڒ�`
--
  -- LOOKUP
  cv_lookup_itm_dtl_sts  CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_DTL_STATUS';                          -- �i�ڏڍ׃X�e�[�^�X
--
  -- ITEM
  cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                  CONSTANT VARCHAR2(1)   := 'N';
  cv_null_ok             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ok;                  -- �C�Ӎ���
  cv_null_ng             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ng;                  -- �K�{����
  cv_varchar             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_varchar;                  -- ������
  cv_number              CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_number;                   -- ���l
  cv_varchar_cd          CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_varchar_cd;               -- �����񍀖�
  cv_number_cd           CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_number_cd;                -- ���l����
  cv_date_cd             CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_date_cd;                  -- ���t����
  cv_not_null            CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_not_null;                 -- �K�{
  cv_msg_comma           CONSTANT VARCHAR2(1)   := ',';                                             -- �J���}
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_item_def_rtype    IS RECORD                                                                -- ���R�[�h�^��錾
      (item_name       VARCHAR2(100)                                                                -- ���ږ�
      ,item_attribute  VARCHAR2(100)                                                                -- ���ڑ���
      ,item_essential  VARCHAR2(100)                                                                -- �K�{�t���O
      ,item_length     NUMBER                                                                       -- ���ڂ̒���
      )
    ;
  --
  TYPE g_item_rtype IS RECORD
      (line_no           VARCHAR2(100)  -- �s�ԍ�
      ,item_code         VARCHAR2(100)  -- �i�ڃR�[�h
      ,item_name         VARCHAR2(100)  -- �i�ږ�
      ,renewal_item_code VARCHAR2(100)  -- ���j���[�A�������i�R�[�h
      ,item_dtl_status   VARCHAR2(100)  -- �i�ڏڍ׃X�e�[�^�X
      ,remarks           VARCHAR2(100)  -- ���l
      )
    ;
  --
  TYPE g_item_def_ttype   IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;                -- �e�[�u���^�̐錾
  --
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(4000)        INDEX BY BINARY_INTEGER;                -- �e�[�u���^�̐錾
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_file_id                NUMBER;                                                                 -- �p�����[�^�i�[�p�ϐ�
  gv_format                 VARCHAR2(100);                                                          -- �p�����[�^�i�[�p�ϐ�
  gn_item_num               NUMBER;                                                                 -- �i�ڈꊇ�o�^�f�[�^���ڐ��i�[�p
  gd_process_date           DATE;                                                                   -- �Ɩ����t
  g_item_def_tab            g_item_def_ttype;                                                       -- �e�[�u���^�ϐ��̐錾
  g_item_rec                g_item_rtype;                                                           -- ���R�[�h�^�ϐ��̐錾
  --
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���b�N�G���[��O ***
  global_check_lock_expt     EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : �I������ (A-5)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- �v���O������
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
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    del_err_expt              EXCEPTION;                              -- �f�[�^�폜�G���[
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    lv_step := 'A-5.1';
    --==============================================================
    -- A-5.1 �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
    --==============================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface
      WHERE  file_id = gn_file_id
      ;
      --
      COMMIT;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00418          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                -- TABLE
                      ,iv_token_value1 => cv_msg_xxcmm_30404          -- �t�@�C���A�b�v���[�hIF
                      ,iv_token_name2  => cv_tkn_errmsg               -- ERR_MSG
                      ,iv_token_value2 => SQLERRM                     -- �G���[���b�Z�[�W
                     );
        RAISE del_err_expt;
    END;
    --
  EXCEPTION
    -- *** �f�[�^�폜��O�n���h�� ***
    WHEN del_err_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : ins_data
   * Description      : �f�[�^�o�^ (A-4)
   ***********************************************************************************/
  PROCEDURE ins_data(
    i_wk_item_rec  IN  g_item_rtype               -- �i�ڈꊇ�X�V���[�N���
   ,ov_errbuf      OUT VARCHAR2                   -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2                   -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    lv_tkn_table              VARCHAR2(60);
    lv_item_code              xxcmm_system_items_b.item_code%TYPE;
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- *** ���[�J�����[�U�[��`��O ***
    ins_err_expt              EXCEPTION;                              -- �f�[�^�X�V�G���[
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
    -- A-4 �f�[�^�o�^
    --==============================================================
    lv_step := 'A-4.1';
    -- Disc�i�ڃA�h�I���f�[�^���b�N�擾
    BEGIN
      SELECT xsib.item_code                       -- �i�ڃR�[�h
      INTO   lv_item_code
      FROM   xxcmm_system_items_b xsib
      WHERE  xsib.item_code              = i_wk_item_rec.item_code
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        RAISE global_check_lock_expt;
    END;
--
    lv_step := 'A-4.2';
    -- Disc�i�ڃA�h�I���f�[�^�X�V
    BEGIN
      UPDATE xxcmm_system_items_b xsib
      SET    xsib.renewal_item_code      = NVL(i_wk_item_rec.renewal_item_code ,xsib.renewal_item_code ) -- ���j���[�A�������i�R�[�h
            ,xsib.item_dtl_status        = NVL(i_wk_item_rec.item_dtl_status ,xsib.item_dtl_status )     -- �i�ڏڍ׃X�e�[�^�X
            ,xsib.remarks                = NVL(i_wk_item_rec.remarks ,xsib.remarks )                     -- ���l
            ,xsib.last_updated_by        = cn_last_updated_by                                            -- �ŏI�X�V��
            ,xsib.last_update_date       = cd_last_update_date                                           -- �ŏI�X�V��
            ,xsib.last_update_login      = cn_last_update_login                                          -- �ŏI�X�V���O�C��
            ,xsib.request_id             = cn_request_id                                                 -- �v��ID
            ,xsib.program_application_id = cn_program_application_id                                     -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
            ,xsib.program_id             = cn_program_id                                                 -- �R���J�����g�E�v���O����ID
            ,xsib.program_update_date    = cd_program_update_date                                        -- �v���O�����ɂ��X�V��
      WHERE xsib.item_code               = i_wk_item_rec.item_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_30403          -- ���b�Z�[�W�R�[�h
                     );
        RAISE ins_err_expt;   -- �f�[�^�X�V��O
    END;
  --
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00803            -- ���b�Z�[�W�R�[�h
                   );
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN ins_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00802            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                  -- TABLE
                    ,iv_token_value1 => lv_tkn_table                  -- Disc�i�ڃA�h�I��
                    ,iv_token_name2  => cv_tkn_input_line_no          -- INPUT_LINE_NO
                    ,iv_token_value2 => i_wk_item_rec.line_no         -- �s�ԍ�
                    ,iv_token_name3  => cv_tkn_input_item_code        -- INPUT_ITEM_CODE
                    ,iv_token_value3 => i_wk_item_rec.item_code       -- �i�ڃR�[�h
                    ,iv_token_name4  => cv_tkn_errmsg                 -- ERR_MSG
                    ,iv_token_value4 => lv_errbuf                     -- �G���[���b�Z�[�W
                   );
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_data;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : �f�[�^�Ó����`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_wk_item_rec  IN  g_item_rtype               -- �i�ڈꊇ�X�V���[�N���
   ,ov_errbuf      OUT VARCHAR2                   -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2                   -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_item';                    -- �v���O������
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
    lv_step                   VARCHAR2(10);                                     -- �X�e�b�v
    ln_cnt                    NUMBER;                                           -- �i�ڑ��݃`�F�b�N�J�E���g�p
    lv_check_flag             VARCHAR2(1);                                      -- �`�F�b�N�t���O
    l_validate_item_tab       g_check_data_ttype;
    lt_lookup_code            fnd_lookup_values_vl.lookup_code%TYPE;
    --
    ln_check_cnt              NUMBER;
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM�ϐ��ޔ�p
    lv_msg_xxcmm_30402        VARCHAR2(10);                                     -- LOOKUP�\
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ��̏�����
    ln_cnt        := 0;
    lv_check_flag := cv_status_normal;
    --
    --==============================================================
    -- ���C������LOOP
    --==============================================================
    lv_step := 'A-3.1';
    --
    l_validate_item_tab(1)  := i_wk_item_rec.line_no;                           -- �s�ԍ�
    l_validate_item_tab(2)  := i_wk_item_rec.item_code;                         -- �i�ڃR�[�h
    l_validate_item_tab(3)  := i_wk_item_rec.item_name;                         -- �i�ږ�
    l_validate_item_tab(4)  := i_wk_item_rec.renewal_item_code;                 -- ���j���[�A�������i�R�[�h
    l_validate_item_tab(5)  := i_wk_item_rec.item_dtl_status;                   -- �i�ڏڍ׃X�e�[�^�X
    l_validate_item_tab(6)  := i_wk_item_rec.remarks;                           -- ���l
    --
    -- �J�E���^�̏�����
    ln_check_cnt := 0;
    --
    <<validate_column_loop>>
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      -- �J�E���^�����Z
      ln_check_cnt := ln_check_cnt + 1;
      --
      -- ���ڂ��u�i�ږ��v�̏ꍇ�`�F�b�N�����{���Ȃ�
      IF ( ln_check_cnt <> 3 ) THEN
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_item_def_tab(ln_check_cnt).item_name             -- ���ږ���
         ,iv_item_value   => l_validate_item_tab(ln_check_cnt)                  -- ���ڂ̒l
         ,in_item_len     => g_item_def_tab(ln_check_cnt).item_length           -- ���ڂ̒���(��������)
         ,in_item_decimal => NULL                                               -- ���ڂ̒����i�����_�ȉ��j
         ,iv_item_nullflg => g_item_def_tab(ln_check_cnt).item_essential        -- �K�{�t���O
         ,iv_item_attr    => g_item_def_tab(ln_check_cnt).item_attribute        -- ���ڂ̑���
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                          ,iv_name          =>  cv_msg_xxcmm_00403              -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1   =>  cv_tkn_input_line_no            -- INPUT_LINE_NO
                          ,iv_token_value1  =>  i_wk_item_rec.line_no           -- �s�ԍ�
                          ,iv_token_name2   =>  cv_tkn_errmsg                   -- ERR_MSG
                          ,iv_token_value2  =>  LTRIM(lv_errmsg)                -- �G���[���b�Z�[�W
                         );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff  =>  lv_errmsg
           ,ov_errbuf        =>  lv_errbuf
           ,ov_retcode       =>  lv_retcode
           ,ov_errmsg        =>  lv_errmsg
          );
          --
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
    END LOOP validate_column_loop;
    --
--
    IF ( lv_check_flag = cv_status_normal ) THEN
      --==============================================================
      -- A-3.2 �i�ڑ��݃`�F�b�N�i�i�ڃR�[�h�j
      --==============================================================
      lv_step := 'A-3.2';
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    ic_item_mst_b iimb
      WHERE   iimb.item_no = i_wk_item_rec.item_code
      AND     ROWNUM       = 1
      ;
      -- �������ʃ`�F�b�N
      IF ( ln_cnt = 0 ) THEN
        -- �}�X�^���݃`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00800                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- INPUT
                      ,iv_token_value1 => cv_msg_xxcmm_30405                    -- �i�ڃR�[�h
                      ,iv_token_name2  => cv_tkn_table                          -- TABLE
                      ,iv_token_value2 => cv_msg_xxcmm_30408                    -- �i�ڃ}�X�^
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- INPUT_LINE_NO
                      ,iv_token_value3 => i_wk_item_rec.line_no                 -- �s�ԍ�
                      ,iv_token_name4  => cv_tkn_input_item_code                -- INPUT_ITEM_CODE
                      ,iv_token_value4 => i_wk_item_rec.item_code               -- �i�ڃR�[�h
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-3.3 �i�ڑ��݃`�F�b�N�i���j���[�A�������i�R�[�h�j
      -- NULL�̏ꍇ�̓`�F�b�N���Ȃ�
      --==============================================================
      lv_step := 'A-3.3';
      IF ( i_wk_item_rec.renewal_item_code IS NOT NULL ) THEN
        SELECT  COUNT(1)
        INTO    ln_cnt
        FROM    ic_item_mst_b iimb
        WHERE   iimb.item_no = i_wk_item_rec.renewal_item_code
        AND     ROWNUM       = 1
        ;
        -- �������ʃ`�F�b�N
        IF ( ln_cnt = 0 ) THEN
          -- �}�X�^���݃`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                  -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00800                  -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                        -- INPUT
                        ,iv_token_value1 => cv_msg_xxcmm_30407                  -- ���j���[�A�������i�R�[�h
                        ,iv_token_name2  => cv_tkn_table                        -- TABLE
                        ,iv_token_value2 => cv_msg_xxcmm_30408                  -- �i�ڃ}�X�^
                        ,iv_token_name3  => cv_tkn_input_line_no                -- INPUT_LINE_NO
                        ,iv_token_value3 => i_wk_item_rec.line_no               -- �s�ԍ�
                        ,iv_token_name4  => cv_tkn_input_item_code              -- INPUT_ITEM_CODE
                        ,iv_token_value4 => i_wk_item_rec.item_code             -- �i�ڃR�[�h
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-3.4 �i�ڏڍ׃X�e�[�^�X�`�F�b�N
      -- NULL�̏ꍇ�̓`�F�b�N���Ȃ�
      --==============================================================
      lv_step := 'A-3.4';
      IF ( i_wk_item_rec.item_dtl_status IS NOT NULL ) THEN
        BEGIN
          SELECT  flvv.lookup_code
          INTO    lt_lookup_code
          FROM    fnd_lookup_values_vl flvv
          WHERE   flvv.lookup_type   = cv_lookup_itm_dtl_sts
          AND     flvv.lookup_code   = i_wk_item_rec.item_dtl_status
          AND     flvv.enabled_flag  = cv_yes
          AND     NVL( flvv.start_date_active, gd_process_date ) <= gd_process_date
          AND     NVL( flvv.end_date_active,   gd_process_date ) >= gd_process_date
          ;
        EXCEPTION
          --*** �f�[�^���o�G���[ ***
          WHEN OTHERS THEN
            lv_sqlerrm := SQLERRM;
            lv_msg_xxcmm_30402 := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                                   ,iv_name         => cv_msg_xxcmm_30402          -- ���b�Z�[�W�R�[�h
                                  );
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                                    -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_00801                                    -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_table                                          -- TABLE
                          ,iv_token_value1 => lv_msg_xxcmm_30402 || '(' || cv_lookup_itm_dtl_sts || ')'   -- LOOKUP�\
                          ,iv_token_name2  => cv_tkn_input_line_no                                  -- INPUT_LINE_NO
                          ,iv_token_value2 => i_wk_item_rec.line_no                                 -- �s�ԍ�
                          ,iv_token_name3  => cv_tkn_input_item_code                                -- INPUT_ITEM_CODE
                          ,iv_token_value3 => i_wk_item_rec.item_code                               -- �i�ڃR�[�h
                          ,iv_token_name4  => cv_tkn_errmsg                                         -- ERR_MSG
                          ,iv_token_value4 => lv_sqlerrm                                            -- �G���[���b�Z�[�W
                         );
            -- ���b�Z�[�W�o��
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
        END;
      END IF;
      --
    END IF;
    --�߂�X�e�[�^�X�̐ݒ�
    IF ( lv_check_flag = cv_status_normal ) THEN
      ov_retcode := cv_status_normal;
    ELSIF ( lv_check_flag = cv_status_error ) THEN
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';        -- �v���O������
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
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    --
    ln_line_cnt               NUMBER;                                 -- �s�J�E���^
    ln_item_num               NUMBER;                                 -- ���ڐ�
    ln_item_cnt               NUMBER;                                 -- ���ڐ��J�E���^
    lv_check_error            VARCHAR2(1);                            -- �G���[�X�e�[�^�X�ޔ�
--
    l_wk_item_tab             g_check_data_ttype;                     --  �e�[�u���^�ϐ���錾(���ڕ���)
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      --  �e�[�u���^�ϐ���錾
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_if_data_expt          EXCEPTION;                              -- �f�[�^���ڐ��G���[��O
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    ln_item_num     := 0;
    -- �f�[�^���ڐ��ݒ�
    gn_item_num     := 6;
    --
    --==============================================================
    -- A-2.1 �Ώۃf�[�^�̕���(���R�[�h����)/�t�@�C���A�b�v���[�hIF�e�[�u�����b�N
    --==============================================================
    lv_step := 'A-2.1';
    xxccp_common_pkg2.blob_to_varchar2(                               -- BLOB�f�[�^�ϊ����ʊ֐�
      in_file_id   => gn_file_id                                      -- �t�@�C���h�c
     ,ov_file_data => l_if_data_tab                                   -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- �f�[�^�`�F�b�N/�X�VLOOP
    -- �w�b�_�[��������
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 2..l_if_data_tab.COUNT LOOP
      --==============================================================
      -- A-2.2 ���ڐ��̃`�F�b�N
      --==============================================================
      lv_step := 'A-2.2';
      -- �f�[�^���ڐ����i�[
      ln_item_num := ( LENGTHB(l_if_data_tab(ln_line_cnt))
                   - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '')))
                   + 1);
      -- ���ڐ�����v���Ȃ��ꍇ
      IF ( gn_item_num <> ln_item_num ) THEN
        RAISE get_if_data_expt;
      END IF;
      --
      --==============================================================
      -- A-2.3 �Ώۃf�[�^�̕���(���ڕ���)/�i�[
      --==============================================================
      lv_step := 'A-2.3';
      <<get_column_loop>>
      FOR ln_item_cnt IN 1..gn_item_num LOOP
        l_wk_item_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(  -- �f���~�^�����ϊ����ʊ֐�
                                        iv_char     => l_if_data_tab(ln_line_cnt)
                                       ,iv_delim    => cv_msg_comma
                                       ,in_part_num => ln_item_cnt
                                      );
      END LOOP get_column_loop;
      -- �ϐ��ɍ��ڂ̒l���i�[
      g_item_rec.line_no := TRIM(l_wk_item_tab(1));
      g_item_rec.item_code := TRIM(l_wk_item_tab(2));
      g_item_rec.item_name := TRIM(l_wk_item_tab(3));
      g_item_rec.renewal_item_code := TRIM(l_wk_item_tab(4));
      g_item_rec.item_dtl_status := TRIM(l_wk_item_tab(5));
      g_item_rec.remarks := TRIM(l_wk_item_tab(6));
      --
      --�u���j���[�A�������i�R�[�h�v�A�u�i�ڏڍ׃X�e�[�^�X�v�A�u���l�v��NULL�̏ꍇ�X�L�b�v
      IF ( g_item_rec.renewal_item_code IS NULL AND g_item_rec.item_dtl_status IS NULL AND g_item_rec.remarks IS NULL ) THEN
        CONTINUE;
      END IF;
      --==============================================================
      -- A-3  �f�[�^�Ó����`�F�b�N
      --==============================================================
      lv_step := 'A-3';
      validate_item(
        i_wk_item_rec  => g_item_rec              -- �i�ڈꊇ�X�V���[�N���
       ,ov_errbuf      => lv_errbuf               -- �G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode              -- ���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal AND lv_errbuf IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
          which => FND_FILE.LOG,
          buff  => lv_errbuf
        );
      END IF;
      IF ( lv_retcode = cv_status_normal ) THEN
        --==============================================================
        -- A-4  �f�[�^�o�^
        --==============================================================
        lv_step := 'A-4';
        ins_data(
          i_wk_item_rec  => g_item_rec              -- �i�ڈꊇ�X�V���[�N���
         ,ov_errbuf      => lv_errbuf               -- �G���[�E���b�Z�[�W
         ,ov_retcode     => lv_retcode              -- ���^�[���E�R�[�h
         ,ov_errmsg      => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode <> cv_status_normal AND lv_errbuf IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(
            which => FND_FILE.LOG,
            buff  => lv_errbuf
          );
        END IF;
      END IF;
      --
      --==============================================================
      -- �����������Z
      --==============================================================
      IF ( lv_retcode = cv_status_normal ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
      --�G���[�X�e�[�^�X�ޔ�
      IF ( lv_retcode = cv_status_error ) THEN
        lv_check_error := cv_status_error;
      END IF;
--
    END LOOP ins_wk_loop;
    --
    -- �����Ώی������i�[
    gn_target_cnt := gn_normal_cnt + gn_error_cnt;
    --
    -- �X�e�[�^�X�ޔ����G���[�Ȃ�G���[��Ԃ�
    IF ( lv_check_error = cv_status_error ) THEN
      ov_retcode := cv_status_error;
    END IF;
  EXCEPTION
    -- *** �f�[�^���ڐ��G���[��O�n���h�� ***
    WHEN get_if_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00028            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                  -- TABLE
                    ,iv_token_value1 => cv_msg_xxcmm_30406            -- �i�ڈꊇ�X�V
                    ,iv_token_name2  => cv_tkn_count                  -- COUNT
                    ,iv_token_value2 => ln_item_num                   -- ���ڐ�
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_id    IN  VARCHAR2          -- 1.�t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- 2.�t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W                 --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h                   --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W       --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init';                        -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);                                                  -- �G���[�E���b�Z�[�W
    lv_errmsg  VARCHAR2(5000);                                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                                     -- �X�e�b�v
    lv_tkn_value              VARCHAR2(100);                                    -- �g�[�N���l
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM��ޔ�
    --
    lv_upload_obj             VARCHAR2(100);                                    -- �t�@�C���A�b�v���[�h����
    lv_up_name                VARCHAR2(1000);                                   -- �A�b�v���[�h���̏o�͗p
    lv_file_id                VARCHAR2(1000);                                   -- �t�@�C��ID�o�͗p
    lv_file_format            VARCHAR2(1000);                                   -- �t�H�[�}�b�g�o�͗p
    lv_file_name              VARCHAR2(1000);                                   -- �t�@�C�����o�͗p
    lt_csv_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;       -- CSV�t�@�C�����o�͗p
    ln_cnt                    NUMBER;                                           -- �J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �f�[�^���ڒ�`�擾�p�J�[�\��
    CURSOR     get_def_info_cur
    IS
      SELECT   flv.meaning                         AS item_name                 -- ���e
              ,DECODE(flv.attribute1, cv_varchar, cv_varchar_cd
                                    , cv_number,  cv_number_cd
                                    , cv_date_cd)  AS item_attribute            -- ���ڑ���
              ,DECODE(flv.attribute2, cv_not_null, cv_null_ng
                                    , cv_null_ok)  AS item_essential            -- �K�{�t���O
              ,TO_NUMBER(flv.attribute3)           AS item_length               -- ���ڂ̒���(��������)
      FROM     fnd_lookup_values_vl  flv                                        -- LOOKUP�\
      WHERE    flv.lookup_type        = cv_lookup_item_def                      -- �i�ڈꊇ�X�V�f�[�^���ڒ�`
      AND      flv.enabled_flag       = cv_yes                                  -- �g�p�\�t���O
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- �K�p�J�n��
      AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date   -- �K�p�I����
      ORDER BY flv.lookup_code;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_param_expt            EXCEPTION;                                        -- �p�����[�^NULL�G���[
    process_date_expt         EXCEPTION;                                        -- �Ɩ����t�擾���s�G���[
    get_profile_expt          EXCEPTION;                                        -- �v���t�@�C���擾��O
    select_file_expt          EXCEPTION;                                        -- �f�[�^���o�G���[�iLOOKUP�\�j
    select_csvfile_expt       EXCEPTION;                                        -- �f�[�^���o�G���[�i�t�@�C���A�b�v���[�hIF�e�[�u���j
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    ln_cnt           := 0;
    --==============================================================
    -- A-1.1 ���̓p�����[�^�iFILE_ID�A�t�H�[�}�b�g�j�́uNULL�v�`�F�b�N
    --==============================================================
    lv_step := 'A-1.1';
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_file_id;
      RAISE get_param_expt;
    END IF;
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := xxccp_common_pkg.get_msg(                                 -- �t�H�[�}�b�g�̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_30400                   -- ���b�Z�[�W�R�[�h
                      );
      RAISE get_param_expt;
    END IF;
    --
    -- IN�p�����[�^���i�[
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- A-1.2 �Ɩ����t�̎擾
    --==============================================================
    lv_step := 'A-1.2';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- NULL�`�F�b�N
    IF ( gd_process_date IS NULL ) THEN
      lv_tkn_value := xxccp_common_pkg.get_msg(                                 -- �t�H�[�}�b�g�̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_30401                   -- ���b�Z�[�W�R�[�h
                      );
      RAISE process_date_expt;
    END IF;
    --
    --==============================================================
    -- A-1.3 �t�@�C���A�b�v���[�h���̎擾
    --==============================================================
    lv_step := 'A-1.3';
    BEGIN
      SELECT   flv.meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv
      WHERE    flv.lookup_type  = cv_lookup_type_upload_obj                     -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
      AND      flv.lookup_code  = gv_format                                     -- �t�H�[�}�b�g
      AND      flv.enabled_flag = cv_yes                                        -- �g�p�\�t���O
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- �K�p�J�n��
      AND      NVL(flv.end_date_active,   gd_process_date) >= gd_process_date   -- �K�p�I����
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE select_file_expt;
    END;
    --
    --==============================================================
    -- A-1.4 Disc�i�ڃA�h�I���̍X�V���ڏ��擾�̎擾
    --==============================================================
    lv_step := 'A-1.4';
    -- �ϐ��̏�����
    ln_cnt := 0;
    -- �e�[�u����`�擾LOOP
    <<def_info_loop>>
    FOR get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_item_def_tab(ln_cnt).item_name      := get_def_info_rec.item_name;      -- ���ږ�
      g_item_def_tab(ln_cnt).item_attribute := get_def_info_rec.item_attribute; -- ���ڑ���
      g_item_def_tab(ln_cnt).item_essential := get_def_info_rec.item_essential; -- �K�{�t���O
      g_item_def_tab(ln_cnt).item_length    := get_def_info_rec.item_length;    -- ���ڂ̒���(��������)
    END LOOP def_info_loop;
    --
    --==============================================================
    -- A-1.5 CSV�t�@�C�����̎擾
    --==============================================================
    lv_step := 'A-1.5';
    BEGIN
      SELECT   fui.file_name                                                    -- �t�@�C����
      INTO     lt_csv_file_name
      FROM     xxccp_mrp_file_ul_interface  fui                                 -- �t�@�C���A�b�v���[�hIF�e�[�u��
      WHERE    fui.file_id = gn_file_id                                         -- �t�@�C��ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE select_csvfile_expt;
    END;
    --
    --==============================================================
    -- A-1.6 IN�p�����[�^�̏o��
    --==============================================================
    lv_step := 'A-1.6';
    lv_up_name     := xxccp_common_pkg.get_msg(                                 -- �A�b�v���[�h���̂̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00021                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_up_name                       -- UPLOAD_NAME
                       ,iv_token_value1 => lv_upload_obj                        -- �t�@�C���A�b�v���[�h����
                      );
    lv_file_name   := xxccp_common_pkg.get_msg(                                 -- �t�@�C�����̂̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00022                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_name                     -- FILE_NAME
                       ,iv_token_value1 => lt_csv_file_name                     -- CSV�t�@�C������
                      );
    lv_file_id     := xxccp_common_pkg.get_msg(                                 -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00023                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_id                       -- FILE_ID
                       ,iv_token_value1 => TO_CHAR(gn_file_id)                  -- FILE_ID
                      );
    lv_file_format := xxccp_common_pkg.get_msg(                                 -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00024                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_format                    -- FORMAT
                      ,iv_token_value1 => gv_format                             -- �t�H�[�}�b�g�p�^�[��
                      );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT                                 -- �o�͂ɕ\��
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG                                    -- ���O�ɕ\��
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
    --*** �p�����[�^NULL�G���[ ***
    WHEN get_param_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00401                      -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_value                            -- VALUE
                    ,iv_token_value1 => lv_tkn_value                            -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �Ɩ����t�擾���s�G���[ ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00435                      -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_value                            -- VALUE
                    ,iv_token_value1 => lv_tkn_value                            -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �f�[�^���o�G���[(�A�b�v���[�h�t�@�C������) ***
    WHEN select_file_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00439                      -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                            -- TABLE
                    ,iv_token_value1 => cv_msg_xxcmm_30402                      -- LOOKUP�\
                    ,iv_token_name2  => cv_tkn_errmsg                           -- ERR_MSG
                    ,iv_token_value2 => lv_sqlerrm                              -- �G���[���b�Z�[�W
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �f�[�^���o�G���[(CSV�t�@�C������) ***
    WHEN select_csvfile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00439                      -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                            -- TABLE
                    ,iv_token_value1 => cv_msg_xxcmm_30404                      -- �t�@�C���A�b�v���[�hIF
                    ,iv_token_name2  => cv_tkn_errmsg                           -- ERR_MSG
                    ,iv_token_value2 => lv_sqlerrm                              -- �G���[���b�Z�[�W
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
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
    iv_file_id    IN  VARCHAR2          -- 1.�t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- 2.�t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    lv_errbuf_bk              VARCHAR2(5000);                         -- �G���[�E���b�Z�[�W
    lv_errmsg_bk              VARCHAR2(5000);                         -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    sub_proc_expt             EXCEPTION;                              -- �T�u�v���O�����G���[
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
    -- ���[�J���ϐ�������
    lv_errbuf     := NULL;
    lv_retcode    := cv_status_normal;
    lv_errmsg     := NULL;
    lv_errbuf_bk  := NULL;
    lv_errmsg_bk  := NULL;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --==============================================================
    -- A-1.  ��������
    --==============================================================
    lv_step := 'A-1';
    proc_init(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
    --==============================================================
    -- A-5.  �I������
    --==============================================================
      ROLLBACK;
      --A-1�̃��b�Z�[�W�ޔ�
      lv_errbuf_bk := lv_errbuf;
      lv_errmsg_bk := lv_errmsg;
      proc_comp(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --A-5������I���̏ꍇA-1�̃G���[��\��
      IF ( lv_retcode = cv_status_normal ) THEN
        lv_errbuf  := lv_errbuf_bk;
        lv_errmsg  := lv_errmsg_bk;
      END IF;
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-2.  �t�@�C���A�b�v���[�hIF�f�[�^�擾
      -- A-3.  �f�[�^�Ó����`�F�b�N
      -- A-4.  �f�[�^�o�^
    --==============================================================
    lv_step := 'A-2';
    get_if_data(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
    --==============================================================
    -- A-5.  �I������
    --==============================================================
      ROLLBACK;
      --A-1�̃��b�Z�[�W�ޔ�
      lv_errbuf_bk := lv_errbuf;
      lv_errmsg_bk := lv_errmsg;
      proc_comp(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --A-5������I���̏ꍇA-2�̃G���[��\��
      IF ( lv_retcode = cv_status_normal ) THEN
        lv_errbuf  := lv_errbuf_bk;
        lv_errmsg  := lv_errmsg_bk;
      END IF;
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    -- A-5.  �I������
    --==============================================================
    lv_step := 'A-5';
    proc_comp(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    -- �G���[������΃��^�[���E�R�[�h���G���[�ŕԂ�
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
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
    errbuf        OUT    VARCHAR2       --   �G���[�E���b�Z�[�W
   ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h
   ,iv_file_id    IN     VARCHAR2       --   �t�@�C��ID
   ,iv_format     IN     VARCHAR2       --   �t�H�[�}�b�g
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
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
    -- ���[�J���ϐ�������
    lv_errbuf       := NULL;
    lv_retcode      := cv_status_normal;
    lv_errmsg       := NULL;
    lv_message_code := NULL;
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_log
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- ���b�Z�[�W(OUTPUT)�o��
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_success_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_error_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
END XXCMM004A15C;
/
