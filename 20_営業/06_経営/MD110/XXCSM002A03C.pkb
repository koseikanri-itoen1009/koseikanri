CREATE OR REPLACE PACKAGE BODY XXCSM002A03C AS
/*******************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A03C(spec)
 * Description      : ���i�v��Q�l�����o��
 * MD.050           : ���i�v��Q�l�����o�� MD050_CSM_002_A03
 * Version          : 1.7
 *
 * Program List
 * -------------------- --------------------------------------------------------
 *  Name                 Description
 *
 *  init                �y���������zA-1
 *
 *  do_check            �y�`�F�b�N�����zA-2
 *
 *  deal_result_data    �y���уf�[�^�̏ڍ׏����zA-3,A-4,A-5,A-6,A-7
 *
 *  deal_plan_data      �y�v��f�[�^�̏ڍ׏����zA-3,A-4,A-8,A-9,A-10
 *
 *  write_line_info     �y���i�P�ʂł̃f�[�^�o�́zA-11
 *
 *  write_csv_file      �y���i�v��Q�l�����f�[�^��CSV�t�@�C���֏o�́zA-11
 *
 *  submain             �y���������zA-1~A-11
 *
 *  main                �y�R���J�����g���s�t�@�C���o�^�v���V�[�W���zA-1~A-12
 *
 * 
 * Change Record
 * ------------- ----- ---------------- ----------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ----------------------------------------
 *  2008/12/04    1.0   SCS ohshikyo     �V�K�쐬
 *  2009/02/16    1.1   SCS K.Yamada     [��QCT024]����0�̕s��̑Ή�
 *  2009/02/18    1.2   SCS K.Sai        [��QCT027]�e���v�z�̏����_2���\���s����w�b�_���t�\���Ή�
 *  2009/05/25    1.3   SCS M.Ohtsuki    [��QT1_1020]
 *  2009/06/10    1.4   SCS M.Ohtsuki    [��QT1_1399]
 *  2009/07/10    1.5   SCS T.Tsukino    [��Q0000637]PT(����Q�Q�r���[�ւ̃q���g��ǉ��j
 *  2010/12/13    1.6   SCS Y.Kanami     [E_�{�ғ�_05803]
 *  2011/03/31    1.7   SCS H.Sasaki     [E_�{�ғ�_06952]�ꎞ�\����̑Ώەi�ڎ擾SQL�C��
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM002A03C';           -- �p�b�P�[�W��
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                      -- �J���}     
  cv_msg_hafu               CONSTANT VARCHAR2(3)   := '-';                      -- 
  cv_msg_space              CONSTANT VARCHAR2(4)   := '';                     -- ��
  cv_msg_duble              CONSTANT VARCHAR2(3)   := '"';                      -- �_�u���N�H�[�e�[�V����
    
  cv_msg_linespace          CONSTANT VARCHAR2(20) := cv_msg_duble|| cv_msg_space ||cv_msg_duble|| cv_msg_comma || cv_msg_duble ||cv_msg_space || cv_msg_duble || cv_msg_comma;
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                  -- �A�v���P�[�V�����Z�k��    
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                  -- �A�h�I���F���ʁEIF�̈�
  
-- 
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ� 
  -- ===============================
--  
  gd_process_date           DATE;                                               -- �Ɩ����t
  gn_index                  NUMBER := 0;                                        -- �o�^��
  gv_kyotenCD               VARCHAR2(32);                                       -- ���_�R�[�h
  gv_taisyoYm               NUMBER(4,0);                                        -- �Ώ۔N�x
--//+UPD START 2009/06/10 T1_1399 M.Ohtsuki
--  gv_kakuteiym              VARCHAR2(6);                                        -- �m��N��
--��������������������������������������������������������������������������������������������������
  gv_kakuteiym              NUMBER(6);                                          -- �m��N��
--//+UPD END   2009/06/10 T1_1399 M.Ohtsuki
  gv_planYm                 NUMBER(4,0);                                        -- �v��N�x
  gv_kyotennm               VARCHAR2(200);                                      -- ���_����
  
  
  
  -- ===============================
  -- ���p���b�Z�[�W�ԍ�
  -- ===============================
--  
  cv_ccp1_msg_90000           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';         -- �Ώی������b�Z�[�W
  cv_ccp1_msg_90001           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';         -- �����������b�Z�[�W
  cv_ccp1_msg_90002           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';         -- �G���[�������b�Z�[�W
  cv_ccp1_msg_90003           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';         -- �X�L�b�v�������b�Z�[�W
  cv_ccp1_msg_90004           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';         -- ����I�����b�Z�[�W
  cv_ccp1_msg_90006           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';         -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_ccp1_msg_00111           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';         -- �z��O�G���[���b�Z�[�W
--  
  -- ===============================  
  -- ���b�Z�[�W�ԍ�
  -- ===============================
--  
  cv_csm1_msg_00005           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';         -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_csm1_msg_00099           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00099';         -- ���i�v��p�Ώۃf�[�^�������b�Z�[�W
  cv_csm1_msg_00107           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00107';         -- ���i�v��Q�l����(���i��2���N����)�w�b�_�p���b�Z�[�W
  cv_csm1_msg_00024           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00024';         -- ���_�R�[�h�`�F�b�N�G���[���b�Z�[�W
  cv_csm1_msg_00048           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';         -- ���̓p�����[�^�擾���b�Z�[�W(���_�R�[�h)
  cv_csm1_msg_10015           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10015';         -- ���̓p�����[�^�擾���b�Z�[�W�i�Ώ۔N�x�j
  
--
  -- ===============================
  -- �g�[�N����`
  -- ===============================
--  
  cv_tkn_year                      CONSTANT VARCHAR2(100) := 'TAISYOU_YM';      -- �Ώ۔N�x
  cv_tkn_kyotencd                  CONSTANT VARCHAR2(100) := 'KYOTEN_CD';       -- ���_�R�[�h
  cv_tkn_kyotennm                  CONSTANT VARCHAR2(100) := 'KYOTEN_NM';       -- ���_����
  cv_tkn_profile                   CONSTANT VARCHAR2(100) := 'PROF_NAME';       -- �v���t�@�C����
  cv_tkn_count                     CONSTANT VARCHAR2(100) := 'COUNT';           -- ��������
  cv_tkn_sysdate                   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI'; -- �쐬����
  cv_tkn_kakuteiym                 CONSTANT VARCHAR2(100) := 'KAKUTEI_YM';      -- �m��N��
  cv_tkn_planym                    CONSTANT VARCHAR2(100) := 'KEIKAKU_YM';      -- �v��N��
  cv_cnt_token                     CONSTANT VARCHAR2(10)  := 'COUNT';           -- �������b�Z�[�W
 

  -- =============================== 
  -- �v���t�@�C��
  -- ===============================
-- �v���t�@�C���E�R�[�h  
  lv_prf_cd_item                    CONSTANT VARCHAR2(100) := 'XXCSM1_DEAL_CATEGORY';    -- XXCMN:����Q�i�ڃJ�e�S�����薼
  lv_prf_cd_sales                   CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';  -- XXCMN:����
  lv_prf_cd_rate                    CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_4';   -- XXCMN:�|��
  lv_prf_cd_amount                  CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_1';  -- XXCMN:����
  lv_prf_cd_margin                  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6'; -- XXCMN:�e���v�z
  lv_prf_cd_margin_rate             CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_7'; -- XXCMN:�e���v��
  lv_prf_cd_make                    CONSTANT VARCHAR2(100) := 'XXCSM1_PLANGUN_ITEM_1';   -- XXCMN:�\����
  lv_prf_cd_result                  CONSTANT VARCHAR2(100) := 'XXCSM1_PLANREF_ITEM_1';   -- XXCMN:�N����
  lv_prf_cd_plan                    CONSTANT VARCHAR2(100) := 'XXCSM1_PLANREF_ITEM_2';   -- XXCMN:�N�v��
  lv_prf_cd_g2_make                 CONSTANT VARCHAR2(100) := 'XXCSM1_PLANREF_ITEM_3';   -- XXCMN:�Q2���\����
  lv_prf_cd_kyoten_make             CONSTANT VARCHAR2(100) := 'XXCSM1_PLANREF_ITEM_4';   -- XXCMN:���_�v�\����

  

-- �v���t�@�C���E����
  lv_prf_cd_item_val                     VARCHAR2(100) ;                                 -- XXCMN:����Q�i�ڃJ�e�S�����薼
  lv_prf_cd_sales_val                    VARCHAR2(100) ;                                 -- XXCMN:����
  lv_prf_cd_rate_val                     VARCHAR2(100) ;                                 -- XXCMN:�|��
  lv_prf_cd_amount_val                   VARCHAR2(100) ;                                 -- XXCMN:����
  lv_prf_cd_margin_val                   VARCHAR2(100) ;                                 -- XXCMN:�e���v�z
  lv_prf_cd_margin_rate_val              VARCHAR2(100) ;                                 -- XXCMN:�e���v��
  lv_prf_cd_make_val                     VARCHAR2(100) ;                                 -- XXCMN:�\����
  lv_prf_cd_result_val                   VARCHAR2(100) ;                                 -- XXCMN:�N����
  lv_prf_cd_plan_val                     VARCHAR2(100) ;                                 -- XXCMN:�N�v��
  lv_prf_cd_g2_make_val                  VARCHAR2(100) ;                                 -- XXCMN:�Q2���\����  
  lv_prf_cd_kyoten_make_val              VARCHAR2(100) ;                                 -- XXCMN:���_�v�\���� 
  
    
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
                     ,iv_name         => cv_csm1_msg_00048                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- �g�[�N���R�[�h1�i���_�R�[�h�j
                     ,iv_token_value1 => gv_kyotenCD                            -- �g�[�N���l1
                     );
                     
    -- LOG�ɏo��
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => CHR(10) || lv_pram_op_1 
                     );
-- �Ώ۔N�x(IN�p�����[�^�̏o��)
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                   -- �Ώ۔N�x�̏o��
                      iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_10015                      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_year                            -- �g�[�N���R�[�h1�i�Ώ۔N�x���́j
                     ,iv_token_value1 => gv_taisyoYm                            -- �g�[�N���l1
                     );
                     
    -- LOG�ɏo��
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                     
                     ,buff   => lv_pram_op_2 || CHR(10)
                     );                     
-- �v��N�x
    gv_planYm := gv_taisyoYm - 1 ;
                   
-- �m��N��

    SELECT
--//+UPD START 2009/06/10 T1_1399 M.Ohtsuki
--        TO_CHAR(ADD_MONTHS(gd_process_date,-1),'MM')
--��������������������������������������������������������������������������������������������������
        TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_process_date,-1),'MM'))
--//+UPD END   2009/06/10 T1_1399 M.Ohtsuki
    INTO
        gv_kakuteiym
    FROM
        DUAL;
    
    IF (gv_kakuteiym IS NULL) THEN
        RAISE global_api_expt;
    END IF;
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
                    name => lv_prf_cd_sales
                   ,val  => lv_prf_cd_sales_val
                   ); -- ����
    FND_PROFILE.GET(
                    name => lv_prf_cd_rate
                   ,val  => lv_prf_cd_rate_val
                   ); -- �|��
    FND_PROFILE.GET(
                    name => lv_prf_cd_amount
                   ,val  => lv_prf_cd_amount_val
                   ); -- ����
    FND_PROFILE.GET(
                    name => lv_prf_cd_margin
                   ,val  => lv_prf_cd_margin_val
                   ); --�e���v�z
    FND_PROFILE.GET(
                    name => lv_prf_cd_margin_rate
                   ,val  => lv_prf_cd_margin_rate_val
                   ); -- �e���v��
    FND_PROFILE.GET(
                    name => lv_prf_cd_make
                   ,val  => lv_prf_cd_make_val
                   ); -- �\����
    FND_PROFILE.GET(
                    name => lv_prf_cd_result
                   ,val  => lv_prf_cd_result_val
                   ); -- �N����
    FND_PROFILE.GET(
                    name => lv_prf_cd_plan
                   ,val  => lv_prf_cd_plan_val
                   ); --�N�v��  
    FND_PROFILE.GET(
                    name => lv_prf_cd_g2_make
                   ,val  => lv_prf_cd_g2_make_val
                   ); --�Q2���\����  
    FND_PROFILE.GET(
                    name => lv_prf_cd_kyoten_make
                   ,val  => lv_prf_cd_kyoten_make_val
                   ); --���_�v�\����                    
    
    -- =========================================================================
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- =========================================================================
    -- ����Q�i�ڃJ�e�S�����薼
    IF (lv_prf_cd_item_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_item;
    -- ����
    ELSIF (lv_prf_cd_sales_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_sales;
        -- �|��
    ELSIF (lv_prf_cd_rate_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_rate;
        -- ����
    ELSIF (lv_prf_cd_amount_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_amount;
        -- �e���v�z
    ELSIF (lv_prf_cd_margin_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_margin;
        -- �e���v��
    ELSIF (lv_prf_cd_margin_rate_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_margin_rate;
        -- �\����
    ELSIF (lv_prf_cd_make_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_make;
        -- �N����
    ELSIF (lv_prf_cd_result_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_result;
        -- �N�v��
    ELSIF (lv_prf_cd_plan_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_plan;
        -- �Q2���\����
    ELSIF (lv_prf_cd_g2_make_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_g2_make;
        -- ���_�v�\����
    ELSIF (lv_prf_cd_kyoten_make_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_kyoten_make;
    END IF;
    
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm1_msg_00005                       -- ���b�Z�[�W�R�[�h
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
                  ,iv_name         => cv_csm1_msg_00024                           -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_kyotencd                         -- �g�[�N���R�[�h1�i���_�R�[�h�j
                  ,iv_token_value1 => gv_kyotenCD                             -- �g�[�N���l1
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
            count(1)
    INTO    
            ln_counts
    FROM    
            xxcsm_item_plan_result                  -- �N�Ԕ̔��v��p���уe�[�u��
    WHERE   
            (subject_year   = gv_taisyoYm -1        -- �O�N�x
    OR      subject_year    = gv_taisyoYm -2)       -- �O�X�N�x
    AND     location_cd     = gv_kyotenCD           -- ���_�R�[�h
    AND     rownum          = 1;                    -- 1�s��
    
    -- ������0�̏ꍇ�A�v��f�[�^�̑��݃`�F�b�N���s���܂��B                                
    IF (ln_counts = 0) THEN
--      
    -- =========================================================================
    -- �v��f�[�^�̑��݃`�F�b�N
    -- =========================================================================
      -- �Đݒ�
      ln_counts := 0;
  
      -- �v��f�[�^�̒��o
      SELECT
                      count(1)
      INTO  
                      ln_counts
      FROM  
                      xxcsm_item_plan_lines plan_lines                          -- ���i�v��w�b�_�e�[�u��
                      ,xxcsm_item_plan_headers plan_headers                     -- ���i�v�斾�׃e�[�u��         
      WHERE 
               plan_lines.item_plan_header_id    = 
                                  plan_headers.item_plan_header_id              -- ���i�v��w�b�_ID
      AND       plan_headers.plan_year           = gv_taisyoYm -1               -- �O�N�x
      AND       plan_headers.location_cd         = gv_kyotenCD                  -- ���_�R�[�h
      AND       rownum                           = 1;                           -- 1�s��   
      
      -- ������0�̏ꍇ�A�G���[���b�Z�[�W���o���āA���������~���܂��B                                
      IF (ln_counts = 0) THEN
          lv_retcode := cv_status_error;
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_csm1_msg_00099                         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_kyotencd                       -- �g�[�N���R�[�h1�i���_�R�[�h�j
                      ,iv_token_value1 => gv_kyotenCD                           -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_year                           -- �g�[�N���R�[�h2�i�Ώ۔N�x�j
                      ,iv_token_value2 => gv_taisyoYm                           -- �g�[�N���l2
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
      END IF;
      --    
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
                  ,iv_name         => cv_csm1_msg_00024                           -- ���b�Z�[�W�R�[�h
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
   * Procedure Name   : deal_plan_data
   * Description      : �v��f�[�^�̏ڍ׏���
   *                    �@�f�[�^�̒��o
   *                    �A�f�[�^�̎Z�o
   *                    �B�f�[�^�̓o�^
   *****************************************************************************/
   PROCEDURE deal_plan_data(
         ov_errbuf     OUT NOCOPY VARCHAR2               --���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2               --���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --���[�U�[�E�G���[�E���b�Z�[�W
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_plan_data';        -- �v���O������
    cn_month                CONSTANT NUMBER         := 5;                       -- ����(�̔����уJ�����_�[)

    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_item_cd              VARCHAR2(10);               --�i�ڃR�[�h
    lv_group_id             VARCHAR2(10);               --���i�Q�R�[�h
-- �N��    
    ln_y_sales              NUMBER  := 0;               --�N��_������z���v
    ln_y_margin             NUMBER  := 0;               --�N��_�e���v�z���v
    ln_y_amount             NUMBER  := 0;               --�N��_���ʍ��v
    ln_y_psa                NUMBER  := 0;               --�N��_����*�艿�̍��v
    ln_y_rate               NUMBER  := 0;               --�N��_�|��
    ln_y_margin_r           NUMBER  := 0;               --�N��_�e���v��
    ln_h_rate               NUMBER  := 0;               --������_�|��
    ln_h_margin_r           NUMBER  := 0;               --������_�e���v��
    ln_y_make               NUMBER  := 0;               -- �N��_�\����
    ln_h_make               NUMBER  := 0;               -- ������_�\����
    
-- ������    
    ln_h_sales              NUMBER  := 0;               --������_������z���v
    ln_h_margin             NUMBER  := 0;               --������_�e���v�z���v
    ln_h_amount             NUMBER  := 0;               --������_���ʍ��v
    ln_h_psa                NUMBER  := 0;               --������_����*�艿�̍��v  
    
-- �Q2���E���_      
    ln_yg_make              NUMBER  := 0;               --�N��_�Q2��_�\����
    ln_yk_make              NUMBER  := 0;               --�N��_���__�\����
    ln_hg_make              NUMBER  := 0;               --������_�Q2��_�\����
    ln_hk_make              NUMBER  := 0;               --������_���__�\����
    ln_g_sum                NUMBER  := 0;               --�Q2��_���㍇�v
    ln_k_sum                NUMBER  := 0;               --���__���㍇�v    
    
--  �ꎞ�ϐ�  
    ln_year                 NUMBER  := 0;               --�N�x���f�p�ϐ�
    ln_month                NUMBER  := 0;               --�����f�p�ϐ�
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP���f�p
       
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--============================================
--  �f�[�^�̒��o�y�v��z�J�[�\��
--============================================
    CURSOR   
        get_sales_plan_data_cur
    IS
--//+DEL START 2009/07/10 ��Q0000637 T.Tsukino
--          SELECT
--//+DEL END 2009/07/10 ��Q0000637 T.Tsukino
--//+ADD START 2009/07/10 ��Q0000637 T.Tsukino
          SELECT /*+ INDEX(xcgv.xsib XXCMM_SYSTEM_ITEMS_B_U01) */ 
--//+ADD END 2009/07/10 ��Q0000637 T.Tsukino
                 xiph.plan_year                         AS  year                     -- �Ώ۔N�x
                ,xipl.month_no                          AS  month                    -- ��
                ,SUM(NVL(xipl.amount,0))                AS  amount                   -- ����
                ,SUM(NVL(xipl.sales_budget,0))          AS  sales                    -- ������z
                ,SUM(NVL(xipl.amount_gross_margin,0))   AS  margin                   -- �e���v�z
                ,xipl.item_group_no                     AS  group_id                 -- ���i�Q�R�[�h
                ,xcgv.item_cd                           AS  item_id                  -- �i�ڃR�[�h
                ,xcgv.item_nm                           AS  item_nm                  -- �i�ږ���
                ,NVL(xcgv.now_unit_price,0)                  AS  price                    -- �艿
          FROM     
                xxcsm_item_plan_lines           xipl                                 -- ���i�v�斾�׃e�[�u��
                ,xxcsm_item_plan_headers        xiph                                 -- ���i�v��w�b�_�e�[�u��
                ,xxcsm_commodity_group2_v       xcgv                                 -- ����Q�Q�r���[
          WHERE    
                 xipl.item_plan_header_id          = xiph.item_plan_header_id        -- ���i�v��w�b�_ID
          AND   xcgv.item_cd                       = xipl.item_no                    -- ���i�R�[�h
          AND   xiph.plan_year                     = gv_taisyoYm - 1                 -- �O�N�x
          AND   xiph.location_cd                   = gv_kyotenCD                     -- ���_�R�[�h
          GROUP BY
                   xiph.plan_year                      -- �Ώ۔N�x
                  ,xipl.month_no                       -- ��
                  ,xipl.item_group_no                  -- ���i�Q�R�[�h
                  ,xcgv.item_cd                        -- ���i�R�[�h
                  ,xcgv.item_nm                        -- ���i����
                  ,xcgv.now_unit_price                 -- �艿
          ORDER BY 
                    item_id    ASC                   -- ���i�R�[�h
                    ,year        ASC                  -- �Ώ۔N�x
                    ,month      ASC                   -- ��
                    ,group_id   ASC                   -- ���i�Q�R�[�h
    ;

-- �Q2���v�F���㍇�v
    CURSOR   
        get_group2_plan_data_cur(
                                in_year IN NUMBER
                                ,in_group_id IN VARCHAR2)
    IS
--//+DEL START 2009/07/10 ��Q0000637 T.Tsukino
--          SELECT
--//+DEL END 2009/07/10 ��Q0000637 T.Tsukino
--//+ADD START 2009/07/10 ��Q0000637 T.Tsukino
          SELECT /*+ INDEX(xcgv.xsib XXCMM_SYSTEM_ITEMS_B_U01) */ 
--//+ADD END 2009/07/10 ��Q0000637 T.Tsukino
                SUM(NVL(xipl.sales_budget,0))      AS g2_sales                        -- �N�Ԕ���
            FROM     
                xxcsm_item_plan_lines             xipl                                -- ���i�v�斾�׃e�[�u��
                ,xxcsm_item_plan_headers          xiph                                -- ���i�v��w�b�_�e�[�u��
                ,xxcsm_commodity_group2_v         xcgv                                -- ����Q�Q�r���[
            WHERE    
                    xipl.item_plan_header_id         = xiph.item_plan_header_id       -- ���i�v��w�b�_ID
            AND     xiph.plan_year                   = in_year                        -- �Ώ۔N�x
            AND     xipl.item_no                     = xcgv.item_cd                   -- ���i�R�[�h
            AND     xiph.location_cd                 = gv_kyotenCD                    -- ���_�R�[�h
            AND     SUBSTR(xcgv.group2_cd,1,2)       = SUBSTR(in_group_id,1,2);
            
            
-- ���_�v�F���㍇�v
    CURSOR   
        get_kyoten_plan_data_cur(in_year IN NUMBER)
    IS
            SELECT   
                  SUM(NVL(xipl.sales_budget,0))    AS kyoten_sales                       -- �N�Ԕ���
            FROM     
                  xxcsm_item_plan_lines       xipl                                     -- ���i�v�斾�׃e�[�u��
                  ,xxcsm_item_plan_headers    xiph                                     -- ���i�v��w�b�_�e�[�u��
            WHERE    
                  xipl.item_plan_header_id     = xiph.item_plan_header_id                -- ���i�v��w�b�_ID
            AND   xiph.plan_year               = in_year                                 -- �Ώ۔N�x
            AND   xiph.location_cd             = gv_kyotenCD;                            -- ���_�R�[�h            

--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

-- ===========================================================================  
--�y�v��f�[�^����-START�z
-- ===========================================================================
    lv_item_cd := NULL;
    
    <<get_sales_plan_data_cur_loop>>
    FOR rec_plan_data IN get_sales_plan_data_cur LOOP
        
        lb_loop_end := TRUE;
        
        -- ������(���v�Z�o�p)
        IF (lv_item_cd IS NULL) THEN
            -- ���i�R�[�h
            lv_item_cd      := rec_plan_data.item_id;
            
            -- ���i�Q�R�[�h
            lv_group_id     := rec_plan_data.group_id;
            
            -- �Ώ۔N�x
            ln_year         := rec_plan_data.year;
--
            -- �N�Ԕ���
            ln_y_sales      := rec_plan_data.sales;
            -- �N�ԑe���v�z
            ln_y_margin     := rec_plan_data.margin;
            -- �N�Ԑ���
            ln_y_amount     := rec_plan_data.amount;
            -- �N�Ԑ���*�艿
            ln_y_psa        := rec_plan_data.amount * rec_plan_data.price;
--
            IF ((gv_kakuteiym >= cn_month) AND (rec_plan_data.month <= gv_kakuteiym) AND (rec_plan_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_plan_data.month >= cn_month) OR (rec_plan_data.month <= gv_kakuteiym)) ) THEN
                -- �����Ԕ���
                ln_h_sales      := rec_plan_data.sales;
                -- �����ԑe���v�z
                ln_h_margin     := rec_plan_data.margin;
                -- �����Ԑ���
                ln_h_amount     := rec_plan_data.amount;
                -- �����Ԑ���*�艿
                ln_h_psa        := rec_plan_data.amount * rec_plan_data.price;
            END IF;
        
        -- ���i�R�[�h���ς�����ꍇ�i���̏��i�j    
        ELSIF ((lv_item_cd <> rec_plan_data.item_id) OR (ln_year <> rec_plan_data.year)) THEN
        
            -- �Q2���v�F���㍇�v
            <<get_group2_plan>>
            FOR rec IN get_group2_plan_data_cur(ln_year,lv_group_id) LOOP
                ln_g_sum := rec.g2_sales;
                
            END LOOP get_group2_plan;

            --�N�ԌQ2���\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_y_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_yg_make := 0;
            ELSE
                -- ���i_�N�Ԕ��぀�Q2��_���㍇�v*100 �y�����_3���l�̌ܓ��z
                ln_yg_make  := ROUND(ln_y_sales / ln_g_sum * 100,2);
            END IF;

            
            --�����ԌQ2���\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_h_sales = 0) THEN
            IF ((ln_h_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_hg_make := 0;
            ELSE
                -- ���i_�����Ԕ��぀�Q2��_���㍇�v*100 �y�����_3���l�̌ܓ��z
                ln_hg_make  := ROUND(ln_h_sales / ln_g_sum * 100,2);
            END IF;


            -- ���_�v�F���㍇�v
            <<get_kyoten_plan>>
            FOR rec IN get_kyoten_plan_data_cur (ln_year) LOOP
                ln_k_sum := rec.kyoten_sales;
                
            END LOOP get_kyoten_plan;
        
            --�N�ԋ��_�\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_y_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_yk_make := 0;
            ELSE
                -- ���i_�N�Ԕ��぀���__���㍇�v*100 �y�����_3���l�̌ܓ��z
                ln_yk_make  := ROUND(ln_y_sales / ln_k_sum * 100,2);
            END IF;
             

            --�����ԋ��_�\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_h_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_hk_make := 0;
            ELSE
                -- ���i_�����Ԕ��぀���__���㍇�v*100 �y�����_3���l�̌ܓ��z
                ln_hk_make  := ROUND(ln_h_sales / ln_k_sum * 100,2);
            END IF;


            -- �N��_�|��/�N��_�e���v��/�N��_�\����:�y�Z�o�����z
            IF (ln_y_sales = 0) THEN
                ln_y_rate     := 0;
                ln_y_margin_r := 0;
                ln_y_make     := 0;
            ELSE
                -- �N��_���぀(�N�Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+UPD START 2009/02/16 CT024 K.Yamada
--                ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
                IF (ln_y_psa = 0) THEN
                  ln_y_rate     := 0;
                ELSE
                  ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100, 2);
                END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
                
                -- �N��_�e���v�z��(�N��_����)*100 �y�����_3���l�̌ܓ��z
                ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
                
                -- �N��_�\����
                ln_y_make     := 100;
            END IF;
            
            -- ������_�|��/������_�e���v��/������_�\����:�y�Z�o�����z
            IF (ln_h_sales = 0) THEN
                ln_h_rate     := 0;
                ln_h_margin_r := 0;
                ln_h_make     := 0;
            ELSE
                -- ������_���぀(������_����*�艿)*100 �y�����_3���l�̌ܓ��z
--//+UPD START 2009/02/16 CT024 K.Yamada
--                ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100,2);
                IF (ln_h_psa = 0) THEN
                  ln_h_rate     := 0;
                ELSE
                  ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100, 2);
                END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
                
                -- ������_�e���v�z��(������_����)*100 �y�����_3���l�̌ܓ��z
                ln_h_margin_r := ROUND(ln_h_margin / ln_h_sales * 100,2);
                
                -- ������_�\����
                ln_h_make     := 100;
            END IF;
            
            --==================================
            -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
            --==================================
            
            UPDATE
                    xxcsm_tmp_sales_plan_ref
            SET
-- ����
                   y_sales          = ln_y_sales                                -- �N�Ԕ���
                  ,y_amount         = ln_y_amount                               -- �N�Ԑ���
                  ,y_rate           = ln_y_rate                                 -- �N�Ԋ|��
                  ,y_margin_rate    = ln_y_margin_r                             -- �N�ԑe���v��
                  ,y_margin         = ln_y_margin                               -- �N�ԑe���v�z
-- �N��
                  ,h_sales          = ln_h_sales                                -- �����Ԕ���
                  ,h_amount         = ln_h_amount                               -- �����Ԑ���
                  ,h_rate           = ln_h_rate                                 -- �����Ԋ|��
                  ,h_margin_rate    = ln_h_margin_r                             -- �����ԑe���v��
                  ,h_margin         = ln_h_margin                               -- �����ԑe���v�z
-- ������
                  ,yg_make          = ln_yg_make                                -- �N�ԌQ�ʍ\����
                  ,yk_make          = ln_yk_make                                -- �N�ԋ��_�\����
                  ,hg_make          = ln_hg_make                                -- �N�ԌQ�ʍ\����
                  ,hk_make          = ln_hk_make                                -- �N�ԋ��_�\����
                  ,g_sum            = ln_g_sum                                  -- �Q�ʂ̍��v
                  ,k_sum            = ln_k_sum                                  -- ���_�̍��v
                  ,y_make           = ln_y_make                                 -- �N�ԍ\����
                  ,h_make           = ln_h_make                                 -- �����\����
            WHERE
                    item_cd         = lv_item_cd                                -- ���i�R�[�h
            AND     year            = ln_year                                   -- �Ώ۔N�x
            AND     flag            = 1;                                        -- �v��
            
            --===================================
            -- ���̏��i�ɂ��āA���v�Z�o��l���Đݒ�
            --===================================
            -- ���i�R�[�h
            lv_item_cd      := rec_plan_data.item_id;
            
            -- ���i�Q�R�[�h
            lv_group_id     := rec_plan_data.group_id;
            
            -- �Ώ۔N�x
            ln_year         := rec_plan_data.year;
  --
            -- �N�Ԕ���
            ln_y_sales      := rec_plan_data.sales;
            -- �N�ԑe���v�z
            ln_y_margin     := rec_plan_data.margin;
            -- �N�Ԑ���
            ln_y_amount     := rec_plan_data.amount;
            -- �N�Ԑ���*�艿
            ln_y_psa        := rec_plan_data.amount * rec_plan_data.price;
            
            
            -- �����Ԕ���
            ln_h_sales      := 0;
            -- �����ԑe���v�z
            ln_h_margin     := 0;
            -- �����Ԑ���
            ln_h_amount     := 0;
            -- �����Ԑ���*�艿
            ln_h_psa        := 0;
  --
            IF ((gv_kakuteiym >= cn_month) AND (rec_plan_data.month <= gv_kakuteiym) AND (rec_plan_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_plan_data.month >= cn_month) OR (rec_plan_data.month <= gv_kakuteiym)) ) THEN
                -- �����Ԕ���
                ln_h_sales      := rec_plan_data.sales;
                -- �����ԑe���v�z
                ln_h_margin     := rec_plan_data.margin;
                -- �����Ԑ���
                ln_h_amount     := rec_plan_data.amount;
                -- �����Ԑ���*�艿
                ln_h_psa        := rec_plan_data.amount * rec_plan_data.price;
            END IF;
            
        ELSIF ((lv_item_cd = rec_plan_data.item_id) AND (ln_year = rec_plan_data.year)) THEN
            --===================================
            -- �y����N�x�̏��i�z�N�ԗ݌v�����Z����
            --===================================
            -- �N�Ԕ���
            ln_y_sales      := ln_y_sales + rec_plan_data.sales;
            -- �N�ԑe���v�z
            ln_y_margin     := ln_y_margin + rec_plan_data.margin;
            -- �N�Ԑ���
            ln_y_amount     := ln_y_amount + rec_plan_data.amount;
            -- �N�Ԑ���*�艿
            ln_y_psa        := ln_y_psa + rec_plan_data.amount * rec_plan_data.price;
                    
            --===================================
            -- �y����N�x�̏��i�z�����ԗ݌v�����Z����
            --===================================
            IF ((gv_kakuteiym >= cn_month) AND (rec_plan_data.month <= gv_kakuteiym) AND (rec_plan_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_plan_data.month >= cn_month) OR (rec_plan_data.month <= gv_kakuteiym)) ) THEN
                    
                -- �����Ԕ���
                ln_h_sales      := ln_h_sales + rec_plan_data.sales;
                -- �����ԑe���v�z
                ln_h_margin     := ln_h_margin + rec_plan_data.margin;
                -- �����Ԑ���
                ln_h_amount     := ln_h_amount + rec_plan_data.amount;
                -- �����Ԑ���*�艿
                ln_h_psa        := ln_h_psa + rec_plan_data.amount * rec_plan_data.price;
            
            END IF;
        END IF;
        
        --===================================
        -- �y���i�P�ʁz���ԃf�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_ref
          (
              toroku_no  --�o�͏�
              ,group_cd        --���i�Q�R�[�h(2��)
              ,item_cd         --���i�R�[�h
              ,item_nm         --���i����
              ,year            --�N�x
              ,month_no        --��
              ,m_sales         --����_����
              ,m_amount        --����_����
              ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
              ,m_margin_rate   --����_�e���v��=����_����^����_�e���v�z*100
              ,m_margin        --����_�e���v�z
              ,flag            --�f�[�^�敪
          )
          VALUES (
              gn_index
              ,rec_plan_data.group_id
              ,rec_plan_data.item_id
              ,rec_plan_data.item_nm
              ,rec_plan_data.year
              ,rec_plan_data.month
              ,rec_plan_data.sales
              ,rec_plan_data.amount
--//+UPD START 2009/02/16 CT024 K.Yamada
--              ,DECODE(rec_plan_data.sales,0,0,ROUND(rec_plan_data.sales / (rec_plan_data.amount * rec_plan_data.price) * 100,2))
              ,DECODE((rec_plan_data.amount * rec_plan_data.price), 0, 0,
                 ROUND(rec_plan_data.sales / (rec_plan_data.amount * rec_plan_data.price) * 100, 2))
--//+UPD END   2009/02/16 CT024 K.Yamada
              ,DECODE(rec_plan_data.sales,0,0,ROUND(rec_plan_data.margin / rec_plan_data.sales * 100,2))
              ,rec_plan_data.margin
              ,1
          );
          
          gn_index := gn_index + 1;
          
    END LOOP get_sales_plan_data_cur_loop;
    
    IF (lb_loop_end) THEN
        
        -- �Q2���v�F���㍇�v
        <<get_group2_plan>>
        FOR rec IN get_group2_plan_data_cur(ln_year,lv_group_id) LOOP
            ln_g_sum := rec.g2_sales;
            
        END LOOP get_group2_plan;

        --�N�ԌQ2���\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_y_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_yg_make := 0;
        ELSE
            -- ���i_�N�Ԕ��぀�Q2��_���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_yg_make  := ROUND(ln_y_sales / ln_g_sum * 100,2);
        END IF;

        
        --�����ԌQ2���\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_h_sales = 0) THEN
        IF ((ln_h_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_hg_make := 0;
        ELSE
            -- ���i_�����Ԕ��぀�Q2��_���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_hg_make  := ROUND(ln_h_sales / ln_g_sum * 100,2);
        END IF;
                

        -- ���_�v�F���㍇�v
        <<get_kyoten_plan>>
        FOR rec IN get_kyoten_plan_data_cur (ln_year) LOOP
            ln_k_sum := rec.kyoten_sales;
            
        END LOOP get_kyoten_plan;

        --�N�ԋ��_�\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_y_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_yk_make := 0;
        ELSE
            -- ���i_�N�Ԕ��぀���__���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_yk_make  := ROUND(ln_y_sales / ln_k_sum * 100,2);
        END IF;
         

          
        --�����ԋ��_�\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_h_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_hk_make := 0;
        ELSE
            -- ���i_�����Ԕ��぀���__���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_hk_make  := ROUND(ln_h_sales / ln_k_sum * 100,2);
        END IF;
                
                

        -- �N��_�|��/�N��_�e���v��/�N��_�\����:�y�Z�o�����z
        IF (ln_y_sales = 0) THEN
            ln_y_rate     := 0;
            ln_y_margin_r := 0;
            ln_y_make     := 0;
        ELSE
            -- �N��_���぀(�N�Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+UPD START 2009/02/16 CT024 K.Yamada
--            ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
            IF (ln_y_psa = 0) THEN
              ln_y_rate     := 0;
            ELSE
              ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100, 2);
            END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
            
            -- �N��_�e���v�z��(�N��_����)*100 �y�����_3���l�̌ܓ��z
            ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
            
            -- �N��_�\����
            ln_y_make     := 100;
        END IF;
        
        -- ������_�|��/������_�e���v��/������_�\����:�y�Z�o�����z
        IF (ln_h_sales = 0) THEN
            ln_h_rate     := 0;
            ln_h_margin_r := 0;
            ln_h_make     := 0;
        ELSE
            -- ������_���぀(������_����*�艿)*100 �y�����_3���l�̌ܓ��z
--//+UPD START 2009/02/16 CT024 K.Yamada
--            ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100,2);
            IF (ln_h_psa = 0) THEN
              ln_h_rate     := 0;
            ELSE
              ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100, 2);
            END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
            
            -- ������_�e���v�z��(������_����)*100 �y�����_3���l�̌ܓ��z
            ln_h_margin_r := ROUND(ln_h_margin / ln_h_sales * 100,2);
            
            -- ������_�\����
            ln_h_make     := 100;
        END IF;
        
        --==================================
        -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
        --==================================
        
        UPDATE
                xxcsm_tmp_sales_plan_ref
        SET
-- ����
               y_sales          = ln_y_sales                                -- �N�Ԕ���
              ,y_amount         = ln_y_amount                               -- �N�Ԑ���
              ,y_rate           = ln_y_rate                                 -- �N�Ԋ|��
              ,y_margin_rate    = ln_y_margin_r                             -- �N�ԑe���v��
              ,y_margin         = ln_y_margin                               -- �N�ԑe���v�z
-- �N��
              ,h_sales          = ln_h_sales                                -- �����Ԕ���
              ,h_amount         = ln_h_amount                               -- �����Ԑ���
              ,h_rate           = ln_h_rate                                 -- �����Ԋ|��
              ,h_margin_rate    = ln_h_margin_r                             -- �����ԑe���v��
              ,h_margin         = ln_h_margin                               -- �����ԑe���v�z
-- ������
              ,yg_make          = ln_yg_make                                -- �N�ԌQ�ʍ\����
              ,yk_make          = ln_yk_make                                -- �N�ԋ��_�\����
              ,hg_make          = ln_hg_make                                -- �N�ԌQ�ʍ\����
              ,hk_make          = ln_hk_make                                -- �N�ԋ��_�\����
              ,g_sum            = ln_g_sum                                  -- �Q�ʂ̍��v
              ,k_sum            = ln_k_sum                                  -- ���_�̍��v
              ,y_make           = ln_y_make                                 -- �N�ԍ\����
              ,h_make           = ln_h_make                                 -- �����\����
        WHERE
                item_cd         = lv_item_cd                                -- ���i�R�[�h
        AND     year            = ln_year                                   -- �Ώ۔N�x
        AND     flag            = 1;                                        -- �v��
    END IF;

-- ===========================================================================  
--�y�v��f�[�^����-END�z
-- ===========================================================================
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
      IF (get_sales_plan_data_cur%ISOPEN) THEN
        CLOSE get_sales_plan_data_cur;
      END IF;
      
      IF (get_group2_plan_data_cur%ISOPEN) THEN
        CLOSE get_group2_plan_data_cur;
      END IF;
      
      IF (get_kyoten_plan_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_plan_data_cur;
      END IF;
      
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_sales_plan_data_cur%ISOPEN) THEN
        CLOSE get_sales_plan_data_cur;
      END IF;
      
      IF (get_group2_plan_data_cur%ISOPEN) THEN
        CLOSE get_group2_plan_data_cur;
      END IF;
      
      IF (get_kyoten_plan_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_plan_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END deal_plan_data;
--

   /****************************************************************************
   * Procedure Name   : deal_result_data
   * Description      : ���уf�[�^�̏ڍ׏���
   *                    �@�f�[�^�̒��o
   *                    �A�f�[�^�̎Z�o
   *                    �B�f�[�^�̓o�^
   ****************************************************************************/
   PROCEDURE deal_result_data(
         ov_errbuf     OUT NOCOPY VARCHAR2               --���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2               --���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --���[�U�[�E�G���[�E���b�Z�[�W
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_result_data';      -- �v���O������
    cn_month                CONSTANT NUMBER         := 5;                       -- ����(�̔����уJ�����_�[��)

    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_item_cd              VARCHAR2(10);               -- �i�ڃR�[�h
    lv_group_id             VARCHAR2(10);               -- ���i�Q�R�[�h
    
    str_temp                VARCHAR2(2000);
-- �N��    
    ln_y_sales              NUMBER  := 0;               -- 1�N�Ԃ̔�����z���v
    ln_y_margin             NUMBER  := 0;               -- 1�N�Ԃ̑e���v�z���v
    ln_y_amount             NUMBER  := 0;               -- 1�N�Ԃ̐��ʍ��v
    ln_y_psa                NUMBER  := 0;               -- 1�N�Ԃ̐���*�艿�̍��v
    ln_y_rate               NUMBER  := 0;               -- �N��_�|��
    ln_y_margin_r           NUMBER  := 0;               -- �N��_�e���v��
    ln_y_make               NUMBER  := 0;               -- �N��_�\����
    ln_h_make               NUMBER  := 0;               -- ������_�\����

-- ������    
    ln_h_sales              NUMBER  := 0;               -- �����Ԃ̔�����z���v
    ln_h_margin             NUMBER  := 0;               -- �����Ԃ̑e���v�z���v
    ln_h_amount             NUMBER  := 0;               -- �����Ԃ̐��ʍ��v
    ln_h_psa                NUMBER  := 0;               -- �����Ԃ̐���*�艿�̍��v
    ln_h_rate               NUMBER  := 0;               -- ������_�|��
    ln_h_margin_r           NUMBER  := 0;               -- ������_�e���v��

-- �Q2���E���_    
    ln_yg_make              NUMBER  := 0;               -- �N�ԌQ2���\����
    ln_yk_make              NUMBER  := 0;               -- �N�ԋ��_�\����
    ln_hg_make              NUMBER  := 0;               -- �����ԌQ2���\����
    ln_hk_make              NUMBER  := 0;               -- �����ԋ��_�\����
    ln_g_sum                NUMBER  := 0;               -- �Q2�����㍇�v
    ln_k_sum                NUMBER  := 0;               -- ���_���㍇�v    
 
-- �ꎞ�ϐ�     
    ln_year                 NUMBER  := 0;               -- �N�x���f�p�ϐ�
    ln_month                NUMBER  := 0;               -- �����f�p�ϐ�
    lb_loop_end             BOOLEAN := FALSE;            -- LOOP���f�p

    
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--============================================
--  �f�[�^�̒��o�y���сz���[�J���E�J�[�\��
--============================================
--                  
    CURSOR   
        get_sales_result_data_cur
    IS
--//+DEL START 2009/07/10 ��Q0000637 T.Tsukino
--          SELECT
--//+DEL END 2009/07/10 ��Q0000637 T.Tsukino
--//+ADD START 2009/07/10 ��Q0000637 T.Tsukino
          SELECT /*+ INDEX(xcgv.xsib XXCMM_SYSTEM_ITEMS_B_U01) */ 
--//+ADD END 2009/07/10 ��Q0000637 T.Tsukino
             xipr.subject_year                      AS  year                        -- �Ώ۔N�x
            ,xipr.month_no                          AS  month                       -- ��
            ,SUM(NVL(xipr.amount,0))                AS  amount                      -- ����
            ,SUM(NVL(xipr.sales_budget,0))          AS  sales                       -- ������z
            ,SUM(NVL(xipr.amount_gross_margin,0))   AS  margin                      -- �e���v�z
            ,xipr.item_group_no                     AS  group_id                    -- ���i�Q�R�[�h
            ,xcgv.item_cd                           AS  item_id                     -- �i�ڃR�[�h
            ,xcgv.item_nm                           AS  item_nm                     -- �i�ږ���
            ,NVL(xcgv.now_unit_price,0)             AS  price                       -- �艿
        FROM     
            xxcsm_item_plan_result          xipr                                    -- ���i�v��p�̔����уe�[�u��
            ,xxcsm_commodity_group2_v       xcgv                                    -- ����Q�Q�r���[
        WHERE    
             xcgv.item_cd                               = xipr.item_no              -- ���i�R�[�h
        AND (xipr.subject_year                          = gv_taisyoYm-2             -- �O�X�N�x
        OR   xipr.subject_year                          = gv_taisyoYm-1)             -- �O�N�x
        AND xipr.location_cd                            = gv_kyotenCD               -- ���_�R�[�h
        GROUP BY
              xipr.subject_year                        -- �Ώ۔N�x
              ,xipr.month_no                           -- ��
              ,xipr.item_group_no                      -- ���i�Q�R�[�h
              ,xcgv.item_cd                            -- ���i�R�[�h
              ,xcgv.item_nm                            -- ���i����
              ,xcgv.now_unit_price                     -- �艿
        ORDER BY 
              item_id       ASC
              ,year         ASC
              ,month        ASC
              ,group_id     ASC
              ;

-- �Q2���v�F���㍇�v
    CURSOR   
        get_group2_result_data_cur(
                                    in_year IN NUMBER
                                    ,in_group_id IN VARCHAR2)
    IS
--//+DEL START 2009/07/10 ��Q0000637 T.Tsukino
--          SELECT
--//+DEL END 2009/07/10 ��Q0000637 T.Tsukino
--//+ADD START 2009/07/10 ��Q0000637 T.Tsukino
          SELECT /*+ INDEX(xcgv.xsib XXCMM_SYSTEM_ITEMS_B_U01) */ 
--//+ADD END 2009/07/10 ��Q0000637 T.Tsukino
              SUM(NVL(xipr.sales_budget,0))       AS g2_sales                    -- �N�Ԕ���
        FROM     
              xxcsm_item_plan_result        xipr                                     -- ���i�v��p�̔����уe�[�u��
              ,xxcsm_commodity_group2_v     xcgv                                     -- ����Q�Q�r���[
        WHERE    
            xipr.item_no                 = xcgv.item_cd                          -- ���i�R�[�h
        AND xipr.subject_year            = in_year                               -- �Ώ۔N�x
        AND xipr.location_cd             = gv_kyotenCD                           -- ���_�R�[�h
        AND SUBSTR(xcgv.group2_cd,1,2)   = SUBSTR(in_group_id,1,2);              -- ���i�Q2���R�[�h



-- ���_�v�F���㍇�v
    CURSOR   
        get_kyoten_result_data_cur(in_year IN NUMBER)
    IS
            SELECT   
                SUM(NVL(xipr.sales_budget,0))   AS kyoten_sales                       -- �N�Ԕ���
            FROM     
                xxcsm_item_plan_result            xipr                                 -- ���i�v��p�̔����уe�[�u��
            WHERE    
                 xipr.subject_year                = in_year                             -- �Ώ۔N�x
            AND  xipr.location_cd                 = gv_kyotenCD;                        -- ���_�R�[�h

            

--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

-- ===========================================================================  
--�y���уf�[�^����-START�z
-- ===========================================================================
    lv_item_cd := NULL;
    <<get_sales_result_data_cur_loop>>
    -- ���уf�[�^�擾
    FOR rec_result_data IN get_sales_result_data_cur LOOP
        
        -- ���f�p
        lb_loop_end := TRUE;
        
        -- ������
        IF (lv_item_cd IS NULL) THEN
            -- ���i�R�[�h
            lv_item_cd      := rec_result_data.item_id;
            
            -- ���i�Q�R�[�h
            lv_group_id     := rec_result_data.group_id;
            
            -- �Ώ۔N�x
            ln_year         := rec_result_data.year;
--
            -- �N�Ԕ���
            ln_y_sales      := rec_result_data.sales;
            -- �N�ԑe���v�z
            ln_y_margin     := rec_result_data.margin;
            -- �N�Ԑ���
            ln_y_amount     := rec_result_data.amount;
            -- �N�Ԑ���*�艿
            ln_y_psa        := rec_result_data.amount * rec_result_data.price;
--
            IF ((gv_kakuteiym >= cn_month) AND (rec_result_data.month <= gv_kakuteiym) AND (rec_result_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_result_data.month >= cn_month) OR (rec_result_data.month <= gv_kakuteiym)) ) THEN
                -- �����Ԕ���
                ln_h_sales      := rec_result_data.sales;
                -- �����ԑe���v�z
                ln_h_margin     := rec_result_data.margin;
                -- �����Ԑ���
                ln_h_amount     := rec_result_data.amount;
                -- �����Ԑ���*�艿
                ln_h_psa        := rec_result_data.amount * rec_result_data.price;
            END IF;
            
            -- ���i�R�[�h���ς�����ꍇ�i���̏��i�j
        ELSIF ((lv_item_cd <> rec_result_data.item_id) OR (ln_year <> rec_result_data.year)) THEN
           
            -- �Q2���v�F���㍇�v
            <<get_group2_result>>
            FOR rec IN get_group2_result_data_cur(ln_year,lv_group_id) LOOP
                ln_g_sum := rec.g2_sales;
                
            END LOOP get_group2_result;

            --�N�ԌQ2���\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_y_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_yg_make := 0;
            ELSE
                -- ���i_�N�Ԕ��぀�Q2��_���㍇�v*100 �y�����_3���l�̌ܓ��z
                ln_yg_make  := ROUND(ln_y_sales / ln_g_sum * 100,2);
            END IF;

            
            -- �����ԌQ2���\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_h_sales = 0) THEN
            IF ((ln_h_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_hg_make := 0;
            ELSE
                -- ���i_�����Ԕ��぀�Q2��_���㍇�v*100 �y�����_3���l�̌ܓ��z
                ln_hg_make  := ROUND(ln_h_sales / ln_g_sum * 100,2);
            END IF;

            -- ���_�v�F���㍇�v
            <<get_kyoten_result>>
            FOR rec IN get_kyoten_result_data_cur(ln_year) LOOP
                ln_k_sum := rec.kyoten_sales;
                
            END LOOP get_kyoten_result;


            -- �N�ԋ��_�\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_y_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_yk_make := 0;
            ELSE
            -- ���i_�N�Ԕ��぀���__���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_yk_make    := ROUND(ln_y_sales / ln_k_sum * 100);
            END IF;

            --�����ԋ��_�\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_h_sales = 0) THEN
            IF ((ln_h_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_hk_make    := 0;
            ELSE
                -- ���i_�����Ԕ��぀���__���㍇�v*100 �y�����_3���l�̌ܓ��z
                ln_hk_make    := ROUND(ln_h_sales / ln_k_sum * 100);
            END IF;
              
            
            -- �N��_�|��/�N��_�e���v��/�N��_�\����:�y�Z�o�����z
            IF (ln_y_sales = 0) THEN
                ln_y_rate     := 0;
                ln_y_margin_r := 0;
                ln_y_make     := 0;
            ELSE
                -- �N��_���぀(�N��_����*�艿)*100 �y�����_3���l�̌ܓ��z
--//+UPD START 2009/02/16 CT024 K.Yamada
--                ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
                IF (ln_y_psa = 0) THEN
                  ln_y_rate     := 0;
                ELSE
                  ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100, 2);
                END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
                
                -- �N��_�e���v�z��(�N��_����)*100 �y�����_3���l�̌ܓ��z
                ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
                
                -- �N��_�\����
                ln_y_make     := 100;
            END IF;
            
            -- ������_�|��/������_�e���v��/������_�\����:�y�Z�o�����z
            IF (ln_h_sales = 0) THEN
                ln_h_rate     := 0;
                ln_h_margin_r := 0;
                ln_h_make     := 0;
            ELSE
                -- ������_���぀(�����Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+UPD START 2009/02/16 CT024 K.Yamada
--                ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100,2);
                IF (ln_h_psa = 0) THEN
                  ln_h_rate     := 0;
                ELSE
                  ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100, 2);
                END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
                
                -- ������_�e���v�z��(������_����)*100 �y�����_3���l�̌ܓ��z
                ln_h_margin_r := ROUND(ln_h_margin / ln_h_sales * 100,2);
                
                -- ������_�\����
                ln_h_make     := 100;
            END IF;
            
            --==================================
            -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
            --==================================
            UPDATE
                    xxcsm_tmp_sales_plan_ref
            SET
-- �N�Ԍv
                  y_sales           = ln_y_sales                                -- �N�Ԕ���
                  ,y_amount         = ln_y_amount                               -- �N�Ԑ���
                  ,y_rate           = ln_y_rate                                 -- �N�Ԋ|��
                  ,y_margin_rate    = ln_y_margin_r                             -- �N�ԑe���v��
                  ,y_margin         = ln_y_margin                               -- �N�ԑe���v�z

-- �����v
                  ,h_sales          = ln_h_sales                                -- �����Ԕ���
                  ,h_amount         = ln_h_amount                               -- �����Ԑ���
                  ,h_rate           = ln_h_rate                                 -- �����Ԋ|��
                  ,h_margin_rate    = ln_h_margin_r                             -- �����ԑe���v��
                  ,h_margin         = ln_h_margin                               -- �����ԑe���v�z
-- �Q�ʁE���_�v
                  ,hg_make          = ln_hg_make                                -- �����ԌQ�ʍ\����
                  ,hk_make          = ln_hk_make                                -- �����ԋ��_�\����
                  ,g_sum            = ln_g_sum                                  -- �Q�ʂ̔��㍇�v
                  ,k_sum            = ln_k_sum                                  -- ���_�ʂ̔��㍇�v
                  ,yg_make          = ln_yg_make                                -- �N�ԌQ�ʍ\����
                  ,yk_make          = ln_yk_make                                -- �N�ԋ��_�\����
                  ,y_make           = ln_y_make                                 -- �N�ԍ\����
                  ,h_make           = ln_h_make                                 -- �����ԍ\����
            WHERE
                    item_cd         = lv_item_cd                                -- ���i�R�[�h
            AND     year            = ln_year                                   -- �Ώ۔N�x
            AND     flag            = 0;                                        -- ����
            

            --===================================
            -- ���̏��i�ɂ��āA���v�Z�o��l���Đݒ�
            --===================================
            -- ���i�R�[�h
            lv_item_cd      := rec_result_data.item_id;
            
            -- ���i�Q�R�[�h
            lv_group_id     := rec_result_data.group_id;
            
            -- �Ώ۔N�x
            ln_year         := rec_result_data.year;
--
            -- �N�Ԕ���
            ln_y_sales      := rec_result_data.sales;
            -- �N�ԑe���v�z
            ln_y_margin     := rec_result_data.margin;
            -- �N�Ԑ���
            ln_y_amount     := rec_result_data.amount;
            -- �N�Ԑ���*�艿
            ln_y_psa        := rec_result_data.amount * rec_result_data.price;
            
            -- �����Ԕ���
            ln_h_sales      := 0;
            -- �����ԑe���v�z
            ln_h_margin     := 0;
            -- �����Ԑ���
            ln_h_amount     := 0;
            -- �����Ԑ���*�艿
            ln_h_psa        := 0;
            
--
            IF ((gv_kakuteiym >= cn_month) AND (rec_result_data.month <= gv_kakuteiym) AND (rec_result_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_result_data.month >= cn_month) OR (rec_result_data.month <= gv_kakuteiym)) ) THEN
                -- �����Ԕ���
                ln_h_sales      := rec_result_data.sales;
                -- �����ԑe���v�z
                ln_h_margin     := rec_result_data.margin;
                -- �����Ԑ���
                ln_h_amount     := rec_result_data.amount;
                -- �����Ԑ���*�艿
                ln_h_psa        := rec_result_data.amount * rec_result_data.price;
            END IF;
            
        ELSIF (ln_year = rec_result_data.year) THEN
            --===================================
            -- �y����N�x�̏��i�z�N�ԗ݌v�����Z����
            --=================================== 
--
            -- �N�Ԕ���
            ln_y_sales      := ln_y_sales + rec_result_data.sales;
            -- �N�ԑe���v�z
            ln_y_margin     := ln_y_margin + rec_result_data.margin;
            -- �N�Ԑ���
            ln_y_amount     := ln_y_amount + rec_result_data.amount;
            -- �N�Ԑ���*�艿
            ln_y_psa        := ln_y_psa + rec_result_data.amount * rec_result_data.price;
                    
            --===================================
            -- �y����N�x�̏��i�z�����ԗ݌v�����Z����
            --===================================
--
            IF ((gv_kakuteiym >= cn_month) AND (rec_result_data.month <= gv_kakuteiym) AND (rec_result_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_result_data.month >= cn_month) OR (rec_result_data.month <= gv_kakuteiym)) ) THEN
                    
                -- �����Ԕ���
                ln_h_sales      := ln_h_sales + rec_result_data.sales;
                -- �����ԑe���v�z
                ln_h_margin     := ln_h_margin + rec_result_data.margin;
                -- �����Ԑ���
                ln_h_amount     := ln_h_amount + rec_result_data.amount;
                -- �����Ԑ���*�艿
                ln_h_psa        := ln_h_psa + rec_result_data.amount * rec_result_data.price;
            
            END IF;
        END IF;
        
        --===================================
        --���i�P�ʂ̌��ԃf�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_ref
          (
              toroku_no        --�o�͏�
              ,group_cd        --���i�Q�R�[�h(2��)
              ,item_cd         --���i�R�[�h
              ,item_nm         --���i����
              ,year            --�N�x
              ,month_no        --��
              ,m_sales         --����_����
              ,m_amount        --����_����
              ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
              ,m_margin_rate   --����_�e���v��=����_�e���v�z�^����_����*100
              ,m_margin        --����_�e���v�z
              ,flag            --�f�[�^�敪
          )
          VALUES (
              gn_index
              ,rec_result_data.group_id
              ,rec_result_data.item_id
              ,rec_result_data.item_nm
              ,rec_result_data.year
              ,rec_result_data.month
              ,rec_result_data.sales
              ,rec_result_data.amount
              ,DECODE((rec_result_data.amount * rec_result_data.price),0,0,ROUND(rec_result_data.sales / (rec_result_data.amount * rec_result_data.price) * 100,2))
              ,DECODE(rec_result_data.sales,0,0,ROUND(rec_result_data.margin / rec_result_data.sales * 100,2))
              ,rec_result_data.margin
              ,0
          );
          gn_index := gn_index + 1;
          
    END LOOP get_sales_result_data_cur_loop;
    
    -- �Ō�f�[�^�̏ꍇ
    IF (lb_loop_end) THEN
    
        -- �Q2���v�F���㍇�v
        <<get_group2_result>>
        FOR rec IN get_group2_result_data_cur(ln_year,lv_group_id) LOOP
            ln_g_sum := rec.g2_sales;
            
        END LOOP get_group2_result;


        --�N�ԌQ2���\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_y_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_yg_make := 0;
        ELSE
            -- ���i_�N�Ԕ��぀�Q2��_���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_yg_make  := ROUND(ln_y_sales / ln_g_sum * 100,2);
        END IF;

        
        -- �����ԌQ2���\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_h_sales = 0) THEN
        IF ((ln_h_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_hg_make := 0;
        ELSE
            -- ���i_�����Ԕ��぀�Q2��_���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_hg_make  := ROUND(ln_h_sales / ln_g_sum * 100,2);
        END IF;


        -- ���_�v�F���㍇�v
        <<get_kyoten_result>>
        FOR rec IN get_kyoten_result_data_cur(ln_year) LOOP
            ln_k_sum := rec.kyoten_sales;
            
        END LOOP get_kyoten_result;


        -- �N�ԋ��_�\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_y_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_yk_make := 0;
        ELSE
            -- ���i_�N�Ԕ��぀���__���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_yk_make    := ROUND(ln_y_sales / ln_k_sum * 100);
        END IF;

        --�����ԋ��_�\����
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_h_sales = 0) THEN
        IF ((ln_h_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_hk_make    := 0;
        ELSE
            -- ���i_�����Ԕ��぀���__���㍇�v*100 �y�����_3���l�̌ܓ��z
            ln_hk_make    := ROUND(ln_h_sales / ln_k_sum * 100);
        END IF;
          
        
        -- �N��_�|��/�N��_�e���v��/�N��_�\����:�y�Z�o�����z
        IF (ln_y_sales = 0) THEN
            ln_y_rate     := 0;
            ln_y_margin_r := 0;
            ln_y_make     := 0;
        ELSE
            -- �N��_���぀(�N��_����*�艿)*100 �y�����_3���l�̌ܓ��z
--//+UPD START 2009/02/16 CT024 K.Yamada
--            ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
            IF (ln_y_psa = 0) THEN
              ln_y_rate     := 0;
            ELSE
              ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100, 2);
            END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
            
            -- �N��_�e���v�z��(�N��_����)*100 �y�����_3���l�̌ܓ��z
            ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
            
            -- �N��_�\����
            ln_y_make     := 100;
        END IF;
        
        -- ������_�|��/������_�e���v��/������_�\����:�y�Z�o�����z
        IF (ln_h_sales = 0) THEN
            ln_h_rate     := 0;
            ln_h_margin_r := 0;
            ln_h_make     := 0;
        ELSE
            -- ������_���぀(�����Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+UPD START 2009/02/16 CT024 K.Yamada
--            ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100,2);
            IF (ln_h_psa = 0) THEN
              ln_h_rate     := 0;
            ELSE
              ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100, 2);
            END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
            
            -- ������_�e���v�z��(������_����)*100 �y�����_3���l�̌ܓ��z
            ln_h_margin_r := ROUND(ln_h_margin / ln_h_sales * 100,2);
            
            -- ������_�\����
            ln_h_make     := 100;
        END IF;
        
        UPDATE
                xxcsm_tmp_sales_plan_ref
        SET
    -- �N�Ԍv
              y_sales           = ln_y_sales                                -- �N�Ԕ���
              ,y_amount         = ln_y_amount                               -- �N�Ԑ���
              ,y_rate           = ln_y_rate                                 -- �N�Ԋ|��
              ,y_margin_rate    = ln_y_margin_r                             -- �N�ԑe���v��
              ,y_margin         = ln_y_margin                               -- �N�ԑe���v�z

    -- �����v
              ,h_sales          = ln_h_sales                                -- �����Ԕ���
              ,h_amount         = ln_h_amount                               -- �����Ԑ���
              ,h_rate           = ln_h_rate                                 -- �����Ԋ|��
              ,h_margin_rate    = ln_h_margin_r                             -- �����ԑe���v��
              ,h_margin         = ln_h_margin                               -- �����ԑe���v�z
    -- �Q�ʁE���_�v
              ,hg_make          = ln_hg_make                                -- �����ԌQ�ʍ\����
              ,hk_make          = ln_hk_make                                -- �����ԋ��_�\����
              ,g_sum            = ln_g_sum                                  -- �Q�ʂ̔��㍇�v
              ,k_sum            = ln_k_sum                                  -- ���_�ʂ̔��㍇�v
              ,yg_make          = ln_yg_make                                -- �N�ԌQ�ʍ\����
              ,yk_make          = ln_yk_make                                -- �N�ԋ��_�\����
              ,y_make           = ln_y_make                                 -- �N�ԍ\����
              ,h_make           = ln_h_make                                 -- �����ԍ\����
        WHERE
                item_cd         = lv_item_cd                                -- ���i�R�[�h
        AND     year            = ln_year                                   -- �Ώ۔N�x
        AND     flag            = 0;                                        -- ����
    END IF;

-- ===========================================================================  
--�y���уf�[�^����-END�z
-- ===========================================================================
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
      IF (get_sales_result_data_cur%ISOPEN) THEN
        CLOSE get_sales_result_data_cur;
      END IF;
      
      IF (get_group2_result_data_cur%ISOPEN) THEN
        CLOSE get_group2_result_data_cur;
      END IF;
      
      IF (get_kyoten_result_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_result_data_cur;
      END IF;
      

    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_sales_result_data_cur%ISOPEN) THEN
        CLOSE get_sales_result_data_cur;
      END IF;
      
      IF (get_group2_result_data_cur%ISOPEN) THEN
        CLOSE get_group2_result_data_cur;
      END IF;
      
      IF (get_kyoten_result_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_result_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END deal_result_data;
--


  /*****************************************************************************
   * Procedure Name   : write_Line_Info
   * Description      : ���i�R�[�h���ɏ����o��
   ****************************************************************************/
  PROCEDURE write_Line_Info(
    in_item_cd    IN  VARCHAR2                                                  -- ���i�R�[�h
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                           -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                           -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    
    -- ���ԁF�f�[�^�E������
    lv_month_sql                VARCHAR2(2000);
    
    -- ���v�i�N�ԁA�����ԁj�F�f�[�^�E������
    lv_sum_sql                  VARCHAR2(2000);
    
    -- �{�f�B�w�b�_���i���iCD-���i�QCD�b���i���́j
    lv_line_head                VARCHAR2(2000);
    
    -- �����i5��|6��|7��|8��|9��|10��|11��|12��|1��|2��|3��|04���j
    lv_line_info                VARCHAR2(4000);
    
    -- ���ږ���
    lv_item_info                VARCHAR2(4000);
    
    -- LOOP�����p
    in_param                    NUMBER := 0;
    lb_loop_end                 BOOLEAN := FALSE;
--//+ADD START 2009/05/25 T1_1020  M.Ohtsuki
    ln_cnt                      NUMBER;
    ln_flag                     NUMBER;
--//+ADD END   2009/05/25 T1_1020  M.Ohtsuki
    
    -- �e���v�ϐ�
    lv_temp_month               VARCHAR2(4000);
    lv_temp_sum                 VARCHAR2(4000);
    
    cv_all_zero         CONSTANT VARCHAR2(100)     := '0,0,0,0,0,0,0,0,0,0,0,0,0,0' || CHR(10);
    cv_year_zz_r        CONSTANT VARCHAR2(100)     := SUBSTR(TO_CHAR(gv_taisyoYm-2),3,4) || lv_prf_cd_result_val;
    cv_year_z_r         CONSTANT VARCHAR2(100)     := SUBSTR(TO_CHAR(gv_taisyoYm-1),3,4) || lv_prf_cd_result_val;
    cv_year_z_p         CONSTANT VARCHAR2(100)     := SUBSTR(TO_CHAR(gv_taisyoYm-1),3,4) || lv_prf_cd_plan_val;
    cv_year_zero        CONSTANT VARCHAR2(10)      := '0,0' || CHR(10);
-- ���v�J�[�\��
    CURSOR get_month_data_cur(
                        in_param IN NUMBER
                        ,in_taisyo_ym IN NUMBER
                        ,in_item_cd IN VARCHAR2
                        ,in_flag IN NUMBER
                        )
    IS 
      SELECT
            DECODE(in_param
--//+UPD START 2009/02/18   CT027 K.Sai
--                       ,0,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0)/1000,2) || cv_msg_comma               -- ����y���z
--                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0)/1000,2) || cv_msg_comma
                       ,0,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0)/1000,0) || cv_msg_comma               -- ����y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0)/1000,0) || cv_msg_comma
--//+UPD END 2009/02/18   CT027 K.Sai
                       ,1,NVL(SUM(DECODE(month_no,5,m_rate,0)  ),0) || cv_msg_comma                -- �|���y���z
                          || NVL(SUM(DECODE(month_no,6,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,m_rate,0)  ),0) || cv_msg_comma
                       ,2,NVL(SUM(DECODE(month_no,5,m_amount,0)  ),0) || cv_msg_comma              -- ���ʁy���z
                          || NVL(SUM(DECODE(month_no,6,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,m_amount,0)  ),0) || cv_msg_comma
                       ,3,NVL(SUM(DECODE(month_no,5,m_margin_rate,0)  ),0) || cv_msg_comma         -- �e���v���y���z
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
--//+UPD START 2009/02/18   CT027 K.Sai
--                       ,4,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0)/1000,2) || cv_msg_comma              -- �e���v�z�y���z
--                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0)/1000,2) || cv_msg_comma
                       ,4,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0)/1000,0) || cv_msg_comma              -- �e���v�z�y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0)/1000,0) || cv_msg_comma
--//+UPD END 2009/02/18   CT027 K.Sai
--//+UPD START 2009/02/16 CT024 K.Yamada
--                       ,5,NVL(SUM(DECODE(month_no,5,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma        -- �\����y���z
--                          || NVL(SUM(DECODE(month_no,6,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,7,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,8,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,9,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,10,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,11,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,12,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,1,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,2,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,3,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,4,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                       ,5,NVL(SUM(DECODE(month_no,5,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0) || cv_msg_comma        -- �\����y���z
                          || NVL(SUM(DECODE(month_no,6,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
--//+UPD END   2009/02/16 CT024 K.Yamada
--//+UPD START 2009/02/16 CT024 K.Yamada
--                       ,6,NVL(SUM(DECODE(month_no,5, DECODE(m_sales,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma               -- �Q2���\����y���z
--                          || NVL(SUM(DECODE(month_no,6, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,7, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,8, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,9, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,10,DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,11,DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,12,DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,1, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,2, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,3, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,4, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                       ,6,NVL(SUM(DECODE(month_no,5, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma               -- �Q2���\����y���z
                          || NVL(SUM(DECODE(month_no,6, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--//+UPD END   2009/02/16 CT024 K.Yamada
--//+UPD START 2009/02/16 CT024 K.Yamada
--                       ,7,NVL(SUM(DECODE(month_no,5,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma                -- ���_�\����y���z
--                          || NVL(SUM(DECODE(month_no,6,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,7,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,8,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,9,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,10,DECODE(m_saleS,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,11,DECODE(m_saleS,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,12,DECODE(m_saleS,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,1,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,2,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,3,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,4,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                       ,7,NVL(SUM(DECODE(month_no,5,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma                -- ���_�\����y���z
                          || NVL(SUM(DECODE(month_no,6,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--//+UPD END   2009/02/16 CT024 K.Yamada
                       ,NULL) AS month_data
      FROM  
            xxcsm_tmp_sales_plan_ref       -- ���i�v��Q�l�������[�N�e�[�u��
      WHERE
            year        = in_taisyo_ym    -- �Ώۓx
      AND   item_cd     = in_item_cd      -- ���i�R�[�h
      AND   flag        = in_flag;
      
-- �N�v�J�[�\��
    CURSOR  get_year_data_cur(
                        in_param IN NUMBER
                        ,in_taisyo_ym IN NUMBER
                        ,in_item_cd IN VARCHAR2
                        ,in_flag IN NUMBER
                        )
    IS
      SELECT   DISTINCT
               DECODE(in_param
--//+UPD START 2009/02/18   CT027 K.Sai
--                    ,0,ROUND(y_sales/1000,2) || cv_msg_comma || ROUND(h_sales/1000,2) || CHR(10)                    -- ���㍇�v
                    ,0,ROUND(y_sales/1000,0) || cv_msg_comma || ROUND(h_sales/1000,0) || CHR(10)                    -- ���㍇�v
--//+UPD END 2009/02/18   CT027 K.Sai
                    ,1,y_rate || cv_msg_comma || h_rate || CHR(10)                      -- �|�����v
                    ,2,y_amount || cv_msg_comma || h_amount || CHR(10)                  -- ���ʍ��v
                    ,3,y_margin_rate || cv_msg_comma || h_margin_rate || CHR(10)        -- �e���v�����v
--//+UPD START 2009/02/18   CT027 K.Sai
--                    ,4,ROUND(y_margin/1000,2) || cv_msg_comma || ROUND(h_margin/1000,2) || CHR(10)                  -- �e���v�z���v
                    ,4,ROUND(y_margin/1000,0) || cv_msg_comma || ROUND(h_margin/1000,0) || CHR(10)                  -- �e���v�z���v
--//+UPD END 2009/02/18   CT027 K.Sai
                    ,5,y_make || cv_msg_comma || h_make || CHR(10)                            -- �\���䍇�v
--//+UPD START 2009/02/16 CT024 K.Yamada
--                    ,6,DECODE(y_sales,0,0,ROUND(y_sales / g_sum * 100,2)) || cv_msg_comma     -- �Q2���\���䍇�v
--                      || DECODE(h_sales,0,0,ROUND(h_sales / g_sum * 100,2)) || CHR(10)
--                    ,7,DECODE(y_sales,0,0,ROUND(y_sales / k_sum * 100,2)) || cv_msg_comma     -- ���_�\���䍇�v
--                      || DECODE(h_sales,0,0,ROUND(h_sales / k_sum * 100,2)) || CHR(10)
                    ,6,DECODE(g_sum,0,0,ROUND(y_sales / g_sum * 100,2)) || cv_msg_comma     -- �Q2���\���䍇�v
                      || DECODE(g_sum,0,0,ROUND(h_sales / g_sum * 100,2)) || CHR(10)
                    ,7,DECODE(k_sum,0,0,ROUND(y_sales / k_sum * 100,2)) || cv_msg_comma     -- ���_�\���䍇�v
                      || DECODE(k_sum,0,0,ROUND(h_sales / k_sum * 100,2)) || CHR(10)
--//+UPD END   2009/02/16 CT024 K.Yamada
                    ,NULL) AS year_data
      FROM  
            xxcsm_tmp_sales_plan_ref       -- ���i�v��Q�l�������[�N�e�[�u��
      WHERE
            year        = in_taisyo_ym    -- �Ώۓx
      AND   item_cd     = in_item_cd      -- ���i�R�[�h
      AND   flag        = in_flag;
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
--//+ADD START 2009/05/25 T1_1020 M.Ohtsuki
    ln_cnt  := 0;
    ln_flag := 0;
--************************************************************************************
--*****���[�N�e�[�u���̃f�[�^�����сA�v��ŏ��i�Q�R�[�h�̎������ɍ��ق������   ******
--*****���уf�[�^�����݂���ꍇ�͎��т̏��i�Q�R�[�h(4��),                       ******
--*****�v��f�[�^�̂ݑ��݂���ꍇ�́A�v��f�[�^�̏��i�Q�R�[�h(3��)���o�͂��܂��B******
--************************************************************************************
    SELECT COUNT(1)                                                                                 -- ���уf�[�^����
    INTO   ln_cnt
    FROM   xxcsm_tmp_sales_plan_ref                                                                 -- ���i�v��Q�l�������[�N�e�[�u��
    WHERE  item_cd = in_item_cd                                                                     -- �i�ڃR�[�h
    AND    flag = 0                                                                                 -- ( 0 = ���уf�[�^)
    AND    ROWNUM = 1;
--
    IF (ln_cnt = 1) THEN                                                                            --���уf�[�^�����݂���ꍇ
      ln_flag := 0;
    ELSE                                                                                            --�v��f�[�^�̂ݑ��݂���ꍇ
      ln_flag := 1;
    END IF;
--//+ADD END   2009/05/25 T1_1020  M.Ohtsuki
    --  ���i�R�[�h-���i�Q�R�[�h|���i���̒��o
    SELECT DISTINCT
            cv_msg_duble || 
--//+UPD START 2010/12/13 E_�{�ғ�_05803 Y.Kanami
--            item_cd      || 
--            cv_msg_hafu  || 
--            group_cd     || 
            group_cd     || 
            cv_msg_hafu  || 
            item_cd      || 
--//+UPD END 2010/12/13 E_�{�ғ�_05803 Y.Kanami
            cv_msg_duble || 
            cv_msg_comma || 
            cv_msg_duble || 
            item_nm      || 
            cv_msg_duble || 
            cv_msg_comma 
    INTO
            lv_line_head
    FROM     
            xxcsm_tmp_sales_plan_ref           -- ���i�v��Q�l�������[�N�e�[�u��
    WHERE
            item_cd = in_item_cd
--//+ADD START 2009/05/25 T1_1020 M.Ohtsuki
    AND     flag = ln_flag;                                                                         -- (����=0�A�v��=1)
--//+ADD END   2009/05/25 T1_1020 M.Ohtsuki
--========================================================================= 
--  0:����E1:�|���E2:���ʁE3:�e���v���E4:�e���v�z�E5:�\����E6:�Q2���\����E7:���_�v�\����
--=========================================================================
      <<line_loop>>
      WHILE (in_param < 8 ) LOOP
              
          IF (in_param = 0) THEN
              
              -- ����y���ږ��z
              lv_item_info := cv_msg_duble || lv_prf_cd_sales_val || cv_msg_duble || cv_msg_comma;
                      
          ELSIF (in_param = 1) THEN
              
              -- �|���y���ږ��z
              lv_item_info := cv_msg_duble || lv_prf_cd_rate_val || cv_msg_duble || cv_msg_comma;    
                      
          ELSIF (in_param = 2) THEN
              
              -- ���ʁy���ږ��z
              lv_item_info := cv_msg_duble || lv_prf_cd_amount_val || cv_msg_duble || cv_msg_comma;
                          
          ELSIF (in_param = 3) THEN
              
              -- �e���v���y���ږ��z
              lv_item_info := cv_msg_duble || lv_prf_cd_margin_rate_val || cv_msg_duble || cv_msg_comma;
                          
          ELSIF (in_param = 4) THEN
              
              -- �e���v�z�y���ږ��z
              lv_item_info := cv_msg_duble || lv_prf_cd_margin_val || cv_msg_duble || cv_msg_comma;
                          
          ELSIF (in_param = 5) THEN
              
              -- �\����y���ږ��z
              lv_item_info := cv_msg_duble || lv_prf_cd_make_val || cv_msg_duble || cv_msg_comma;
                                              
                -- �Q2���\����E���_�v�\����
          ELSIF (in_param = 6) THEN
                
                -- �Q2���\����y���ږ��z
                lv_item_info := cv_msg_duble || lv_prf_cd_g2_make_val || cv_msg_duble || cv_msg_comma;
                        
          ELSIF (in_param = 7) THEN
                
                -- ���_�v�\����y���ږ��z
                lv_item_info := cv_msg_duble || lv_prf_cd_kyoten_make_val || cv_msg_duble || cv_msg_comma;
          END IF;    
          
          IF (in_param = 0) THEN
                -- ���s�̏ꍇ�A���i�R�[�h_���i�Q�R�[�h|���i��
                lv_line_info := lv_line_info || lv_line_head || lv_item_info;
          ELSE
                -- ���s�ȊO�̏ꍇ�A��|��|���i��
                lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info;
          END IF;
          
          --=========================================================================   
          --  �O�X�N�x���сy0:����E1:�|���E2:���ʁE3:�e���v���E4:�e���v�z�E5:�\����z
          --=========================================================================
          IF (in_param < 6) THEN
              
              --������
              lv_temp_month := NULL;
              lv_temp_sum   := NULL;
              
              <<zzm_result_loop>>  -- �O�X�N�x���сi���v�j
              FOR rec IN get_month_data_cur(in_param,gv_taisyoYm - 2,in_item_cd,0) LOOP
                  lb_loop_end := TRUE;
                  
                  lv_temp_month := rec.month_data;
                  
              END LOOP zzm_result_loop;

              IF (lb_loop_end) THEN
                 
                 
                 <<zzy_result_loop>>  -- �O�X�N�x����(�N�v)
                  FOR rec IN get_year_data_cur(in_param,gv_taisyoYm - 2,in_item_cd,0) LOOP
                      lb_loop_end := FALSE;
                      
                      lv_temp_sum := rec.year_data;
                  END LOOP zzy_result_loop;                  

                  IF (lb_loop_end) THEN
                      lv_temp_sum := cv_year_zero;
                  END IF;
                  
                  -- 1�s�̃f�[�^�F�i���iCD_���i�QCD�b���i��|���ږ��́j�{ �i�N�x���сj�{�i5��04���j�{�i�N�Ԍv�b�����v�j        
                  lv_line_info := lv_line_info || cv_msg_duble || cv_year_zz_r || cv_msg_duble || cv_msg_comma || lv_temp_month || lv_temp_sum;
                  
              ELSE
                    lv_line_info := lv_line_info ||  cv_all_zero;
              END IF;
          --=========================================================================   
          --  �O�N�x�v��y0:����E1:�|���E2:���ʁE3:�e���v���E4:�e���v�z�E5:�\����z
          --=========================================================================
          
              --������
              lv_temp_month := NULL;
              lv_temp_sum   := NULL;
              lb_loop_end   := FALSE;
              
              -- ���s�ȊO�̏ꍇ�A��|��|���i��
              lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info;
        
              
              <<zm_plan_loop>>  -- �O�N�x�v��(���v)
              FOR rec IN get_month_data_cur(in_param,gv_taisyoYm - 1,in_item_cd,1) LOOP
                  lb_loop_end := TRUE;
                  
                  lv_temp_month := rec.month_data;
                  
              END LOOP zm_plan_loop;

              IF (lb_loop_end) THEN
                 
                 <<zy_plan_loop>>  -- �O�N�x�v��(�N�v)
                  FOR rec IN get_year_data_cur(in_param,gv_taisyoYm - 1,in_item_cd,1) LOOP
                      lb_loop_end := FALSE;
                      
                      lv_temp_sum := rec.year_data;
                  END LOOP zy_plan_loop;

                  IF (lb_loop_end) THEN
                      lv_temp_sum := cv_year_zero;
                  END IF;
                  
                  -- 1�s�̃f�[�^�F�i���iCD_���i�QCD�b���i��|���ږ��́j�{ �i�N�x���сj�{�i5��04���j�{�i�N�Ԍv�b�����v�j        
                  lv_line_info := lv_line_info || cv_msg_duble || cv_year_z_p || cv_msg_duble || cv_msg_comma || lv_temp_month || lv_temp_sum;
                  
              ELSE
                    lv_line_info := lv_line_info ||  cv_all_zero;
              END IF;
          END IF;
          --=========================================================================   
          --  �O�N�x���сy0:����E1:�|���E2:���ʁE3:�e���v���E4:�e���v�z�E5:�\����E6:�Q2���\����E7:���_�v�\����z
          --=========================================================================
          --������
          lv_temp_month := NULL;
          lv_temp_sum   := NULL;
          lb_loop_end   := FALSE;
          
          IF (in_param < 6) THEN
              -- ���s�ȊO�̏ꍇ�A��|��|���i��
              lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info;
          END IF;

          <<zm_result_loop>>  -- �O�N�x����(���v)
          FOR rec IN get_month_data_cur(in_param,gv_taisyoYm - 1,in_item_cd,0) LOOP
              lb_loop_end := TRUE;
              
              lv_temp_month := rec.month_data;
              
          END LOOP zm_result_loop;

          IF (lb_loop_end) THEN
            
             <<zy_result_loop>>  -- �O�N�x����(�N�v)
              FOR rec IN get_year_data_cur(in_param,gv_taisyoYm - 1,in_item_cd,0) LOOP
                  lb_loop_end := FALSE;
                  
                  lv_temp_sum := rec.year_data;
              END LOOP zy_result_loop;                  

              IF (lb_loop_end) THEN
                  lv_temp_sum := cv_year_zero;
              END IF;
              
              -- 1�s�̃f�[�^�F�i���iCD_���i�QCD�b���i��|���ږ��́j�{ �i�N�x���сj�{�i5��04���j�{�i�N�Ԍv�b�����v�j        
              lv_line_info := lv_line_info || cv_msg_duble || cv_year_z_r || cv_msg_duble || cv_msg_comma || lv_temp_month || lv_temp_sum;
              
          ELSE
                lv_line_info := lv_line_info ||  cv_all_zero;
          END IF;
              -- ���̍���
          in_param := in_param + 1;
              
     END LOOP line_loop;
    
    -- �{�f�B���̏o��
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
    lv_data_head                VARCHAR2(4000);
    
    -- ���i�Q4���P�ʏ��
    lv_data_line                VARCHAR2(4000);
        
    -- ���i�R�[�h
    lv_item_cd                  VARCHAR2(10);
                                      
--============================================
--  ���i�R�[�h���o�y�J�[�\���z
--============================================ 
    CURSOR  
            get_item_cd_cur
        IS
--//+UPD START 2011/03/29 Ver1.7
--          SELECT
----//+UPD START 2010/12/13 E_�{�ғ�_05803 Y.Kanami
----                  DISTINCT(item_cd)
--                  DISTINCT group_cd
--                         , item_cd
----//+UPD END 2010/12/13 E_�{�ғ�_05803 Y.Kanami
--          FROM     
--                  xxcsm_tmp_sales_plan_ref         -- ���i�v��Q�l�������[�N�e�[�u��
----//+UPD START 2010/12/13 E_�{�ғ�_05803 Y.Kanami
----          ORDER BY item_cd ASC;
--          ORDER BY group_cd ASC
--                 , item_cd ASC;
----//+UPD END 2010/12/13 E_�{�ғ�_05803 Y.Kanami
      SELECT  DISTINCT
              CASE  WHEN  nic.attribute3 IS NOT NULL  THEN  tspr.group_cd
                    ELSE  cgv4.group4_cd
              END                 group_code
            , tspr.item_cd        item_cd
      FROM    xxcsm_tmp_sales_plan_ref      tspr
            , xxcsm_commodity_group4_v      cgv4
            , ( SELECT  DISTINCT  icv.attribute3
                FROM    xxcsm_item_category_v   icv
                WHERE   icv.attribute3  IS NOT NULL
              )   nic
      WHERE   tspr.item_cd        =   cgv4.item_cd
      AND     tspr.item_cd        =   nic.attribute3(+)
      ORDER BY
              group_code        ASC
            , tspr.item_cd      ASC;
--//+UPD END   2011/03/29 Ver1.7
--

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
                     ,iv_name         => cv_csm1_msg_00107                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- �g�[�N���R�[�h1�i���_�R�[�h�j
                     ,iv_token_value1 => gv_kyotenCD                            -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_kyotennm                        -- �g�[�N���R�[�h2�i���_�R�[�h���́j
                     ,iv_token_value2 => gv_kyotennm                            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_year                            -- �g�[�N���R�[�h3�i�Ώ۔N�x�j
                     ,iv_token_value3 => gv_taisyoYm                            -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_sysdate                         -- �g�[�N���R�[�h4�i�Ɩ����t�j
--//+UPD START 2009/02/18   K.Sai
--                     ,iv_token_value4 => gd_process_date                        -- �g�[�N���l4
                     ,iv_token_value4  => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI')   -- �g�[�N���l4
--//+UPD END 2009/02/18   K.Sai
                     ,iv_token_name5  => cv_tkn_planym                          -- �g�[�N���R�[�h5�i�v��N�x�j
                     ,iv_token_value5 => gv_planYm                              -- �g�[�N���l5
                     ,iv_token_name6  => cv_tkn_kakuteiym                       -- �g�[�N���R�[�h6�i�m��N���j
                     ,iv_token_value6 => gv_kakuteiym                           -- �g�[�N���l6
                     );
     -- �w�b�_���̏o��
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     
                     ,buff   => lv_data_head || CHR(10)
                     );
    -- =========================================================================
    -- �{�f�B���̏o��
    -- =========================================================================
    <<csv_loop>>
    FOR rec IN get_item_cd_cur LOOP
    
        -- ���i�R�[�h
        lv_item_cd := rec.ITEM_CD;
        
        -- �Ώی����y���Z�z
        gn_target_cnt := gn_target_cnt + 1;
        
        lv_data_line := NULL;
        
        -- ���i�R�[�h�P�ʂŃ{�f�B�����o�́iwrite_Line_Info���Ăяo���j        
        write_Line_Info(
                      lv_item_cd
                      ,lv_errbuf
                      ,lv_retcode
                      ,lv_errmsg
                      );
         
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          
          -- ���b�Z�[�W���o��
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
        -- ���팏���y���Z�z  
        ELSIF (lv_retcode = cv_status_normal) THEN
          gn_normal_cnt := gn_normal_cnt + 1 ;            
        END IF;
      
    END LOOP csv_loop;

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
      IF (get_item_cd_cur%ISOPEN) THEN
        CLOSE get_item_cd_cur;
      END IF;
      

    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_item_cd_cur%ISOPEN) THEN
        CLOSE get_item_cd_cur;
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
    IF (lv_retcode <> cv_status_normal) THEN                                      -- �߂�l���ُ�̏ꍇ
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

-- ���уf�[�^�y���o�E�Z�o�E�o�^�z
    deal_result_data(                                                           -- deal_ResultData���R�[��
       lv_errbuf                                                                -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                               -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;

-- �v��f�[�^�y���o�E�Z�o�E�o�^�z
    deal_Plan_Data(                                                             -- deal_PlanData���R�[��
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
    cv_which_log        CONSTANT VARCHAR2(10)    := 'LOG';  -- �o�͐�  
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    retcode := cv_status_normal;
--
--##################  �Œ蕔 END   #####################################

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

-- ���̓p�����[�^
    gv_kyotenCD     := iv_kyoten_cd;                       --���_�R�[�h
    gv_taisyoYm     := TO_NUMBER(iv_taisyo_ym);            --�Ώ۔N�x


-- ��������
    submain(                                      -- submain���R�[��
        lv_errbuf                                 -- �G���[�E���b�Z�[�W
       ,lv_retcode                                -- ���^�[���E�R�[�h
       ,lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
     );

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
                    ,iv_name         => cv_ccp1_msg_90000
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
                    ,iv_name         => cv_ccp1_msg_90001
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
                    ,iv_name         => cv_ccp1_msg_90002
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
                    ,iv_name         => cv_ccp1_msg_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
 
--�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_ccp1_msg_90004;
    ELSE
      lv_message_code := cv_ccp1_msg_90006;
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
END XXCSM002A03C;
/
