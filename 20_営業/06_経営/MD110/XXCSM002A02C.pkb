CREATE OR REPLACE PACKAGE BODY XXCSM002A02C AS
/*******************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A02C(spec)
 * Description      : ���i�v��Q�ʌv�掑���o��
 * MD.050           : ���i�v��Q�ʌv�掑���o�� MD050_CSM_002_A02
 * Version          : 1.2
 *
 * Program List
 * -------------------- --------------------------------------------------------
 *  Name                 Description
 *
 * init                 �y���������z�FA-1
 *
 * do_check             �y�`�F�b�N�����z�FA-2
 * 
 * deal_group4_data     �y���i�Q4���f�[�^�̏ڍ׏����zA-3,A-4,A-5
 *
 * deal_group3_data     �y���i�Q3���f�[�^�̏ڍ׏����zA-6,A-7,A-8
 * 
 * write_line_info      �y���i�Q4���P�ʂŃf�[�^�̏o�́zA-9
 * 
 * write_csv_file       �y���i�v��Q�ʌv�掑���o�̓f�[�^��CSV�t�@�C���֏o�́zA-9
 *  
 * final                �y�I�������zA-10
 *  
 * submain              �y���������z
 * 
 * main                 �y���C�������z
 * 
 * Change Record
 * ------------- ----- ---------------- ----------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ----------------------------------------
 *  2008/12/04    1.0   ohshikyo        �V�K�쐬
 *  2009/02/17    1.1   M.Ohtsuki      �m��QCT_023�n����0�̕s��̑Ή�
 *  2009/02/18    1.2   K.Sai          �m��QCT_026�n�e���v�z�̏����_2���\���s����w�b�_���t�\���Ή� 
 *
******************************************************************************/
--
-- 
 --#######################  �Œ�O���[�o���萔�錾�� START   ######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;           -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;             -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;            -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                           -- CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                                      -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                           -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                                      -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                          -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;                   -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;                      -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;                   -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                                      -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';

  
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                             -- �Ώی���
  gn_normal_cnt             NUMBER;                                             -- ���팏��
  gn_error_cnt              NUMBER;                                             -- �G���[����
  gn_warn_cnt               NUMBER;                                             -- �X�L�b�v����
--
--################################  �Œ蕔 END   ################################
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
--################################  �Œ蕔 END   ################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--  
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM002A02C';           -- �p�b�P�[�W��
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                      -- �J���}     
  cv_msg_hafu               CONSTANT VARCHAR2(3)   := '-';                      -- 
  cv_msg_space              CONSTANT VARCHAR2(2)   := '';                       -- ��
  cv_msg_duble              CONSTANT VARCHAR2(3)   := '"';                      -- �_�u���N�H�[�e�[�V����
  cv_msg_star               CONSTANT VARCHAR2(3)   := '*';                      -- 
  
    
  cv_msg_linespace          CONSTANT VARCHAR2(20)   := cv_msg_duble || cv_msg_space || cv_msg_duble|| cv_msg_comma ;
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                  -- �A�v���P�[�V�����Z�k��        
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                  -- �A�h�I���F���ʁEIF�̈�
  cv_unit                   CONSTANT NUMBER        := 1000;                     -- �o�͒P�ʁF��~
-- 
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ� 
  -- ===============================
--  
  gd_process_date           DATE;                                               -- �Ɩ����t
  gn_index                  NUMBER := 0;                                        -- �o�^��
  gv_kyotencd               VARCHAR2(32);                                       -- ���_�R�[�h
  gn_taisyoym               NUMBER(4,0);                                        -- �Ώ۔N�x
  gv_kyotennm               VARCHAR2(200);                                      -- ���_����
  
  
  -- ===============================
  -- ���p���b�Z�[�W�ԍ�
  -- ===============================
--  
  cv_ccp_msg_90000           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';         -- �Ώی������b�Z�[�W
  cv_ccp_msg_90001           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';         -- �����������b�Z�[�W
  cv_ccp_msg_90002           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';         -- �G���[�������b�Z�[�W
  cv_ccp_msg_90003           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';         -- �X�L�b�v�������b�Z�[�W
  cv_ccp_msg_90004           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';         -- ����I�����b�Z�[�W
  cv_ccp_msg_90006           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';         -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_ccp1_msg_00111          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';         -- �z��O�G���[���b�Z�[�W
--  
  -- ===============================  
  -- ���b�Z�[�W�ԍ�
  -- ===============================
--  
  cv_csm_msg_00005           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';         -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_csm_msg_00099           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00099';         -- ���i�v��p�Ώۃf�[�^�������b�Z�[�W
  cv_csm_msg_00096           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00096';         -- ���i�v��Q�ʌv�掑���o��(���i��2���N����)�w�b�_�p���b�Z�[�W
  cv_csm_msg_00024           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00024';         -- ���_�R�[�h�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_00048           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';         -- ���̓p�����[�^�擾���b�Z�[�W(���_�R�[�h)
  cv_csm_msg_10015           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10015';         -- ���̓p�����[�^�擾���b�Z�[�W�i�Ώ۔N�x�j
--
  -- ===============================
  -- �g�[�N����`
  -- ===============================
--  
  cv_tkn_year                      CONSTANT VARCHAR2(100) := 'TAISYOU_YM';       -- �Ώ۔N�x
  cv_tkn_kyotencd                  CONSTANT VARCHAR2(100) := 'KYOTEN_CD';       -- ���_�R�[�h
  cv_tkn_kyotennm                  CONSTANT VARCHAR2(100) := 'KYOTEN_NM';       -- ���_����
  cv_tkn_profile                   CONSTANT VARCHAR2(100) := 'PROF_NAME';       -- �v���t�@�C����
  cv_tkn_sysdate                   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI'; -- �쐬����
  cv_cnt_token                     CONSTANT VARCHAR2(10)  := 'COUNT';           -- ����
 

  -- =============================== 
  -- �v���t�@�C��
  -- ===============================
-- �v���t�@�C���E�R�[�h  
  lv_prf_cd_item                CONSTANT VARCHAR2(100) := 'XXCSM1_DEAL_CATEGORY';    -- XXCMN:����Q�i�ڃJ�e�S�����薼
  lv_prf_cd_sale                CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';  -- XXCMN:����
  lv_prf_cd_margin              CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6'; -- XXCMN:�e���v�z
  lv_prf_cd_mrate               CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_7'; -- XXCMN:�e���v��
  lv_prf_cd_make                CONSTANT VARCHAR2(100) := 'XXCSM1_PLANGUN_ITEM_1';   -- XXCMN:�\����
  lv_prf_cd_ext                 CONSTANT VARCHAR2(100) := 'XXCSM1_PLANGUN_ITEM_2';   -- XXCMN:�O�N�L����
  lv_prf_cd_year                CONSTANT VARCHAR2(100) := 'XXCSM1_UNIT_ITEM_3';      -- XXCMN:�N

  

-- �v���t�@�C���E����
  lv_prf_cd_item_val              VARCHAR2(100) ;                                 -- XXCMN:����Q�i�ڃJ�e�S�����薼
  lv_prf_cd_sale_val              VARCHAR2(100) ;                                 -- XXCMN:����
  lv_prf_cd_margin_val            VARCHAR2(100) ;                                 -- XXCMN:�e���v�z
  lv_prf_cd_mrate_val             VARCHAR2(100) ;                                 -- XXCMN:�e���v��
  lv_prf_cd_make_val              VARCHAR2(100) ;                                 -- XXCMN:�\���� 
  lv_prf_cd_ext_val               VARCHAR2(100) ;                                 -- XXCMN:�O�N�L���� 
  lv_prf_cd_year_val              VARCHAR2(100) ;                                 -- XXCMN:�N 
  
    
    /****************************************************************************
   * Procedure Name   : init
   * Description      : ��������            
   ****************************************************************************/
   PROCEDURE init (    
         ov_errbuf     OUT NOCOPY VARCHAR2               --���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2               --���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --���[�U�[�E�G���[�E���b�Z�[�W
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- �p�����[�^���b�Z�[�W�o�͗p
    lv_pram_op_1                VARCHAR2(100);
    lv_pram_op_2                VARCHAR2(100);
    
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value                VARCHAR2(1000);
    
--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################


-- �Ɩ����t

    gd_process_date := xxccp_common_pkg2.get_process_date;                      -- �Ɩ����t�擾
    

-- ���_�R�[�h(IN�p�����[�^�̏o��)
    lv_pram_op_1 := xxccp_common_pkg.get_msg(                                   -- ���_�R�[�h�̏o��
                      iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm_msg_00048                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- �g�[�N���R�[�h1�i���_�R�[�h�j
                     ,iv_token_value1 => gv_kyotencd                            -- �g�[�N���l1
                     );
    -- LOG�ɏo��                 
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                     
                     ,buff   => CHR(10) || lv_pram_op_1 
                     );  
-- �Ώ۔N�x(IN�p�����[�^�̏o��)
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                   -- �Ώ۔N�x�̏o��
                      iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm_msg_10015                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_year                            -- �g�[�N���R�[�h1�i�Ώ۔N�x���́j
                     ,iv_token_value1 => gn_taisyoym                            -- �g�[�N���l1
                     );
                     
    -- LOG�ɏo��                 
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                     
                     ,buff   => lv_pram_op_2 || CHR(10) 
                     ); 

--

-- ===========================================================================
-- �v���t�@�C�����̎擾
-- ===========================================================================
    -- �ϐ����������� 
    lv_tkn_value := NULL;
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    name => lv_prf_cd_item
                   ,val  => lv_prf_cd_item_val
                   ); --����Q�i�ڃJ�e�S�����薼
    FND_PROFILE.GET(
                    name => lv_prf_cd_sale
                   ,val  => lv_prf_cd_sale_val
                   ); -- ����
    FND_PROFILE.GET(
                    name => lv_prf_cd_margin
                   ,val  => lv_prf_cd_margin_val
                   ); -- �e���v�z
    FND_PROFILE.GET(
                    name => lv_prf_cd_mrate
                   ,val  => lv_prf_cd_mrate_val
                   ); -- �e���v��
    FND_PROFILE.GET(
                    name => lv_prf_cd_make
                   ,val  => lv_prf_cd_make_val
                   ); -- �\����
    FND_PROFILE.GET(
                    name => lv_prf_cd_ext
                   ,val  => lv_prf_cd_ext_val
                   ); -- �O�N�L����
    FND_PROFILE.GET(
                    name => lv_prf_cd_year
                   ,val  => lv_prf_cd_year_val
                   ); -- �N
    

    -- =========================================================================
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- =========================================================================
      -- ����Q�i�ڃJ�e�S�����薼
    IF (lv_prf_cd_item_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_item;
        -- ����
    ELSIF (lv_prf_cd_sale_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_sale;
        -- �e���v�z
    ELSIF (lv_prf_cd_margin_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_margin;
        -- �e���v��
    ELSIF (lv_prf_cd_mrate_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_mrate;
        -- �\����
    ELSIF (lv_prf_cd_make_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_make;
        -- �O�N�L����
    ELSIF (lv_prf_cd_ext_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_ext;
        -- �O�N�L����
    ELSIF (lv_prf_cd_year_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_year;
    END IF;
    
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm_msg_00005                        -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_profile                          -- �g�[�N���R�[�h1�i�v���t�@�C���j
                    ,iv_token_value1 => lv_tkn_value                            -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ###########################
--
  END init;
--

   /****************************************************************************
   * Procedure Name   : do_check
   * Description      : �`�F�b�N����            
   ****************************************************************************/
   PROCEDURE do_check (
         ov_errbuf     OUT NOCOPY VARCHAR2               -- ���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              -- ���[�U�[�E�G���[�E���b�Z�[�W
   IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--

-- ===============================
-- �Œ胍�[�J���萔
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'do_check'; -- �v���O������
    
-- ===============================
-- �Œ胍�[�J���ϐ�
-- ===============================
    -- ���_�R�[�h
    lv_kyoten_cd              VARCHAR2(32); 
    
    -- �f�[�^���݃`�F�b�N�p
    ln_counts                 NUMBER(1,0) := 0;
  
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

    -- ���_�̑��݃`�F�b�N

    SELECT  
          base_name                               -- ���喼��
          ,base_code                              -- ����R�[�h
    INTO    
           gv_kyotennm
          ,lv_kyoten_cd
    FROM    
          xxcsm_loc_name_list_v                   -- ���喼�̃r���[
    WHERE   
          base_code = gv_kyotencd;                -- ���_�R�[�h

    --���݂��Ȃ��ꍇ�A�G���[���b�Z�[�W���o���āA���������~���܂��B                                
    IF (lv_kyoten_cd IS NULL ) THEN
    lv_retcode := cv_status_error;
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcsm                                -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_csm_msg_00024                           -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_kyotencd                         -- �g�[�N���R�[�h1�i���_�R�[�h�j
                  ,iv_token_value1 => gv_kyotencd                             -- �g�[�N���l1
                 );
      lv_errbuf := lv_errmsg;
    RAISE global_api_others_expt;
    END IF;

-- =============================================================================
-- ���уf�[�^�̑��݃`�F�b�N
-- =============================================================================
    --������
    ln_counts := 0;

    --���уf�[�^�̒��o
    SELECT  
            COUNT(1)
    INTO    
            ln_counts
    FROM    
            xxcsm_item_plan_result                  -- �N�Ԕ̔��v��p���уe�[�u��
    WHERE   
            (subject_year   = gn_taisyoym -1        -- �O�N�x
    OR      subject_year    = gn_taisyoym -2)       -- �O�X�N�x
    AND     location_cd     = gv_kyotencd           -- ���_�R�[�h
    AND     rownum          = 1;
    
    -- ������0�̏ꍇ�A�����͒��~
   IF (ln_counts = 0) THEN
       lv_retcode := cv_status_error;
       lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcsm                              -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_csm_msg_00099                         -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_kyotencd                       -- �g�[�N���R�[�h1�i���_�R�[�h�j
                   ,iv_token_value1 => gv_kyotencd                           -- �g�[�N���l1
                   ,iv_token_name2  => cv_tkn_year                           -- �g�[�N���R�[�h2�i�Ώ۔N�x�j
                   ,iv_token_value2 => gn_taisyoym                           -- �g�[�N���l2
                  );
       lv_errbuf := lv_errmsg;
       RAISE global_api_others_expt;
   END IF;

--

--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    -- *** ���_�R�[�h�����݂��Ȃ��ꍇ ***
    WHEN NO_DATA_FOUND THEN
      lv_retcode := cv_status_error;
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcsm                                -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_csm_msg_00024                           -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_kyotencd                         -- �g�[�N���R�[�h1�i���_�R�[�h�j
                  ,iv_token_value1 => gv_kyotenCD                             -- �g�[�N���l1
                 );
      lv_errbuf  := lv_errmsg;
      
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ###########################
--
  END do_check;
--

   /****************************************************************************
   * Procedure Name   : deal_group4_data
   * Description      : ���i�Q�R�[�h4���f�[�^�̏ڍ׏���
   *                    �@�f�[�^�̒��o
   *                    �A�f�[�^�̎Z�o
   *                    �B�f�[�^�̓o�^
   *****************************************************************************/
   PROCEDURE deal_group4_data(
         ov_errbuf     OUT NOCOPY VARCHAR2               --���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2               --���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --���[�U�[�E�G���[�E���b�Z�[�W
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_group4_data';      -- �v���O������

    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_group4_cd            VARCHAR2(32);               --���i�Q4���R�[�h
-- �N��    
    ln_y_sales              NUMBER  := 0;               --�N��_������z���v
    ln_y_margin             NUMBER  := 0;               --�N��_�e���v�z���v
    ln_y_margin_r           NUMBER  := 0;               --�N��_�e���v��

--  �ꎞ�ϐ�  
    ln_year                 NUMBER  := 0;               --�N�x���f�p�ϐ�
    lb_loop_end             BOOLEAN := FALSE;           --LOOP�������f�p
       
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--============================================
--  �f�[�^�̒��o�y���i�Q4���z�J�[�\��
--============================================
    CURSOR   
        get_sales_group4_data_cur
    IS
      SELECT   
             xipr.subject_year                       AS  year            -- �Ώ۔N�x
            ,xipr.month_no                           AS  month           -- ��
            ,SUM(NVL(xipr.sales_budget,0))           AS  sales           -- ������z
            ,SUM(NVL(xipr.amount_gross_margin,0))    AS  margin          -- �e���v�z
            ,xcgv.group4_cd                          AS  group_id        -- ���i�Q4���R�[�h
            ,xcgv.group4_nm                          AS  group_nm        -- ���i�Q4������
      FROM     
             xxcsm_item_plan_result                 xipr                 -- ���i�v��p�̔����уe�[�u��
            ,xxcsm_commodity_group4_v               xcgv                 -- ����Q4�r���[
      WHERE    
          xcgv.item_cd                                   = xipr.item_no           -- ���i�R�[�h
      AND (xipr.subject_year                             = gn_taisyoym-2         -- �Ώ۔N�x�i�O�X�N�x�j
      OR   xipr.subject_year                             = gn_taisyoym-1)        -- �Ώ۔N�x�i�O�N�x�j
      AND  xipr.location_cd                              = gv_kyotencd           -- ���_�R�[�h
      GROUP BY
               xipr.subject_year                        -- �Ώ۔N�x
              ,xipr.month_no                            -- ��
              ,xcgv.group4_cd                           -- ���i�Q4���R�[�h
              ,xcgv.group4_nm                           -- ���i�Q4������
      ORDER BY 
               group_id  ASC
              ,year      ASC
              ,month     ASC
              ,group_nm  ASC;
--                  

--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    <<deal_group4>>
    -- ���i�Q4���f�[�^�̒��o�iLOOP�����j
    FOR rec_group4_data IN get_sales_group4_data_cur LOOP
        
        -- LOOP�������f�p
        lb_loop_end := TRUE;
        
        -- ������(�݌v�l�Z�o�p)
        IF (lv_group4_cd IS NULL) THEN
            -- ���i�Q4���R�[�h
            lv_group4_cd      := rec_group4_data.group_id;
            
            -- �Ώ۔N�x
            ln_year         := rec_group4_data.year;

            -- �N��_����
            ln_y_sales      := rec_group4_data.sales;
            
            -- �N��_�e���v�z
            ln_y_margin     := rec_group4_data.margin;
        
        -- ���i�Q4���R�[�h���ς�����ꍇ�i���̏��i�Q4���R�[�h�j    
        ELSIF ((lv_group4_cd <> rec_group4_data.group_id) OR (ln_year <> rec_group4_data.year)) THEN
           
            -- �N��_�e���v��:�y�Z�o�����z
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--          IF (ln_y_margin = 0) THEN
            IF (ln_y_sales = 0) THEN
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
                ln_y_margin_r := 0;
            ELSE
                -- �N��_�e���v�z��(�N��_����)*100 �y�����_3���l�̌ܓ��z
                ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
            END IF;
            
            --==================================
            -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
            --==================================
            
            UPDATE
                    xxcsm_tmp_sales_plan_gun
            SET
                   y_sales          = ln_y_sales                                -- �N�Ԕ���
                  ,y_margin_rate    = ln_y_margin_r                             -- �N�ԑe���v��
                  ,y_margin         = ln_y_margin                               -- �N�ԑe���v�z
            WHERE
                    group_cd_4      = lv_group4_cd                              -- ���i�Q4���R�[�h
            AND     year            = ln_year;                                  -- �Ώ۔N�x
            
            --===================================
            -- ���̃f�[�^
            --===================================
            -- ���i�Q4���R�[�h
            lv_group4_cd    := rec_group4_data.group_id;
            
            -- �Ώ۔N�x
            ln_year         := rec_group4_data.year;

            -- �N��_����
            ln_y_sales      := rec_group4_data.sales;
            
            -- �N��_�e���v�z
            ln_y_margin     := rec_group4_data.margin;
        -- �N�x�Ə��i�Q�R�[�h�͕ς���Ă��Ȃ��ꍇ�A�N�Ԍv���Z�o����
        ELSIF (ln_year = rec_group4_data.year) THEN
            --===================================
            -- �y����N�x�̏��i�z�N�ԗ݌v�����Z����
            --===================================
            -- �N��_����
            ln_y_sales      := ln_y_sales + rec_group4_data.sales;
            
            -- �N��_�e���v�z
            ln_y_margin     := ln_y_margin + rec_group4_data.margin;

        END IF;
        
        --===================================
        -- �y���i�Q4���P�ʁz�f�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_gun
          (
               toroku_no            -- �o�͏�
              ,group_cd_4           -- ���i�Q�R�[�h(4��)
              ,group_nm_4           -- ���i�Q�R�[�h(4��)
              ,group_cd_3           -- ���i�Q�R�[�h(3��)
              ,group_nm_3           -- ���i�Q�R�[�h(3��)
              ,year                 -- �N�x
              ,month_no             -- ��
              ,m_sales              -- ����_����
              ,m_margin_rate        -- ����_�e���v��=����_�e���v�z�^����_����*100
              ,m_margin             -- ����_�e���v�z
          )
          VALUES (
               gn_index                                 -- �o�^��
              ,rec_group4_data.group_id                 -- ���i�Q�R�[�h(3��) || '*'
              ,rec_group4_data.group_nm                 -- ���i�Q����(3��) 
              ,NULL                                     -- ���i�Q�R�[�h(3��)
              ,NULL                                     -- ���i�Q����(3��)
              ,rec_group4_data.year                     -- �N�x
              ,rec_group4_data.month                    -- ��
              ,rec_group4_data.sales                    -- ����_����
              ,DECODE(rec_group4_data.sales,0,0,ROUND(rec_group4_data.margin / rec_group4_data.sales * 100,2))  -- ����_�e���v��
              ,rec_group4_data.margin
          );
          
          gn_index := gn_index + 1;
    END LOOP deal_group4;
    
    -- �Ō�f�[�^�̏ꍇ
    IF (lb_loop_end) THEN
        
        -- �N��_�e���v��:�y�Z�o�����z
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--      IF (ln_y_margin = 0) THEN
        IF (ln_y_sales = 0) THEN
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
            ln_y_margin_r := 0;
        ELSE
            -- �N��_�e���v�z��(�N��_����)*100 �y�����_3���l�̌ܓ��z
            ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
        END IF;
        
        --==================================
        -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
        --==================================
        
        UPDATE
                xxcsm_tmp_sales_plan_gun
        SET
               y_sales          = ln_y_sales                                -- �N�Ԕ���
              ,y_margin_rate    = ln_y_margin_r                             -- �N�ԑe���v��
              ,y_margin         = ln_y_margin                               -- �N�ԑe���v�z
        WHERE
                group_cd_4      = lv_group4_cd                              -- ���i�Q4���R�[�h
        AND     year            = ln_year;                                  -- �Ώ۔N�x
        
    END IF;

--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_sales_group4_data_cur%ISOPEN) THEN
        CLOSE get_sales_group4_data_cur;
      END IF;
      
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_sales_group4_data_cur%ISOPEN) THEN
        CLOSE get_sales_group4_data_cur;
      END IF;
      

--
--#####################################  �Œ蕔 END   ###########################
--
  END deal_group4_data;
--


   /****************************************************************************
   * Procedure Name   : deal_group3_data
   * Description      : ���i�Q�R�[�h3���f�[�^�̏ڍ׏���
   *                    �@�f�[�^�̒��o
   *                    �A�f�[�^�̎Z�o
   *                    �B�f�[�^�̓o�^
   *****************************************************************************/
   PROCEDURE deal_group3_data(
         ov_errbuf     OUT NOCOPY VARCHAR2               --���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2               --���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --���[�U�[�E�G���[�E���b�Z�[�W
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_group3_data';      -- �v���O������

    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_group3_cd            VARCHAR2(32);               -- ���i�Q3���R�[�h
   
    ln_y_sales              NUMBER  := 0;               -- �N��_������z���v
    ln_y_margin             NUMBER  := 0;               -- �N��_�e���v�z���v
    ln_y_margin_r           NUMBER  := 0;               -- �N��_�e���v��
    ln_year                 NUMBER  := 0;               -- �N�x���f�p�ϐ�
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP�������f�p�ϐ�
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--============================================
--  �f�[�^�̒��o�y���i�Q4���z�J�[�\��
--============================================
    CURSOR   
        get_sales_group3_data_cur
    IS
      SELECT   
             xipr.subject_year                           as  year                -- �Ώ۔N�x
            ,xipr.month_no                               as  month               -- ��
            ,sum(nvl(xipr.sales_budget,0))               as  sales               -- ������z
            ,sum(nvl(xipr.amount_gross_margin,0))        as  margin              -- �e���v�z
            ,xcgv.group3_cd                              as  group_id            -- ���i�Q3���R�[�h
            ,xcgv.group3_nm                              AS  group_nm            -- ���i�Q3������
      FROM     
             xxcsm_item_plan_result                     xipr                     -- ���i�v��p�̔����уe�[�u��
            ,xxcsm_commodity_group3_v                   xcgv                     -- ����Q�Q�r���[
      WHERE    
          xcgv.item_cd                                   = xipr.item_no           -- ���i�R�[�h
      AND (xipr.subject_year                             = gn_taisyoym-2         -- �Ώ۔N�x�i�O�X�N�x�j
      OR   xipr.subject_year                             = gn_taisyoym-1)        -- �Ώ۔N�x�i�O�N�x�j
      AND  xipr.location_cd                              = gv_kyotencd           -- ���_�R�[�h
      GROUP BY
               xipr.subject_year                       -- �Ώ۔N�x
              ,xipr.month_no                           -- ��
              ,xcgv.group3_cd                          -- ���i�Q3���R�[�h
              ,xcgv.group3_nm                          -- ���i�Q3������
      ORDER BY 
               group_id  ASC
              ,year      ASC
              ,month     ASC
              ,group_nm  ASC;

--

--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

    <<deal_group3>>
    -- ���i�Q3���f�[�^�̒��o�iLOOP�����j
    FOR rec_group3_data IN get_sales_group3_data_cur LOOP
        
        -- ���f�p
        lb_loop_end := TRUE;
        
        -- ������(���v�Z�o�p)
        IF (lv_group3_cd IS NULL) THEN
            -- ���i�Q3���R�[�h
            lv_group3_cd    := rec_group3_data.group_id;
            
            -- �Ώ۔N�x
            ln_year         := rec_group3_data.year;

            -- �N��_����
            ln_y_sales      := rec_group3_data.sales;
            
            -- �N��_�e���v�z
            ln_y_margin     := rec_group3_data.margin;
        
        -- ���i�Q3���R�[�h���ς�����ꍇ�i���̏��i�Q3���R�[�h�j    
        ELSIF ((lv_group3_cd <> rec_group3_data.group_id) OR (ln_year <> rec_group3_data.year)) THEN
           
            -- �N��_�e���v��:�y�Z�o�����z
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--          IF (ln_y_margin = 0) THEN
            IF (ln_y_sales = 0) THEN
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
                ln_y_margin_r := 0;
            ELSE
                -- �N��_�e���v�z��(�N��_����)*100 �y�����_3���l�̌ܓ��z
                ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
            END IF;
            
            --==================================
            -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
            --==================================
            
            UPDATE
                    xxcsm_tmp_sales_plan_gun
            SET
                   y_sales          = ln_y_sales                                -- �N��_����
                  ,y_margin_rate    = ln_y_margin_r                             -- �N��_�e���v��
                  ,y_margin         = ln_y_margin                               -- �N��_�e���v�z
            WHERE
                    group_cd_4      = lv_group3_cd                              -- ���i�Q3���R�[�h 
            AND     year            = ln_year;                                  -- �Ώ۔N�x
            
            --===================================
            -- ���̃f�[�^
            --===================================
            -- ���i�Q3���R�[�h
            lv_group3_cd    := rec_group3_data.group_id;
            
            -- �Ώ۔N�x
            ln_year         := rec_group3_data.year;

            -- �N��_����
            ln_y_sales      := rec_group3_data.sales;
            
            -- �N��_�e���v�z
            ln_y_margin     := rec_group3_data.margin;
        -- �N�x�Ə��i�Q�R�[�h�͕ς���Ă��Ȃ��ꍇ�A�N�Ԍv���Z�o����
        ELSIF (ln_year = rec_group3_data.year) THEN
            -- �N��_����
            ln_y_sales      := ln_y_sales + rec_group3_data.sales;
            
            -- �N��_�e���v�z
            ln_y_margin     := ln_y_margin + rec_group3_data.margin;
            
        END IF;
        
        --===================================
        -- �y���i�Q3���P�ʁz�f�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_gun
          (
               toroku_no                -- �o�͏�
              ,group_cd_4               -- ���i�Q�R�[�h(4��)
              ,group_nm_4               -- ���i�Q�R�[�h(4��)
              ,group_cd_3               -- ���i�Q�R�[�h(3��)
              ,group_nm_3               -- ���i�Q�R�[�h(3��)
              ,year                     -- �N�x
              ,month_no                 -- ��
              ,m_sales                  -- ����_����
              ,m_margin_rate            -- ����_�e���v��=����_�e���v�z�^����_����*100
              ,m_margin                 -- ����_�e���v�z
          )
          VALUES (
              gn_index                                          -- �o�͏�
              ,rec_group3_data.group_id                         -- ���i�Q�R�[�h(4��) 
              ,rec_group3_data.group_nm                         -- ���i�Q����(4��) 
              ,SUBSTR(rec_group3_data.group_id,1,3)             -- ���i�Q�R�[�h(3��)
              ,rec_group3_data.group_nm                         -- ���i�Q����(3��)
              ,rec_group3_data.year                             -- �N�x
              ,rec_group3_data.month                            -- ��
              ,rec_group3_data.sales                            -- ����_����
              ,DECODE(rec_group3_data.sales,0,0,ROUND(rec_group3_data.margin / rec_group3_data.sales * 100,2))  -- ����_�e���v��
              ,rec_group3_data.margin                           -- ����_�e���v�z
          );
          gn_index := gn_index + 1;
    END LOOP deal_group3;
    
    -- �Ō�f�[�^�̏ꍇ
    IF (lb_loop_end) THEN
        -- �N��_�e���v��:�y�Z�o�����z
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--      IF (ln_y_margin = 0) THEN
        IF (ln_y_sales = 0) THEN
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
            ln_y_margin_r := 0;
        ELSE
            -- �N��_�e���v�z��(�N��_����)*100 �y�����_3���l�̌ܓ��z
            ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
        END IF;
        
        --==================================
        -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
        --==================================
        
        UPDATE
                xxcsm_tmp_sales_plan_gun
        SET
               y_sales          = ln_y_sales                                -- �N��_����
              ,y_margin_rate    = ln_y_margin_r                             -- �N��_�e���v��
              ,y_margin         = ln_y_margin                               -- �N��_�e���v�z
        WHERE
                group_cd_4      = lv_group3_cd                              -- ���i�Q3���R�[�h 
        AND     year            = ln_year;                                  -- �Ώ۔N�x
    END IF;
    

--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_sales_group3_data_cur%ISOPEN) THEN
        CLOSE get_sales_group3_data_cur;
      END IF;
      
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_sales_group3_data_cur%ISOPEN) THEN
        CLOSE get_sales_group3_data_cur;
      END IF;
      

--
--#####################################  �Œ蕔 END   ###########################
--
  END deal_group3_data;
--



  /*****************************************************************************
   * Procedure Name   : write_Line_Info
   * Description      : ���i�Q4���R�[�h���ɏ����o��
   ****************************************************************************/
  PROCEDURE write_Line_Info(
        iv_group4_cd  IN  VARCHAR2                                                  -- ���i�R�[�h
       ,ov_errbuf     OUT NOCOPY VARCHAR2                                           -- �G���[�E���b�Z�[�W
       ,ov_retcode    OUT NOCOPY VARCHAR2                                           -- ���^�[���E�R�[�h
       ,ov_errmsg     OUT NOCOPY VARCHAR2)                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    
    cv_prg_name   CONSTANT VARCHAR2(100) := 'write_Line_Info';    -- �v���O������ 
    
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################

    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    
    -- ���Ԍv�F�f�[�^�E������
    lv_month_sql                VARCHAR2(2000);
    
    -- �N�Ԍv�F�f�[�^�E������
    lv_sum_sql                  VARCHAR2(2000);
    
    -- �{�f�B�w�b�_���i���i�QCD�b���i�Q���́j
    lv_line_head                VARCHAR2(2000);
    
    -- �����i5��|6��|7��|8��|9��|10��|11��|12��|1��|2��|3��|04���j
    lv_line_info                VARCHAR2(4000);
    
    -- ���ږ���
    lv_item_info                VARCHAR2(4000);
    
    -- LOOP�����p
    in_param                    NUMBER(1,0) := 0;               -- ����0�F����
    lb_loop_end                 BOOLEAN := FALSE;               -- ���f�p
    cn_count                    CONSTANT NUMBER := 4;           -- ���f�p
    
    ln_taisyou_ym               NUMBER(4,0) := gn_taisyoym - 2; -- �O�X�N�x
    
    -- �e���v�ϐ�
    lv_temp_month               VARCHAR2(4000);
    lv_temp_other               VARCHAR2(4000);
    lv_temp_sum                 VARCHAR2(4000);
    cv_all_zero                 CONSTANT VARCHAR2(100)     := '0,0,0,0,0,0,0,0,0,0,0,0,0' || CHR(10);
    cv_year_zero                CONSTANT VARCHAR2(10)      := '0' || CHR(10);
    
-- ���v�J�[�\��
    CURSOR get_month_data_cur(
                        in_param IN NUMBER
                        ,in_year IN NUMBER
                        )
    IS 
        SELECT   DISTINCT
        DECODE(in_param
--//+UPD START 2009/02/18   CT026 K.Sai
--                   ,0,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0) ), 0) / cv_unit,2) || cv_msg_comma               -- ����y���z
--                      || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                   ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma              -- �e���v�z�y���z
--                      || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
                   ,0,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0) ), 0) / cv_unit,0) || cv_msg_comma               -- ����y���z
                      || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                   ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma              -- �e���v�z�y���z
                      || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
--//+UPD END   2009/02/18   CT026 K.Sai
                   ,2,NVL(SUM(DECODE(month_no,5,m_margin_rate,0)  ),0) || cv_msg_comma         -- �e���v���y���z
                      || NVL(SUM(DECODE(month_no,6,m_margin_rate,0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,7,m_margin_rate,0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,8,m_margin_rate,0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,9,m_margin_rate,0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,10,m_margin_rate,0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,11,m_margin_rate,0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,12,m_margin_rate,0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,1,m_margin_rate,0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,2,m_margin_rate,0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,3,m_margin_rate,0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,4,m_margin_rate,0)  ),0) || cv_msg_comma
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--                   ,3,NVL(SUM(DECODE(month_no,5,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma        -- �\����y���z
--                      || NVL(SUM(DECODE(month_no,6,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,7,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,8,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,9,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,10,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,11,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,12,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,1,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,2,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,3,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                     || NVL(SUM(DECODE(month_no,4,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                   ,3,NVL(SUM(DECODE(month_no,5,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma        -- �\����y���z
                      || NVL(SUM(DECODE(month_no,6,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,7,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,8,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,9,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,10,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,11,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,12,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,1,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,2,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,3,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,4,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
                   ,NULL) AS month_data
        FROM  
           xxcsm_tmp_sales_plan_gun       -- ���i�v��Q�ʌv�掑���o�̓��[�N�e�[�u��
        WHERE
              year        = in_year         -- �N�x
        AND   group_cd_4  = iv_group4_cd;   -- ���i�Q�R�[�h

-- �N�v�J�[�\��
    CURSOR  get_year_data_cur(
                        in_param IN NUMBER
                        ,in_year IN NUMBER
                        )
    IS
        SELECT   DISTINCT
                 DECODE(in_param
--//+UPD START 2009/02/18   CT026 K.Sai
--                      ,0,ROUND(NVL(y_sales,0) / cv_unit,2)         || CHR(10)                  -- ����N�v
--                      ,1,ROUND(NVL(y_margin,0) / cv_unit,2)        || CHR(10)                  -- �e���v�z�N�v
                      ,0,ROUND(NVL(y_sales,0) / cv_unit,0)         || CHR(10)                  -- ����N�v
                      ,1,ROUND(NVL(y_margin,0) / cv_unit,0)        || CHR(10)                  -- �e���v�z�N�v
--//+UPD END 2009/02/18   CT026 K.Sai
                      ,2,NVL(y_margin_rate,0)                      || CHR(10)                  -- �e���v���N�v
                      ,3,DECODE(NVL(y_sales,0),0,0,100)            || CHR(10)                  -- �\����N�v
                      ,NULL) AS year_data
        FROM  
              xxcsm_tmp_sales_plan_gun          -- ���i�v��Q�ʌv�掑���o�̓��[�N�e�[�u��
        WHERE
              year        = in_year            -- �N�x
        AND   group_cd_4  = iv_group4_cd;      -- ���i�Q�R�[�h
        
        
-- �y�O�N�L�����z���Ԍv 
    CURSOR  get_ext_month_cur
    IS
        SELECT DISTINCT
                NVL(SUM(DECODE( xwspg_a.month_no, 5,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma   -- �O�N�x�L�����y���z
              || NVL(SUM(DECODE(xwspg_a.month_no, 6,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 7,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 8,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 9,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no,10,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no,11,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no,12,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 1,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 2,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 3,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 4,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
                AS ext_month
        FROM
             xxcsm_tmp_sales_plan_gun xwspg_a                      -- �O�N�x
            ,xxcsm_tmp_sales_plan_gun xwspg_b                      -- �O�X�N�x
        WHERE
            xwspg_a.group_cd_4    = xwspg_b.group_cd_4            -- ���i�Q4���R�[�h
        AND xwspg_a.month_no      = xwspg_b.month_no              -- ��
        AND xwspg_b.year          = gn_taisyoym - 2               -- �O�X�N�x
        AND xwspg_a.year          = gn_taisyoym - 1               -- �O�N�x
        AND xwspg_b.group_cd_4    = iv_group4_cd;                 -- ���i�Q4���R�[�h�ŕR�t�� 
        
 -- �y�O�N�L�����z�N�Ԍv
    CURSOR  
            get_ext_year_cur
    IS
        SELECT DISTINCT
                NVL(DECODE(xwspg_b.y_sales,0,0,ROUND((xwspg_a.y_sales / xwspg_b.y_sales - 1) * 100,2)),0) || CHR(10) -- �L�����N�v      
                AS ext_year
        FROM
             xxcsm_tmp_sales_plan_gun xwspg_a                      -- �O�N�x
            ,xxcsm_tmp_sales_plan_gun xwspg_b                      -- �O�X�N�x
        WHERE
            xwspg_a.group_cd_4    = xwspg_b.group_cd_4            -- ���i�Q4���R�[�h
        AND xwspg_a.month_no      = xwspg_b.month_no              -- ��
        AND xwspg_b.year          = gn_taisyoym - 2               -- �O�X�N�x
        AND xwspg_a.year          = gn_taisyoym - 1               -- �O�N�x
        AND xwspg_b.group_cd_4    = iv_group4_cd;                 -- ���i�Q4���R�[�h�ŕR�t��    

--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ������
    lv_line_head := NULL;
    lv_line_info := NULL;
    lv_item_info := NULL;
    
    --  ���i�Q�R�[�h||���i�Q���̒��o
    SELECT  DISTINCT
            cv_msg_duble || 
            group_cd_4   || 
            cv_msg_duble ||
            cv_msg_comma ||
            cv_msg_duble ||
            group_nm_4   ||
            cv_msg_duble ||
            CHR(10)
    INTO
            lv_line_head
    FROM     
            xxcsm_tmp_sales_plan_gun           -- ���i�v��Q�ʌv�掑���o�̓��[�N�e�[�u��
    WHERE
            group_cd_4 = iv_group4_cd;
    
    --  �ُ�̏ꍇ
    IF (lv_line_head IS NULL) THEN
        RAISE global_api_others_expt;
    END IF;
    
    -- �擪�s(���i�Q�R�[�h||���i�Q��)
    lv_line_info := lv_line_head ;
    
    -- �N�x��LOOP�����y�O�X�N�x~�O�N�x�z
    <<year_loop>>
    WHILE (ln_taisyou_ym < gn_taisyoym ) LOOP
    
        -- ������
        in_param := 0;
        
        <<item_loop>>
        -- ���� ��LOOP�����y 0:����E1:�e���v���E2:�e���v�z�E3:�\����z
        WHILE (in_param < cn_count ) LOOP

            lb_loop_end := FALSE;
            
            -- ���ږ��̂̐ݒ�
            IF (in_param = 0) THEN
                
                -- ����y���ږ��z
                lv_item_info := cv_msg_duble || lv_prf_cd_sale_val || cv_msg_duble || cv_msg_comma;
            ELSIF (in_param = 1) THEN
                
                -- �e���v�z�y���ږ��z
                lv_item_info := cv_msg_duble || lv_prf_cd_margin_val || cv_msg_duble || cv_msg_comma;
            ELSIF (in_param = 2) THEN
                
                -- �e���v���y���ږ��z
                lv_item_info := cv_msg_duble || lv_prf_cd_mrate_val || cv_msg_duble || cv_msg_comma;
            ELSIF (in_param = 3) THEN
                
                -- �\����y���ږ��z
                lv_item_info := cv_msg_duble || lv_prf_cd_make_val || cv_msg_duble || cv_msg_comma;
            END IF;
            
            -- �O�N�x�i�O�X�N�x�j
            lv_temp_other := cv_msg_duble || SUBSTR(ln_taisyou_ym,3,4) || lv_prf_cd_year_val || cv_msg_duble || cv_msg_comma;
            
            -- ��||���ږ���
            lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info || lv_temp_other;
            
            --==================================================================   
            --  �f�[�^���o�y0:����E1:�e���v���E2:�e���v�z�E3:�\����E4:�O�N�L�����z
            --==================================================================
                
            --������
            lv_temp_month := NULL;
            lv_temp_sum   := NULL;
            
            
            -- ���Ԍv
            <<get_month_data>>
            FOR rec IN get_month_data_cur(in_param,ln_taisyou_ym) LOOP
                lb_loop_end := TRUE;
                
                lv_temp_month := rec.month_data;
            END LOOP get_month_data;
            
            IF (lb_loop_end) THEN
                -- �N�Ԍv
                <<get_year_data>>
                FOR rec IN get_year_data_cur(in_param,ln_taisyou_ym) LOOP
                    lb_loop_end := FALSE;
                    lv_temp_sum := rec.year_data;
                END LOOP get_year_data;
                
                IF (lb_loop_end) THEN
                    lv_temp_sum := cv_year_zero;
                END IF;
                
                -- 1�s�̃f�[�^�F�i�󔒁j�{ �i���ږ��́b�N�x�j�{�i5��04���j�{�i�N�Ԍv�j        
                lv_line_info := lv_line_info || lv_temp_month || lv_temp_sum;
            ELSE

                lv_line_info := lv_line_info || cv_all_zero;
            END IF;
            
            -- ���̍���
            in_param := in_param + 1;
        END LOOP item_loop;
        
        -- ��s
        lv_line_info := lv_line_info || CHR(10);
        
        ln_taisyou_ym := ln_taisyou_ym + 1;
    END LOOP year_loop;
    

    -- �O�N�L�����y���ږ��z
    lv_item_info := cv_msg_duble || lv_prf_cd_ext_val || cv_msg_duble || cv_msg_comma;
    
    
    lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info || lv_temp_other ;
    
    -- ������
    lb_loop_end := FALSE;
    lv_temp_month := NULL;
    lv_temp_sum   := NULL;
    
    -- �O�N�L�����y���Ԍv�z���o
    <<get_ext_month>>
    FOR rec IN get_ext_month_cur LOOP
        lb_loop_end := TRUE;
        lv_temp_month := rec.ext_month;
        
    END LOOP get_ext_month;
    
    -- ���ԃf�[�^�����݂���ꍇ
    IF (lb_loop_end) THEN

        <<get_ext_year>>
         -- �O�N�L�����y�N�Ԍv�z���o
        FOR rec IN get_ext_year_cur LOOP
            lb_loop_end := FALSE;
            lv_temp_sum := rec.ext_year;
        END LOOP get_ext_year;
        
        IF (lb_loop_end) THEN
            lv_temp_sum := cv_year_zero;
        END IF;
        
        lv_line_info := lv_line_info || lv_temp_month || lv_temp_sum;
    ELSE
        lv_line_info := lv_line_info || cv_all_zero;
    END IF;
    
    -- �o��
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     
                     ,buff   => lv_line_info
                     );

--#################################  �Œ��O������  #############################
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      IF (get_month_data_cur%ISOPEN) THEN
         CLOSE get_month_data_cur;
      END IF;
      
      IF (get_year_data_cur%ISOPEN) THEN
         CLOSE get_year_data_cur;
      END IF;
      
      IF (get_ext_month_cur%ISOPEN) THEN
         CLOSE get_ext_month_cur;
      END IF;
      
      IF (get_ext_year_cur%ISOPEN) THEN
         CLOSE get_ext_year_cur;
      END IF;
        
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      IF (get_month_data_cur%ISOPEN) THEN
         CLOSE get_month_data_cur;
      END IF;
      
      IF (get_year_data_cur%ISOPEN) THEN
         CLOSE get_year_data_cur;
      END IF;
      
      IF (get_ext_month_cur%ISOPEN) THEN
         CLOSE get_ext_month_cur;
      END IF;
      
      IF (get_ext_year_cur%ISOPEN) THEN
         CLOSE get_ext_year_cur;
      END IF;
      
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_month_data_cur%ISOPEN) THEN
         CLOSE get_month_data_cur;
      END IF;
      
      IF (get_year_data_cur%ISOPEN) THEN
         CLOSE get_year_data_cur;
      END IF;
      
      IF (get_ext_month_cur%ISOPEN) THEN
         CLOSE get_ext_month_cur;
      END IF;
      
      IF (get_ext_year_cur%ISOPEN) THEN
         CLOSE get_ext_year_cur;
      END IF;      
        
--#####################################  �Œ蕔 END   ###########################
  END write_Line_Info;
--

   /****************************************************************************
   * Procedure Name   : write_csv_file
   * Description      : �f�[�^�̏o��            
   ****************************************************************************/
   PROCEDURE write_csv_file (  
         ov_errbuf     OUT NOCOPY VARCHAR2               --���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2               --���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --���[�U�[�E�G���[�E���b�Z�[�W
        
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'write_csv_file';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    
    -- �w�b�_���
    lv_data_head                VARCHAR2(2000);
    
    -- ���i�Q4���P�ʏ��
    lv_data_line                VARCHAR2(4000);    
        
    -- ���i�Q3���R�[�h
    lv_group3_cd                  VARCHAR2(10);
    
    -- ���i�Q4���R�[�h
    lv_group4_cd                  VARCHAR2(10);

                                      
--============================================
--  ���i�Q3���R�[�h���o�y�J�[�\���z
--============================================ 
    CURSOR  
            get_group3_cd_cur
    IS
     SELECT DISTINCT
          group_cd_3
     FROM     
          xxcsm_tmp_sales_plan_gun         -- ���i�v��Q�ʌv�掑���o�̓��[�N�e�[�u��
     WHERE
          group_cd_3 IS NOT NULL
     ORDER BY group_cd_3 ASC
;
--

--============================================
--  ���i�Q4���R�[�h���o�y�J�[�\���z
--============================================ 
    CURSOR  
            get_group4_cd_cur(in_group_cd_3 IN VARCHAR2)
    IS
     SELECT  DISTINCT
             group_cd_4
     FROM     
             xxcsm_tmp_sales_plan_gun         -- ���i�v��Q�ʌv�掑���o�̓��[�N�e�[�u��
     WHERE
             group_cd_4 LIKE  in_group_cd_3 || '%' 
     AND     group_cd_3 IS NULL
     ORDER BY group_cd_4 ASC;


  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################   
    
    -- �w�b�_���̒��o
    lv_data_head := xxccp_common_pkg.get_msg(                                   -- ���_�R�[�h�̏o��
                      iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm_msg_00096                       -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- �g�[�N���R�[�h1�i���_�R�[�h�j
                     ,iv_token_value1 => gv_kyotencd                            -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_kyotennm                        -- �g�[�N���R�[�h2�i���_�R�[�h���́j
                     ,iv_token_value2 => gv_kyotennm                            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_year                            -- �g�[�N���R�[�h3�i�Ώ۔N�x�j
                     ,iv_token_value3 => gn_taisyoym                            -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_sysdate                         -- �g�[�N���R�[�h4�i�Ɩ����t�j
--//+UPD START 2009/02/18   K.Sai
--                     ,iv_token_value4 => gd_process_date                        -- �g�[�N���l4
                     ,iv_token_value4 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI')  -- �g�[�N���l4
--//+UPD END 2009/02/18   K.Sai
                     );
                     
    -- �w�b�_���̏o��
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     
                     ,buff   => lv_data_head || CHR(10)
                     ); 
                     
    -- �{�f�B���̒��o
    <<group3_loop>>
    FOR rec3 IN get_group3_cd_cur LOOP
    
        -- ���i�Q3���R�[�h
        lv_group3_cd := rec3.group_cd_3;        
       
        <<group4_loop>>
        -- ���i�Q4���R�[�h�̒��o
        FOR rec4 IN get_group4_cd_cur(lv_group3_cd) LOOP
            
            lv_group4_cd := rec4.group_cd_4;
            
            -- �Ώی����y���Z�z
            gn_target_cnt := gn_target_cnt + 1;
            
            lv_data_line := NULL;
            
            -- ���i�Q4���R�[�h�P�ʂŃ{�f�B�����o�́iwrite_Line_Info���Ăяo���j        
            write_Line_Info(
                          lv_group4_cd
                          ,lv_errbuf
                          ,lv_retcode
                          ,lv_errmsg
                          );

            -- �G���[���� 
            IF (lv_retcode = cv_status_error) THEN
                gn_error_cnt := gn_error_cnt + 1 ;

                -- ���b�Z�[�W���o��
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
            -- ���팏���y���Z�z 
            ELSIF (lv_retcode = cv_status_normal) THEN
                gn_normal_cnt := gn_normal_cnt + 1 ;
            END IF;
            
        END LOOP group4_loop;
            lv_group4_cd := rec3.group_cd_3 || '*';
            
            -- �Ώی����y���Z�z
            gn_target_cnt := gn_target_cnt + 1;
            
            lv_data_line := NULL;
            
            -- ���i�Q4���R�[�h�P�ʂŃ{�f�B�����o�́iwrite_Line_Info���Ăяo���j        
            write_Line_Info(
                          lv_group4_cd
                          ,lv_errbuf
                          ,lv_retcode
                          ,lv_errmsg
                          );

            -- �G���[���� 
            IF (lv_retcode = cv_status_error) THEN
                gn_error_cnt := gn_error_cnt + 1 ;

                -- ���b�Z�[�W���o��
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
            -- ���팏���y���Z�z 
            ELSIF (lv_retcode = cv_status_normal) THEN
                gn_normal_cnt := gn_normal_cnt + 1 ;
            END IF;
      
    END LOOP group3_loop;
    
                         
--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_group3_cd_cur%ISOPEN) THEN
        CLOSE get_group3_cd_cur;
      END IF;
      
      IF (get_group4_cd_cur%ISOPEN) THEN
        CLOSE get_group4_cd_cur;
      END IF;
      

    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_group3_cd_cur%ISOPEN) THEN
        CLOSE get_group3_cd_cur;
      END IF;
      
      IF (get_group4_cd_cur%ISOPEN) THEN
        CLOSE get_group4_cd_cur;
      END IF;

--
--#####################################  �Œ蕔 END   ###########################
--
  END write_csv_file;
--

  /*****************************************************************************
   * Procedure Name   : submain
   * Description      : ��������
   ****************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2                                           -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                           -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';      -- �v���O������
    
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################

--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--##################  �Œ蕔 END   #####################################

-- �����J�E���^�̏�����
    gn_target_cnt := 0;                                                         -- �Ώی����J�E���^�̏�����
    gn_normal_cnt := 0;                                                         -- ���팏���J�E���^�̏�����
    gn_error_cnt  := 0;                                                         -- �G���[�����J�E���^�̏�����
    gn_warn_cnt   := 0;                                                         -- �X�L�b�v�����J�E���^�̏�����

-- ��������
    init(                                                                       -- init���R�[��
       lv_errbuf                                                                -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                               -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;
    
-- �`�F�b�N����
    do_check(                                                                   -- do_check���R�[��
       lv_errbuf                                                                -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                               -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;

-- ���i�Q4���y���o�E�Z�o�E�o�^�z
    deal_group4_data(                                                           -- deal_ResultData���R�[��
       lv_errbuf                                                                -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                               -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;

-- ���i�Q3���y���o�E�Z�o�E�o�^�z
    deal_group3_data(                                                             -- deal_PlanData���R�[��
       lv_errbuf                                                                -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                               -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;

-- �f�[�^�̏o��
    write_csv_file(                                                             -- write_csv_file���R�[��
       lv_errbuf                                                                -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                               -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;
          
    
--#################################  �Œ��O������  #############################
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 END   ###########################
--
  END submain;
--

  /*****************************************************************************
   * Procedure Name   : main
   * Description      : �O���ďo���C���v���V�[�W��
   ****************************************************************************/
  PROCEDURE main(
    errbuf           OUT    NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W
    retcode          OUT    NOCOPY VARCHAR2,         --   �G���[�R�[�h
    iv_taisyo_ym     IN     VARCHAR2,                --   �Ώ۔N�x
    iv_kyoten_cd     IN     VARCHAR2                 --   ���_�R�[�h
  ) AS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
-- �I�����b�Z�[�W�R�[�h
    lv_message_code   VARCHAR2(100);     -- �I���R�[�h
-- ===============================
-- �Œ胍�[�J���萔
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'main'; -- �v���O������
    cv_which_log        CONSTANT VARCHAR2(10)     := 'LOG';  -- �o�͐�    
--
  BEGIN
--
--###########################  �Œ蕔 START   ###########################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_which_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    retcode := cv_status_normal;
--
--##################  �Œ蕔 END   #####################################


-- ���̓p�����[�^
    gv_kyotencd     := iv_kyoten_cd;                       --���_�R�[�h
    gn_taisyoym     := TO_NUMBER(iv_taisyo_ym);            --�Ώ۔N�x

-- ��������
    submain(                                      -- submain���R�[��
        lv_errbuf                                 -- �G���[�E���b�Z�[�W
       ,lv_retcode                                -- ���^�[���E�R�[�h
       ,lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
     );
     
-- �z��O�ُ�̏ꍇ     
   IF(lv_retcode = cv_status_error) THEN
         IF (lv_errmsg IS NULL) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm
                       ,iv_name         => cv_ccp1_msg_00111
                       );
         END IF;
         -- �G���[�o��
         fnd_file.put_line(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg            -- ���[�U�[�E�G���[���b�Z�[�W
         );
         
         fnd_file.put_line(
            which  => FND_FILE.LOG
           ,buff   => lv_errbuf            -- �G���[���b�Z�[�W
         );
        -- �����J�E���^�̏�����
        gn_target_cnt := 0;                                                         -- �Ώی����J�E���^�̏�����
        gn_normal_cnt := 0;                                                         -- ���팏���J�E���^�̏�����
        gn_error_cnt  := 1;                                                         -- �G���[�����J�E���^�̏�����
        gn_warn_cnt   := 0;                                                         -- �X�L�b�v�����J�E���^�̏�����
   END IF;
   
--�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp_msg_90000
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    

--���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp_msg_90001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );

--�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp_msg_90002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );

--�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp_msg_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
 
--�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_ccp_msg_90004;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_ccp_msg_90006;
    END IF;

    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    

--�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;

--�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;

--#####################  �Œ��O������ START   ########################
  EXCEPTION
  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
  WHEN global_api_others_expt THEN
    errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    retcode := cv_status_error;
    ROLLBACK;
  -- *** OTHERS��O�n���h�� ***
  WHEN OTHERS THEN
    errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
    retcode := cv_status_error;
    ROLLBACK;
--#####################  �Œ蕔 END   ###################################
    
--  
  END main;
--

--##############################################################################


END XXCSM002A02C;
/
