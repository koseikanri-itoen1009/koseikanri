CREATE OR REPLACE PACKAGE BODY XXINV550005C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550005C(body)
 * Description      : �v��E�ړ��E�݌ɁF�݌�(���[)
 * MD.050/070       : T_MD050_BPO_550_�݌�(���[)Issue1.0 (T_MD050_BPO_550)
 *                  : �I���X�i�b�v�V���b�g�쐬           (T_MD070_BPO_55E)
 * Version          : 1.0
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/22    1.0  Oracle �勴�F�Y  �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  gv_pkg_name            CONSTANT VARCHAR2(20) := 'XXINV550005C' ;     -- �p�b�P�[�W��
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_inv     CONSTANT VARCHAR2(5)   := 'XXINV' ;           -- �A�v���P�[�V�����iXXINV�j
  gc_xxinv_10117         CONSTANT VARCHAR2(15)  := 'APP-XXINV-10117' ; -- �I���X�i�b�v�V���b�g�쐬�G���[
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  parameter_check_expt     EXCEPTION;     -- �p�����[�^�`�F�b�N��O
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_invent_ym             IN  VARCHAR2     -- 01 : �Ώ۔N��	
    ,iv_whse_code1            IN  VARCHAR2     -- 02 : �q�ɃR�[�h�P
    ,iv_whse_code2            IN  VARCHAR2     -- 03 : �q�ɃR�[�h�Q
    ,iv_whse_code3            IN  VARCHAR2     -- 04 : �q�ɃR�[�h�R
    ,iv_whse_department1      IN  VARCHAR2     -- 05 : �q�ɊǗ������P
    ,iv_whse_department2      IN  VARCHAR2     -- 06 : �q�ɊǗ������Q
    ,iv_whse_department3      IN  VARCHAR2     -- 07 : �q�ɊǗ������R
    ,iv_block1                IN  VARCHAR2     -- 08 : �u���b�N�P
    ,iv_block2                IN  VARCHAR2     -- 09 : �u���b�N�Q
    ,iv_block3                IN  VARCHAR2     -- 10 : �u���b�N�R
    ,iv_arti_div_code         IN  VARCHAR2     -- 11 : ���i�敪
    ,iv_item_class_code       IN  VARCHAR2     -- 12 : �i�ڋ敪
    ,ov_errbuf                OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode               OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg                OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
--
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
    -- *** ���[�J���ϐ� ***
    ln_ret_num        NUMBER ;        -- �֐��߂�l�F���l�^
    lv_err_code       VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    create_snap_expt  EXCEPTION ;     -- �I���X�i�b�v�V���b�g�쐬�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �I���X�i�b�v�V���b�g�쐬�v���O�����ďo
    -- ====================================================
    ln_ret_num := xxinv550004c.create_snapshot( iv_invent_ym         -- �Ώ۔N��
                                               ,iv_whse_code1        -- �q�ɃR�[�h1
                                               ,iv_whse_code2        -- �q�ɃR�[�h2
                                               ,iv_whse_code3        -- �q�ɃR�[�h3
                                               ,iv_whse_department1  -- �q�ɊǗ�����1
                                               ,iv_whse_department2  -- �q�ɊǗ�����2
                                               ,iv_whse_department3  -- �q�ɊǗ�����3
                                               ,iv_block1            -- �u���b�N1
                                               ,iv_block2            -- �u���b�N2
                                               ,iv_block3            -- �u���b�N3
                                               ,iv_arti_div_code     -- ���i�敪
                                               ,iv_item_class_code   -- �i�ڋ敪
                                              )
    ;
    IF ( ln_ret_num <> 0 ) THEN
      lv_err_code := gc_xxinv_10117 ;
      RAISE create_snap_expt ;
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg  ;
    ov_errbuf  := lv_errbuf  ;
--
  EXCEPTION
    --*** �I���X�i�b�v�V���b�g�쐬�G���[��O ***
    WHEN create_snap_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv
                                            ,lv_err_code    ) ;
      ov_errmsg := lv_errmsg ;
      ov_errbuf := SQLERRM;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
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
 PROCEDURE main
    (
      errbuf                  OUT  VARCHAR2     -- �G���[���b�Z�[�W
     ,retcode                 OUT  VARCHAR2     -- �G���[�R�[�h
     ,iv_invent_ym            IN   VARCHAR2     -- 01. �Ώ۔N��	
     ,iv_whse_code1           IN   VARCHAR2     -- 02. �q�ɃR�[�h�P
     ,iv_whse_code2           IN   VARCHAR2     -- 03. �q�ɃR�[�h�Q
     ,iv_whse_code3           IN   VARCHAR2     -- 04. �q�ɃR�[�h�R
     ,iv_whse_department1     IN   VARCHAR2     -- 05. �q�ɊǗ������P
     ,iv_whse_department2     IN   VARCHAR2     -- 06. �q�ɊǗ������Q
     ,iv_whse_department3     IN   VARCHAR2     -- 07. �q�ɊǗ������R
     ,iv_block1               IN   VARCHAR2     -- 08. �u���b�N�P
     ,iv_block2               IN   VARCHAR2     -- 09. �u���b�N�Q
     ,iv_block3               IN   VARCHAR2     -- 10. �u���b�N�R
     ,iv_arti_div_code        IN   VARCHAR2     -- 11. ���i�敪
     ,iv_item_class_code      IN   VARCHAR2     -- 12. �i�ڋ敪
    ) 
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_invent_ym           -- 01 : �Ώ۔N��	
      ,iv_whse_code1          -- 02 : �q�ɃR�[�h�P
      ,iv_whse_code2          -- 03 : �q�ɃR�[�h�Q
      ,iv_whse_code3          -- 04 : �q�ɃR�[�h�R
      ,iv_whse_department1    -- 05 : �q�ɊǗ������P
      ,iv_whse_department2    -- 06 : �q�ɊǗ������Q
      ,iv_whse_department3    -- 07 : �q�ɊǗ������R
      ,iv_block1              -- 08 : �u���b�N�P
      ,iv_block2              -- 09 : �u���b�N�Q
      ,iv_block3              -- 10 : �u���b�N�R
      ,iv_arti_div_code       -- 11 : ���i�敪
      ,iv_item_class_code     -- 12 : �i�ڋ敪
      ,lv_errbuf              -- �G���[�E���b�Z�[�W
      ,lv_retcode             -- ���^�[���E�R�[�h
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXINV550005C;
/