CREATE OR REPLACE PACKAGE BODY      XXCSM002A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A12C(body)
 * Description      : ���i�v�惊�X�g(���n��)�o��
 * MD.050           : ���i�v�惊�X�g(���n��)�o�� MD050_CSM_002_A12
 * Version          : 1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                �y���������zA-1
 *  get_all_location    �y�S���_�擾�zA-2
 *  check_location      �y�`�F�b�N�����zA-3,A-4
 *  get_all_location    �y���i�v��f�[�^�擾�zA-5
 *  count_item_kbn      �y���ʏ��i�敪�̏����zA-6,A-7
 *  count_sum_item      �y���ʏ��i���v�̏����zA-8,A-9
 *  count_item_group    �y���ʏ��i�Q�̏����zA-10,A-11
 *  count_discount      �y���ʒl���̏����zA-12,A-13
 *  count_location      �y���ʋ��_�ʂ̏����zA-14,A-15
 *  get_output_data     �y���i�v�惊�X�g�f�[�^�o�́zA-16
 *  submain             �y���������z
 *  main                �y�R���J�����g���s�t�@�C���o�^�v���V�[�W���z
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/14    1.0   M.Ohtsuki        �V�K�쐬
 *  2009/02/09    1.1   M.Ohtsuki       �m��QCT_002�nSQL�����s���̏C��
 *  2009/02/10    1.2   T.Shimoji       �m��QCT_009�n�ގ��@�\���쓝��ɂ��C��
 *  2009/02/13    1.3   S.Son           �m��QCT_016�n�V���i�Ή�
 *  2009/02/17    1.4   M.Ohtsuki       �m��QCT_025�nSQL�����s���̏C��
 *  2009/02/20    1.5   T.Tsukino        [��QCT_052] CSV�o�͂̓��t�t�H�[�}�b�g�s���Ή�
 *  2009/05/07    1.6   M.Ohtsuki        [��QT1_0858] ���ʊ֐��C���ɔ����p�����[�^�̒ǉ�
 *
 *****************************************************************************************/
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
  gn_target_cnt             NUMBER;                                                                 -- �Ώی���
  gn_normal_cnt             NUMBER;                                                                 -- ���팏��
  gn_error_cnt              NUMBER;                                                                 -- �G���[����
  gn_warn_cnt               NUMBER;                                                                 -- �X�L�b�v����
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
  --*** �X�L�b�v��O ***
  global_skip_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--  
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM002A12C';                               -- �p�b�P�[�W��
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                                          -- �J���}
  cv_msg_space              CONSTANT VARCHAR2(4)   := '';                                           -- ��
  cv_msg_duble              CONSTANT VARCHAR2(3)   := '"';                                          -- �_�u���N�H�[�e�[�V����
--
  cv_msg_space4             CONSTANT VARCHAR2(20)  := cv_msg_duble || cv_msg_space ||
                                                      cv_msg_duble || cv_msg_comma ||
                                                      cv_msg_duble || cv_msg_space ||
                                                      cv_msg_duble || cv_msg_comma ||
                                                      cv_msg_duble || cv_msg_space ||
                                                      cv_msg_duble || cv_msg_comma ||
                                                      cv_msg_duble || cv_msg_space ||
                                                      cv_msg_duble;                                 -- "�u�����N"�~4
--
  cv_msg_space16            CONSTANT VARCHAR2(20)  := cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space;                                 -- ��s
--
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                                      -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                                      -- �A�h�I���F���ʁEIF�̈�
  cv_normal                 CONSTANT VARCHAR2(2)   := '10';                                         -- �������(10 = �W������)
--//+DEL START 2009/02/13 CT016 S.Son
--cv_single_item            CONSTANT VARCHAR2(1)   := '1';                                          -- ���i�P�i
--//+DEL END 2009/02/13 CT016 S.Son
--//+ADD START 2009/02/13 CT016 S.Son
  cv_group_kbn              CONSTANT VARCHAR2(1)   := '0';                                          -- ���i�Q
--//+ADD END 2009/02/13 CT016 S.Son
  cn_year_total             CONSTANT NUMBER(10)    := 999999;                                       -- �N�Ԍv
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ� 
  -- ===============================
--
  gd_process_date           DATE;                                                                   -- �Ɩ����t
  gn_index                  NUMBER := 0;                                                            -- �o�^��
  gn_taisyoyear             NUMBER(4,0);                                                            -- �Ώ۔N�x
  gv_kyotencd               VARCHAR2(32);                                                           -- ���_�R�[�h
  gv_genkacd                VARCHAR2(200);                                                          -- �������
  gv_genkanm                VARCHAR2(200);                                                          -- ������ʖ�
  gv_kaisou                 VARCHAR2(2);                                                            -- �K�w
--
  -- ===============================
  -- ���p���b�Z�[�W�ԍ�
  -- ===============================
--
  cv_ccp1_msg_90000         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                           -- �Ώی������b�Z�[�W
  cv_ccp1_msg_90001         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                           -- �����������b�Z�[�W
  cv_ccp1_msg_90002         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                           -- �G���[�������b�Z�[�W
  cv_ccp1_msg_90003         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                           -- �X�L�b�v�������b�Z�[�W
  cv_ccp1_msg_90004         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                           -- ����I�����b�Z�[�W
  cv_ccp1_msg_90006         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                           -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_ccp1_msg_00111         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- �z��O�G���[���b�Z�[�W
--//+ADD START 2009/02/10 CT009 T.Shimoji
  cv_ccp1_msg_90005         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                           -- �x���I�����b�Z�[�W
--//+ADD END 2009/02/10 CT009 T.Shimoji
--  
  -- ===============================  
  -- ���b�Z�[�W�ԍ�
  -- ===============================
--
  cv_csm1_msg_10003         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';                           -- ���̓p�����[�^�擾���b�Z�[�W(�Ώ۔N�x)
  cv_csm1_msg_00048         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';                           -- ���̓p�����[�^�擾���b�Z�[�W(���_�R�[�h)
  cv_csm1_msg_10017         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10017';                           -- ���̓p�����[�^�擾���b�Z�[�W�i������ʖ��j
  cv_csm1_msg_10016         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10004';                           -- ���̓p�����[�^�擾���b�Z�[�W�i�K�w�j
  cv_csm1_msg_00005         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                           -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_csm1_msg_00087         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';                           -- ���i�v�斢�ݒ胁�b�Z�[�W
  cv_csm1_msg_00088         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';                           -- ���i�v��P�i�ʈ��������������b�Z�[�W
  cv_csm1_msg_00090         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00090';                           -- ���i�v�惊�X�g(���n��)�w�b�_�p���b�Z�[�W
  cv_csm1_msg_10001         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';                           -- �Ώۃf�[�^0�����b�Z�[�W
--
  -- ===============================
  -- �g�[�N����`
  -- ===============================
--  
  cv_tkn_year               CONSTANT VARCHAR2(100) := 'YYYY';                                       -- �Ώ۔N�x
  cv_tkn_kyotencd           CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                                  -- ���_�R�[�h
  cv_tkn_genka_nm           CONSTANT VARCHAR2(100) := 'GENKA_NM';                                   -- ������ʖ�
  cv_tkn_genka_cd           CONSTANT VARCHAR2(100) := 'GENKA_CD';                                   -- �������
  cv_tkn_kaisou             CONSTANT VARCHAR2(100) := 'HIERARCHY_LEVEL';                            -- �K�w
  cv_tkn_prof_name          CONSTANT VARCHAR2(100) := 'PROF_NAME';                                  -- �v���t�@�C����
  cv_tkn_count              CONSTANT VARCHAR2(100) := 'COUNT';                                      -- ��������
  cv_tkn_sakusei_date       CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';                            -- �쐬����
  cv_tkn_taisyou_ym         CONSTANT VARCHAR2(100) := 'TAISYOU_YM';                                 -- �Ώ۔N�x
--
  -- ===============================
  -- �v���t�@�C��
  -- ===============================
-- �v���t�@�C���E����
  gv_prf_amount             VARCHAR2(100);                                                          -- XXCSM:����
  gv_prf_sales              VARCHAR2(100);                                                          -- XXCSM:����
  gv_prf_cost_price         VARCHAR2(100);                                                          -- XXCSM:����
  gv_prf_gross_margin       VARCHAR2(100);                                                          -- XXCSM:�e���v�z
  gv_prf_rough_rate         VARCHAR2(100);                                                          -- XXCSM:�e���v��
  gv_prf_rate               VARCHAR2(100);                                                          -- XXCSM:�|��
  gv_prf_item_sum           VARCHAR2(100);                                                          -- XXCSM:���i���v
  gv_prf_item_discount      VARCHAR2(100);                                                          -- XXCSM:����l��
  gv_prf_foothold_sum       VARCHAR2(100);                                                          -- XXCSM:���_�v
--
  gv_kyoten_cd              VARCHAR2(10);                                                           -- ���_�R�[�h
  gv_kyoten_nm              VARCHAR2(200);                                                          -- ���_����
--
    /****************************************************************************
   * Procedure Name   : init
   * Description      : ��������
   ****************************************************************************/
  PROCEDURE init(
              ov_errbuf     OUT NOCOPY VARCHAR2                                                     --���ʁE�G���[�E���b�Z�[�W
             ,ov_retcode    OUT NOCOPY VARCHAR2                                                     --���^�[���E�R�[�h
             ,ov_errmsg     OUT NOCOPY VARCHAR2                                                     --���[�U�[�E�G���[�E���b�Z�[�W
             )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';                                     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf               VARCHAR2(4000);                                                         -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);                                                            -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(4000);                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    --
    cv_kind_of_cost         CONSTANT VARCHAR2(100) := 'XXCSM1_KIND_OF_COST';                        -- �������
    -- �v���t�@�C���E�R�[�h
    cv_prf_amount           CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_1';                     -- XXCSM:����
    cv_prf_sales            CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';                     -- XXCSM:����
    cv_prf_cost_price       CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_8';                     -- XXCSM:����
    cv_prf_gross_margin     CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6';                    -- XXCSM:�e���v�z
    cv_prf_rough_rate       CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_7';                    -- XXCSM:�e���v��
    cv_prf_rate             CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_4';                     -- XXCSM:�|��
    cv_prf_item_sum         CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';                    -- XXCSM:���i���v
    cv_prf_item_discount    CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';                    -- XXCSM:����l��
    cv_prf_foothold_sum     CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_5';                     -- XXCSM:���_�v
    -- �p�����[�^���b�Z�[�W�o�͗p
    lv_pram_op_1            VARCHAR2(100);
    lv_pram_op_2            VARCHAR2(100);
    lv_pram_op_3            VARCHAR2(100);
    lv_pram_op_4            VARCHAR2(100);
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value            VARCHAR2(100);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- =============================================================================================
    -- (A-1,�@) ������ʖ��̎擾
    -- =============================================================================================
   SELECT  ffvv.description           genka_nm                                                      -- ������ʖ�
   INTO    gv_genkanm
   FROM    fnd_flex_value_sets        ffvs                                                          -- �l�Z�b�g�w�b�_
          ,fnd_flex_values            ffv                                                           -- �l�Z�b�g����
          ,fnd_flex_values_vl         ffvv                                                          -- �l�Z�b�g����
   WHERE   ffvs.flex_value_set_id   = ffv.flex_value_set_id                                         -- �o�����[�Z�b�gID
     AND   ffv.flex_value_set_id    = ffvv.flex_value_set_id                                        -- �o�����[�Z�b�gID
     AND   ffv.flex_value_id        = ffvv.flex_value_id                                            -- �o�����[ID
     AND   ffvs.flex_value_set_name = cv_kind_of_cost                                               -- ������ʒl�Z�b�g
     AND   ffv.flex_value           = gv_genkacd;                                                   -- (= IN �������)
    -- =============================================================================================
    -- (A-1,�A) ���̓p�����[�^�̏o��
    -- =============================================================================================
    lv_pram_op_1 := xxccp_common_pkg.get_msg(                                                       -- ���_�R�[�h�̏o��
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_10003                                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_year                                                -- �g�[�N���R�[�h1�i�Ώ۔N�x�j
                     ,iv_token_value1 => gn_taisyoyear                                              -- �g�[�N���l1
                     );
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                                       -- �Ώ۔N�x�̏o��
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_00048                                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kyotencd                                            -- �g�[�N���R�[�h1(���_�R�[�h�j
                     ,iv_token_value1 => gv_kyotencd                                                -- �g�[�N���l1
                     );
    lv_pram_op_3 := xxccp_common_pkg.get_msg(                                                       -- ������ʂ̏o��
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_10017                                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_genka_cd                                            -- �g�[�N���R�[�h1�i������ʁj
                     ,iv_token_value1 => gv_genkacd                                                 -- �g�[�N���l1
                     );
    lv_pram_op_4 := xxccp_common_pkg.get_msg(                                                       -- �K�w�̏o��
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_10016                                          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kaisou                                              -- �g�[�N���R�[�h1�i�K�w�j
                     ,iv_token_value1 => gv_kaisou                                                  -- �g�[�N���l1
                     );
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ���O�ɕ\��
                     ,buff   => lv_pram_op_1  || CHR(10) ||
                                lv_pram_op_2  || CHR(10) ||
                                lv_pram_op_3  || CHR(10) ||
                                lv_pram_op_4  || CHR(10) ||
                                ''            || CHR(10)                                            -- ��s�̑}��
                                );
--
    -- =============================================================================================
    -- (A-1,�B) �Ɩ��������t�̎擾
    -- =============================================================================================
--
    gd_process_date := xxccp_common_pkg2.get_process_date;                                          -- �Ɩ����t��ϐ��Ɋi�[
--
    -- =============================================================================================
    -- (A-1,�C) �v���t�@�C�����̎擾
    -- =============================================================================================
    -- �ϐ����������� 
    lv_tkn_value := NULL;
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    gv_prf_amount        := FND_PROFILE.VALUE(cv_prf_amount);                                       -- XXCSM:����
    gv_prf_sales         := FND_PROFILE.VALUE(cv_prf_sales);                                        -- XXCSM:����
    gv_prf_cost_price    := FND_PROFILE.VALUE(cv_prf_cost_price);                                   -- XXCSM:����
    gv_prf_gross_margin  := FND_PROFILE.VALUE(cv_prf_gross_margin);                                 -- XXCSM:�e���v�z
    gv_prf_rough_rate    := FND_PROFILE.VALUE(cv_prf_rough_rate);                                   -- XXCSM:�e���v��
    gv_prf_rate          := FND_PROFILE.VALUE(cv_prf_rate);                                         -- XXCSM:�|��
    gv_prf_item_sum      := FND_PROFILE.VALUE(cv_prf_item_sum);                                     -- XXCSM:���i���v
    gv_prf_item_discount := FND_PROFILE.VALUE(cv_prf_item_discount);                                -- XXCSM:����l��
    gv_prf_foothold_sum  := FND_PROFILE.VALUE(cv_prf_foothold_sum);                                 -- XXCSM:���_�v
    -- ===================================
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- ===================================
    IF (gv_prf_amount IS NULL) THEN                                                                 -- XXCSM:����
      lv_tkn_value := cv_prf_amount;
    ELSIF (gv_prf_sales IS NULL) THEN                                                               -- XXCSM:����
      lv_tkn_value := cv_prf_sales;
    ELSIF (gv_prf_cost_price IS NULL) THEN                                                          -- XXCSM:����
      lv_tkn_value := cv_prf_cost_price;
    ELSIF (gv_prf_gross_margin IS NULL) THEN                                                        -- XXCSM:�e���v�z
      lv_tkn_value := cv_prf_gross_margin;
    ELSIF (gv_prf_rough_rate IS NULL) THEN                                                          -- XXCSM:�e���v��
      lv_tkn_value := cv_prf_rough_rate;
    ELSIF (gv_prf_rate IS NULL) THEN                                                                -- XXCSM:�|��
      lv_tkn_value := cv_prf_rate;
    ELSIF (gv_prf_item_sum IS NULL) THEN                                                            -- XXCSM:���i���v
      lv_tkn_value := cv_prf_item_sum;
    ELSIF (gv_prf_item_discount IS NULL) THEN                                                       -- XXCSM:����l��
      lv_tkn_value := cv_prf_item_discount;
    ELSIF (gv_prf_foothold_sum IS NULL) THEN                                                        -- XXCSM:���_�v
      lv_tkn_value := cv_prf_foothold_sum;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm1_msg_00005                                           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name                                            -- �g�[�N���R�[�h1�i�v���t�@�C���j
                    ,iv_token_value1 => lv_tkn_value                                                -- �g�[�N���l1
                   );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
   /****************************************************************************
   * Procedure Name   : check_location
   * Description      : �`�F�b�N����
   ****************************************************************************/
  PROCEDURE check_location(
        ov_errbuf           OUT NOCOPY   VARCHAR2                                                   -- ���ʁE�G���[�E���b�Z�[�W
       ,ov_retcode          OUT NOCOPY   VARCHAR2                                                   -- ���^�[���E�R�[�h
       ,ov_errmsg           OUT NOCOPY   VARCHAR2                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
       )
  IS
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf               VARCHAR2(4000);                                                         -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);                                                            -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(4000);                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
-- ===============================
-- �Œ胍�[�J���萔
-- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'check_location';                           -- �v���O������
-- ===============================
-- �Œ胍�[�J���ϐ�
-- ===============================
    -- �f�[�^���݃`�F�b�N�p
    ln_counts               NUMBER;
-- ===============================
-- ���[�J����O
-- ===============================
    location_check_expt     EXCEPTION;
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
  -- ===============================
  -- �ϐ��̏�����
  -- ===============================
    ov_retcode := cv_status_normal;
    ln_counts  := 0;
--
--###########################  �Œ蕔 END   ############################
    -- =============================================================================================
    -- (A-3) �N�ԏ��i�v��f�[�^���݃`�F�b�N
    -- =============================================================================================
    SELECT  COUNT(1)
    INTO    ln_counts
    FROM    xxcsm_item_plan_lines     xipl                                                          -- ���i�v��w�b�_�e�[�u��
           ,xxcsm_item_plan_headers   xiph                                                          -- ���i�v�斾�׃e�[�u��
    WHERE   xipl.item_plan_header_id  = xiph.item_plan_header_id                                    -- ���i�v��w�b�_ID
      AND   xiph.plan_year            = gn_taisyoyear                                               -- �Ώ۔N�x
      AND   xiph.location_cd          = gv_kyoten_cd                                                -- ���_�R�[�h
      AND   ROWNUM                    = 1;                                                          -- 1�s��
    -- ������0�̏ꍇ�A�G���[���b�Z�[�W���o���āA�������X�L�b�v���܂��B
    IF (ln_counts = 0) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm1_msg_00087                                           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_kyotencd                                             -- �g�[�N���R�[�h1�i���_�R�[�h�j
                    ,iv_token_value1 => gv_kyoten_cd                                                -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_taisyou_ym                                           -- �g�[�N���R�[�h2�i�Ώ۔N�x�j
                    ,iv_token_value2 => gn_taisyoyear                                               -- �g�[�N���l2
                    );
      RAISE location_check_expt;
    END IF;
    -- =============================================================================================
    -- (A-4) �������σf�[�^���݃`�F�b�N
    -- =============================================================================================
    ln_counts := 0;                                                                                 -- �ϐ��̏�����
--
    SELECT  COUNT(1)
    INTO    ln_counts
    FROM    xxcsm_item_plan_lines    xipl                                                           -- ���i�v��w�b�_�e�[�u��
           ,xxcsm_item_plan_headers  xiph                                                           -- ���i�v�斾�׃e�[�u��
    WHERE   xipl.item_plan_header_id = xiph.item_plan_header_id                                     -- ���i�v��w�b�_ID
      AND   xiph.plan_year           = gn_taisyoyear                                                -- �Ώ۔N�x
      AND   xiph.location_cd         = gv_kyoten_cd                                                 -- ���_�R�[�h
--//+UPD START 2009/02/13 CT016 S.Son
    --AND   xipl.item_kbn            = cv_single_item                                               -- ���i�敪(1 = ���i�P�i)
      AND   xipl.item_kbn            <> cv_group_kbn                                                -- ���i�敪(1 = ���i�P�i�A2 = �V���i)
--//+UPD END 2009/02/13 CT016 S.Son
      AND   ROWNUM                   = 1;                                                           -- 1�s��
    -- ������0�̏ꍇ�A�G���[���b�Z�[�W���o���āA���������~���܂��B
    IF (ln_counts = 0) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm1_msg_00088                                           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_kyotencd                                             -- �g�[�N���R�[�h1�i���_�R�[�h�j
                    ,iv_token_value1 => gv_kyoten_cd                                                -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_taisyou_ym                                           -- �g�[�N���R�[�h2�i�Ώ۔N�x�j
                    ,iv_token_value2 => gn_taisyoyear                                               -- �g�[�N���l2
                    );
      RAISE location_check_expt;
    END IF;
  EXCEPTION
    WHEN location_check_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������  #############################
--
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
  END check_location;
--
   /****************************************************************************
   * Procedure Name   : count_item_kbn
   * Description      : (A-6),(A-7) ���i�敪�f�[�^����
   ****************************************************************************/
  PROCEDURE count_item_kbn (
         iv_group1_cd       IN  VARCHAR2                                                            -- ���i�Q�R�[�h1
        ,iv_group1_nm       IN  VARCHAR2                                                            -- ���i�Q�R�[�h1����
        ,ov_errbuf          OUT NOCOPY    VARCHAR2                                                  -- ���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode         OUT NOCOPY    VARCHAR2                                                  -- ���^�[���E�R�[�h
        ,ov_errmsg          OUT NOCOPY    VARCHAR2                                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        )
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf               VARCHAR2(4000);                                                         -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);                                                            -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(4000);                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
-- ===============================
-- ���[�J���萔
-- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'count_item_kbn';                             -- �v���O������
    cv_percent              CONSTANT VARCHAR2(10)  := '%';
-- ===============================
-- ���[�J���ϐ�
-- ===============================
--
    ln_m_amount             NUMBER;                                                                 -- ���ʏ��i�敪����
    ln_m_sales              NUMBER;                                                                 -- ���ʏ��i�敪����
    ln_m_cost               NUMBER;                                                                 -- ���ʏ��i�敪����
    ln_m_margin             NUMBER;                                                                 -- ���ʏ��i�敪�e���v�z
    ln_m_margin_rate        NUMBER;                                                                 -- ���ʏ��i�敪�e���v��
    ln_m_rate               NUMBER;                                                                 -- ���ʏ��i�敪�|��
    ln_m_price              NUMBER;                                                                 -- ���ʏ��i�敪�艿
--
    ln_y_amount             NUMBER;                                                                 -- �N�ԏ��i�敪����
    ln_y_sales              NUMBER;                                                                 -- �N�ԏ��i�敪����
    ln_y_cost               NUMBER;                                                                 -- �N�ԏ��i�敪����
    ln_y_margin             NUMBER;                                                                 -- �N�ԏ��i�敪�e���v�z
    ln_y_margin_rate        NUMBER;                                                                 -- �N�ԏ��i�敪�e���v��
    ln_y_rate               NUMBER;                                                                 -- �N�ԏ��i�敪�|��
    ln_y_price              NUMBER;                                                                 -- �N�ԏ��i�敪�艿
--
    lv_group1_cd            VARCHAR2(100);                                                          -- �p�����[�^�i�[�p
-- ============================================
--  ���i�敪���ʏW�v�E�J�[�\��
-- ============================================
    CURSOR count_item_kbn_cur(iv_group_cd  VARCHAR2)
    IS
      SELECT    DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- ���i�敪�ʌ��ʌ���
               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- ���i�敪�ʌ��ʌv�艿
               ,SUM(xipl.sales_budget)                      sales_budget                            -- ���i�敪�ʌ��ʌv������z
               ,SUM(xipl.amount)                            amount                                  -- ���i�敪�ʌ��ʐ���
               ,xipl.year_month                                                                     -- �N��
      FROM      xxcsm_item_plan_lines                       xipl                                    -- ���i�v�斾�׃e�[�u��
               ,xxcsm_item_plan_headers                     xiph                                    -- ���i�v��w�b�_�e�[�u��
               ,xxcsm_commodity_group4_v                    xcg4                                    -- ����Q�S�r���[
      WHERE     xiph.item_plan_header_id  = xipl.item_plan_header_id                                -- �w�b�_ID
        AND     xiph.plan_year            = gn_taisyoyear                                           -- �\�Z�N�x
        AND     xiph.location_cd          = gv_kyoten_cd                                            -- ���_�R�[�h
        AND     xipl.item_group_no        LIKE  iv_group_cd                                         -- ���i�Q�R�[�h
--//+UPD START 2009/02/13 CT016 S.Son
      --AND   xipl.item_kbn            = cv_single_item                                             -- ���i�敪(1 = ���i�P�i)
        AND   xipl.item_kbn            <> cv_group_kbn                                              -- ���i�敪(1 = ���i�P�i�A2 = �V���i)
--//+UPD END 2009/02/13 CT016 S.Son
        AND     xipl.item_no              = xcg4.item_cd                                            -- ���i�R�[�h
      GROUP BY  xipl.year_month                                                                     -- �N��
      ORDER BY  xipl.year_month;                                                                    -- �N��
--
    count_item_kbn_rec    count_item_kbn_cur%ROWTYPE;
--
  BEGIN
--
    lv_group1_cd     := iv_group1_cd || cv_percent;
      -- ===============================
      -- �ϐ��̏�����
      -- ===============================
    ln_y_amount      := 0;
    ln_y_sales       := 0;
    ln_y_cost        := 0;
    ln_y_margin      := 0;
    ln_y_margin_rate := 0;
    ln_y_rate        := 0;
    ln_y_price       := 0;
--
    OPEN count_item_kbn_cur(iv_group_cd => lv_group1_cd);
    <<count_item_kbn_loop>>                                                                         -- ���i�敪���ʃf�[�^�W�v
    LOOP
      FETCH count_item_kbn_cur INTO count_item_kbn_rec;
      EXIT WHEN count_item_kbn_cur%NOTFOUND;                                                        -- �Ώۃf�[�^�����������J��Ԃ�
      -- ===============================
      -- �ϐ��̏�����
      -- ===============================
      ln_m_amount      := 0;
      ln_m_sales       := 0;
      ln_m_cost        := 0;
      ln_m_margin      := 0;
      ln_m_margin_rate := 0;
      ln_m_rate        := 0;
      ln_m_price       := 0;
    -- =============================================================================================
    -- (A-6) ���i�敪�W�v
    -- =============================================================================================
      -- ===============================
      -- ���ʃf�[�^�̎擾
      -- ===============================
      --���ʏ��i�敪����
      ln_m_amount        := count_item_kbn_rec.amount;                                              -- ����
      --���ʏ��i�敪����
      ln_m_sales         := count_item_kbn_rec.sales_budget;                                        -- ������z 
      --���ʏ��i�敪����
      ln_m_cost          := count_item_kbn_rec.cost;                                                -- ����
      --���ʏ��i�敪�e���v�z
      ln_m_margin        := (ln_m_sales - ln_m_cost);                                               -- (������z - ����)
      --���ʏ��i�敪�e���v��
      IF (ln_m_sales = 0) THEN
        ln_m_margin_rate := 0;
      ELSE
        ln_m_margin_rate := ROUND((ln_m_margin / ln_m_sales * 100),2);                              -- (�e���v�z / ������z * 100)
      END IF;
      --���ʏ��i�敪�|������
      ln_m_price         := count_item_kbn_rec.unit_price;                                          -- �艿
      --���ʏ��i�敪�|��
      IF (ln_m_price = 0) THEN
        ln_m_rate        := 0;
      ELSE
        ln_m_rate        := ROUND((ln_m_sales / ln_m_price * 100),2);                               -- (������z / �艿 * 100)
      END IF;
      -- ===============================
      -- �N�ԃf�[�^�̎擾
      -- ===============================
      --�N�ԏ��i�敪����
      ln_y_amount        := (ln_y_amount + ln_m_amount);
      --�N�ԏ��i�敪����
      ln_y_sales         := (ln_y_sales + ln_m_sales);
      --�N�ԏ��i�敪����
      ln_y_cost          := (ln_y_cost + ln_m_cost);
      --�N�ԏ��i�敪�e���v�z
      ln_y_margin        := (ln_y_margin + ln_m_margin);
      --�N�ԏ��i�敪�|������
      ln_y_price         := (ln_y_price + ln_m_price);
    -- =============================================================================================
    -- (A-7) ���i�敪�f�[�^�o�^����(����)
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
          output_order                                                                              -- �o�͏�
         ,location_cd                                                                               -- ���_�R�[�h
         ,location_nm                                                                               -- ���_��
         ,item_cd                                                                                   -- �R�[�h
         ,item_nm                                                                                   -- ����
         ,year_month                                                                                -- �N��
         ,amount                                                                                    -- ����
         ,sales                                                                                     -- ����
         ,cost                                                                                      -- ����
         ,margin                                                                                    -- �e���v�z
         ,margin_rate                                                                               -- �e���v��
         ,rate                                                                                      -- �|��
         ,discount                                                                                  -- �l��
         )
      VALUES(
          gn_index                                                                                  -- �o�͏�
         ,gv_kyoten_cd                                                                              -- ���_�R�[�h
         ,gv_kyoten_nm                                                                              -- ���_��
         ,iv_group1_cd                                                                              -- �R�[�h
         ,iv_group1_nm                                                                              -- ����
         ,count_item_kbn_rec.year_month                                                             -- �N��
         ,ln_m_amount                                                                               -- ����
         ,ROUND((ln_m_sales / 1000),0)                                                              -- ����
         ,ROUND((ln_m_cost / 1000),0)                                                               -- ����
         ,ROUND((ln_m_margin / 1000),0)                                                             -- �e���v�z
         ,ln_m_margin_rate                                                                          -- �e���v��
         ,ln_m_rate                                                                                 -- �|��
         ,NULL                                                                                      -- �l��
         );
--
      gn_index := gn_index + 1;                                                                     -- �o�^�����C���N�������g
--
    END LOOP count_item_kbn_loop;
    CLOSE count_item_kbn_cur;
    --�N�ԏ��i�敪�e���v��
    IF (ln_y_sales = 0) THEN
      ln_y_margin_rate := 0;
    ELSE
      ln_y_margin_rate := ROUND((ln_y_margin / ln_y_sales * 100),2);
    END IF;
    --�N�ԏ��i�敪�|��
    IF (ln_y_price = 0)THEN
      ln_y_rate        := 0;
    ELSE
      ln_y_rate        := ROUND((ln_y_sales / ln_y_price * 100),2);
    END IF;
    -- =============================================================================================
    -- (A-7) ���i�敪�f�[�^�o�^����(�N��)
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
          output_order                                                                              -- �o�͏�
         ,location_cd                                                                               -- ���_�R�[�h
         ,location_nm                                                                               -- ���_��
         ,item_cd                                                                                   -- �R�[�h
         ,item_nm                                                                                   -- ����
         ,year_month                                                                                -- �N��
         ,amount                                                                                    -- ����
         ,sales                                                                                     -- ����
         ,cost                                                                                      -- ����
         ,margin                                                                                    -- �e���v�z
         ,margin_rate                                                                               -- �e���v��
         ,rate                                                                                      -- �|��
         ,discount                                                                                  -- �l��
         )
      VALUES(
          gn_index                                                                                  -- �o�͏�
         ,gv_kyoten_cd                                                                              -- ���_�R�[�h
         ,gv_kyoten_nm                                                                              -- ���_��
         ,iv_group1_cd                                                                              -- �R�[�h
         ,iv_group1_nm                                                                              -- ����
         ,cn_year_total                                                                             -- �N��
         ,ln_y_amount                                                                               -- ����
         ,ROUND((ln_y_sales / 1000),0)                                                              -- ����
         ,ROUND((ln_y_cost / 1000),0)                                                               -- ����
         ,ROUND((ln_y_margin / 1000),0)                                                             -- �e���v�z
         ,ln_y_margin_rate                                                                          -- �e���v��
         ,ln_y_rate                                                                                 -- �|��
         ,NULL                                                                                      -- �l��
         );
--
      gn_index := gn_index + 1;                                                                     -- �o�^�����C���N�������g
--
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
      IF (count_item_kbn_cur%ISOPEN) THEN
        CLOSE count_item_kbn_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (count_item_kbn_cur%ISOPEN) THEN
        CLOSE count_item_kbn_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END count_item_kbn;
--
   /****************************************************************************
   * Procedure Name   : count_sum_item
   * Description      : (A-8),(A-9) ���v���i�f�[�^����
   ****************************************************************************/
  PROCEDURE count_sum_item(
         ov_errbuf          OUT NOCOPY   VARCHAR2                                                   -- ���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode         OUT NOCOPY   VARCHAR2                                                   -- ���^�[���E�R�[�h
        ,ov_errmsg          OUT NOCOPY   VARCHAR2                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
        )
  IS
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf               VARCHAR2(4000);                                                         -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);                                                            -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(4000);                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
-- ===============================
-- ���[�J���萔
-- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'count_sum_item';                             -- �v���O������
    cv_not_d                CONSTANT VARCHAR2(10)  := 'D%';                                         -- (D = ���̑�)
-- ===============================
-- ���[�J���ϐ�
-- ===============================
--
    ln_m_amount             NUMBER;                                                                 -- ���ʍ��v���i����
    ln_m_sales              NUMBER;                                                                 -- ���ʍ��v���i����
    ln_m_cost               NUMBER;                                                                 -- ���ʍ��v���i����
    ln_m_margin             NUMBER;                                                                 -- ���ʍ��v���i�e���v�z
    ln_m_margin_rate        NUMBER;                                                                 -- ���ʍ��v���i�e���v��
    ln_m_rate               NUMBER;                                                                 -- ���ʍ��v���i�|��
    ln_m_price              NUMBER;                                                                 -- ���ʍ��v���i�艿
--
    ln_y_amount             NUMBER;                                                                 -- �N�ԍ��v���i����
    ln_y_sales              NUMBER;                                                                 -- �N�ԍ��v���i����
    ln_y_cost               NUMBER;                                                                 -- �N�ԍ��v���i����
    ln_y_margin             NUMBER;                                                                 -- �N�ԍ��v���i�e���v�z
    ln_y_margin_rate        NUMBER;                                                                 -- �N�ԍ��v���i�e���v��
    ln_y_rate               NUMBER;                                                                 -- �N�ԍ��v���i�|��
    ln_y_price              NUMBER;                                                                 -- �N�ԍ��v���i�艿
--
-- ============================================
--  ���ʏ��i���v�̎擾�E�J�[�\��
-- ============================================
    CURSOR count_sum_item_cur
    IS
      SELECT    DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- ���v���i���ʌ���
               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- ���v���i���ʌv�艿
               ,SUM(xipl.sales_budget)                      sales_budget                            -- ���v���i���ʌv������z
               ,SUM(xipl.amount)                            amount                                  -- ���v���i���ʐ���
               ,xipl.year_month                                                                     -- �N��
      FROM      xxcsm_item_plan_lines                       xipl                                    -- ���i�v�斾�׃e�[�u��
               ,xxcsm_item_plan_headers                     xiph                                    -- ���i�v��w�b�_�e�[�u��
               ,xxcsm_commodity_group4_v                    xcg4                                    -- ����Q�S�r���[
      WHERE     xiph.item_plan_header_id  = xipl.item_plan_header_id                                -- �w�b�_ID
        AND     xiph.plan_year            = gn_taisyoyear                                           -- �\�Z�N�x
        AND     xiph.location_cd          = gv_kyoten_cd                                            -- ���_�R�[�h
        AND     xipl.item_group_no        NOT LIKE  cv_not_d                                        -- ���i�Q�R�[�h
--//+UPD START 2009/02/13 CT016 S.Son
      --AND   xipl.item_kbn            = cv_single_item                                             -- ���i�敪(1 = ���i�P�i)
        AND   xipl.item_kbn            <> cv_group_kbn                                              -- ���i�敪(1 = ���i�P�i�A2 = �V���i)
--//+UPD END 2009/02/13 CT016 S.Son
        AND     xipl.item_no              = xcg4.item_cd                                            -- ���i�R�[�h
      GROUP BY  xipl.year_month                                                                     -- �N��
      ORDER BY  xipl.year_month;                                                                    -- �N��
--
    count_sum_item_rec   count_sum_item_cur%ROWTYPE;
--
  BEGIN
      -- ===============================
      -- �ϐ��̏�����
      -- ===============================
    ln_y_amount      := 0;
    ln_y_sales       := 0;
    ln_y_cost        := 0;
    ln_y_margin      := 0;
    ln_y_margin_rate := 0;
    ln_y_rate        := 0;
    ln_y_price       := 0;
--
    OPEN count_sum_item_cur;
    <<count_sum_item_loop>>                                                                         -- ���v���i���ʃf�[�^�W�v
    LOOP
      FETCH count_sum_item_cur INTO count_sum_item_rec;
      EXIT WHEN count_sum_item_cur%NOTFOUND;                                                        -- �Ώۃf�[�^�����������J��Ԃ�
      -- ===============================
      -- �ϐ��̏�����
      -- ===============================
      ln_m_amount      := 0;
      ln_m_sales       := 0;
      ln_m_cost        := 0;
      ln_m_margin      := 0;
      ln_m_margin_rate := 0;
      ln_m_rate        := 0;
      ln_m_price       := 0;
    -- =============================================================================================
    -- (A-8) ���i���v�W�v
    -- =============================================================================================
      -- ===============================
      -- ���ʃf�[�^�̎擾
      -- ===============================
      --���ʏ��i�敪����
      ln_m_amount        := count_sum_item_rec.amount;                                              -- ����
      --���ʏ��i�敪����
      ln_m_sales         := count_sum_item_rec.sales_budget;                                        -- ������z 
      --���ʏ��i�敪����
      ln_m_cost          := count_sum_item_rec.cost;                                                -- ����
      --���ʏ��i�敪�e���v�z
      ln_m_margin        := (ln_m_sales - ln_m_cost);                                               -- (������z - ����)
      --���ʏ��i�敪�e���v��
      IF (ln_m_sales = 0) THEN
        ln_m_margin_rate := 0;
      ELSE
        ln_m_margin_rate := ROUND((ln_m_margin / ln_m_sales * 100),2);                              -- (�e���v�z / ������z * 100)
      END IF;
      --���ʏ��i�敪�|������
      ln_m_price         := count_sum_item_rec.unit_price;                                          -- �艿
      --���ʏ��i�敪�|��
      IF (ln_m_price = 0) THEN
        ln_m_rate        := 0;
      ELSE
        ln_m_rate        := ROUND((ln_m_sales / ln_m_price * 100),2);                               -- (������z / �艿 * 100)
      END IF;
      -- ===============================
      -- �N�ԃf�[�^�̎擾
      -- ===============================
      --�N�ԏ��i�敪����
      ln_y_amount        := (ln_y_amount + ln_m_amount);
      --�N�ԏ��i�敪����
      ln_y_sales         := (ln_y_sales + ln_m_sales);
      --�N�ԏ��i�敪����
      ln_y_cost          := (ln_y_cost + ln_m_cost);
      --�N�ԏ��i�敪�e���v�z
      ln_y_margin        := (ln_y_margin + ln_m_margin);
      --�N�ԏ��i�敪�|������
      ln_y_price         := (ln_y_price + ln_m_price);
    -- =============================================================================================
    -- (A-9) ���i���v�f�[�^�o�^����
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
          output_order                                                                              -- �o�͏�
         ,location_cd                                                                               -- ���_�R�[�h
         ,location_nm                                                                               -- ���_��
         ,item_cd                                                                                   -- �R�[�h
         ,item_nm                                                                                   -- ����
         ,year_month                                                                                -- �N��
         ,amount                                                                                    -- ����
         ,sales                                                                                     -- ����
         ,cost                                                                                      -- ����
         ,margin                                                                                    -- �e���v�z
         ,margin_rate                                                                               -- �e���v��
         ,rate                                                                                      -- �|��
         ,discount                                                                                  -- �l��
         )
      VALUES(
          gn_index                                                                                  -- �o�͏�
         ,gv_kyoten_cd                                                                              -- ���_�R�[�h
         ,gv_kyoten_nm                                                                              -- ���_��
         ,NULL                                                                                      -- �R�[�h
         ,gv_prf_item_sum                                                                           -- ����
         ,count_sum_item_rec.year_month                                                             -- �N��
         ,ln_m_amount                                                                               -- ����
         ,ROUND((ln_m_sales / 1000),0)                                                              -- ����
         ,ROUND((ln_m_cost / 1000),0)                                                               -- ����
         ,ROUND((ln_m_margin / 1000),0)                                                             -- �e���v�z
         ,ln_m_margin_rate                                                                          -- �e���v��
         ,ln_m_rate                                                                                 -- �|��
         ,NULL                                                                                      -- �l��
         );
--
      gn_index := gn_index + 1;                                                                     -- �o�^�����C���N�������g
--
    END LOOP count_sum_item_loop;
    CLOSE count_sum_item_cur;
    --�N�ԏ��i�敪�e���v��
    IF (ln_y_sales = 0) THEN
      ln_y_margin_rate := 0;
    ELSE
      ln_y_margin_rate := ROUND((ln_y_margin / ln_y_sales * 100),2);
    END IF;
    --�N�ԏ��i�敪�|��
    IF (ln_y_price = 0) THEN
      ln_y_rate        := 0;
    ELSE
      ln_y_rate        := ROUND((ln_y_sales / ln_y_price * 100),2);
    END IF;
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
          output_order                                                                              -- �o�͏�
         ,location_cd                                                                               -- ���_�R�[�h
         ,location_nm                                                                               -- ���_��
         ,item_cd                                                                                   -- �R�[�h
         ,item_nm                                                                                   -- ����
         ,year_month                                                                                -- �N��
         ,amount                                                                                    -- ����
         ,sales                                                                                     -- ����
         ,cost                                                                                      -- ����
         ,margin                                                                                    -- �e���v�z
         ,margin_rate                                                                               -- �e���v��
         ,rate                                                                                      -- �|��
         ,discount                                                                                  -- �l��
         )
      VALUES(
          gn_index                                                                                  -- �o�͏�
         ,gv_kyoten_cd                                                                              -- ���_�R�[�h
         ,gv_kyoten_nm                                                                              -- ���_��
         ,NULL                                                                                      -- �R�[�h
         ,gv_prf_item_sum                                                                           -- ����
         ,cn_year_total                                                                             -- �N��
         ,ln_y_amount                                                                               -- ����
         ,ROUND((ln_y_sales / 1000),0)                                                              -- ����
         ,ROUND((ln_y_cost / 1000),0)                                                               -- ����
         ,ROUND((ln_y_margin / 1000),0)                                                             -- �e���v�z
         ,ln_y_margin_rate                                                                          -- �e���v��
         ,ln_y_rate                                                                                 -- �|��
         ,NULL                                                                                      -- �l��
         );
--
      gn_index := gn_index + 1;                                                                     -- �o�^�����C���N�������g
--
  EXCEPTION
--#################################  �Œ��O������  #############################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (count_sum_item_cur%ISOPEN) THEN
        CLOSE count_sum_item_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (count_sum_item_cur%ISOPEN) THEN
        CLOSE count_sum_item_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END count_sum_item;
--
   /****************************************************************************
   * Procedure Name   : count_item_group
   * Description      : (A-10),(A-11) ���i�Q�f�[�^����
   ****************************************************************************/
  PROCEDURE count_item_group(
                     iv_item_cd        IN  VARCHAR2                                                 -- ���i�Q�R�[�h
                    ,iv_item_nm        IN  VARCHAR2                                                 -- ���i�Q��
                    ,in_cost           IN  NUMBER                                                   -- ���i�Q�ʔN�Ԍv����
                    ,in_unit_price     IN  NUMBER                                                   -- ���i�Q�ʔN�Ԍv�艿
                    ,in_sales_budget   IN  NUMBER                                                   -- ���i�Q�ʔN�Ԍv������z
                    ,in_amount         IN  NUMBER                                                   -- ���i�Q�ʔN�Ԍv����
                    ,ov_retcode        OUT NOCOPY VARCHAR2                                          -- �G���[�E���b�Z�[�W
                    ,ov_errbuf         OUT NOCOPY VARCHAR2                                          -- ���^�[���E�R�[�h
                    ,ov_errmsg         OUT NOCOPY VARCHAR2                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
                    )
  IS
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                                                         -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
-- ===============================
-- �Œ胍�[�J���萔
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'count_item_group';                             -- �v���O������
-- ===============================
-- �Œ胍�[�J���ϐ�
-- ===============================
--
    ln_m_amount             NUMBER;                                                                 -- ���ʏ��i�Q�ʐ���
    ln_m_sales              NUMBER;                                                                 -- ���ʏ��i�Q�ʔ���
    ln_m_cost               NUMBER;                                                                 -- ���ʏ��i�Q�ʌ���
    ln_m_margin             NUMBER;                                                                 -- ���ʏ��i�Q�ʑe���v�z
    ln_m_margin_rate        NUMBER;                                                                 -- ���ʏ��i�Q�ʑe���v��
    ln_m_rate               NUMBER;                                                                 -- ���ʏ��i�Q�ʊ|��
    ln_m_price              NUMBER;                                                                 -- ���ʏ��i�Q�ʒ艿
--
    ln_y_amount             NUMBER;                                                                 -- �N�ԏ��i�Q�ʐ���
    ln_y_sales              NUMBER;                                                                 -- �N�ԏ��i�Q�ʔ���
    ln_y_cost               NUMBER;                                                                 -- �N�ԏ��i�Q�ʌ���
    ln_y_margin             NUMBER;                                                                 -- �N�ԏ��i�Q�ʑe���v�z
    ln_y_margin_rate        NUMBER;                                                                 -- �N�ԏ��i�Q�ʑe���v��
    ln_y_rate               NUMBER;                                                                 -- �N�ԏ��i�Q�ʊ|��
    ln_y_price              NUMBER;                                                                 -- �N�ԏ��i�Q�ʒ艿
--
-- ============================================
--  ���i�Q���ʏW�v�E�J�[�\��
-- ============================================
    CURSOR count_item_group_cur
    IS
      SELECT    DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- ���i�Q�ʌ��ʌ���
               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- ���i�Q�ʌ��ʌv�艿
               ,SUM(xipl.sales_budget)                      sales_budget                            -- ���i�Q�ʌ��ʌv������z
               ,SUM(xipl.amount)                            amount                                  -- ���i�Q�ʌ��ʐ���
               ,xipl.year_month                                                                     -- �N��
      FROM      xxcsm_item_plan_lines                       xipl                                    -- ���i�v�斾�׃e�[�u��
               ,xxcsm_item_plan_headers                     xiph                                    -- ���i�v��w�b�_�e�[�u��
               ,xxcsm_commodity_group4_v                    xcg4                                    -- ����Q�S�r���[
      WHERE     xiph.item_plan_header_id  = xipl.item_plan_header_id                                -- �w�b�_ID
        AND     xiph.plan_year            = gn_taisyoyear                                           -- �\�Z�N�x
        AND     xiph.location_cd          = gv_kyoten_cd                                            -- ���_�R�[�h
        AND     xcg4.group4_cd            = iv_item_cd                                              -- ���i�Q�R�[�h
--//+UPD START 2009/02/13 CT016 S.Son
      --AND   xipl.item_kbn            = cv_single_item                                             -- ���i�敪(1 = ���i�P�i)
        AND   xipl.item_kbn            <> cv_group_kbn                                              -- ���i�敪(1 = ���i�P�i�A2 = �V���i)
--//+UPD END 2009/02/13 CT016 S.Son
        AND     xipl.item_no              = xcg4.item_cd                                            -- ���i�R�[�h
      GROUP BY  xipl.year_month                                                                     -- �N��
      ORDER BY  xipl.year_month;                                                                    -- �N��
--
    count_item_group_rec   count_item_group_cur%ROWTYPE;
--
  BEGIN
    -- ===============================
    -- �ϐ��̏�����
    -- ===============================
    ln_y_amount      := 0;
    ln_y_sales       := 0;
    ln_y_cost        := 0;
    ln_y_margin      := 0;
    ln_y_margin_rate := 0;
    ln_y_rate        := 0;
    ln_y_price       := 0;
--
    OPEN count_item_group_cur;
    <<count_item_group_loop>>                                                                       -- ���i�Q���ʃf�[�^�W�v
    LOOP
      FETCH count_item_group_cur INTO count_item_group_rec;
      EXIT WHEN count_item_group_cur%NOTFOUND;                                                      -- �Ώۃf�[�^�����������J��Ԃ�
    -- =============================================================================================
    -- (A-10) ���i�Q�W�v
    -- =============================================================================================
      -- ===============================
      -- �ϐ��̏�����
      -- ===============================
      ln_m_amount      := 0;
      ln_m_sales       := 0;
      ln_m_cost        := 0;
      ln_m_margin      := 0;
      ln_m_margin_rate := 0;
      ln_m_rate        := 0;
      ln_m_price       := 0;
      -- ===============================
      -- ���ʃf�[�^�̎擾
      -- ===============================
      --���ʏ��i�Q�ʐ���
      ln_m_amount        := count_item_group_rec.amount;                                            -- ����
      --���ʏ��i�Q�ʔ���
      ln_m_sales         := count_item_group_rec.sales_budget;                                      -- ������z 
      --���ʏ��i�Q�ʌ���
      ln_m_cost          := count_item_group_rec.cost;                                              -- ����
      --���ʏ��i�Q�ʑe���v�z
      ln_m_margin        := (ln_m_sales - ln_m_cost );                                              -- (������z - ����)
      --���ʏ��i�Q�ʑe���v��
      IF (ln_m_sales = 0) THEN
        ln_m_margin_rate := 0;
      ELSE
        ln_m_margin_rate := ROUND((ln_m_margin / ln_m_sales * 100),2);                              -- (�e���v�z / ������z * 100)
      END IF;
      --���ʏ��i�Q�ʊ|������
      ln_m_price         := count_item_group_rec.unit_price;                                        -- �艿
      --���ʏ��i�Q�ʊ|��
      IF (ln_m_price = 0) THEN
        ln_m_rate        := 0;
      ELSE
        ln_m_rate        := ROUND((ln_m_sales / ln_m_price * 100),2);                               -- (������z / �艿 * 100)
      END IF;
    -- =============================================================================================
    -- (A-11) ���i�Q�f�[�^�o�^����(����) 
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
          output_order                                                                              -- �o�͏�
         ,location_cd                                                                               -- ���_�R�[�h
         ,location_nm                                                                               -- ���_��
         ,item_cd                                                                                   -- �R�[�h
         ,item_nm                                                                                   -- ����
         ,year_month                                                                                -- �N��
         ,amount                                                                                    -- ����
         ,sales                                                                                     -- ����
         ,cost                                                                                      -- ����
         ,margin                                                                                    -- �e���v�z
         ,margin_rate                                                                               -- �e���v��
         ,rate                                                                                      -- �|��
         ,discount                                                                                  -- �l��
         )
      VALUES(
          gn_index                                                                                  -- �o�͏�
         ,gv_kyoten_cd                                                                              -- ���_�R�[�h
         ,gv_kyoten_nm                                                                              -- ���_��
         ,iv_item_cd                                                                                -- �R�[�h
         ,iv_item_nm                                                                                -- ����
         ,count_item_group_rec.year_month                                                           -- �N��
         ,ln_m_amount                                                                               -- ����
         ,ROUND((ln_m_sales / 1000),0)                                                              -- ����
         ,ROUND((ln_m_cost / 1000),0)                                                               -- ����
         ,ROUND((ln_m_margin / 1000),0)                                                             -- �e���v�z
         ,ln_m_margin_rate                                                                          -- �e���v��
         ,ln_m_rate                                                                                 -- �|��
         ,NULL                                                                                      -- �l��
         );
--
      gn_index := gn_index + 1;                                                                     -- �o�^�����C���N�������g
--
    END LOOP count_item_group_loop;
    CLOSE count_item_group_cur;
      -- ===============================
      -- �N�ԃf�[�^�̎擾
      -- ===============================
      --�N�ԏ��i�Q�ʐ���
    ln_y_amount        := in_amount;                                                                -- ����
    --�N�ԏ��i�Q�ʔ���
    ln_y_sales         := in_sales_budget;                                                          -- ������z 
    --�N�ԏ��i�Q�ʌ���
    ln_y_cost          := in_cost;                                                                  -- ����
    --�N�ԏ��i�Q�ʑe���v�z
    ln_y_margin        := (ln_y_sales - ln_y_cost );                                                -- (������z - ����)
    --�N�ԏ��i�Q�ʑe���v��
    IF (ln_y_sales = 0) THEN
      ln_y_margin_rate := 0;
    ELSE
      ln_y_margin_rate := ROUND((ln_y_margin / ln_y_sales * 100),2);                                -- (�e���v�z / ������z * 100)
    END IF;
    --�N�ԏ��i�Q�ʊ|��
    IF (in_unit_price = 0) THEN
      ln_y_rate        := 0;
    ELSE
      ln_y_rate        := ROUND((ln_y_sales / in_unit_price * 100),2);                              -- (������z / �艿 * 100)
    END IF;
    -- =============================================================================================
    -- (A-11) ���i�Q�f�[�^�o�^����(�N�Ԍv)
    -- =============================================================================================
    INSERT INTO
      xxcsm_tmp_sales_plan_time(                                                                    -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
        output_order                                                                                -- �o�͏�
       ,location_cd                                                                                 -- ���_�R�[�h
       ,location_nm                                                                                 -- ���_��
       ,item_cd                                                                                     -- �R�[�h
       ,item_nm                                                                                     -- ����
       ,year_month                                                                                  -- �N��
       ,amount                                                                                      -- ����
       ,sales                                                                                       -- ����
       ,cost                                                                                        -- ����
       ,margin                                                                                      -- �e���v�z
       ,margin_rate                                                                                 -- �e���v��
       ,rate                                                                                        -- �|��
       ,discount                                                                                    -- �l��
       )
    VALUES(
        gn_index                                                                                    -- �o�͏�
       ,gv_kyoten_cd                                                                                -- ���_�R�[�h
       ,gv_kyoten_nm                                                                                -- ���_��
       ,iv_item_cd                                                                                  -- �R�[�h
       ,iv_item_nm                                                                                  -- ����
       ,cn_year_total                                                                               -- �N��
       ,ln_y_amount                                                                                 -- ����
       ,ROUND((ln_y_sales / 1000),0)                                                                -- ����
       ,ROUND((ln_y_cost / 1000),0)                                                                 -- ����
       ,ROUND((ln_y_margin / 1000),0)                                                               -- �e���v�z
       ,ln_y_margin_rate                                                                            -- �e���v��
       ,ln_y_rate                                                                                   -- �|��
       ,NULL                                                                                        -- �l��
       );
--
      gn_index := gn_index + 1;                                                                     -- �o�^�����C���N�������g
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
      IF (count_item_group_cur%ISOPEN) THEN
        CLOSE count_item_group_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (count_item_group_cur%ISOPEN) THEN
        CLOSE count_item_group_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END count_item_group;
--
   /****************************************************************************
   * Procedure Name   : count_discount
   * Description      : (A-12),(A-13) �l���f�[�^����
   ****************************************************************************/
  PROCEDURE count_discount(
         ov_errbuf     OUT NOCOPY VARCHAR2                                                          -- ���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2                                                          -- ���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                                                         -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
-- ===============================
-- �Œ胍�[�J���萔
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'count_discount_cur';                           -- �v���O������
-- ===============================
-- �Œ胍�[�J���ϐ�
-- ===============================
    -- �f�[�^���݃`�F�b�N�p
    ln_discount_total         NUMBER;                                                               -- �N�Ԓl���z�擾�p
    ln_cnt                    NUMBER;
    ln_discount_cnt           NUMBER;
-- ============================================
--  �l�����ʃf�[�^�̎擾�E�J�[�\��
-- ============================================
    CURSOR count_discount_cur
    IS
      SELECT    xipb.sales_discount                sales_discount                                   -- ����l��
               ,xipb.year_month                    year_month                                       -- �N��
      FROM      xxcsm_item_plan_headers            xiph                                             -- ���i�v��w�b�_�e�[�u��
               ,xxcsm_item_plan_loc_bdgt           xipb                                             -- ���i�v�拒�_�ʗ\�Z�e�[�u��
      WHERE     xiph.item_plan_header_id  = xipb.item_plan_header_id                                -- �w�b�_ID
        AND     xiph.plan_year            = gn_taisyoyear                                           -- �\�Z�N�x
        AND     xiph.location_cd          = gv_kyoten_cd                                            -- ���_�R�[�h
      ORDER BY  xipb.year_month;                                                                     -- �N��
--
    count_discount_rec   count_discount_cur%ROWTYPE;
--
  BEGIN
  -- ===============================
  -- �ϐ��̏�����
  -- ===============================
    ln_discount_total := 0;
--
    SELECT    COUNT(1)
    INTO      ln_discount_cnt
    FROM      xxcsm_item_plan_headers            xiph                                               -- ���i�v��w�b�_�e�[�u��
             ,xxcsm_item_plan_loc_bdgt           xipb                                               -- ���i�v�拒�_�ʗ\�Z�e�[�u��
    WHERE     xiph.item_plan_header_id  = xipb.item_plan_header_id                                  -- �w�b�_ID
      AND     xiph.plan_year            = gn_taisyoyear                                             -- �\�Z�N�x
      AND     xiph.location_cd          = gv_kyoten_cd;                                             -- ���_�R�[�h
--
    IF (ln_discount_cnt = 12) THEN                                                                  -- �f�[�^����������̏ꍇ
      OPEN count_discount_cur;
      <<count_discount_loop>>                                                                       -- �l�����ʃf�[�^�W�v
      LOOP
        FETCH count_discount_cur INTO count_discount_rec;
        EXIT WHEN count_discount_cur%NOTFOUND;                                                      -- �Ώۃf�[�^�����������J��Ԃ�
    -- =============================================================================================
    -- (A-12) �l���W�v
    -- =============================================================================================
        ln_discount_total := (ln_discount_total + count_discount_rec.sales_discount);               -- �l���z�����Z
    -- =============================================================================================
    -- (A-13) �l���f�[�^�o�^
    -- =============================================================================================
        INSERT INTO
          xxcsm_tmp_sales_plan_time(                                                                -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
            output_order                                                                            -- �o�͏�
           ,location_cd                                                                             -- ���_�R�[�h
           ,location_nm                                                                             -- ���_��
           ,item_cd                                                                                 -- �R�[�h
           ,item_nm                                                                                 -- ����
           ,year_month                                                                              -- �N��
           ,amount                                                                                  -- ����
           ,sales                                                                                   -- ����
           ,cost                                                                                    -- ����
           ,margin                                                                                  -- �e���v�z
           ,margin_rate                                                                             -- �e���v��
           ,rate                                                                                    -- �|��
           ,discount                                                                                -- �l��
           )
        VALUES(
            gn_index                                                                                -- �o�͏�
           ,gv_kyoten_cd                                                                            -- ���_�R�[�h
           ,gv_kyoten_nm                                                                            -- ���_��
           ,NULL                                                                                    -- �R�[�h
           ,gv_prf_item_discount                                                                    -- ����
           ,count_discount_rec.year_month                                                           -- �N��
           ,NULL                                                                                    -- ����
           ,NULL                                                                                    -- ����
           ,NULL                                                                                    -- ����
           ,NULL                                                                                    -- �e���v�z
           ,NULL                                                                                    -- �e���v��
           ,NULL                                                                                    -- �|��
           ,ROUND((count_discount_rec.sales_discount / 1000),0)                                     -- �l��
           );
--
        gn_index := gn_index + 1;                                                                   -- �o�^�����C���N�������g
--
      END LOOP count_discount_loop;
--
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
          output_order                                                                              -- �o�͏�
         ,location_cd                                                                               -- ���_�R�[�h
         ,location_nm                                                                               -- ���_��
         ,item_cd                                                                                   -- �R�[�h
         ,item_nm                                                                                   -- ����
         ,year_month                                                                                -- �N��
         ,amount                                                                                    -- ����
         ,sales                                                                                     -- ����
         ,cost                                                                                      -- ����
         ,margin                                                                                    -- �e���v�z
         ,margin_rate                                                                               -- �e���v��
         ,rate                                                                                      -- �|��
         ,discount                                                                                  -- �l��
         )
      VALUES(
          gn_index                                                                                  -- �o�͏�
         ,gv_kyoten_cd                                                                              -- ���_�R�[�h
         ,gv_kyoten_nm                                                                              -- ���_��
         ,NULL                                                                                      -- �R�[�h
         ,gv_prf_item_discount                                                                      -- ����
         ,cn_year_total                                                                             -- �N��
         ,NULL                                                                                      -- ����
         ,NULL                                                                                      -- ����
         ,NULL                                                                                      -- ����
         ,NULL                                                                                      -- �e���v�z
         ,NULL                                                                                      -- �e���v��
         ,NULL                                                                                      -- �|��
         ,ROUND((ln_discount_total / 1000),0)                                                       -- �l��
         );
--
        gn_index := gn_index + 1;                                                                   -- �o�^�����C���N�������g
--
   ELSE                                                                                             -- �f�[�^�������s���ȏꍇ
     ln_cnt := 1;
     <<no_data_loop>>                                                                               -- (�l�� = 0)�̃f�[�^��o�^
     LOOP
     EXIT WHEN ln_cnt > 13;
       INSERT INTO
         xxcsm_tmp_sales_plan_time(                                                                 -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
         output_order                                                                               -- �o�͏�
        ,location_cd                                                                                -- ���_�R�[�h
        ,location_nm                                                                                -- ���_��
        ,item_cd                                                                                    -- �R�[�h
        ,item_nm                                                                                    -- ����
        ,year_month                                                                                 -- �N��
        ,amount                                                                                     -- ����
        ,sales                                                                                      -- ����
        ,cost                                                                                       -- ����
        ,margin                                                                                     -- �e���v�z
        ,margin_rate                                                                                -- �e���v��
        ,rate                                                                                       -- �|��
        ,discount                                                                                   -- �l��
        )
       VALUES(
         gn_index                                                                                   -- �o�͏�
        ,gv_kyoten_cd                                                                               -- ���_�R�[�h
        ,gv_kyoten_nm                                                                               -- ���_��
        ,NULL                                                                                       -- �R�[�h
        ,gv_prf_item_discount                                                                       -- ����
        ,gn_index                                                                                   -- �N��
        ,NULL                                                                                       -- ����
        ,NULL                                                                                       -- ����
        ,NULL                                                                                       -- ����
        ,NULL                                                                                       -- �e���v�z
        ,NULL                                                                                       -- �e���v��
        ,NULL                                                                                       -- �|��
        ,0                                                                                          -- �l��
        );
--
       gn_index := gn_index + 1;                                                                    -- �o�^�����C���N�������g
       ln_cnt   := ln_cnt   + 1;
      END LOOP no_data_loop;
    END IF;
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
      IF (count_discount_cur%ISOPEN) THEN
        CLOSE count_discount_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (count_discount_cur%ISOPEN) THEN
        CLOSE count_discount_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END count_discount;
--
   /****************************************************************************
   * Procedure Name   : count_location
   * Description      : (A-14),(A-15) ���_�ʃf�[�^����
   ****************************************************************************/
  PROCEDURE count_location(
         ov_errbuf     OUT NOCOPY VARCHAR2                                                          -- ���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode    OUT NOCOPY VARCHAR2                                                          -- ���^�[���E�R�[�h
        ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                                                         -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
-- ===============================
-- �Œ胍�[�J���萔
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'count_location';                               -- �v���O������
-- ===============================
-- �Œ胍�[�J���ϐ�
-- ===============================
    ln_m_amount               NUMBER;                                                               -- ���ʋ��_�ʐ���
    ln_m_sales                NUMBER;                                                               -- ���ʋ��_�ʔ���
    ln_m_cost                 NUMBER;                                                               -- ���ʋ��_�ʌ���
    ln_m_margin               NUMBER;                                                               -- ���ʋ��_�ʑe���v�z
    ln_m_margin_rate          NUMBER;                                                               -- ���ʋ��_�ʑe���v��
    ln_m_rate                 NUMBER;                                                               -- ���ʋ��_�ʊ|��
    ln_m_price                NUMBER;                                                               -- ���ʋ��_�ʒ艿
--
    ln_y_amount               NUMBER;                                                               -- �N�ԋ��_�ʐ���
    ln_y_sales                NUMBER;                                                               -- �N�ԋ��_�ʔ���
    ln_y_cost                 NUMBER;                                                               -- �N�ԋ��_�ʌ���
    ln_y_margin               NUMBER;                                                               -- �N�ԋ��_�ʑe���v�z
    ln_y_margin_rate          NUMBER;                                                               -- �N�ԋ��_�ʑe���v��
    ln_y_rate                 NUMBER;                                                               -- �N�ԋ��_�ʊ|��
    ln_y_price                NUMBER;                                                               -- �N�ԋ��_�ʒ艿
-- ============================================
--  ���_�ʌ��ʃf�[�^�̎擾�E�J�[�\��
-- ============================================
    CURSOR count_location_cur
    IS
      SELECT    DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- ���_�ʌ��ʌ���
               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- ���_�ʌ��ʌv�艿
               ,SUM(xipl.sales_budget)                      sales_budget                            -- ���_�ʌ��ʌv������z
               ,SUM(xipl.amount)                            amount                                  -- ���_�ʌ��ʐ���
               ,xipl.year_month                                                                     -- �N��
      FROM      xxcsm_item_plan_lines                       xipl                                    -- ���i�v�斾�׃e�[�u��
               ,xxcsm_item_plan_headers                     xiph                                    -- ���i�v��w�b�_�e�[�u��
               ,xxcsm_commodity_group4_v                    xcg4                                    -- ����Q�S�r���[
      WHERE     xiph.item_plan_header_id  = xipl.item_plan_header_id                                -- �w�b�_ID
        AND     xiph.plan_year            = gn_taisyoyear                                           -- �\�Z�N�x
        AND     xiph.location_cd          = gv_kyoten_cd                                            -- ���_�R�[�h
--//+UPD START 2009/02/13 CT016 S.Son
      --AND   xipl.item_kbn            = cv_single_item                                             -- ���i�敪(1 = ���i�P�i)
        AND   xipl.item_kbn            <> cv_group_kbn                                              -- ���i�敪(1 = ���i�P�i�A2 = �V���i)
--//+UPD END 2009/02/13 CT016 S.Son
        AND     xipl.item_no              = xcg4.item_cd                                            -- ���i�R�[�h
      GROUP BY  xipl.year_month                                                                     -- �N��
      ORDER BY  xipl.year_month;                                                                    -- �N��
--
    count_location_rec   count_location_cur%ROWTYPE;
--
  BEGIN
      -- ===============================
      -- �ϐ��̏�����
      -- ===============================
    ln_y_amount      := 0;
    ln_y_sales       := 0;
    ln_y_cost        := 0;
    ln_y_margin      := 0;
    ln_y_margin_rate := 0;
    ln_y_rate        := 0;
    ln_y_price       := 0;
--
    OPEN count_location_cur;
    <<count_location_loop>>                                                                         -- ���_�ʌ��ʃf�[�^�W�v
    LOOP
      FETCH count_location_cur INTO count_location_rec;
      EXIT WHEN count_location_cur%NOTFOUND;                                                        -- �Ώۃf�[�^�����������J��Ԃ�
      -- ===============================
      -- �ϐ��̏�����
      -- ===============================
      ln_m_amount      := 0;
      ln_m_sales       := 0;
      ln_m_cost        := 0;
      ln_m_margin      := 0;
      ln_m_margin_rate := 0;
      ln_m_rate        := 0;
      ln_m_price       := 0;
    -- =============================================================================================
    -- (A-14) ���_�ʏW�v
    -- =============================================================================================
      -- ===============================
      -- ���ʃf�[�^�̎擾
      -- ===============================
      --���ʏ��i�敪����
      ln_m_amount        := count_location_rec.amount;                                              -- ����
      --���ʏ��i�敪����
      ln_m_sales         := count_location_rec.sales_budget;                                        -- ������z 
      --���ʏ��i�敪����
      ln_m_cost          := count_location_rec.cost;                                                -- ����
      --���ʏ��i�敪�e���v�z
      ln_m_margin        := (ln_m_sales - ln_m_cost);                                               -- (������z - ����)
      --���ʏ��i�敪�e���v��
      IF (ln_m_sales = 0) THEN
        ln_m_margin_rate := 0;
      ELSE
        ln_m_margin_rate := ROUND((ln_m_margin / ln_m_sales * 100),2);                              -- (�e���v�z / ������z * 100)
      END IF;
      --���ʏ��i�敪�|������
      ln_m_price         := count_location_rec.unit_price;                                          -- �艿
      --���ʏ��i�敪�|��
      IF (ln_m_price = 0) THEN
        ln_m_rate        := 0;
      ELSE
        ln_m_rate        := ROUND((ln_m_sales / ln_m_price * 100),2);                               -- (������z / �艿 * 100)
      END IF;
      -- ===============================
      -- �N�ԃf�[�^�̎擾
      -- ===============================
      --�N�ԏ��i�敪����
      ln_y_amount        := (ln_y_amount + ln_m_amount);
      --�N�ԏ��i�敪����
      ln_y_sales         := (ln_y_sales + ln_m_sales);
      --�N�ԏ��i�敪����
      ln_y_cost          := (ln_y_cost + ln_m_cost);
      --�N�ԏ��i�敪�e���v�z
      ln_y_margin        := (ln_y_margin + ln_m_margin);
      --�N�ԏ��i�敪�|������
      ln_y_price         := (ln_y_price + ln_m_price);
    -- =============================================================================================
    -- (A-15) ���_�ʃf�[�^�o�^����
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
          output_order                                                                              -- �o�͏�
         ,location_cd                                                                               -- ���_�R�[�h
         ,location_nm                                                                               -- ���_��
         ,item_cd                                                                                   -- �R�[�h
         ,item_nm                                                                                   -- ����
         ,year_month                                                                                -- �N��
         ,amount                                                                                    -- ����
         ,sales                                                                                     -- ����
         ,cost                                                                                      -- ����
         ,margin                                                                                    -- �e���v�z
         ,margin_rate                                                                               -- �e���v��
         ,rate                                                                                      -- �|��
         ,discount                                                                                  -- �l��
         )
      VALUES(
          gn_index                                                                                  -- �o�͏�
         ,gv_kyoten_cd                                                                              -- ���_�R�[�h
         ,gv_kyoten_nm                                                                              -- ���_��
         ,NULL                                                                                      -- �R�[�h
         ,gv_prf_foothold_sum                                                                       -- ����
         ,count_location_rec.year_month                                                             -- �N��
         ,ln_m_amount                                                                               -- ����
         ,ROUND((ln_m_sales / 1000),0)                                                              -- ����
         ,ROUND((ln_m_cost / 1000),0)                                                               -- ����
         ,ROUND((ln_m_margin / 1000),0)                                                             -- �e���v�z
         ,ln_m_margin_rate                                                                          -- �e���v��
         ,ln_m_rate                                                                                 -- �|��
         ,NULL                                                                                      -- �l��
         );
--
      gn_index := gn_index + 1;                                                                     -- �o�^�����C���N�������g
--
    END LOOP count_location_loop;
    CLOSE count_location_cur;
    --�N�ԏ��i�敪�e���v��
    IF (ln_y_sales = 0) THEN
      ln_y_margin_rate := 0;
    ELSE
      ln_y_margin_rate := ROUND((ln_y_margin / ln_y_sales * 100),2);
    END IF;
    --�N�ԏ��i�敪�|��
    IF (ln_y_price = 0) THEN
      ln_y_rate        := 0;
    ELSE
      ln_y_rate        := ROUND((ln_y_sales / ln_y_price * 100),2);
    END IF;
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
          output_order                                                                              -- �o�͏�
         ,location_cd                                                                               -- ���_�R�[�h
         ,location_nm                                                                               -- ���_��
         ,item_cd                                                                                   -- �R�[�h
         ,item_nm                                                                                   -- ����
         ,year_month                                                                                -- �N��
         ,amount                                                                                    -- ����
         ,sales                                                                                     -- ����
         ,cost                                                                                      -- ����
         ,margin                                                                                    -- �e���v�z
         ,margin_rate                                                                               -- �e���v��
         ,rate                                                                                      -- �|��
         ,discount                                                                                  -- �l��
         )
      VALUES(
          gn_index                                                                                  -- �o�͏�
         ,gv_kyoten_cd                                                                              -- ���_�R�[�h
         ,gv_kyoten_nm                                                                              -- ���_��
         ,NULL                                                                                      -- �R�[�h
         ,gv_prf_foothold_sum                                                                       -- ����
         ,cn_year_total                                                                             -- �N��
         ,ln_y_amount                                                                               -- ����
         ,ROUND((ln_y_sales / 1000),0)                                                              -- ����
         ,ROUND((ln_y_cost / 1000),0)                                                               -- ����
         ,ROUND((ln_y_margin / 1000),0)                                                             -- �e���v�z
         ,ln_y_margin_rate                                                                          -- �e���v��
         ,ln_y_rate                                                                                 -- �|��
         ,NULL                                                                                      -- �l��
         );
--
      gn_index := gn_index + 1;                                                                     -- �o�^�����C���N�������g
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
      IF (count_location_cur%ISOPEN) THEN
        CLOSE count_location_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (count_location_cur%ISOPEN) THEN
        CLOSE count_location_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END count_location;
--
   /****************************************************************************
   * Procedure Name   : get_item_group
   * Description      : ���i�v��f�[�^���o
   *****************************************************************************/
  PROCEDURE get_item_group(
         ov_errbuf         OUT NOCOPY VARCHAR2                                                      -- ���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode        OUT NOCOPY VARCHAR2                                                      -- ���^�[���E�R�[�h
        ,ov_errmsg         OUT NOCOPY VARCHAR2)                                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_item_group';                             -- �v���O������
    cv_others               CONSTANT VARCHAR2(1)   := 'D';                                          -- ���̑�
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf              VARCHAR2(4000);                                                          -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);                                                             -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(4000);                                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_warnmsg             VARCHAR2(4000);                                                          -- ���[�U�[�E�x���E���b�Z�[�W
    lv_group1_cd           VARCHAR2(100);                                                           -- ���i�Q�R�[�h1����p
    lv_group1_nm           VARCHAR2(100);
--
--###########################  �Œ蕔 END   ####################################
    -- =============================================================================================
    -- (A-5) ���i�v��f�[�^���o
    -- =============================================================================================
    CURSOR
        get_item_data_cur
    IS
      SELECT    xcg4.group1_cd                              group1_cd                               -- ���i�Q�R�[�h1
               ,xcg4.group1_nm                              group1_nm                               -- ���i�Q����1
               ,xcg4.group4_cd                              item_cd                                 -- ���i�Q�R�[�h
               ,xcg4.group4_nm                              item_nm                                 -- ���i�Q����
               ,DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- ���i�Q�N�Ԍv�挴��
               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- ���i�Q�ʔN�Ԍv�艿
               ,SUM(xipl.sales_budget)                      sales_budget                            -- ���i�Q�ʔN�Ԍv������z
               ,SUM(xipl.amount)                            amount                                  -- ���i�Q�ʔN�Ԍv����
      FROM      xxcsm_item_plan_lines                       xipl                                    -- ���i�v�斾�׃e�[�u��
               ,xxcsm_item_plan_headers                     xiph                                    -- ���i�v��w�b�_�e�[�u��
               ,xxcsm_commodity_group4_v                    xcg4                                    -- ����Q�S�r���[
      WHERE     xiph.item_plan_header_id = xipl.item_plan_header_id                                 -- �w�b�_ID
        AND     xiph.plan_year           = gn_taisyoyear                                            -- �\�Z�N�x
        AND     xiph.location_cd         = gv_kyoten_cd                                             -- ���_�R�[�h
--//+UPD START 2009/02/13 CT016 S.Son
      --AND   xipl.item_kbn            = cv_single_item                                             -- ���i�敪(1 = ���i�P�i)
        AND   xipl.item_kbn            <> cv_group_kbn                                              -- ���i�敪(1 = ���i�P�i�A2 = �V���i)
--//+UPD END 2009/02/13 CT016 S.Son
        AND     xipl.item_no             = xcg4.item_cd                                             -- ���i�R�[�h
      GROUP BY  xcg4.group1_cd                                                                      -- ���i�Q�R�[�h1
               ,xcg4.group1_nm                                                                      -- ���i�Q����1
               ,xcg4.group4_cd                                                                      -- ���i�Q�R�[�h
               ,xcg4.group4_nm                                                                      -- ���i�Q����
--//+DEL START 2009/02/17 CT025 M.Ohtsuki
--             ,xcg4.now_item_cost                                                                  -- �W������(�����_)
--             ,xcg4.now_business_cost                                                              -- �c�ƌ���(�����_)
--             ,xcg4.now_unit_price                                                                 -- �艿(�����_)
--//+DEL END   2009/02/17 CT025 M.Ohtsuki
      ORDER BY  xcg4.group1_cd                                                                      -- ���i�Q�R�[�h1
               ,xcg4.group1_nm;                                                                     -- ���i�Q����1
--
    get_item_data_rec   get_item_data_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- =======================================
    -- �f�[�^�̏����y���i�z
    -- =======================================
    OPEN get_item_data_cur;
    <<get_item_data_loop>>                                                                          -- ���i�Q�P��LOOP
    LOOP
      FETCH get_item_data_cur INTO get_item_data_rec;
      EXIT WHEN get_item_data_cur%NOTFOUND;                                                         -- �Ώۃf�[�^�����������J��Ԃ�
      --
      IF (lv_group1_cd <> get_item_data_rec.group1_cd) THEN                                         -- ���i�Q�R�[�h1�u���C�N��
    -- =============================================================================================
    -- (A-6) ���i�敪���ʏW�v (A-7) ���ʏ��i�敪�f�[�^�o�^����
    -- =============================================================================================
        count_item_kbn(
                       iv_group1_cd => lv_group1_cd                                                 -- �O�񏈗����̏��i�Q�R�[�h1
                      ,iv_group1_nm => lv_group1_nm                                                 -- �O�񏈗����̏��i�Q�R�[�h����
                      ,ov_errbuf    => lv_errbuf                                                    -- �G���[�E���b�Z�[�W
                      ,ov_retcode   => lv_retcode                                                   -- ���^�[���E�R�[�h
                      ,ov_errmsg    => lv_errmsg                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    -- =============================================================================================
    -- (A-10) ���i�Q���ʏW�v  (A-11) ���ʏ��i�Q�敪�f�[�^�o�^����
    -- =============================================================================================
      IF (get_item_data_rec.sales_budget <> 0) THEN                                                 -- (������z = 0)�̏ꍇ�����͂��Ȃ�
        count_item_group(
                        iv_item_cd       => get_item_data_rec.item_cd                               -- ���i�Q�R�[�h
                       ,iv_item_nm       => get_item_data_rec.item_nm                               -- ���i�Q����
                       ,in_cost          => get_item_data_rec.cost                                  -- ���i�Q�ʔN�Ԍv����
                       ,in_unit_price    => get_item_data_rec.unit_price                            -- ���i�Q�ʔN�Ԍv�艿
                       ,in_sales_budget  => get_item_data_rec.sales_budget                          -- ���i�Q�ʔN�Ԍv������z
                       ,in_amount        => get_item_data_rec.amount                                -- ���i�Q�ʔN�Ԍv����
                       ,ov_errbuf        => lv_errbuf                                               -- �G���[�E���b�Z�[�W
                       ,ov_retcode       => lv_retcode                                              -- ���^�[���E�R�[�h
                       ,ov_errmsg        => lv_errmsg                                               -- ���[�U�[�E�G���[�E���b�Z�[�W
                       );
      END IF;
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      lv_group1_cd := get_item_data_rec.group1_cd;                                                  -- ���f�p���i�Q�R�[�h1���㏑��
      lv_group1_nm := get_item_data_rec.group1_nm;
    END LOOP get_item_data_loop;
    CLOSE get_item_data_cur;
    -- =============================================================================================
    -- (A-6) ���i�敪���ʏW�v (A-7) ���ʏ��i�敪�f�[�^�o�^����
    -- =============================================================================================
    count_item_kbn(
                    iv_group1_cd => lv_group1_cd                                                    -- �O�񏈗����̏��i�Q�R�[�h1
                   ,iv_group1_nm => lv_group1_nm                                                    -- �O�񏈗����̏��i�Q�R�[�h����
                   ,ov_errbuf    => lv_errbuf                                                       -- �G���[�E���b�Z�[�W
                   ,ov_retcode   => lv_retcode                                                      -- ���^�[���E�R�[�h
                   ,ov_errmsg    => lv_errmsg                                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================================
    -- (A-8) ���i���v���ʏW�v (A-9) ���ʏ��i���v�f�[�^�o�^����
    -- =============================================================================================
    count_sum_item(
                    ov_errbuf    => lv_errbuf                                                       -- �G���[�E���b�Z�[�W
                   ,ov_retcode   => lv_retcode                                                      -- ���^�[���E�R�[�h
                   ,ov_errmsg    => lv_errmsg                                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
                   );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================================
    -- (A-12) �l�����ʏW�v    (A-13) ���ʒl���f�[�^�o�^����
    -- =============================================================================================
    count_discount(
                   ov_errbuf    => lv_errbuf                                                        -- �G���[�E���b�Z�[�W
                  ,ov_retcode   => lv_retcode                                                       -- ���^�[���E�R�[�h
                  ,ov_errmsg    => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================================
    -- (A-14) ���_�ʌ��ʏW�v  (A-15) ���ʋ��_�ʃf�[�^�o�^����
    -- =============================================================================================
    count_location(
                   ov_errbuf    => lv_errbuf                                                        -- �G���[�E���b�Z�[�W
                  ,ov_retcode   => lv_retcode                                                       -- ���^�[���E�R�[�h
                  ,ov_errmsg    => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_item_data_cur%ISOPEN) THEN
        CLOSE get_item_data_cur;
      END IF;            
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_item_data_cur%ISOPEN) THEN
        CLOSE get_item_data_cur;
      END IF;            
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_item_data_cur%ISOPEN) THEN
        CLOSE get_item_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END get_item_group;
--
   /*****************************************************************************
   * Procedure Name   : get_all_location
   * Description      : ���_���ɏ������J��Ԃ�
   ****************************************************************************/
  PROCEDURE get_all_location(
        ov_errbuf      OUT NOCOPY VARCHAR2                                                          -- �G���[�E���b�Z�[�W
       ,ov_retcode     OUT NOCOPY VARCHAR2                                                          -- ���^�[���E�R�[�h
       ,ov_errmsg      OUT NOCOPY VARCHAR2)                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
      -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)  := 'get_all_location';                         -- �v���O������

    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    ln_count                  NUMBER;                                                               -- �v���p
--
    lv_get_loc_tab            xxcsm_common_pkg.g_kyoten_ttype;                                      -- ���_�R�[�h���X�g�i�[�p
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- =============================================================================================
    -- (A-2) �S���_�擾
    -- =============================================================================================
    xxcsm_common_pkg.get_kyoten_cd_lv6(                                                             -- �c�ƕ���z���̋��_���X�g�擾
                                     iv_kyoten_cd      => gv_kyotencd                               -- ���_(����)�R�[�h
                                    ,iv_kaisou         => gv_kaisou                                 -- �K�w
--//ADD START 2009/05/07 T1_0858 M.Ohtsuki
                                    ,iv_subject_year   => gn_taisyoyear                             -- �Ώ۔N�x
--//ADD END   2009/05/07 T1_0858 M.Ohtsuki
                                    ,o_kyoten_list_tab => lv_get_loc_tab                            -- ���_�R�[�h���X�g
                                    ,ov_retcode        => lv_retcode                                -- �G���[�E���b�Z�[�W
                                    ,ov_errbuf         => lv_errbuf                                 -- ���^�[���E�R�[�h
                                    ,ov_errmsg         => lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
                                    );
--
    IF (lv_retcode <> cv_status_normal) THEN                                                        -- �߂�l���ُ�̏ꍇ
        RAISE global_api_others_expt;
    END IF;
  -- ================================================
  -- �y���_�R�[�h���X�g�z���_���ɉ��L�������J��Ԃ�
  -- ================================================
    <<kyoten_list_loop>>
    FOR ln_count IN 1..lv_get_loc_tab.COUNT LOOP                                                    -- ���_�P��LOOP
      BEGIN
        gv_kyoten_cd := lv_get_loc_tab(ln_count).kyoten_cd;                                         -- ���_�R�[�h
        gv_kyoten_nm := lv_get_loc_tab(ln_count).kyoten_nm;                                         -- ���_����
        --
        -- ================================================
        -- �y�`�F�b�N�����z
        -- ================================================
        check_location(
                       ov_errbuf    => lv_errbuf                                                    -- �G���[�E���b�Z�[�W
                      ,ov_retcode   => lv_retcode                                                   -- ���^�[���E�R�[�h
                      ,ov_errmsg    => lv_errmsg                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
        IF (lv_retcode = cv_status_warn) THEN                                                       -- �߂�l���x���̏ꍇ
            -- ���̃f�[�^�Ɉړ����܂�
          RAISE global_skip_expt;
        ELSIF (lv_retcode = cv_status_error) THEN                                                   -- �߂�l���ُ�̏ꍇ
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- �y���i�v��f�[�^���o�����z
        -- ================================================
        get_item_group(
                       ov_errbuf    => lv_errbuf                                                    -- �G���[�E���b�Z�[�W
                      ,ov_retcode   => lv_retcode                                                   -- ���^�[���E�R�[�h
                      ,ov_errmsg    => lv_errmsg                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
        IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
          RAISE global_process_expt;
        END IF;
    --  
    --#################################  �X�L�b�v��O������  START#############################
    --
      EXCEPTION
        WHEN global_skip_expt THEN
          gn_target_cnt := gn_target_cnt + 1 ;                                                      -- �Ώی��������Z���܂�
          gn_error_cnt := gn_error_cnt + 1 ;                                                        -- �X�L�b�v���������Z���܂�
--
          fnd_file.put_line(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errmsg
                           );
         --//+ADD START 2009/02/10 CT009 T.Shimoji
         -- �߂�X�e�[�^�X�x���ݒ�
         ov_retcode := cv_status_warn;
         --//+ADD END 2009/02/10 CT009 T.Shimoji
    --
    --#################################  �X�L�b�v��O������  END#############################
    --
      END;
      IF (lv_retcode = cv_status_normal) THEN
        gn_target_cnt := gn_target_cnt + 1;                                                         -- �Ώی��������Z���܂�
        gn_normal_cnt := gn_normal_cnt + 1;                                                         -- ���폈�����������Z���܂�
      ELSE
        lv_retcode := cv_status_normal;
      END IF;
--
    END LOOP kyoten_list_loop;
--  
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    WHEN global_process_expt THEN
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
  END get_all_location;
--
   /****************************************************************************
   * Procedure Name   : get_output_data
   * Description      : ���i�v�惊�X�g�f�[�^�o��
   *****************************************************************************/
  PROCEDURE get_output_data(
              ov_errbuf   OUT NOCOPY   VARCHAR2                                                     -- �G���[�E���b�Z�[�W
             ,ov_retcode  OUT NOCOPY   VARCHAR2                                                     -- ���^�[���E�R�[�h
             ,ov_errmsg   OUT NOCOPY   VARCHAR2                                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
            )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_output_data';                            -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf              VARCHAR2(4000);                                                          -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);                                                             -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(4000);                                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_warnmsg             VARCHAR2(4000);                                                          -- ���[�U�[�E�x���E���b�Z�[�W
    lv_location_cd         VARCHAR2(100);                                                           -- ���f�p���_�R�[�h
    lv_item_nm             VARCHAR2(100);                                                           -- ���f�p����
    lv_data_head           VARCHAR2(4000);                                                          -- �w�b�_�[�f�[�^�i�[�p
--
    lv_out_amount          VARCHAR2(4000);                                                          -- ���ʏo�͗p
    lv_out_sales           VARCHAR2(4000);                                                          -- ������z�o�͗p
    lv_out_cost            VARCHAR2(4000);                                                          -- �����o�͗p
    lv_out_margin          VARCHAR2(4000);                                                          -- �e���v�z�o�͗p
    lv_out_margin_rate     VARCHAR2(4000);                                                          -- �e���v���o�͗p
    lv_out_rate            VARCHAR2(4000);                                                          -- �|���o�͗p
    lv_out_discount        VARCHAR2(4000);                                                          -- �l���o�͗p
    lv_msg_no_data         VARCHAR2(100);                                                           -- �Ώۃf�[�^�������b�Z�[�W
--###########################  �Œ蕔 END   ####################################
    CURSOR 
      get_output_data_cur
    IS
      SELECT    xwip.location_cd           location_cd                                              -- ���_�R�[�h
               ,xwip.location_nm           location_nm                                              -- ���_��
               ,xwip.item_cd               item_cd                                                  -- �R�[�h
               ,xwip.item_nm               item_nm                                                  -- ����
               ,xwip.amount                amount                                                   -- ����
               ,xwip.sales                 sales                                                    -- ������z
               ,xwip.cost                  cost                                                     -- ����
               ,xwip.margin                margin                                                   -- �e���v�z
               ,xwip.margin_rate           margin_rate                                              -- �e���v��
               ,xwip.rate                  rate                                                     -- �|��
               ,xwip.discount              discount                                                 -- �l��
      FROM      xxcsm_tmp_sales_plan_time   xwip                                                    -- ���i�v�惊�X�g_���n�񃏁[�N�e�[�u��
      ORDER BY  xwip.output_order;                                                                  -- �o�͏�
--
    get_output_data_rec  get_output_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =============================================================================================
    -- (A-16) �`�F�b�N���X�g�f�[�^�o��
    -- =============================================================================================
    -- �w�b�_���̒��o
    lv_data_head := xxccp_common_pkg.get_msg(                                                       -- ���_�R�[�h�̏o��
             iv_application  => cv_xxcsm                                                            -- �A�v���P�[�V�����Z�k��
            ,iv_name         => cv_csm1_msg_00090                                                   -- ���b�Z�[�W�R�[�h
            ,iv_token_name1  => cv_tkn_year                                                         -- �g�[�N���R�[�h1�i�Ώ۔N�x�j
            ,iv_token_value1 => gn_taisyoyear                                                       -- �g�[�N���l1
            ,iv_token_name2  => cv_tkn_genka_nm                                                     -- �g�[�N���R�[�h2�i�����j
            ,iv_token_value2 => gv_genkanm                                                          -- �g�[�N���l2
            ,iv_token_name3  => cv_tkn_sakusei_date                                                 -- �g�[�N���R�[�h3�i�Ɩ����t�j
 --//+UPD START 2009/02/20 CT052 T.Tsukino
--            ,iv_token_value3 => gd_process_date                                                     -- �g�[�N���l3
            ,iv_token_value3 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')                                  -- �g�[�N���l3
 --//+UPD END 2009/02/20 CT052 T.Tsukino
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
--
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT
                     ,buff   => lv_data_head
                     );
--�ϐ���������
    lv_out_sales       := cv_msg_space4 || cv_msg_comma 
                                        || cv_msg_duble
                                        || gv_prf_sales
                                        || cv_msg_duble;                                            -- �o�͋敪(����)���i�[
    lv_out_cost        := cv_msg_space4 || cv_msg_comma
                                        || cv_msg_duble
                                        || gv_prf_cost_price
                                        || cv_msg_duble;                                            -- �o�͋敪(����)���i�[
    lv_out_margin      := cv_msg_space4 || cv_msg_comma
                                        || cv_msg_duble
                                        || gv_prf_gross_margin
                                        || cv_msg_duble;                                            -- �o�͋敪(�e���v�z)���i�[
    lv_out_margin_rate := cv_msg_space4 || cv_msg_comma
                                        || cv_msg_duble
                                        || gv_prf_rough_rate
                                        || cv_msg_duble;                                            -- �o�͋敪(�e���v��)���i�[
    lv_out_rate        := cv_msg_space4 || cv_msg_comma
                                        || cv_msg_duble
                                        || gv_prf_rate
                                        || cv_msg_duble;                                            -- �o�͋敪(�|��)���i�[
--
    OPEN get_output_data_cur;
    <<get_output_data_loop>>                                                                        -- �f�[�^����
    LOOP
      FETCH get_output_data_cur INTO get_output_data_rec;
      EXIT WHEN get_output_data_cur%NOTFOUND;                                                       -- �Ώۃf�[�^�����������J��Ԃ�
--
      IF ((get_output_data_cur%ROWCOUNT = 1)                                                        -- 1���� OR ���_�R�[�h�u���C�N��
        OR (lv_location_cd <> get_output_data_rec.location_cd)) THEN
        IF (lv_location_cd <> get_output_data_rec.location_cd) THEN                                 -- ���_�R�[�h�u���C�N��
          fnd_file.put_line(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_out_amount      || CHR(10) ||
                                      lv_out_sales       || CHR(10) ||
                                      lv_out_cost        || CHR(10) ||
                                      lv_out_margin      || CHR(10) ||
                                      lv_out_margin_rate || CHR(10) ||
                                      lv_out_rate        || CHR(10) ||
                                      cv_msg_space16
                           );
          --�ϐ���������
          lv_out_sales       := cv_msg_space4 || cv_msg_comma 
                                              || cv_msg_duble
                                              || gv_prf_sales
                                              || cv_msg_duble;                                      -- �o�͋敪(����)���i�[
          lv_out_cost        := cv_msg_space4 || cv_msg_comma
                                              || cv_msg_duble
                                              || gv_prf_cost_price
                                              || cv_msg_duble;                                      -- �o�͋敪(����)���i�[
          lv_out_margin      := cv_msg_space4 || cv_msg_comma
                                              || cv_msg_duble
                                              || gv_prf_gross_margin
                                              || cv_msg_duble;                                      -- �o�͋敪(�e���v�z)���i�[
          lv_out_margin_rate := cv_msg_space4 || cv_msg_comma
                                              || cv_msg_duble
                                              || gv_prf_rough_rate
                                              || cv_msg_duble;                                      -- �o�͋敪(�e���v��)���i�[
          lv_out_rate        := cv_msg_space4 || cv_msg_comma
                                              || cv_msg_duble
                                              || gv_prf_rate
                                              || cv_msg_duble;                                      -- �o�͋敪(�|��)���i�[
        END IF;
        --�w�b�_�[�f�[�^�쐬(���_�R�[�h�C���_���C�R�[�h�C���́C����)
        lv_out_amount := cv_msg_duble || get_output_data_rec.location_cd || cv_msg_duble
                      || cv_msg_comma
                      || cv_msg_duble || get_output_data_rec.location_nm || cv_msg_duble
                      || cv_msg_comma
                      || cv_msg_duble || get_output_data_rec.item_cd     || cv_msg_duble
                      || cv_msg_comma
                      || cv_msg_duble || get_output_data_rec.item_nm     || cv_msg_duble
                      || cv_msg_comma
                      || cv_msg_duble || gv_prf_amount                   || cv_msg_duble;
--
      ELSE
        IF (lv_item_nm <> get_output_data_rec.item_nm) THEN                                         -- ���̃u���C�N��
          IF (lv_item_nm = gv_prf_item_discount) THEN  
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => lv_out_discount
                             );
            --�ϐ���������
            lv_out_sales       := cv_msg_space4 || cv_msg_comma 
                                                || cv_msg_duble
                                                || gv_prf_sales
                                                || cv_msg_duble;                                    -- �o�͋敪(����)���i�[
            lv_out_cost        := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_cost_price
                                                || cv_msg_duble;                                    -- �o�͋敪(����)���i�[
            lv_out_margin      := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_gross_margin
                                                || cv_msg_duble;                                    -- �o�͋敪(�e���v�z)���i�[
            lv_out_margin_rate := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_rough_rate
                                                || cv_msg_duble;                                    -- �o�͋敪(�e���v��)���i�[
            lv_out_rate        := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_rate
                                                || cv_msg_duble;                                    -- �o�͋敪(�|��)���i�[
          ELSE
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => lv_out_amount      || CHR(10) ||
                                        lv_out_sales       || CHR(10) ||
                                        lv_out_cost        || CHR(10) ||
                                        lv_out_margin      || CHR(10) ||
                                        lv_out_margin_rate || CHR(10) ||
                                        lv_out_rate        || CHR(10) ||
                                        cv_msg_space16
                             );
            --�ϐ���������
            lv_out_sales       := cv_msg_space4 || cv_msg_comma 
                                                || cv_msg_duble
                                                || gv_prf_sales
                                                || cv_msg_duble;                                    -- �o�͋敪(����)���i�[
            lv_out_cost        := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_cost_price
                                                || cv_msg_duble;                                    -- �o�͋敪(����)���i�[
            lv_out_margin      := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_gross_margin
                                                || cv_msg_duble;                                    -- �o�͋敪(�e���v�z)���i�[
            lv_out_margin_rate := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_rough_rate
                                                || cv_msg_duble;                                    -- �o�͋敪(�e���v��)���i�[
            lv_out_rate        := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_rate
                                                || cv_msg_duble;                                    -- �o�͋敪(�|��)���i�[
          END IF;
          IF (get_output_data_rec.item_cd IS NOT NULL ) THEN                                        -- �R�[�h��NULL�ȊO
             --�w�b�_�[�f�[�^�쐬(�u�����N�C�u�����N�C�R�[�h�C���́C����)
             lv_out_amount := cv_msg_duble || cv_msg_space                || cv_msg_duble
                           || cv_msg_comma                     
                           || cv_msg_duble || cv_msg_space                || cv_msg_duble
                           || cv_msg_comma
                           || cv_msg_duble || get_output_data_rec.item_cd || cv_msg_duble
                           || cv_msg_comma
                           || cv_msg_duble || get_output_data_rec.item_nm || cv_msg_duble
                           || cv_msg_comma
                           || cv_msg_duble || gv_prf_amount               || cv_msg_duble;

--
          ELSE                                                                                      -- �R�[�h��NULL
            IF (get_output_data_rec.item_nm = gv_prf_item_discount) THEN
             --�w�b�_�[�f�[�^�쐬(�u�����N�C�u�����N�C�u�����N�C����l���C�u�����N)
            lv_out_discount := cv_msg_duble || cv_msg_space                || cv_msg_duble
                            || cv_msg_comma
                            || cv_msg_duble || cv_msg_space                || cv_msg_duble
                            || cv_msg_comma
                            || cv_msg_duble || cv_msg_space                || cv_msg_duble
                            || cv_msg_comma
                            || cv_msg_duble || get_output_data_rec.item_nm || cv_msg_duble
                            || cv_msg_comma
                            || cv_msg_duble || cv_msg_space                || cv_msg_duble;
            ELSE
             --�w�b�_�[�f�[�^�쐬(�u�����N�C�u�����N�C�R�[�h�C���́C����)
            lv_out_amount := cv_msg_duble || cv_msg_space                || cv_msg_duble
                          || cv_msg_comma
                          || cv_msg_duble || cv_msg_space                || cv_msg_duble
                          || cv_msg_comma
                          || cv_msg_duble || cv_msg_space                || cv_msg_duble
                          || cv_msg_comma
                          || cv_msg_duble || get_output_data_rec.item_nm || cv_msg_duble
                          || cv_msg_comma
                          || cv_msg_duble || gv_prf_amount               || cv_msg_duble;

            END IF;
          END IF;
        END IF;
      END IF;
      --�o�͗p���b�Z�[�W�̍쐬
      lv_out_amount      := lv_out_amount      || cv_msg_comma || get_output_data_rec.amount;       -- ����
      lv_out_sales       := lv_out_sales       || cv_msg_comma || get_output_data_rec.sales;        -- ������z
      lv_out_cost        := lv_out_cost        || cv_msg_comma || get_output_data_rec.cost;         -- ����
      lv_out_margin      := lv_out_margin      || cv_msg_comma || get_output_data_rec.margin;       -- �e���v�z
      lv_out_margin_rate := lv_out_margin_rate || cv_msg_comma || get_output_data_rec.margin_rate;  -- �e���v�z
      lv_out_rate        := lv_out_rate        || cv_msg_comma || get_output_data_rec.rate;         -- �e���v��
      lv_out_discount    := lv_out_discount    || cv_msg_comma || get_output_data_rec.discount;     -- ����l��
--
      lv_location_cd  := get_output_data_rec.location_cd;                                           -- ���f�p���_�R�[�h���i�[
      lv_item_nm      := get_output_data_rec.item_nm;                                               -- ���f�p���̂��i�[
--
    END LOOP get_output_data_loop;
--
    IF (get_output_data_cur%ROWCOUNT = 0) THEN                                                      -- �f�[�^����������0���̏ꍇ
      lv_msg_no_data := xxccp_common_pkg.get_msg(                                                   -- ���b�Z�[�W�̎擾
                        iv_application  => cv_xxcsm                                                 -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_csm1_msg_10001                                        -- ���b�Z�[�W�R�[�h
                       );
      fnd_file.put_line(                                                                            -- �Ώۃf�[�^0�����o��
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_msg_no_data || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                       );
      --//+ADD START 2009/02/10 CT009 T.Shimoji
      -- �߂�X�e�[�^�X�x���ݒ�
      ov_retcode := cv_status_warn;
      --//+ADD END 2009/02/10 CT009 T.Shimoji
    ELSE
      fnd_file.put_line(                                                                            -- �ŏI�f�[�^���o��
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_out_amount      || CHR(10) ||
                                  lv_out_sales       || CHR(10) ||
                                  lv_out_cost        || CHR(10) ||
                                  lv_out_margin      || CHR(10) ||
                                  lv_out_margin_rate || CHR(10) ||
                                  lv_out_rate
                       );
    END IF;
    CLOSE get_output_data_cur;
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_output_data_cur%ISOPEN) THEN
        CLOSE get_output_data_cur;
      END IF;            
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_output_data_cur%ISOPEN) THEN
        CLOSE get_output_data_cur;
      END IF;            
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================
      IF (get_output_data_cur%ISOPEN) THEN
        CLOSE get_output_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END get_output_data;
--
  /*****************************************************************************
   * Procedure Name   : submain
   * Description      : ��������
   ****************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                                              -- �v���O������
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                                                         -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    gn_target_cnt := 0;                                                                             -- �Ώی����J�E���^�̏�����
    gn_normal_cnt := 0;                                                                             -- ���팏���J�E���^�̏�����
    gn_error_cnt  := 0;                                                                             -- �G���[�����J�E���^�̏�����
    gn_warn_cnt   := 0;                                                                             -- �X�L�b�v�����J�E���^�̏�����
-- ��������
    init(                                                                                           -- init���R�[��
       ov_errbuf  => lv_errbuf                                                                      -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode                                                                     -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode <> cv_status_normal) THEN                                                        -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;
-- �S���_�擾����
    get_all_location(
       ov_errbuf  => lv_errbuf                                                                      -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode                                                                     -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    --//+UPD START 2009/02/10 CT009 T.Shimoji
    --IF (lv_retcode <> cv_status_normal) THEN                                                        -- �߂�l���ُ�̏ꍇ
    --  RAISE global_process_expt;
    --END IF;
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
    --//+UPD END 2009/02/10 CT009 T.Shimoji
-- ���i�v�惊�X�g�f�[�^�o��
    get_output_data(
       ov_errbuf  => lv_errbuf                                                                      -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode                                                                     -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    --//+UPD START 2009/02/10 CT009 T.Shimoji
    --IF (lv_retcode <> cv_status_normal) THEN                                                        -- �߂�l���ُ�̏ꍇ
    --  RAISE global_process_expt;
    --END IF;
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
    --//+UPD END 2009/02/10 CT009 T.Shimoji
--
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
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   ****************************************************************************/
  PROCEDURE main(
                errbuf           OUT    NOCOPY VARCHAR2                                             -- �G���[���b�Z�[�W
               ,retcode          OUT    NOCOPY VARCHAR2                                             -- �G���[�R�[�h
               ,iv_taisyo_year   IN            VARCHAR2                                             -- �Ώ۔N�x
               ,iv_kyoten_cd     IN            VARCHAR2                                             -- ���_�R�[�h
               ,iv_cost_kind     IN            VARCHAR2                                             -- �������
               ,iv_kyoten_kaisou IN            VARCHAR2                                             -- �K�w
               )
  IS
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                                                         -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
-- �I�����b�Z�[�W�R�[�h
    lv_message_code   VARCHAR2(100);                                                                -- �I���R�[�h
-- ===============================
-- �Œ胍�[�J���萔
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'main';                                         -- �v���O������
    cv_which_log        CONSTANT VARCHAR2(10)    := 'LOG';                                          -- �o�͐�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    retcode := cv_status_normal;
--
--##################  �Œ蕔 END   #####################################
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
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
--��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
      );
--
--###########################  �Œ蕔 END   #############################
-- ���̓p�����[�^��ϐ����i�[
    gn_taisyoyear   := TO_NUMBER(iv_taisyo_year);                                                   -- �Ώ۔N�x
    gv_kyotencd     := iv_kyoten_cd;                                                                -- ���_�R�[�h
    gv_genkacd      := iv_cost_kind;                                                                -- �������
    gv_kaisou       := iv_kyoten_kaisou;                                                            -- �K�w
-- ��������
    submain(                                                                                        -- submain���R�[��
            ov_retcode => lv_retcode                                                                -- �G���[�E���b�Z�[�W
           ,ov_errbuf  => lv_errbuf                                                                 -- ���^�[���E�R�[�h
           ,ov_errmsg  => lv_errmsg                                                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
           );
--
    IF(lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm
                        ,iv_name         => cv_ccp1_msg_00111
                        );
      END IF;
--
      fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf            -- �G���[���b�Z�[�W
       );
      --//+ADD START 2009/02/10 CT009 T.Shimoji
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg            -- ���[�U�[�E�G���[���b�Z�[�W
      );
      --//+ADD END 2009/02/10 CT009 T.Shimoji
     -- �����J�E���^�̏�����
      gn_target_cnt := 0;                                                                           -- �Ώی����J�E���^�̏�����
      gn_normal_cnt := 0;                                                                           -- ���팏���J�E���^�̏�����
      gn_error_cnt  := 1;                                                                           -- �G���[�����J�E���^�̏�����
      gn_warn_cnt   := 0;                                                                           -- �X�L�b�v�����J�E���^�̏�����
    END IF;
--��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
      );
--�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp1_msg_90000
                    ,iv_token_name1  => cv_tkn_count
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
                    ,iv_token_name1  => cv_tkn_count
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
                    ,iv_token_name1  => cv_tkn_count
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
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
--��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
      );
--�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_ccp1_msg_90004;
--//+ADD START 2009/02/10 CT009 T.Shimoji
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_ccp1_msg_90005;
--//+ADD END 2009/02/10 CT009 T.Shimoji
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
--
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
--  
END XXCSM002A12C;
/
