CREATE OR REPLACE PACKAGE BODY  XXCSM002A11C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A11C(spec)
 * Description      : ���i�v�惊�X�g(���n��CS�P��)�o��
 * MD.050           : ���i�v�惊�X�g(���n��CS�P��)�o�� MD050_CSM_002_A11
 * Version          : 1.12
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                �y���������zA-1
 *
 *  do_check            �y�`�F�b�N�����zA-2~A-3
 *
 *  deal_item_data     �y���i�P�ʂ̏����zA-4~A-6
 *
 *  deal_group4_data    �y���i�Q�P�ʂ̏����zA-7~A-9
 *
 *  deal_group1_data    �y���i�敪�P�ʂ̏����zA-10~A-12
 *
 *  deal_sum_data       �y���i���v�P�ʂ̏����zA-13~A-15
 *
 *  deal_down_data      �y���i�l���P�ʂ̏����zA-16~A-17
 *
 *  deal_kyoten_data    �y���_�P�ʂ̏����zA-18~A-20
 *
 *  deal_all_data       �y���_���X�g�P�ʂ̏����zA-2~A-20
 *
 *  get_col_data        �y�e���ڃf�[�^�̎擾�zA-21
 *     
 *  deal_csv_data        �y�o�̓{�f�B���̎擾�zA-21
 *  
 *  write_csv_file      �y�o�͏����zA-22
 *  
 *  submain             �y���������zA-1~A-23
 *
 *  main                �y�R���J�����g���s�t�@�C���o�^�v���V�[�W���zA-1~A-23
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/05    1.0   ohshikyo        �V�K�쐬
 *  2009/02/10    1.1   SCS T.Tsukino   [��QCT_008] �ގ��@�\���쓝��Ή�
 *  2009/02/16    1.2   SCS S.Son       [��QCT_020] ����0�̕s��Ή�
 *  2009/02/18    1.3   SCS S.Son       [��QCT_028] �����̃J�E���g�ɕs��Ή�
 *                                      [��QCT_030] �o�͏��̕s��Ή�
 *                                      [��QCT_041] �����_�o�͂̕s��Ή�
 *  2009/02/23    1.4   SCS N.Izumi     [��QCT_056] �����l���N�v�̕s��Ή�
 *  2009/02/26    1.5   SCS S.Son       [��QCT_062] ���i�Q�v�o�͏��s��Ή�
 *  2009/05/07    1.6   SCS M.Ohtsuki   [��QT1_0858] ���ʊ֐��C���ɔ����p�����[�^�̒ǉ�
 *  2010/03/24    1.7   SCS N.Abe       [E_�{�ғ�_01906] PT�Ή�(�q���g��ǉ�)
 *  2010/04/26    1.8   SCS N.Abe       [E_�{�ғ�_02367] �P��(�{)�ȊO�����o����Ή�
 *  2010/12/17    1.9   SCS Y.Kanami    [E_�{�ғ�_05803]
 *  2011/01/05    1.10  SCS OuKou       [E_�{�ғ�_05803]
 *  2012/12/14    1.11  SCSK K.Taniguchi[E_�{�ғ�_09949] �V�������I���\�Ή�
 *  2013/01/31    1.12  SCSK K.Taniguchi [E_�{�ғ�_09949]�N�x�J�n���擾�̕s��Ή�
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

  cn_unit                   CONSTANT NUMBER        := 1000;                     -- �o�͒P�ʁF��~
  cv_all_zero               CONSTANT VARCHAR2(100) := '0,0,0,0,0,0,0,0,0,0,0,0,0' || CHR(10); -- ���ԂƔN�ԃf�[�^:0
  cv_sum_zero               CONSTANT VARCHAR2(10)   := '0' || CHR(10);  -- �N�ԃf�[�^:0
  cn_base_price             CONSTANT NUMBER        := 10;                     -- �W������
  cn_bus_price              CONSTANT NUMBER        := 20;                     -- �c�ƌ���
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
  gn_target_cnt             NUMBER;       -- �Ώی���
  gn_normal_cnt             NUMBER;       -- ���팏��
  gn_error_cnt              NUMBER;       -- �G���[����
  gn_warn_cnt               NUMBER;       -- �X�L�b�v����
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
  global_skip_expt    EXCEPTION;
--//+ADD START 2009/02/18 CT028 S.Son
  sales_skip_expt     EXCEPTION;
--//+ADD END 2009/02/18 CT028 S.Son

--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--  
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM002A11C';               -- �p�b�P�[�W��
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                          -- �J���}     
  cv_msg_hafu               CONSTANT VARCHAR2(3)   := '-';                          -- 
  cv_msg_space              CONSTANT VARCHAR2(4)   := '';                           -- ��
  cv_msg_duble              CONSTANT VARCHAR2(3)   := '"';                          -- �_�u���N�H�[�e�[�V����
    
  cv_msg_linespace          CONSTANT VARCHAR2(20) := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma || cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
                                                     
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                      -- �A�v���P�[�V�����Z�k��    
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                      -- �A�h�I���F���ʁEIF�̈�
  cv_group_A                CONSTANT VARCHAR2(10)  := 'A' ;                         -- ���i�QA
  cv_group_C                CONSTANT VARCHAR2(10)  := 'C' ;                         -- ���i�QC
  cv_group_D                CONSTANT VARCHAR2(10)  := 'D' ;                         -- ���i�QD
  cv_group_N                CONSTANT VARCHAR2(10)  := 'N' ;                         -- ���i�QN

--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                          -- �t���OY
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';                          -- �t���ON
  cv_whse_code              CONSTANT VARCHAR2(3)   := '000';                        -- �����q��
  cv_new_cost               CONSTANT VARCHAR2(10)  := '10';                         -- �p�����[�^�F�V�������敪�i�V�����j
  cv_old_cost               CONSTANT VARCHAR2(10)  := '20';                         -- �p�����[�^�F�V�������敪�i�������j
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
-- 
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ� 
  -- ===============================
--  
  gd_process_date          DATE;                                               -- �Ɩ����t
  gn_index                 NUMBER := 0;                                        -- �o�^��
  gv_kyotencd              VARCHAR2(32);                                       -- ���_�R�[�h  
  gn_taisyoym              NUMBER(4,0);                                        -- �Ώ۔N�x
  gv_genkacd               VARCHAR2(200);                                      -- �������
  gv_genkanm               VARCHAR2(200);                                      -- ������ʖ�
  gv_kaisou                VARCHAR2(2);                                        -- �K�w
  gv_org_id                NUMBER;                                             -- �݌ɑg�DID
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  gv_new_old_cost_class    VARCHAR2(2);                                        -- �V�������敪(�p�����[�^�i�[�p)
  gd_gl_start_date         DATE;                                               -- �N�����̔N�x�J�n��
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
  
  -- ===============================
  -- ���p���b�Z�[�W�ԍ�
  -- ===============================
--  
  cv_ccp1_msg_90000           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';         -- �Ώی������b�Z�[�W
  cv_ccp1_msg_90001           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';         -- �����������b�Z�[�W
  cv_ccp1_msg_90002           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';         -- �G���[�������b�Z�[�W
  cv_ccp1_msg_90003           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';         -- �X�L�b�v�������b�Z�[�W
  cv_ccp1_msg_90004           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';         -- ����I�����b�Z�[�W
--//+ADD START 2009/02/13 CT008 T.Shimoji
  cv_ccp1_msg_90005           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';         -- �x���I�����b�Z�[�W
--//+ADD START 2009/02/13 CT008 T.Shimoji
  cv_ccp1_msg_90006           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';         -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_ccp1_msg_00111           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';         -- �z��O�G���[���b�Z�[�W
--  
  -- ===============================  
  -- ���b�Z�[�W�ԍ�
  -- ===============================
--  
  cv_csm1_msg_00005           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';         -- �v���t�@�C���擾�G���[���b�Z�[�W
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_csm1_msg_10168           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10168';         -- �N�x�J�n���擾�G���[
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
  cv_csm1_msg_00087           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';         -- ���i�v�斢�ݒ胁�b�Z�[�W
  cv_csm1_msg_00088           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';         -- ���i�v��P�i�ʈ��������������b�Z�[�W
  cv_csm1_msg_00093           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00093';         -- ���i�v�惊�X�g(���n��:C/S�P��)�w�b�_�p���b�Z�[�W
  cv_csm1_msg_00037           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00037';         -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_csm1_msg_00048           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';         -- ���̓p�����[�^�擾���b�Z�[�W(���_�R�[�h)
  cv_csm1_msg_10015           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10015';         -- ���̓p�����[�^�擾���b�Z�[�W�i�Ώ۔N�x�j
  cv_csm1_msg_10016           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10016';         -- ���̓p�����[�^�擾���b�Z�[�W�i�K�w�j
  cv_csm1_msg_10017           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10017';         -- ���̓p�����[�^�擾���b�Z�[�W�i������ʖ��j
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_csm1_msg_10167           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10167';         -- ���̓p�����[�^�擾���b�Z�[�W�i�V�������敪�j
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
  cv_csm1_msg_10122           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10122';         -- ���i�v��f�[�^�̓����l��0�`�F�b�N���b�Z�[�W
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--  cv_csm1_msg_10131           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10131';         -- �P�ʕϊ��}�X�^�ɓo�^����Ă��Ȃ����b�Z�[�W
--  cv_csm1_msg_10133           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10133';         -- �P�ʕϊ��}�X�^�ɓo�^����Ă����P�ʂ��u�{�v�łȂ����b�Z�[�W
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
--//+ADD START 2009/02/10 CT008 T.Tsukino
  cv_csm1_msg_10001           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';         -- �Ώۃf�[�^0�����b�Z�[�W
--//+ADD END 2009/02/10 CT008 T.Tsukino
--
  -- ===============================
  -- �g�[�N����`
  -- ===============================
--  
  cv_tkn_year                      CONSTANT VARCHAR2(100) := 'TAISYOU_YM';      -- �Ώ۔N�x
  cv_tkn_kyotencd                  CONSTANT VARCHAR2(100) := 'KYOTEN_CD';       -- ���_�R�[�h
  cv_tkn_genka_cd                  CONSTANT VARCHAR2(100) := 'GENKA_CD';        -- �������
  cv_tkn_genka_nm                  CONSTANT VARCHAR2(100) := 'GENKA_NM';        -- ������ʖ�
  cv_tkn_org_code                  CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';    -- �݌ɑg�D�R�[�h
  cv_tkn_kaisou                    CONSTANT VARCHAR2(100) := 'KAISOU';          -- �K�w
  cv_tkn_profile                   CONSTANT VARCHAR2(100) := 'PROF_NAME';       -- �v���t�@�C����
  cv_tkn_count                     CONSTANT VARCHAR2(100) := 'COUNT';           -- ��������
  cv_tkn_sysdate                   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI'; -- �쐬����
  cv_cnt_token                     CONSTANT VARCHAR2(100) := 'COUNT';           -- �������b�Z�[�W
  cv_tkn_item_cd                   CONSTANT VARCHAR2(100) := 'ITEM_CD';         -- ���i�R�[�h
  cv_tkn_item_nm                   CONSTANT VARCHAR2(100) := 'ITEM_NM';         -- ���i����
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_tkn_new_old_cost_cls          CONSTANT VARCHAR2(100) := 'NEW_OLD_COST_CLASS';  -- �V�������敪
  cv_tkn_sobid                     CONSTANT VARCHAR2(100) := 'SET_OF_BOOKS_ID';     -- ��v����ID
  cv_tkn_process_date              CONSTANT VARCHAR2(100) := 'PROCESS_DATE';        -- �Ɩ����t
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
--//+DEL START 2009/02/18 CT028 S.Son
--cv_tkn_month_no                  CONSTANT VARCHAR2(100) := 'MONTH_NO';        -- ��
--//+DEL END 2009/02/18 CT028 S.Son
  -- =============================== 
  -- �v���t�@�C��
  -- ===============================
-- �v���t�@�C���E�R�[�h  
  lv_prf_cd_sales                   CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';     -- XXCMN:����
  lv_prf_cd_rate                    CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_4';     -- XXCMN:�|��
  lv_prf_cd_amount                  CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_1';     -- XXCMN:����
  lv_prf_cd_margin                  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6';    -- XXCMN:�e���v�z
  
  lv_prf_cd_sum                     CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';    -- XXCMN:���i���v
  lv_prf_cd_down_sales              CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';    -- XXCMN:����l��
  lv_prf_cd_down_pay                CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';    -- XXCMN:�����l��
  lv_prf_cd_p_sum                   CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_5';     -- XXCMN:���_�v
  lv_prf_cd_team                    CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';   -- XXCMN:�݌ɑg�D�R�[�h
  lv_prf_cd_price_e                 CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_6';     -- XXCMN:�c�ƌ���
  lv_prf_cd_price_h                 CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_7';     -- XXCMN:�W������
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  cv_prf_gl_set_of_bks_id           CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';           -- ��v����ID�v���t�@�C����
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--  lv_prf_cd_unit_hon                CONSTANT VARCHAR2(100) := 'XXCSM1_UNIT_ITEM_1';         -- XXCMN:�{
--  lv_prf_cd_unit_cs                 CONSTANT VARCHAR2(100) := 'XXCSM1_UNIT_ITEM_2';         -- XXCMN:CS
-- == 2010/04/26 V1.8 Deleted END   ===============================================================

  

-- �v���t�@�C���E����
  lv_prf_cd_sales_val                   VARCHAR2(100) ;                                 -- XXCMN:����
  lv_prf_cd_rate_val                    VARCHAR2(100) ;                                 -- XXCMN:�|��
  lv_prf_cd_amount_val                  VARCHAR2(100) ;                                 -- XXCMN:����
  lv_prf_cd_margin_val                  VARCHAR2(100) ;                                 -- XXCMN:�e���v�z
  lv_prf_cd_sum_val                     VARCHAR2(100) ;                                 -- XXCMN:���i���v
  lv_prf_cd_down_sales_val              VARCHAR2(100) ;                                 -- XXCMN:����l��
  lv_prf_cd_down_pay_val                VARCHAR2(100) ;                                 -- XXCMN:�����l��
  lv_prf_cd_p_sum_val                   VARCHAR2(100) ;                                 -- XXCMN:���_�v
  lv_prf_cd_team_val                    VARCHAR2(100) ;                                 -- XXCMN:�݌ɑg�D�R�[�h
  lv_prf_cd_price_e_val                 VARCHAR2(100) ;                                 -- XXCMN:�c�ƌ���
  lv_prf_cd_price_h_val                 VARCHAR2(100) ;                                 -- XXCMN:�W������
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
  gv_prf_gl_set_of_bks_id               VARCHAR2(100) ;                                 -- ��v����ID(Char)
  gn_prf_gl_set_of_bks_id               NUMBER;                                         -- ��v����ID
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--  lv_prf_cd_unit_hon_val                VARCHAR2(100) ;                                 -- XXCMN:�{
--  lv_prf_cd_unit_cs_val                 VARCHAR2(100) ;                                 -- XXCMN:CS
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
    
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
    lv_pram_op_3                VARCHAR2(100);
    lv_pram_op_4                VARCHAR2(100);
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    lv_pram_op_5                VARCHAR2(100);
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
    
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value                VARCHAR2(100);
    
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
                     ,iv_name         => cv_csm1_msg_00048                      -- ���b�Z�[�W�R�[�h
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
                     ,iv_name         => cv_csm1_msg_10015                      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_year                            -- �g�[�N���R�[�h1�i�Ώ۔N�x���́j
                     ,iv_token_value1 => gn_taisyoym                            -- �g�[�N���l1
                     );
                     
    -- LOG�ɏo��
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_pram_op_2  
                     );
                     
    -- �������(IN�p�����[�^�̏o��)
    lv_pram_op_3 := xxccp_common_pkg.get_msg(                                    -- ������ʂ̏o��
                      iv_application  => cv_xxcsm                                -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_10017                       -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_genka_cd                         -- �g�[�N���R�[�h1�i������ʁj
                     ,iv_token_value1 => gv_genkacd                              -- �g�[�N���l1
                     );
                     
    -- LOG�ɏo��
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_pram_op_3  
                     );
                     
    -- �K�w(IN�p�����[�^�̏o��)
    lv_pram_op_4 := xxccp_common_pkg.get_msg(                                   -- �K�w�̏o��
                      iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_10016                      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kaisou                          -- �g�[�N���R�[�h1�i�K�w�j
                     ,iv_token_value1 => gv_kaisou                              -- �g�[�N���l1
                     );
                     
    -- LOG�ɏo��
    fnd_file.put_line(
                      which  => FND_FILE.LOG
--//+UPD START E_�{�ғ�_09949 K.Taniguchi
--                   ,buff   => lv_pram_op_4 || CHR(10)
                     ,buff   => lv_pram_op_4
--//+UPD END E_�{�ғ�_09949 K.Taniguchi
                     );

--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    -- �V�������敪(IN�p�����[�^�̏o��)
    lv_pram_op_5 := xxccp_common_pkg.get_msg(                                   -- �K�w�̏o��
                      iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_10167                      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_new_old_cost_cls                -- �g�[�N���R�[�h1�i�V�������敪�j
                     ,iv_token_value1 => gv_new_old_cost_class                  -- �g�[�N���l1
                     );

    -- LOG�ɏo��
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_pram_op_5 || CHR(10)
                     );
--//+ADD END E_�{�ғ�_09949 K.Taniguchi

    -- ===========================================================================
    -- �v���t�@�C�����̎擾
    -- ===========================================================================
    -- �ϐ����������� 
    lv_tkn_value := NULL;
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
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
                    name => lv_prf_cd_sum
                   ,val  => lv_prf_cd_sum_val
                   ); -- ���i���v
    FND_PROFILE.GET(
                    name => lv_prf_cd_down_sales
                   ,val  => lv_prf_cd_down_sales_val
                   ); -- ����l��
    FND_PROFILE.GET(
                    name => lv_prf_cd_down_pay
                   ,val  => lv_prf_cd_down_pay_val
                   ); -- �����l��
    FND_PROFILE.GET(
                    name => lv_prf_cd_p_sum
                   ,val  => lv_prf_cd_p_sum_val
                   ); -- ���_�v
    FND_PROFILE.GET(
                    name => lv_prf_cd_team
                   ,val  => lv_prf_cd_team_val
                   ); -- �݌ɑg�D�R�[�h
    FND_PROFILE.GET(
                    name => lv_prf_cd_price_e
                   ,val  => lv_prf_cd_price_e_val
                   ); -- �c�ƌ���                     
    FND_PROFILE.GET(
                    name => lv_prf_cd_price_h
                   ,val  => lv_prf_cd_price_h_val
                   ); -- �W������
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    FND_PROFILE.GET(
                    name => cv_prf_gl_set_of_bks_id
                   ,val  => gv_prf_gl_set_of_bks_id
                   ); -- ��v����ID
    gn_prf_gl_set_of_bks_id := TO_NUMBER(gv_prf_gl_set_of_bks_id);
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--    FND_PROFILE.GET(
--                    name => lv_prf_cd_unit_hon
--                   ,val  => lv_prf_cd_unit_hon_val
--                   ); -- �P�ʁF�{
--    FND_PROFILE.GET(
--                    name => lv_prf_cd_unit_cs
--                   ,val  => lv_prf_cd_unit_cs_val
--                   ); -- �P�ʁFCS
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
    
    -- =========================================================================
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- =========================================================================
    -- ����
    IF (lv_prf_cd_sales_val IS NULL) THEN
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
        -- ���i���v
    ELSIF (lv_prf_cd_sum_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_sum;
        -- ����l��
    ELSIF (lv_prf_cd_down_sales_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_down_sales;
        -- �����l��
    ELSIF (lv_prf_cd_down_pay_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_down_pay;
        -- ���_�v
    ELSIF (lv_prf_cd_p_sum_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_p_sum;
        -- �݌ɑg�DID
    ELSIF (lv_prf_cd_team_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_team;
        -- �c�ƌ���
    ELSIF (lv_prf_cd_price_e_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_price_e;
        -- �W������
    ELSIF (lv_prf_cd_price_h_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_price_h;
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--        -- �P�ʁF�{
--    ELSIF (lv_prf_cd_unit_hon_val IS NULL) THEN
--      lv_tkn_value := lv_prf_cd_unit_hon;
--        -- �P�ʁFCS
--    ELSIF (lv_prf_cd_unit_cs_val IS NULL) THEN
--      lv_tkn_value := lv_prf_cd_unit_cs;
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
        -- ��v����ID
    ELSIF (gn_prf_gl_set_of_bks_id IS NULL) THEN
      lv_tkn_value := cv_prf_gl_set_of_bks_id;
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
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

    -- �݌ɑg�DID
   gv_org_id  := xxcoi_common_pkg.get_organization_id(lv_prf_cd_team_val);
   
   IF (gv_org_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm1_msg_00037                       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_org_code                         -- �g�[�N���R�[�h1�i�v���t�@�C���j
                    ,iv_token_value1 => lv_prf_cd_team_val                      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
   END IF;
   
    -- ������ʖ���
   IF (gv_genkacd = cn_bus_price) THEN
       gv_genkanm := lv_prf_cd_price_e_val; -- �c�ƌ���
   ELSIF (gv_genkacd = cn_base_price) THEN
       gv_genkanm := lv_prf_cd_price_h_val; -- �W������
   END IF;

--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    -- =====================
    -- �N�����̔N�x�J�n���擾
    -- =====================
    BEGIN
      -- �N�x�J�n��
      SELECT  gp.start_date             AS start_date             -- �N�x�J�n��
      INTO    gd_gl_start_date                                    -- �N�����̔N�x�J�n��
      FROM    gl_sets_of_books          gsob                      -- ��v����}�X�^
             ,gl_periods                gp                        -- ��v�J�����_
      WHERE   gsob.set_of_books_id      = gn_prf_gl_set_of_bks_id -- ��v����ID
      AND     gp.period_set_name        = gsob.period_set_name    -- �J�����_��
      AND     gp.period_year            = (
                                            -- �N�����̔N�x
                                            SELECT  gp2.period_year           AS period_year            -- �N�x
                                            FROM    gl_sets_of_books          gsob2                     -- ��v����}�X�^
                                                   ,gl_periods                gp2                       -- ��v�J�����_
                                            WHERE   gsob2.set_of_books_id     = gn_prf_gl_set_of_bks_id -- ��v����ID
                                            AND     gp2.period_set_name       = gsob2.period_set_name   -- �J�����_��
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
                                            AND     gp2.adjustment_period_flag = cv_flg_n               -- ������v���ԊO
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
                                            AND     gd_process_date           BETWEEN gp2.start_date    -- �Ɩ����t���_
                                                                              AND     gp2.end_date
                                          )
      AND     gp.adjustment_period_flag = cv_flg_n              -- ������v���ԊO
      AND     gp.period_num             = 1                     -- �N�x�J�n��
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_csm1_msg_10168
                      ,iv_token_name1  => cv_tkn_sobid
                      ,iv_token_value1 => TO_CHAR(gn_prf_gl_set_of_bks_id)       -- ��v����ID
                      ,iv_token_name2  => cv_tkn_process_date
                      ,iv_token_value2 => TO_CHAR(gd_process_date, 'YYYY/MM/DD') -- �Ɩ����t
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
--//+ADD START 2009/02/12 CT008 T.Tsukino
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--//+ADD END 2009/02/12 CT008 T.Tsukino
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
         iv_kyoten_cd   IN  VARCHAR2                     -- ���_�R�[�h
        ,ov_errbuf     OUT NOCOPY VARCHAR2               -- ���ʁE�G���[�E���b�Z�[�W
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
    -- �f�[�^���݃`�F�b�N�p
    ln_counts                 NUMBER(1,0) := 0;
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--    lb_loop_end               BOOLEAN     := FALSE;
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
--//+ADD START 2009/02/10 CT008 T.Tsukino
-- ===============================
-- ���[�J����O
-- ===============================
    location_check_expt     EXCEPTION;
--//+ADD END 2009/02/10 CT008 T.Tsukino
-- == 2010/04/26 V1.8 Deleted START ===============================================================
---- ============================================
----  �P�ʕϊ��}�X�^���̎擾�E�J�[�\��
---- ============================================
--    CURSOR   
--        get_unit_info_cur(
--                          iv_item_no      IN VARCHAR2                      -- ���i�R�[�h
--                          )
--    IS
--      SELECT   
--           mucc.from_unit_of_measure              AS  unit_from                -- ��P��(�{)
--      FROM     
--           mtl_system_items_b                     msib                         -- �i�ڃ}�X�^
--          ,mtl_uom_class_conversions              mucc                         -- �P�ʕϊ��}�X�^
--      WHERE    
--            mucc.inventory_item_id                 = msib.inventory_item_id    -- �i��ID
--      AND   msib.segment1                          = iv_item_no                -- ���i�R�[�h
--      AND   msib.organization_id                   = gv_org_id                 -- �݌ɑg�DID
--      AND   mucc.to_unit_of_measure                = lv_prf_cd_unit_cs_val     -- �ϊ���P��(CS)
--      ;
---- ============================================
----  ���i�R�[�h�̎擾�E�J�[�\��
---- ============================================
--    CURSOR   
--        get_item_cd_cur(
--                          iv_kyoten_cd      IN VARCHAR2                      -- ���_�R�[�h
--                          )
--    IS
--      SELECT 
--            xcgv.item_cd                          AS  item_cd                  -- �i�ڃR�[�h
--           ,xcgv.item_nm                          AS  item_nm                  -- �i�ږ���
--      FROM 
--           xxcsm_commodity_group4_v                xcgv                        -- ����Q�S�r���[
--      WHERE    
--        EXISTS (
--          SELECT
--              'X'
--          FROM
--               xxcsm_item_plan_lines                  xipl                         -- ���i�v�斾�׃e�[�u��
--              ,xxcsm_item_plan_headers                xiph                         -- ���i�v��w�b�_�e�[�u��
--          WHERE
--               xipl.item_plan_header_id              = xiph.item_plan_header_id   -- ���i�v��w�b�_ID
--          AND  xipl.item_no                          = xcgv.item_cd               -- ���i�R�[�h
--          AND  xiph.plan_year                        = gn_taisyoym                -- �Ώ۔N�x
--          AND  xiph.location_cd                      = iv_kyoten_cd               -- ���_�R�[�h
--          AND  xipl.item_kbn                         <> '0'                       -- ���i�敪(���i�Q�ȊO)
--        )
--      ;
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

    -- �N�ԏ��i�v��f�[�^���݃`�F�b�N

    SELECT
                  COUNT(1)
    INTO  
                  ln_counts
    FROM  
                   xxcsm_item_plan_lines xipl                            -- ���i�v��w�b�_�e�[�u��
                  ,xxcsm_item_plan_headers xiph                          -- ���i�v�斾�׃e�[�u��
    WHERE 
              xipl.item_plan_header_id      = xiph.item_plan_header_id   -- ���i�v��w�b�_ID
    AND       xiph.plan_year                = gn_taisyoym                -- �Ώ۔N�x
    AND       xiph.location_cd              = iv_kyoten_cd               -- ���_�R�[�h
    AND       ROWNUM                        = 1;                         -- 1�s��   

    -- ������0�̏ꍇ�A�������X�L�b�v���܂��B                                
    IF (ln_counts = 0) THEN
--//+UPD START 2009/02/10 CT008 T.Tsukino
--      ov_retcode := cv_status_warn;
--      RETURN;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm1_msg_00087                                           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_kyotencd                                             -- �g�[�N���R�[�h1�i���_�R�[�h�j
                    ,iv_token_value1 => iv_kyoten_cd                                                -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_year                                           -- �g�[�N���R�[�h2�i�Ώ۔N�x�j
                    ,iv_token_value2 => gn_taisyoym                                                 -- �g�[�N���l2
                    );
      RAISE location_check_expt;
--//+UPD END 2009/02/10 CT008 T.Tsukino
    END IF;

    -- �������σf�[�^���݃`�F�b�N
    ln_counts := 0;
    
    SELECT
              COUNT(1)
    INTO  
              ln_counts
    FROM  
               xxcsm_item_plan_lines xipl                         -- ���i�v��w�b�_�e�[�u��
              ,xxcsm_item_plan_headers xiph                       -- ���i�v�斾�׃e�[�u��         
    WHERE 
              xipl.item_plan_header_id    = xiph.item_plan_header_id   -- ���i�v��w�b�_ID
    AND       xiph.plan_year              = gn_taisyoym                -- �Ώ۔N�x
    AND       xiph.location_cd            = iv_kyoten_cd               -- ���_�R�[�h
    AND       xipl.item_kbn               <> '0'                       -- ���i�Q�ȊO
    AND       ROWNUM                      = 1;                         -- 1�s��   
    -- ������0�̏ꍇ�A�������X�L�b�v���܂��B                                
    IF (ln_counts = 0) THEN
--//+UPD START 2009/02/10 CT008 T.Tsukino
--      ov_retcode := cv_status_warn;
--      RETURN;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm1_msg_00088                                           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_kyotencd                                             -- �g�[�N���R�[�h1�i���_�R�[�h�j
                    ,iv_token_value1 => iv_kyoten_cd                                                -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_year                                           -- �g�[�N���R�[�h2�i�Ώ۔N�x�j
                    ,iv_token_value2 => gn_taisyoym                                                 -- �g�[�N���l2
                    );
      RAISE location_check_expt;
--//+UPD END 2009/02/10 CT008 T.Tsukino
    END IF;
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--    -- �P�ʕϊ��}�X�^�ł̃`�F�b�N����
--    <<get_item_cd_cur_loop>>
--    FOR rec_item_cd IN get_item_cd_cur(iv_kyoten_cd) LOOP
--        
--        <<get_unit_info_cur_loop>>
--        FOR rec_unit_info IN get_unit_info_cur(rec_item_cd.item_cd) LOOP
--            lb_loop_end := TRUE;
--            
--            -- ��P�ʂ̔��f(����F�{ �ُ�F�{�ȊO)
--            IF ((rec_unit_info.unit_from IS NULL) OR (rec_unit_info.unit_from <> lv_prf_cd_unit_hon_val)) THEN
--                lv_errmsg := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_xxcsm                    -- �A�v���P�[�V�����Z�k��
--                            ,iv_name         => cv_csm1_msg_10133          -- ���b�Z�[�W�R�[�h
--                            ,iv_token_name1  => cv_tkn_kyotencd            -- �g�[�N���R�[�h1�i���_�R�[�h�j
--                            ,iv_token_value1 => iv_kyoten_cd               -- �g�[�N���l1
--                            ,iv_token_name2  => cv_tkn_item_cd             -- �g�[�N���R�[�h2�i���i�R�[�h�j
--                            ,iv_token_value2 => rec_item_cd.item_cd        -- �g�[�N���l1
--                            ,iv_token_name3  => cv_tkn_item_nm             -- �g�[�N���R�[�h3�i���i���́j
--                            ,iv_token_value3 => rec_item_cd.item_nm        -- �g�[�N���l2
--                );
--                -- LOG�ɏo��
--                fnd_file.put_line(
--                                  which  => FND_FILE.LOG
--                                 ,buff   => lv_errmsg || CHR(10)
--                                 );
--            END IF;
--        END LOOP get_unit_info_cur_loop;
--        
--        -- �P�ʕϊ��}�X�^�ɑ��݂��Ȃ��ꍇ
--        IF (lb_loop_end = FALSE) THEN
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_xxcsm                    -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_csm1_msg_10131          -- ���b�Z�[�W�R�[�h
--                        ,iv_token_name1  => cv_tkn_kyotencd            -- �g�[�N���R�[�h1�i���_�R�[�h�j
--                        ,iv_token_value1 => iv_kyoten_cd               -- �g�[�N���l1
--                        ,iv_token_name2  => cv_tkn_item_cd             -- �g�[�N���R�[�h2�i���i�R�[�h�j
--                        ,iv_token_value2 => rec_item_cd.item_cd        -- �g�[�N���l1
--                        ,iv_token_name3  => cv_tkn_item_nm             -- �g�[�N���R�[�h3�i���i���́j
--                        ,iv_token_value3 => rec_item_cd.item_nm        -- �g�[�N���l2
--            );
--            -- LOG�ɏo��
--            fnd_file.put_line(
--                              which  => FND_FILE.LOG
--                             ,buff   => lv_errmsg || CHR(10)
--                             );
--        END IF;
--        
--        lb_loop_end := FALSE;
--        
--    END LOOP get_unit_info_cur_loop;    
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
--
--//+ADD START 2009/02/10 CT008 T.Tsukino
  EXCEPTION
    WHEN location_check_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--//+ADD END 2009/02/10 CT008 T.Tsukino
--
--#################################  �Œ��O������  #############################
--
--//+DEL START 2009/02/10 CT008 T.Tsukino
--  EXCEPTION
--//+DEL START 2009/02/10 CT008 T.Tsukino
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--      -- ================================================
--      -- �J�[�\���̃N���[�Y
--      -- ================================================
--
--      IF (get_item_cd_cur%ISOPEN) THEN
--        CLOSE get_item_cd_cur;
--      END IF;
--      
--      IF (get_unit_info_cur%ISOPEN) THEN
--        CLOSE get_unit_info_cur;
--      END IF;
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
-- == 2010/04/26 V1.8 Deleted START ===============================================================
--      -- ================================================
--      -- �J�[�\���̃N���[�Y
--      -- ================================================
--
--      IF (get_item_cd_cur%ISOPEN) THEN
--        CLOSE get_item_cd_cur;
--      END IF;
--      
--      IF (get_unit_info_cur%ISOPEN) THEN
--        CLOSE get_unit_info_cur;
--      END IF;
-- == 2010/04/26 V1.8 Deleted END   ===============================================================
--
--#####################################  �Œ蕔 END   ###########################
--
  END do_check;
--
   /****************************************************************************
   * Procedure Name   : deal_group4_data
   * Description      : ���i�Q�f�[�^�̏ڍ׏���
   *                    �@�f�[�^�̒��o
   *                    �A�f�[�^�̎Z�o
   *                    �B�f�[�^�̓o�^
   ****************************************************************************/
   PROCEDURE deal_group4_data(
         iv_group4_cd   IN  VARCHAR2                      --���i�Q�R�[�h
        ,ov_errbuf      OUT NOCOPY VARCHAR2               --���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode     OUT NOCOPY VARCHAR2               --���^�[���E�R�[�h
        ,ov_errmsg      OUT NOCOPY VARCHAR2)              --���[�U�[�E�G���[�E���b�Z�[�W
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_group4_data';      -- �v���O������

    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    ln_y_sales              NUMBER  := 0;               --�N��_������z���v
    ln_y_margin             NUMBER  := 0;               --�N��_�e���v�z���v
    ln_y_amount             NUMBER  := 0;               --�N��_���ʍ��v
    ln_y_psa                NUMBER  := 0;               --�N��_����*�艿�̍��v
    ln_y_bsa                NUMBER  := 0;               --�N��_����*�����̍��v
    ln_y_rate               NUMBER  := 0;               --�N��_�|��
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP���f�p
--//+ADD START 2009/02/16 CT020 S.Son
    ln_m_rate               NUMBER  := 0;               --����_�|��
--//+ADD END 2009/02/16 CT020 S.Son
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--============================================
--  �f�[�^�̒��o�y���i�Q�z���[�J���E�J�[�\��
--============================================
--                  
    CURSOR   
        get_group4_data_cur
    IS
      SELECT   
             xwspc.group_cd_1                                 AS  group_cd_1                -- ���i�Q�R�[�h(1��)
            ,xwspc.group_nm_1                                 AS  group_nm_1                -- ���i�Q����(1��)
            ,xwspc.group_cd_4                                 AS  group_cd_4                -- ���i�Q�R�[�h(4��)
            ,xwspc.group_nm_4                                 AS  group_nm_4                -- ���i�Q����(4��)
            ,xwspc.month_no                                   AS  month                     -- ��
            ,SUM(NVL(xwspc.m_amount,0))                       AS  amount                    -- ����
            ,SUM(NVL(xwspc.m_sales,0))                        AS  sales                     -- ������z
            ,SUM(NVL(xwspc.t_price,0))                        AS  t_price                   -- ����*�艿
            ,SUM(NVL(xwspc.g_price,0))                        AS  g_price                   -- ����*����
      FROM     
            xxcsm_tmp_sales_plan_cs    xwspc                -- ���i�v�惊�X�g�o�̓��[�N�e�[�u��
      WHERE    
            xwspc.group_cd_4                                  = iv_group4_cd               -- ���i�Q�R�[�h(4��)
      GROUP BY
               xwspc.group_cd_1                                                            -- ���i�Q�R�[�h(1��)
              ,xwspc.group_cd_4                                                            -- ���i�Q�R�[�h(4��)
              ,xwspc.group_nm_1                                                            -- ���i�Q����(1��)
              ,xwspc.group_nm_4                                                            -- ���i�Q����(4��)
              ,xwspc.month_no                                                              -- ��
      ORDER BY 
               group_cd_1  ASC
               ,month       ASC
;
--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    
    <<get_group4_data_loop>>
    -- �y���i�Q�z�f�[�^�擾
    FOR rec_group4 IN get_group4_data_cur LOOP
        
        lb_loop_end     := TRUE;
        
        -- =======================================
        -- �N�ԗ݌v�y���Z�z
        -- =======================================
        
        -- �N�Ԕ���
        ln_y_sales      := ln_y_sales + rec_group4.sales;
        
        -- �N�Ԑ���(CS)
        ln_y_amount     := ln_y_amount + rec_group4.amount ;
        
        ln_y_psa        := ln_y_psa + rec_group4.t_price;
        
        ln_y_bsa        := ln_y_bsa + rec_group4.g_price;
--//+ADD START 2009/02/16 CT020 S.Son
        --���ʊ|���Z�o
        IF (rec_group4.t_price = 0) THEN
          ln_m_rate := 0;
        ELSE
          ln_m_rate := ROUND(rec_group4.sales / rec_group4.t_price * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
            
        --===================================
        -- �y���i�Q-���ԁz�f�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_cs
          (
              toroku_no        --�o�͏�
              ,group_cd_1      --���i�Q�R�[�h(1��)
              ,group_nm_1      --���i�Q����(1��)
              ,group_cd_4      --���i�Q�R�[�h(4��)
              ,group_nm_4      --���i�Q����(1��)
              ,item_cd         --���i�R�[�h
              ,item_nm         --���i����
              ,month_no        --��
              ,m_sales         --����_����
              ,m_amount        --����_����
              ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
              ,m_margin        --����_�e���v�z
              ,t_price         -- �艿������
              ,g_price         -- ����������
          )
          VALUES (
               gn_index
              ,rec_group4.group_cd_1
              ,rec_group4.group_nm_1
              ,NULL
              ,NULL
              ,rec_group4.group_cd_4
              ,rec_group4.group_nm_4
              ,rec_group4.month
              ,rec_group4.sales
              ,rec_group4.amount 
--//+UPD START 2009/02/16 CT020 S.Son
--            ,ROUND(rec_group4.sales / rec_group4.t_price * 100,2)
              ,ln_m_rate
--//+UPD END 2009/02/16 CT020 S.Son
              ,rec_group4.sales - rec_group4.g_price
              ,rec_group4.t_price
              ,rec_group4.g_price
          );
        -- �o�^���̉��Z
        gn_index := gn_index + 1;
          
    END LOOP get_group4_data_loop;
    
    -- �y���i�Q�z�N�ԃf�[�^�̓o�^
    IF (lb_loop_end) THEN
        
        -- �N�ԑe���v�z
        ln_y_margin     := ln_y_sales - ln_y_bsa;
        
        -- �N��_�|���y�Z�o�����z:�N��_���぀(�N�Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+ADD START 2009/02/16 CT020 S.Son
        IF (ln_y_psa = 0) THEN
          ln_y_rate   := 0;
        ELSE
          ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
        -- �X�V����
        UPDATE
                xxcsm_tmp_sales_plan_cs
        SET
               y_sales          = ln_y_sales      -- �N�Ԕ���
              ,y_amount         = ln_y_amount     -- �N�Ԑ���
              ,y_rate           = ln_y_rate       -- �N�Ԋ|��
              ,y_margin         = ln_y_margin     -- �N�ԑe���v�z
        WHERE
               item_cd          = iv_group4_cd;   -- ���i�R�[�h

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
      IF (get_group4_data_cur%ISOPEN) THEN
        CLOSE get_group4_data_cur;
      END IF;
      

    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_group4_data_cur%ISOPEN) THEN
        CLOSE get_group4_data_cur;
      END IF;
      
--
--#####################################  �Œ蕔 END   ###########################
--
  END deal_group4_data;
--
  /*****************************************************************************
   * Procedure Name   : deal_group1_data
   * Description      : �y���i�敪�z�f�[�^�̏ڍ׏���
   ****************************************************************************/
  PROCEDURE deal_group1_data(
        iv_group1_cd    IN  VARCHAR2          -- ���i�敪�R�[�h
       ,ov_errbuf       OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
       ,ov_retcode      OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
       ,ov_errmsg       OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W
        
  IS
  
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_group1_data';      -- �v���O������
    
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    ln_y_sales              NUMBER  := 0;               --�N��_������z���v
    ln_y_margin             NUMBER  := 0;               --�N��_�e���v�z���v
    ln_y_amount             NUMBER  := 0;               --�N��_���ʍ��v
    ln_y_psa                NUMBER  := 0;               --�N��_����*�艿�̍��v
    ln_y_bsa                NUMBER  := 0;               --�N��_����*�����̍��v
    ln_y_rate               NUMBER  := 0;               --�N��_�|��
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP���f�p
--//+ADD START 2009/02/16 CT020 S.Son
    ln_m_rate               NUMBER  := 0;               --����_�|��
--//+ADD END 2009/02/16 CT020 S.Son
    
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--============================================
--  �f�[�^�̒��o�y���i�敪�z�J�[�\��
--============================================
--                  
    CURSOR   
        get_group1_data_cur
    IS
      SELECT   
             group_cd_1                                 AS  group_cd_1                -- ���i�Q�R�[�h(1��)
            ,group_nm_1                                 AS  group_nm_1                -- ���i�Q����(1��)
            ,month_no                                   AS  month                     -- ��
            ,SUM(NVL(m_amount,0))                       AS  amount                    -- ����
            ,SUM(NVL(m_sales,0))                        AS  sales                     -- ������z
            ,SUM(NVL(t_price,0))                        AS  t_price                   -- ����*�艿
            ,SUM(NVL(g_price,0))                        AS  g_price                   -- ����*����
      FROM     
            xxcsm_tmp_sales_plan_cs                      -- ���i�v�惊�X�g�o�̓��[�N�e�[�u��
      WHERE    
            group_cd_4                                  IS NULL                      -- ���i�Q�R�[�h(1��)
      AND   group_cd_1                                  = iv_group1_cd               -- ���i�Q�R�[�h(1��)
      GROUP BY
               group_cd_1                                                            -- ���i�Q�R�[�h(1��)
              ,group_nm_1                                                            -- ���i�Q�R�[�h(1��)
              ,month_no                                                              -- ��
      ORDER BY 
               month_no    ASC;

--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    
    <<get_group1_data_loop>>
    -- �y���i�敪�z�f�[�^�擾
    FOR rec_group1 IN get_group1_data_cur LOOP
        
        lb_loop_end     := TRUE;
        
        -- =======================================
        -- �N�ԗ݌v�y���Z�z
        -- =======================================
        
        -- �N�Ԕ���
        ln_y_sales      := ln_y_sales + rec_group1.sales;
        
        -- �N�Ԑ���(CS)
        ln_y_amount     := ln_y_amount + rec_group1.amount ;
        
        ln_y_psa        := ln_y_psa + rec_group1.t_price;
        
        ln_y_bsa        := ln_y_bsa + rec_group1.g_price;
--//+ADD START 2009/02/16 CT020 S.Son
        --���ʊ|���̎Z�o
        IF (rec_group1.t_price = 0) THEN
          ln_m_rate := 0;
        ELSE
          ln_m_rate := ROUND(rec_group1.sales / rec_group1.t_price * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
            
        --===================================
        -- �y���i�敪�z���ԃf�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_cs
          (
              toroku_no        --�o�͏�
              ,group_cd_1      --���i�Q�R�[�h(1��)
              ,group_nm_1      --���i�Q����(1��)
              ,group_cd_4      --���i�Q�R�[�h(4��)
              ,group_nm_4      --���i�Q����(1��)
              ,item_cd         --���i�R�[�h
              ,item_nm         --���i����
              ,month_no        --��
              ,m_sales         --����_����
              ,m_amount        --����_����
              ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
              ,m_margin        --����_�e���v�z
              ,t_price         -- �艿������
              ,g_price         -- ����������
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,rec_group1.group_cd_1
              ,rec_group1.group_nm_1
              ,rec_group1.month
              ,rec_group1.sales
              ,rec_group1.amount 
--//+UPD START 2009/02/16 CT020 S.Son
--            ,ROUND(rec_group1.sales / rec_group1.t_price * 100,2)
              ,ln_m_rate
--//+UPD END 2009/02/16 CT020 S.Son
              ,rec_group1.sales - rec_group1.g_price
              ,rec_group1.t_price
              ,rec_group1.g_price
          );
        -- �o�^���̉��Z
        gn_index := gn_index + 1;
          
    END LOOP get_group1_data_loop;
    
    -- �y���i�敪�z�N�ԃf�[�^�̓o�^
    IF (lb_loop_end) THEN
        
        -- �N�ԑe���v�z
        ln_y_margin     := ln_y_sales - ln_y_bsa;
        
        -- �N��_�|���y�Z�o�����z:�N��_���぀(�N�Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+ADD START 2009/02/16 CT020 S.Son
        IF (ln_y_psa = 0) THEN
          ln_y_rate   := 0;
        ELSE
          ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
        -- �X�V����
        UPDATE
                xxcsm_tmp_sales_plan_cs
        SET
               y_sales          = ln_y_sales     -- �N�Ԕ���
              ,y_amount         = ln_y_amount    -- �N�Ԑ���
              ,y_rate           = ln_y_rate      -- �N�Ԋ|��
              ,y_margin         = ln_y_margin    -- �N�ԑe���v�z
        WHERE
               item_cd          = iv_group1_cd;  -- ���i�敪�R�[�h

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
      IF (get_group1_data_cur%ISOPEN) THEN
        CLOSE get_group1_data_cur;
      END IF;
      

    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_group1_data_cur%ISOPEN) THEN
        CLOSE get_group1_data_cur;
      END IF;
      
--
--#####################################  �Œ蕔 END   ###########################
--
  END deal_group1_data;
--
  
    
   /*****************************************************************************
   * Procedure Name   : deal_sum_data
   * Description      : �y���i���v�z�f�[�^�̏ڍ׏���
   ****************************************************************************/
  PROCEDURE deal_sum_data(
            ov_errbuf     OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
           ,ov_retcode    OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
           ,ov_errmsg     OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_sum_data';      -- �v���O������
    
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    ln_y_sales              NUMBER  := 0;               --�N��_������z���v
    ln_y_margin             NUMBER  := 0;               --�N��_�e���v�z���v
    ln_y_amount             NUMBER  := 0;               --�N��_���ʍ��v
    ln_y_psa                NUMBER  := 0;               --�N��_����*�艿�̍��v
    ln_y_bsa                NUMBER  := 0;               --�N��_����*�����̍��v
    ln_y_rate               NUMBER  := 0;               --�N��_�|��
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP���f�p
--//+ADD START 2009/02/16 CT020 S.Son
    ln_m_rate               NUMBER  := 0;               --����_�|��
--//+ADD END 2009/02/16 CT020 S.Son
    
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--============================================
--  �f�[�^�̒��o�y���i���v�z���[�J���E�J�[�\��
--============================================
--                  
    CURSOR   
        get_sum_data_cur
    IS
      SELECT   
             month_no                                   AS  month                     -- ��
            ,SUM(NVL(m_amount,0))                       AS  amount                    -- ����
            ,SUM(NVL(m_sales,0))                        AS  sales                     -- ������z
            ,SUM(NVL(t_price,0))                        AS  t_price                   -- ����*�艿
            ,SUM(NVL(g_price,0))                        AS  g_price                   -- ����*����
      FROM     
            xxcsm_tmp_sales_plan_cs                      -- ���i�v�惊�X�g�o�̓��[�N�e�[�u��
      WHERE    
            item_cd                                     IN ( 'A','C' )           -- ���i�Q(A+C)
      GROUP BY
            month_no                                                                  -- ��
      ORDER BY 
            month_no    ASC;


--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    
    <<get_sum_data_loop>>
    -- �y���i���v�z�f�[�^�擾
    FOR rec_sum IN get_sum_data_cur LOOP
        
        lb_loop_end     := TRUE;
        
        -- =======================================
        -- �N�ԗ݌v�y���Z�z
        -- =======================================
        
        -- �N�Ԕ���
        ln_y_sales      := ln_y_sales + rec_sum.sales;
        
        -- �N�Ԑ���(CS)
        ln_y_amount     := ln_y_amount + rec_sum.amount ;
        
        ln_y_psa        := ln_y_psa + rec_sum.t_price;
        
        ln_y_bsa        := ln_y_bsa + rec_sum.g_price;
--//+ADD START 2009/02/16 CT020 S.Son
        --���ʊ|���̎Z�o
        IF (rec_sum.t_price = 0) THEN
          ln_m_rate := 0;
        ELSE
          ln_m_rate := ROUND(rec_sum.sales / rec_sum.t_price * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
            
        --===================================
        -- �y���i���v�z���ԃf�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_cs
          (
              toroku_no        --�o�͏�
              ,group_cd_1      --���i�Q�R�[�h(1��)
              ,group_nm_1      --���i�Q����(1��)
              ,group_cd_4      --���i�Q�R�[�h(4��)
              ,group_nm_4      --���i�Q����(1��)
              ,item_cd         --���i�R�[�h
              ,item_nm         --���i����
              ,month_no        --��
              ,m_sales         --����_����
              ,m_amount        --����_����
              ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
              ,m_margin        --����_�e���v�z
              ,t_price         -- �艿������
              ,g_price         -- ����������
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,lv_prf_cd_sum_val
              ,rec_sum.month
              ,rec_sum.sales
              ,rec_sum.amount
--//+UPD START 2009/02/16 CT020 S.Son
--            ,ROUND(rec_sum.sales / rec_sum.t_price * 100,2)
              ,ln_m_rate
--//+UPD END 2009/02/16 CT020 S.Son
              ,rec_sum.sales - rec_sum.g_price
              ,rec_sum.t_price
              ,rec_sum.g_price
          );
        -- �o�^���̉��Z
        gn_index := gn_index + 1;
          
    END LOOP get_sum_data_loop;
    
    -- �y���i���v�z�N�ԃf�[�^�̓o�^
    IF (lb_loop_end) THEN
        -- �N�ԑe���v�z
        ln_y_margin     := ln_y_sales - ln_y_bsa;
        
        -- �N��_�|���y�Z�o�����z:�N��_���぀(�N�Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+ADD START 2009/02/16 CT020 S.Son
        IF (ln_y_psa = 0) THEN
          ln_y_rate   := 0;
        ELSE
          ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
        
        -- �X�V����
        UPDATE
                xxcsm_tmp_sales_plan_cs
        SET
               y_sales          = ln_y_sales          -- �N�Ԕ���
              ,y_amount         = ln_y_amount         -- �N�Ԑ���
              ,y_rate           = ln_y_rate           -- �N�Ԋ|��
              ,y_margin         = ln_y_margin         -- �N�ԑe���v�z
        WHERE
               item_nm          = lv_prf_cd_sum_val;  -- ���i���́F���i���v

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
      IF (get_sum_data_cur%ISOPEN) THEN
        CLOSE get_sum_data_cur;
      END IF;
      

    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_sum_data_cur%ISOPEN) THEN
        CLOSE get_sum_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--  
  END deal_sum_data;
--

   /*****************************************************************************
   * Procedure Name   : deal_down_data
   * Description      : �y����l���E�����l���z�f�[�^�̏ڍ׏���
   ****************************************************************************/
  PROCEDURE deal_down_data(
        iv_kyoten_cd    IN  VARCHAR2            -- ���_�R�[�h
       ,ov_errbuf       OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W
       ,ov_retcode      OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h
       ,ov_errmsg       OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_down_data';      -- �v���O������
    
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    ln_y_sales_d            NUMBER  := 0;               --�N��_����l�����v
    ln_y_sales_p            NUMBER  := 0;               --�N��_�����l�����v
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
--  �f�[�^�̒��o�y����l���E�����l���z���[�J���E�J�[�\��
--============================================
--                  
    CURSOR   
        get_down_data_cur
    IS
      SELECT   
             xiplb.month_no                                   AS  month                     -- ��
            ,SUM(NVL(xiplb.sales_discount,0))                 AS  sales_d                   -- ����l��
            ,SUM(NVL(xiplb.receipt_discount,0))               AS  receipt_d                 -- �����l��
      FROM     
            xxcsm_item_plan_loc_bdgt                        xiplb                          -- ���i�v�拒�_�ʗ\�Z�e�[�u��
            ,xxcsm_item_plan_headers                        xiph                           -- ���i�v��w�b�_�e�[�u��
      WHERE    
            xiplb.item_plan_header_id                        = xiph.item_plan_header_id    -- ���i�v��w�b�_ID
      AND   xiph.plan_year                                   = gn_taisyoym                 -- �Ώ۔N�x
      AND   xiph.location_cd                                 = iv_kyoten_cd                -- ���_�R�[�h
      AND   EXISTS (
                    SELECT   
                         'X'
                    FROM     
                         xxcsm_item_plan_lines               xipl                            -- ���i�v�斾�׃e�[�u��
                    WHERE                           
                        xipl.item_plan_header_id             = xiplb.item_plan_header_id     -- ���i�v��w�b�_ID
                    AND xipl.item_kbn                         <> '0'                         -- ���i�敪
                   )
      GROUP BY
            month_no                                        -- ��
      ORDER BY 
            month_no    ASC;


--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    
    <<get_down_data_loop>>
    -- �y����l���E�����l���z�f�[�^�擾
    FOR rec_down IN get_down_data_cur LOOP
        
        lb_loop_end     := TRUE;
        
        -- =======================================
        -- �N�ԗ݌v�y���Z�z
        -- =======================================
        
        -- �N��_����l��
        ln_y_sales_d      := ln_y_sales_d + rec_down.sales_d;
        
        
        -- �N��_�����l��
        ln_y_sales_p     := ln_y_sales_p + rec_down.receipt_d;
            
        --===================================
        -- �y����l���z���ԃf�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_cs
          (
              toroku_no        --�o�͏�
              ,group_cd_1      --���i�Q�R�[�h(1��)
              ,group_nm_1      --���i�Q����(1��)
              ,group_cd_4      --���i�Q�R�[�h(4��)
              ,group_nm_4      --���i�Q����(1��)
              ,item_cd         --���i�R�[�h
              ,item_nm         --���i����
              ,month_no        --��
              ,m_sales         --����_����
              ,m_amount        --����_����
              ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
              ,m_margin        --����_�e���v�z
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,'N'
              ,lv_prf_cd_down_sales_val
              ,rec_down.month
              ,rec_down.sales_d
              ,0
              ,0
              ,rec_down.sales_d
          );
          
        -- �o�^���̉��Z
        gn_index := gn_index + 1;

        --===================================
        -- �y�����l���z���ԃf�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_cs
          (
              toroku_no        --�o�͏�
              ,group_cd_1      --���i�Q�R�[�h(1��)
              ,group_nm_1      --���i�Q����(1��)
              ,group_cd_4      --���i�Q�R�[�h(4��)
              ,group_nm_4      --���i�Q����(1��)
              ,item_cd         --���i�R�[�h
              ,item_nm         --���i����
              ,month_no        --��
              ,m_sales         --����_����
              ,m_amount        --����_����
              ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
              ,m_margin        --����_�e���v�z
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,'N'
              ,lv_prf_cd_down_pay_val
              ,rec_down.month
              ,rec_down.receipt_d
              ,0
              ,0
              ,rec_down.receipt_d
          );
          
        -- �o�^���̉��Z
        gn_index := gn_index + 1;
          
    END LOOP get_down_data_loop;
    
    -- �N�ԃf�[�^�̓o�^
    IF (lb_loop_end) THEN
        
        -- �N��_����l��
        UPDATE
                xxcsm_tmp_sales_plan_cs
        SET
               y_sales          = ln_y_sales_d                                -- �N�Ԕ���
              ,y_margin         = ln_y_sales_d                                -- �N�ԑe���v�z

        WHERE
               item_nm          = lv_prf_cd_down_sales_val;                   -- ���i���́F����l��
               
        -- �N��_�����l��
        UPDATE
                xxcsm_tmp_sales_plan_cs
        SET
--//+UPD START 2009/02/23 CT056 N.Izumi
--               y_sales          = ln_y_sales_d                                -- �N�Ԕ���
--              ,y_margin         = ln_y_sales_d                                -- �N�ԑe���v�z
               y_sales          = ln_y_sales_p                                -- �N�Ԕ���
              ,y_margin         = ln_y_sales_p                                -- �N�ԑe���v�z
--//+UPD END   2009/02/23 CT056 N.Izumi

        WHERE
               item_nm          = lv_prf_cd_down_pay_val;                     -- ���i���́F�����l��
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
      IF (get_down_data_cur%ISOPEN) THEN
        CLOSE get_down_data_cur;
      END IF;
      
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_down_data_cur%ISOPEN) THEN
        CLOSE get_down_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--  
  END deal_down_data;
--  
   /*****************************************************************************
   * Procedure Name   : deal_kyoten_data
   * Description      : �y���_�v�z�f�[�^�̏ڍ׏���
   ****************************************************************************/
  PROCEDURE deal_kyoten_data(
            ov_errbuf     OUT NOCOPY VARCHAR2                                   -- �G���[�E���b�Z�[�W
           ,ov_retcode    OUT NOCOPY VARCHAR2                                   -- ���^�[���E�R�[�h
           ,ov_errmsg     OUT NOCOPY VARCHAR2)                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_kyoten_data';      -- �v���O������
    
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    ln_y_sales              NUMBER  := 0;               --�N��_������z���v
    ln_y_margin             NUMBER  := 0;               --�N��_�e���v�z���v
    ln_y_amount             NUMBER  := 0;               --�N��_���ʍ��v
    ln_y_rate               NUMBER  := 0;               --�N��_�|��
    ln_y_bsa                NUMBER  := 0;               --�N��_����*�����̍��v
    ln_y_psa                NUMBER  := 0;               --�N��_����*�艿�̍��v
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP���f�p
--//+ADD START 2009/02/16 CT020 S.Son
    ln_m_rate               NUMBER  := 0;               --����_�|��
--//+ADD END 2009/02/16 CT020 S.Son
    
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--============================================
--  �f�[�^�̒��o�y���_�v�z���[�J���E�J�[�\��
--============================================
--                  
    CURSOR   
        get_kyoten_data_cur
    IS
      SELECT   
             month_no                                   AS  month                     -- ��
            ,SUM(NVL(m_amount,0))                       AS  amount                    -- ����
            ,SUM(NVL(m_sales,0))                        AS  sales                     -- ������z
            ,SUM(NVL(t_price,0))                        AS  t_price                   -- ����*�艿
            ,SUM(NVL(g_price,0))                        AS  g_price                   -- ����*����
      FROM     
            xxcsm_tmp_sales_plan_cs                      -- ���i�v�惊�X�g�o�̓��[�N�e�[�u��
      WHERE    
            item_cd                                     IN ( 'A','C','D','N' )        -- ���i�Q(A+C+D+N)
      GROUP BY
            month_no                                                                  -- ��
      ORDER BY 
            month_no    ASC;


--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    
    <<get_kyoten_data_loop>>
    -- �y���_�v�z�f�[�^�擾
    FOR rec_kyoten IN get_kyoten_data_cur LOOP
        
        lb_loop_end     := TRUE;
        
        -- =======================================
        -- �N�ԗ݌v�y���Z�z
        -- =======================================
        
        -- �N�Ԕ���
        ln_y_sales      := ln_y_sales + rec_kyoten.sales;
        
        -- �N�Ԑ���(CS)
        ln_y_amount     := ln_y_amount + rec_kyoten.amount;
        
        ln_y_psa        := ln_y_psa + rec_kyoten.t_price;
        
        ln_y_bsa        := ln_y_bsa + rec_kyoten.g_price;
--//+ADD START 2009/02/16 CT020 S.Son
        --���ʊ|���̎Z�o
        IF (rec_kyoten.t_price = 0) THEN
          ln_m_rate := 0;
        ELSE
          ln_m_rate := ROUND(rec_kyoten.sales / rec_kyoten.t_price * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
            
        --===================================
        -- �y���_�v�z���ԃf�[�^�̓o�^
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_cs
          (
              toroku_no        --�o�͏�
              ,group_cd_1      --���i�Q�R�[�h(1��)
              ,group_nm_1      --���i�Q����(1��)
              ,group_cd_4      --���i�Q�R�[�h(4��)
              ,group_nm_4      --���i�Q����(1��)
              ,item_cd         --���i�R�[�h
              ,item_nm         --���i����
              ,month_no        --��
              ,m_sales         --����_����
              ,m_amount        --����_����
              ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
              ,m_margin        --����_�e���v�z
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,lv_prf_cd_p_sum_val
              ,rec_kyoten.month
              ,rec_kyoten.sales
              ,rec_kyoten.amount 
--//+UPD START 2009/02/16 CT020 S.Son
--            ,ROUND(rec_kyoten.sales / rec_kyoten.t_price * 100,2)
              ,ln_m_rate
--//+UPD END 2009/02/16 CT020 S.Son
              ,rec_kyoten.sales - rec_kyoten.g_price
          );
        -- �o�^���̉��Z
        gn_index := gn_index + 1;
          
    END LOOP get_kyoten_data_loop;
    
    -- �y���_�v�z�N�ԃf�[�^�̓o�^
    IF (lb_loop_end) THEN
        -- �N�ԑe���v�z
        ln_y_margin     := ln_y_sales - ln_y_bsa;
        
        -- �N��_�|���y�Z�o�����z:�N��_���぀(�N�Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+ADD START 2009/02/16 CT020 S.Son
        IF (ln_y_psa = 0) THEN
          ln_y_rate   := 0;
        ELSE
          ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
        
        UPDATE
                xxcsm_tmp_sales_plan_cs
        SET
               y_sales          = ln_y_sales             -- �N�Ԕ���
              ,y_amount         = ln_y_amount            -- �N�Ԑ���
              ,y_rate           = ln_y_rate              -- �N�Ԋ|��
              ,y_margin         = ln_y_margin            -- �N�ԑe���v�z

        WHERE
               item_nm          = lv_prf_cd_p_sum_val;   -- ���i���́F���_�v

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
      IF (get_kyoten_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_data_cur;
      END IF;
      

    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- �J�[�\���̃N���[�Y
      -- ================================================

      IF (get_kyoten_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_data_cur;
      END IF;  
--
--#####################################  �Œ蕔 END   ###########################
-- 
  END deal_kyoten_data;
--  
   /****************************************************************************
   * Procedure Name   : deal_item_data
   * Description      : �y���i�z�f�[�^�̏ڍ׏���
   *****************************************************************************/
   PROCEDURE deal_item_data(
         iv_kyoten_cd      IN  VARCHAR2                      --���_�R�[�h
        ,ov_errbuf         OUT NOCOPY VARCHAR2               --���ʁE�G���[�E���b�Z�[�W
        ,ov_retcode        OUT NOCOPY VARCHAR2               --���^�[���E�R�[�h
        ,ov_errmsg         OUT NOCOPY VARCHAR2)              --���[�U�[�E�G���[�E���b�Z�[�W
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_item_data';        -- �v���O������
--//+ADD START 2010/12/17 E_�{�ғ�_05803 Y.Kanami
    cn_value_1              CONSTANT NUMBER := 1;                               -- ����1 
--//+ADD END 2010/12/17 E_�{�ғ�_05803 Y.Kanami
    
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_item_cd              VARCHAR2(10);               -- �i�ڃR�[�h
    lv_group_cd_1           VARCHAR2(10);               -- ���i�Q�R�[�h(1��)
    lv_group_cd_4           VARCHAR2(10);               -- ���i�Q�R�[�h(4��)
    ln_y_sales              NUMBER  := 0;               -- �N��_������z���v
    ln_y_margin             NUMBER  := 0;               -- �N��_�e���v�z���v
    ln_y_amount             NUMBER  := 0;               -- �N��_���ʍ��v
    ln_y_psa                NUMBER  := 0;               -- �N��_����*�艿�̍��v
    ln_y_bsa                NUMBER  := 0;               -- �N��_����*�����̍��v
    ln_y_rate               NUMBER  := 0;               -- �N��_�|��
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP���f�p
    lv_month_no             VARCHAR2(10);               -- ��
--//+ADD START 2009/02/16 CT020 S.Son
    ln_m_rate               NUMBER  := 0;               -- ����_�|��
    ln_m_amount             NUMBER  := 0;               -- ����_����
--//+ADD END 2009/02/16 CT020 S.Son
--//+ADD START 2009/02/18 CT028 S.Son
    lb_skip_flg             BOOLEAN := FALSE;           --����0�`�F�b�N�X�L�b�v�t���O
--//+ADD END 2009/02/18 CT028 S.Son
--//+ADD START 2010/12/17 E_�{�ғ�_05803 Y.Kanami
    lv_item_cd_pre          VARCHAR2(10);               -- ���b�Z�[�W�o�͗p�i�ڃR�[�h
--//+ADD END 2010/12/17 E_�{�ғ�_05803 Y.Kanami
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_warnmsg VARCHAR2(4000);  -- ���[�U�[�E�x���E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################

--//+UPD START E_�{�ғ�_09949 K.Taniguchi
--// SELECT���CASE�����g�p��GROUP BY��ł�2�d�̋L�q�������邽��
--// FROM��ł̃C�����C���r���[�����s���܂��B
--// �܂��q���g�傪�Ȃ������ǂ����s�v��ƂȂ邽�߃q���g��͍폜���܂��B
----============================================
----  �f�[�^�̒��o�y���i�z�J�[�\��
----============================================
--    CURSOR   
--        get_item_data_cur(
--                          iv_kyoten_cd      IN VARCHAR2                         -- ���_�R�[�h
--                          )
--    IS
---- == 2010/03/24 V1.7 Modified START ===============================================================
----      SELECT   
--      SELECT /*+ LEADING(xiph xipl) */
---- == 2010/03/24 V1.7 Modified END   ===============================================================
--             xipl.month_no                          AS  month                    -- ��
--            ,SUM(NVL(xipl.amount,0))                AS  amount                   -- ����
--            ,SUM(NVL(xipl.sales_budget,0))          AS  sales                    -- ������z
--            ,SUM(NVL(xipl.amount_gross_margin,0))   AS  margin                   -- �e���v�z
--            ,xcgv.group1_cd                         AS  group_cd_1               -- ���i�Q1���R�[�h
--            ,xcgv.group1_nm                         AS  group_nm_1               -- ���i�Q1������
--            ,xcgv.group4_cd                         AS  group_cd_4               -- ���i�Q4���R�[�h
--            ,xcgv.group4_nm                         AS  group_nm_4               -- ���i�Q4������
--            ,xcgv.item_cd                           AS  item_id                  -- �i�ڃR�[�h
--            ,xcgv.item_nm                           AS  item_nm                  -- �i�ږ���
--            ,DECODE(gv_genkacd
--                 ,cn_base_price,xcgv.now_item_cost
--                 ,cn_bus_price,xcgv.now_business_cost
--                 ,0)                                AS  base_price               -- 10:�W������ 20:�c�ƌ���
--            ,NVL(xcgv.now_unit_price,0)             AS  con_price                -- �艿
---- == 2010/04/26 V1.8 Modified START ===============================================================
----            ,NVL(mucc.conversion_rate,0)            AS  conversion               -- ����
--            ,NVL(iimb.attribute11, 0)               AS  conversion               -- ����
---- == 2010/04/26 V1.8 Modified END   ===============================================================
--      FROM     
--            xxcsm_item_plan_lines                   xipl                         -- ���i�v�斾�׃e�[�u��
--            ,xxcsm_item_plan_headers                xiph                         -- ���i�v��w�b�_�e�[�u��
--            ,xxcsm_commodity_group4_v               xcgv                         -- ����Q�S�r���[
---- == 2010/04/26 V1.8 Modified START ===============================================================
----            ,mtl_system_items_b                     msib                         -- �i�ڃ}�X�^
----            ,mtl_uom_class_conversions              mucc                         -- �P�ʕϊ��}�X�^
--            ,ic_item_mst_b                          iimb                         -- OPM�i�ڃA�h�I��
---- == 2010/04/26 V1.8 Modified END   ===============================================================
--      WHERE    
--             xipl.item_plan_header_id                = xiph.item_plan_header_id   -- ���i�v��w�b�_ID
--      AND   xcgv.item_cd                             = xipl.item_no               -- ���i�R�[�h
---- == 2010/04/26 V1.8 Modified START ===============================================================
----      AND   mucc.inventory_item_id                   = msib.inventory_item_id     -- �i��ID
----      AND   msib.segment1                            = xipl.item_no               -- ���i�R�[�h
----      AND   msib.organization_id                     = gv_org_id                 -- �݌ɑg�DID
--      AND   xipl.item_no                             = iimb.item_no              -- ���i�R�[�h
---- == 2010/04/26 V1.8 Modified END   ===============================================================
--      AND   xiph.plan_year                           = gn_taisyoym               -- �Ώ۔N�x
--      AND   xiph.location_cd                         = iv_kyoten_cd              -- ���_�R�[�h
--      AND   xipl.item_kbn                            <> '0'                      -- ���i�敪(���i�Q�ȊO)
---- == 2010/04/26 V1.8 Deleted START ===============================================================
----      AND   xcgv.unit_of_issue                       = lv_prf_cd_unit_hon_val    -- �P��(�{)
----      AND   mucc.from_unit_of_measure                = lv_prf_cd_unit_hon_val    -- ��P��(�{)
----      AND   mucc.to_unit_of_measure                  = lv_prf_cd_unit_cs_val     -- �ϊ���P��(CS)
---- == 2010/04/26 V1.8 Deleted END   ===============================================================
--      GROUP BY
--               xipl.month_no                       -- ��
--              ,xcgv.group1_cd                      -- ���i�Q1���R�[�h
--              ,xcgv.group1_nm                      -- ���i�Q1������
--              ,xcgv.group4_cd                      -- ���i�Q4���R�[�h
--              ,xcgv.group4_nm                      -- ���i�Q4������
--              ,xcgv.item_cd                        -- ���i�R�[�h
--              ,xcgv.item_nm                        -- ���i����
--              ,xcgv.now_unit_price                 -- �艿
---- == 2010/04/26 V1.8 Modified START ===============================================================
----              ,mucc.conversion_rate                -- ����
--              ,iimb.attribute11                    -- ����
---- == 2010/04/26 V1.8 Modified END   ===============================================================
--              ,xcgv.now_item_cost                  -- �W������
--              ,xcgv.now_business_cost              -- �W������
--      ORDER BY 
--                 group_cd_1         ASC            -- ���i�Q1���R�[�h
--                ,group_cd_4         ASC            -- ���i�Q4���R�[�h
--                ,item_cd            ASC            -- ���i�R�[�h
--    ;

--============================================
--  �f�[�^�̒��o�y���i�z�J�[�\��
--============================================
    CURSOR
        get_item_data_cur(
                          iv_kyoten_cd      IN VARCHAR2                         -- ���_�R�[�h
                          )
    IS
      SELECT
             sub.month_no                          AS  month                    -- ��
            ,SUM(NVL(sub.amount,0))                AS  amount                   -- ����
            ,SUM(NVL(sub.sales_budget,0))          AS  sales                    -- ������z
            ,SUM(NVL(sub.amount_gross_margin,0))   AS  margin                   -- �e���v�z
            ,sub.group1_cd                         AS  group_cd_1               -- ���i�Q1���R�[�h
            ,sub.group1_nm                         AS  group_nm_1               -- ���i�Q1������
            ,sub.group4_cd                         AS  group_cd_4               -- ���i�Q4���R�[�h
            ,sub.group4_nm                         AS  group_nm_4               -- ���i�Q4������
            ,sub.item_cd                           AS  item_id                  -- �i�ڃR�[�h
            ,sub.item_nm                           AS  item_nm                  -- �i�ږ���
            ,DECODE(gv_genkacd
                 ,cn_base_price,sub.now_item_cost
                 ,cn_bus_price, sub.now_business_cost
                 ,0)                               AS  base_price               -- 10:�W������ 20:�c�ƌ���
            ,NVL(sub.now_unit_price,0)             AS  con_price                -- �艿
            ,NVL(sub.attribute11, 0)               AS  conversion               -- ����
      FROM
      (
          SELECT
                 xipl.month_no                          AS  month_no                 -- ��
                ,xipl.amount                            AS  amount                   -- ����
                ,xipl.sales_budget                      AS  sales_budget             -- ������z
                ,xipl.amount_gross_margin               AS  amount_gross_margin      -- �e���v�z
                ,xcgv.group1_cd                         AS  group1_cd                -- ���i�Q1���R�[�h
                ,xcgv.group1_nm                         AS  group1_nm                -- ���i�Q1������
                ,xcgv.group4_cd                         AS  group4_cd                -- ���i�Q4���R�[�h
                ,xcgv.group4_nm                         AS  group4_nm                -- ���i�Q4������
                ,xcgv.item_cd                           AS  item_cd                  -- �i�ڃR�[�h
                ,xcgv.item_nm                           AS  item_nm                  -- �i�ږ���
                 --
                 -- �W������
                 -- �p�����[�^�F�V�������敪
                ,CASE gv_new_old_cost_class
                   --
                   -- 10�F�V���� �I����
                   WHEN cv_new_cost THEN
                     NVL(xcgv.now_item_cost, 0)
                   --
                   -- 20�F������ �I����
                   WHEN cv_old_cost THEN
                     NVL(
                           (
                             -- �W�������}�X�^���O�N�x�̕W���������擾
                             SELECT SUM(ccmd.cmpnt_cost) AS cmpnt_cost                    -- �W������
                             FROM   cm_cmpt_dtl     ccmd                                  -- OPM�W�������}�X�^
                                   ,cm_cldr_dtl     ccld                                  -- �����J�����_����
                             WHERE  ccmd.calendar_code = ccld.calendar_code               -- �����J�����_�R�[�h
                             AND    ccmd.period_code   = ccld.period_code                 -- ���ԃR�[�h
                             AND    ccmd.item_id       = xcgv.opm_item_id                 -- �i��ID
                             AND    ccmd.whse_code     = cv_whse_code                     -- �����q��
                             AND    ccld.start_date   <= ADD_MONTHS(gd_process_date, -12) -- �O�N�x���_
                             AND    ccld.end_date     >= ADD_MONTHS(gd_process_date, -12) -- �O�N�x���_
                           )
                       , 0
                     )
                 END                                    AS  now_item_cost            -- �W������
                 --
                 -- �c�ƌ���
                 -- �p�����[�^�F�V�������敪
                ,CASE gv_new_old_cost_class
                   --
                   -- 10�F�V���� �I����
                   WHEN cv_new_cost THEN
                     NVL(xcgv.now_business_cost, 0)
                   --
                   -- 20�F������ �I����
                   WHEN cv_old_cost THEN
                     NVL(
                           (
                             -- �O�N�x�̉c�ƌ�����i�ڕύX��������擾
                             SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- �c�ƌ���
                             FROM    xxcmm_system_items_b_hst      xsibh               -- �i�ڕύX����
                             WHERE   xsibh.item_hst_id   =
                               (
                                 -- �O�N�x�̕i�ڕύX����ID
                                 SELECT  MAX(item_hst_id)      AS item_hst_id          -- �i�ڕύX����ID
                                 FROM    xxcmm_system_items_b_hst xsibh2               -- �i�ڕύX����
                                 WHERE   xsibh2.item_code      =  xcgv.item_cd         -- �i�ڃR�[�h
                                 AND     xsibh2.apply_date     <  gd_gl_start_date     -- �N�����̔N�x�J�n��
                                 AND     xsibh2.apply_flag     =  cv_flg_y             -- �K�p�ς�
                                 AND     xsibh2.discrete_cost  IS NOT NULL             -- �c�ƌ��� IS NOT NULL
                               )
                           )
                       , 0
                     )
                 END                                    AS  now_business_cost        --�c�ƌ���
                 --
                 -- �艿
                 -- �p�����[�^�F�V�������敪
                ,CASE gv_new_old_cost_class
                   --
                   -- 10�F�V���� �I����
                   WHEN cv_new_cost THEN
                     NVL(xcgv.now_unit_price, 0)
                   --
                   -- 20�F������ �I����
                   WHEN cv_old_cost THEN
                     NVL(
                           (
                             -- �O�N�x�̒艿��i�ڕύX��������擾
                             SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- �艿
                             FROM    xxcmm_system_items_b_hst      xsibh               -- �i�ڕύX����
                             WHERE   xsibh.item_hst_id   =
                               (
                                 -- �O�N�x�̕i�ڕύX����ID
                                 SELECT  MAX(item_hst_id)      AS item_hst_id          -- �i�ڕύX����ID
                                 FROM    xxcmm_system_items_b_hst xsibh2               -- �i�ڕύX����
                                 WHERE   xsibh2.item_code      =  xcgv.item_cd         -- �i�ڃR�[�h
                                 AND     xsibh2.apply_date     <  gd_gl_start_date     -- �N�����̔N�x�J�n��
                                 AND     xsibh2.apply_flag     =  cv_flg_y             -- �K�p�ς�
                                 AND     xsibh2.fixed_price    IS NOT NULL             -- �艿 IS NOT NULL
                               )
                           )
                       , 0
                     )
                 END                                    AS  now_unit_price           -- �艿
                ,NVL(iimb.attribute11, 0)               AS  attribute11              -- ����
          FROM     
                 xxcsm_item_plan_lines                  xipl                         -- ���i�v�斾�׃e�[�u��
                ,xxcsm_item_plan_headers                xiph                         -- ���i�v��w�b�_�e�[�u��
                ,xxcsm_commodity_group4_v               xcgv                         -- ���i�Q�S�r���[
                ,ic_item_mst_b                          iimb                         -- OPM�i�ڃA�h�I��
          WHERE    
                 xipl.item_plan_header_id               = xiph.item_plan_header_id   -- ���i�v��w�b�_ID
          AND    xcgv.item_cd                           = xipl.item_no               -- ���i�R�[�h
          AND    xipl.item_no                           = iimb.item_no               -- ���i�R�[�h
          AND    xiph.plan_year                         = gn_taisyoym                -- �Ώ۔N�x
          AND    xiph.location_cd                       = iv_kyoten_cd               -- ���_�R�[�h
          AND    xipl.item_kbn                          <> '0'                       -- ���i�敪(���i�Q�ȊO)
      ) sub
      GROUP BY
               sub.month_no                        -- ��
              ,sub.group1_cd                       -- ���i�Q1���R�[�h
              ,sub.group1_nm                       -- ���i�Q1������
              ,sub.group4_cd                       -- ���i�Q4���R�[�h
              ,sub.group4_nm                       -- ���i�Q4������
              ,sub.item_cd                         -- ���i�R�[�h
              ,sub.item_nm                         -- ���i����
              ,sub.now_unit_price                  -- �艿
              ,sub.attribute11                     -- ����
              ,sub.now_item_cost                   -- �W������
              ,sub.now_business_cost               -- �c�ƌ���
      ORDER BY 
               group_cd_1         ASC              -- ���i�Q1���R�[�h
              ,group_cd_4         ASC              -- ���i�Q4���R�[�h
              ,item_cd            ASC              -- ���i�R�[�h
    ;
--//+UPD END E_�{�ғ�_09949 K.Taniguchi
--============================================
--  ���i�Q�R�[�h�̒��o�E�J�[�\��
--============================================
    CURSOR   
        get_group4_code_cur
    IS
      SELECT  
        group_cd_4      AS group_cd4
      FROM
        xxcsm_tmp_sales_plan_cs
      GROUP BY group_cd_4;
      
--============================================
--  ���i�敪�R�[�h�̒��o�E�J�[�\��
--============================================
    CURSOR   
        get_group1_code_cur
    IS
      SELECT  
        group_cd_1      AS group_cd1
      FROM
        xxcsm_tmp_sales_plan_cs
      GROUP BY group_cd_1;

--
  BEGIN
--

--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--//+ADD START 2009/02/18 CT028 S.Son
    --���[�J���ϐ�������
    lv_item_cd := NULL;
--//+ADD END 2009/02/18 CT028 S.Son
--//+ADD START 2010/12/17 E_�{�ғ�_05803 Y.Kanami
    lv_item_cd_pre := NULL;   -- ���b�Z�[�W�o�͗p
--//+ADD END 2010/12/17 E_�{�ғ�_05803 Y.Kanami    
    -- =======================================
    -- �f�[�^�̏����y���i�z
    -- =======================================
    <<get_item_data_cur_loop>>
    FOR rec_item_data IN get_item_data_cur(iv_kyoten_cd) LOOP   
        BEGIN
--//+UPD START 2009/02/18 CT028 S.Son
--//+MOD START 2010/12/17 E_�{�ғ�_05803 Y.Kanami
            -- ======================================================
            -- ������0�̏ꍇ�A1��ݒ肵�����𑱍s����
            -- ======================================================
--//+MOD END 2010/12/17 E_�{�ғ�_05803 Y.Kanami
          --IF ((rec_item_data.sales = 0) OR (rec_item_data.conversion = 0)) THEN
            IF (lv_item_cd IS NULL) OR (lv_item_cd <> rec_item_data.item_id) THEN
              lb_skip_flg := TRUE;
            END IF;
--//+UPD START 2010/12/17 E_�{�ғ�_05803 Y.Kanami
--            --����0�̏ꍇ�X�L�b�v���āA���b�Z�[�W�o��
--            IF (rec_item_data.conversion = 0) THEN
--                -- ���i�R�[�h
--                lv_item_cd      := rec_item_data.item_id;
----//+DEL START 2009/02/18 CT028 S.Son
--                -- ��
--              --lv_month_no     := rec_item_data.month;
----//+DEL END 2009/02/18 CT028 S.Son
--                -- ���̃f�[�^�Ɉړ����܂�
--                RAISE global_skip_expt;
--            END IF;
            -- ������NULL�܂���0�̏ꍇ�͓�����1�Ƃ��ď����𑱍s����
            IF ( rec_item_data.conversion = 0 ) THEN
              -- �����Ɂu1�v��ݒ肷��
              rec_item_data.conversion := cn_value_1;
--
              -- ���i�R�[�h
              lv_item_cd      := rec_item_data.item_id;
--

              IF (lv_item_cd_pre IS NULL 
                OR lv_item_cd_pre <> lv_item_cd) THEN
                -- ���b�Z�[�W�o��
                lv_warnmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm                              -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_csm1_msg_10122                     -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_kyotencd                       -- �g�[�N���R�[�h1�i���_�R�[�h�j
                          ,iv_token_value1 => iv_kyoten_cd                          -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_item_cd                        -- �g�[�N���R�[�h2�i���i�R�[�h�j
                          ,iv_token_value2 => lv_item_cd                            -- �g�[�N���l2
                             );
              
                -- LOG�ɏo��
                fnd_file.put_line(
                                which  => FND_FILE.LOG
                               ,buff   => lv_warnmsg  || CHR(10)
                               );
              END IF;
--
              -- ���b�Z�[�W�o�͗p�ϐ��ɕi�ڃR�[�h��ݒ肷��
              lv_item_cd_pre := lv_item_cd;
--
            END IF;
--//+UPD END 2010/12/17 E_�{�ғ�_05803 Y.Kanami
            --����0�̏ꍇ�X�L�b�v
-- MODIFY  START  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-�{�ғ�_05803
--            IF (rec_item_data.sales = 0) THEN 
            IF rec_item_data.sales = 0 AND rec_item_data.amount = 0 THEN 
-- MODIFY  END  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-�{�ғ�_05803
              RAISE sales_skip_expt;
            END IF;
--//+UPD END 2009/02/18 CT028 S.Son
                 
            IF (lb_loop_end = FALSE) THEN
                
                lb_loop_end := TRUE;
                
                -- ���i�R�[�h
                lv_item_cd      := rec_item_data.item_id;
                
                -- �N��_����
                ln_y_sales      := 0;
                
                -- �N��_����(CS)
                ln_y_amount     := 0;

                -- �N��_����*�艿
                ln_y_psa        := 0;
                
                -- �N��_����*����
                ln_y_bsa        := 0;
                                        
                -- �N��_�e���v�z
                ln_y_margin     := 0;
    
            END IF;
             
            -- ==================================
            -- �y���i�P�ʁz�W�v
            -- ==================================
            IF (lv_item_cd <> rec_item_data.item_id ) THEN

              -- �N��_�|���y�Z�o�����z:�N��_���぀(�N�Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+ADD START 2009/02/16 CT020 S.Son
              IF (ln_y_psa = 0) THEN
                ln_y_rate   := 0;
              ELSE
                ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
              END IF;
--//+ADD END 2009/02/16 CT020 S.Son
              -- �N��_�e���v�z
              ln_y_margin     := ln_y_sales - ln_y_bsa;
              
              -- ==================================
              -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
              -- ==================================
              
              UPDATE
                      xxcsm_tmp_sales_plan_cs
              SET
                     y_sales          = ln_y_sales    -- �N�Ԕ���
                    ,y_amount         = ln_y_amount   -- �N�Ԑ���
                    ,y_rate           = ln_y_rate     -- �N�Ԋ|��
                    ,y_margin         = ln_y_margin   -- �N�ԑe���v�z

              WHERE
                      item_cd         = lv_item_cd;   -- ���i�R�[�h
              
              -- ===================================
              -- ���̏��i�̏ꍇ�A�Đݒ�
              -- ===================================
              -- ���i�R�[�h
              lv_item_cd      := rec_item_data.item_id;
              
              -- �N��_����
              ln_y_sales      := rec_item_data.sales;
              
              -- �N��_����(CS)
--//+ADD START 2009/02/16 CT020 S.Son
              IF (rec_item_data.conversion = 0 ) THEN
                ln_y_amount := 0;
              ELSE
                ln_y_amount     := ROUND(rec_item_data.amount /rec_item_data.conversion,0);
              END IF;
--//+ADD END 2009/02/16 CT020 S.Son
              -- �N��_����*�艿
              ln_y_psa        := rec_item_data.amount * rec_item_data.con_price;
              
              -- �N��_����*����
              ln_y_bsa        := rec_item_data.amount * rec_item_data.base_price;
                                      

            ELSE
                -- ===================================
                -- �y���ꏤ�i�z�N�ԗ݌v�����Z����
                -- ===================================
                -- �N�Ԕ���
                ln_y_sales      := ln_y_sales + rec_item_data.sales;
                
                -- �N�Ԑ���(CS)
--//+ADD START 2009/02/16 CT020 S.Son
                IF (rec_item_data.conversion = 0) THEN
                  ln_y_amount   := ln_y_amount + 0;
                ELSE
                  ln_y_amount     := ln_y_amount + ROUND(rec_item_data.amount /rec_item_data.conversion,0);
                END IF;
--//+ADD END 2009/02/16 CT020 S.Son
                -- �N�Ԑ���*�艿
                ln_y_psa        := ln_y_psa + rec_item_data.amount * rec_item_data.con_price;
                
                -- �N��_����*����
                ln_y_bsa        := ln_y_bsa + rec_item_data.amount * rec_item_data.base_price;
                
            END IF;
--//+ADD START 2009/02/16 CT020 S.Son
            --���ʊ|���̎Z�o
            IF (rec_item_data.amount = 0) OR (rec_item_data.con_price = 0) THEN
              ln_m_rate := 0;
            ELSE
              ln_m_rate := ROUND(rec_item_data.sales / (rec_item_data.amount * rec_item_data.con_price) * 100,2);
            END IF;
            --���ʐ��ʂ̎Z�o
            IF (rec_item_data.conversion = 0) THEN
              ln_m_amount := 0;
            ELSE
              ln_m_amount := ROUND(rec_item_data.amount / rec_item_data.conversion,0);
            END IF;
--//+ADD END 2009/02/16 CT020 S.Son
            -- ===================================
            -- �y���i�P�ʁz���ԃf�[�^�̓o�^
            -- ===================================
            INSERT INTO xxcsm_tmp_sales_plan_cs
              (
                  toroku_no        --�o�͏�
                  ,group_cd_1      --���i�Q�R�[�h(1��)
                  ,group_nm_1      --���i�Q����(1��)
                  ,group_cd_4      --���i�Q�R�[�h(4��)
                  ,group_nm_4      --���i�Q����(1��)
                  ,item_cd         --���i�R�[�h
                  ,item_nm         --���i����
                  ,month_no        --��
                  ,m_sales         --����_����
                  ,m_amount        --����_����=����/����
                  ,m_rate          --����_�|��=����_����^�i����_����*�艿�j*100
                  ,m_margin        --����_�e���v�z
                  ,t_price         -- ����*�艿
                  ,g_price         -- ����*����
              )
              VALUES (
                   gn_index
                  ,rec_item_data.group_cd_1
                  ,rec_item_data.group_nm_1
                  ,rec_item_data.group_cd_4
                  ,rec_item_data.group_nm_4
                  ,rec_item_data.item_id
                  ,rec_item_data.item_nm
                  ,rec_item_data.month
                  ,rec_item_data.sales
--//+UPD START 2009/02/16 CT020 S.Son
--                ,ROUND(rec_item_data.amount / rec_item_data.conversion,0)
                  ,ln_m_amount
--                ,ROUND(rec_item_data.sales / (rec_item_data.amount * rec_item_data.con_price) * 100,2)
                  ,ln_m_rate
--//+UPD END 2009/02/16 CT020 S.Son
                  ,rec_item_data.sales - rec_item_data.amount * rec_item_data.base_price
                  ,rec_item_data.amount * rec_item_data.con_price
                  ,rec_item_data.amount * rec_item_data.base_price
              );
              
              -- �o�^���y���Z�z
              gn_index := gn_index + 1;

        --
        --#################################  �X�L�b�v  START #############################
        --
        EXCEPTION
            WHEN global_skip_expt THEN
--//+DEL START 2009/02/18 CT028 S.Son
                -- �Ώی��������Z���܂�
              --gn_target_cnt := gn_target_cnt + 1 ;
                -- �X�L�b�v���������Z���܂�
              --gn_warn_cnt := gn_warn_cnt + 1 ;
--//+DEL END 2009/02/18 CT028 S.Son
                IF lb_skip_flg = TRUE THEN
                  lv_warnmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                              -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_csm1_msg_10122                     -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1  => cv_tkn_kyotencd                       -- �g�[�N���R�[�h1�i���_�R�[�h�j
                            ,iv_token_value1 => iv_kyoten_cd                          -- �g�[�N���l1
                            ,iv_token_name2  => cv_tkn_item_cd                        -- �g�[�N���R�[�h2�i���i�R�[�h�j
                            ,iv_token_value2 => lv_item_cd                            -- �g�[�N���l2
--//+DEL START 2009/02/18 CT028 S.Son
                          --,iv_token_name3  => cv_tkn_month_no                       -- �g�[�N���R�[�h3�i���j
                          --,iv_token_value3 => lv_month_no                           -- �g�[�N���l3
--//+DEL END 2009/02/18 CT028 S.Son
                           );
            
                  -- LOG�ɏo��
                  fnd_file.put_line(
                                  which  => FND_FILE.LOG
                                 ,buff   => lv_warnmsg  || CHR(10)
                                 );
                 END IF;
                 lb_skip_flg := FALSE;
--//+ADD START 2009/02/18 CT028 S.Son
            --����0�̂Ƃ��A�X�L�b�v���āA���b�Z�[�W���o���Ȃ�
            WHEN sales_skip_expt THEN
                NULL;
--//+ADD END 2009/02/18 CT028 S.Son
        --
        --#################################  �X�L�b�v  END #############################
        --
        END;
    END LOOP get_item_data_cur_loop;
    -- �Ō�̃��R�[�h
    IF (lb_loop_end) THEN
        
        -- ================================================
        -- �y�����i�P�ʁ��z
        -- ================================================
        -- �N��_�|���y�Z�o�����z:�N��_���぀(�N�Ԑ���*�艿)*100 �y�����_3���l�̌ܓ��z
--//+ADD START 2009/02/16 CT020 S.Son
        IF (ln_y_psa = 0) THEN
          ln_y_rate   := 0;
        ELSE
          ln_y_rate   := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
--//+ADD END 2009/02/16 CT020 S.Son
        -- �N�ԑe���v�z
        ln_y_margin     := ln_y_sales - ln_y_bsa;
        --==================================
        -- �Z�o�������v�l�����[�N�e�[�u���֓o�^
        --==================================
        
        UPDATE
                xxcsm_tmp_sales_plan_cs
        SET
               y_sales          = ln_y_sales      -- �N�Ԕ���
              ,y_amount         = ln_y_amount     -- �N�Ԑ���
              ,y_rate           = ln_y_rate       -- �N�Ԋ|��
              ,y_margin         = ln_y_margin     -- �N�ԑe���v�z
        WHERE
                item_cd         = lv_item_cd;     -- ���i�R�[�h
                
        -- ================================================
        -- �y�������i�Q�P�ʁ����z
        -- ================================================
        <<get_group4_data>>
        FOR rec_group4 IN get_group4_code_cur LOOP
            
            lv_group_cd_4:= rec_group4.group_cd4;

            deal_group4_data(
                       lv_group_cd_4                  -- ���i�Q�R�[�h�i4���j
                      ,lv_errbuf                      -- �G���[�E���b�Z�[�W
                      ,lv_retcode                     -- ���^�[���E�R�[�h
                      ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
            IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
              RAISE global_process_expt;
            END IF;
        
        END LOOP get_group4_data;
        
        -- ================================================
        -- �y���������i�敪�P�ʁ������z
        -- ================================================
        <<get_group1_data>>
        FOR rec_group1 IN get_group1_code_cur LOOP
            
            lv_group_cd_1:= rec_group1.group_cd1;

            deal_group1_data(
                       lv_group_cd_1                  -- ���i�Q�R�[�h�i1���j
                      ,lv_errbuf                      -- �G���[�E���b�Z�[�W
                      ,lv_retcode                     -- ���^�[���E�R�[�h
                      ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
            IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
              RAISE global_process_expt;
            END IF;
        
        END LOOP get_group1_data;
        
        -- ================================================
        -- �y�����������i���v���������z
        -- ================================================
        deal_sum_data(
                   lv_errbuf                      -- �G���[�E���b�Z�[�W
                  ,lv_retcode                     -- ���^�[���E�R�[�h
                  ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
                  );
        IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
          RAISE global_process_expt;
        END IF;
        
    END IF;

    -- ================================================
    -- �y��������������l���^�����l�������������z
    -- ================================================
    deal_down_data(
               iv_kyoten_cd                   -- ���_�R�[�h�i1���j
              ,lv_errbuf                      -- �G���[�E���b�Z�[�W
              ,lv_retcode                     -- ���^�[���E�R�[�h
              ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
    IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;
    -- ================================================
    -- �y���������������_�v�������������z
    -- ================================================
    deal_kyoten_data(
               lv_errbuf                      -- �G���[�E���b�Z�[�W
              ,lv_retcode                     -- ���^�[���E�R�[�h
              ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
    IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;

-- ===========================================================================  
--�y�f�[�^����-END(���i�P��)�z
-- ===========================================================================
--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
--//+ADD START 2009/02/10 CT008 T.Tsukino
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--//+ADD END 2009/02/10 CT008 T.Tsukino
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
      
      IF (get_group4_code_cur%ISOPEN) THEN
        CLOSE get_group4_code_cur;
      END IF;
      
      IF (get_group1_code_cur%ISOPEN) THEN
        CLOSE get_group1_code_cur;
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
      
      IF (get_group4_code_cur%ISOPEN) THEN
        CLOSE get_group4_code_cur;
      END IF;
      
      IF (get_group1_code_cur%ISOPEN) THEN
        CLOSE get_group1_code_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ###########################
--
  END deal_item_data;
--

   /*****************************************************************************
   * Procedure Name   : get_col_data
   * Description      : �e���ڂ̃f�[�^���擾�y���ʁE����E�|���E�e���v�z�z
   ****************************************************************************/
  PROCEDURE get_col_data(
        iv_parament    IN  VARCHAR2                 -- �ݒ�\�l�F�yA,C,D,���i���v,����l��,�����l��,���_�v�z
       ,in_kind        IN  NUMBER                   -- �����敪:�y0:���i�E���i�Q�E���i�敪 1:���i���v�E����l���E�����l���E���_�v�z
       ,iv_head        IN  VARCHAR2                 -- �ݒ�\�l�F�y�R�[�h|���́z�����́y��|���́z
       ,iv_first       IN  BOOLEAN                  -- �ݒ�\�l�F�yTRUE:���_�R�[�h���܂ߍs�� FALSE:���ʂ̍s�ځz
       ,ov_errbuf      OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W
       ,ov_retcode     OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h
       ,ov_errmsg      OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W
       ,ov_col_data    OUT NOCOPY VARCHAR2)         --��������
  IS
      -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)  := 'get_col_data';        -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    in_param        NUMBER :=0 ;
    lv_item_col     VARCHAR2(100);
    lb_loop_end     BOOLEAN := FALSE;
    lv_col_data     VARCHAR2(6000);
    
-- ==========================================================
-- ���v�y�J�[�\���z
-- ==========================================================
    CURSOR get_month_data_cur0(
                         in_item_param      IN NUMBER       -- �������ڋ敪�y0:����1:����2:�e���v�z3:�|���z
                        ,iv_param           IN VARCHAR2     -- �ϐ��y�ݒ�\�l�FA,C,D�z
                        )
    IS 
      SELECT
             DECODE(in_item_param
                       ,0,NVL(SUM(DECODE(month_no,5,m_amount,0)  ),0) || cv_msg_comma              -- ���ʁy���z
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
--//+UPD START 2009/02/19 CT041 S.Son
/*
                       ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma               -- ����y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                       ,2,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma              -- �e���v�z�y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
*/
                       ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0) / cn_unit) || cv_msg_comma               -- ����y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                       ,2,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cn_unit) || cv_msg_comma              -- �e���v�z�y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
--//+UPD END 2009/02/19 CT041 S.Son
                       ,3,NVL(SUM(DECODE(month_no,5,m_rate,0)  ),0) || cv_msg_comma                -- �|���y���z
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
                       ,NULL) AS month_data
      FROM  
            xxcsm_tmp_sales_plan_cs       -- ���i�v�惊�X�g_CS�P�ʃ��[�N�e�[�u��
      WHERE
            item_cd  = iv_param          -- ���i�E���i�Q�E���i�敪�P��
;

-- ==========================================================
-- ���v�y�J�[�\���z
-- ==========================================================
    CURSOR get_month_data_cur1(
                         in_item_param      IN NUMBER       -- �������ڋ敪�y0:����1:����2:�e���v�z3:�|���z
                        ,iv_param           IN VARCHAR2     -- �ϐ��y�ݒ�\�l�F���i���v,����l��,�����l��,���_�v�z
                        )
    IS 
      SELECT
             DECODE(in_item_param
                       ,0,NVL(SUM(DECODE(month_no,5,m_amount,0)  ),0) || cv_msg_comma              -- ���ʁy���z
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
--//+UPD START 2009/02/19 CT041 S.Son
/*
                       ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma               -- ����y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                       ,2,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma              -- �e���v�z�y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
*/
                       ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0) / cn_unit) || cv_msg_comma               -- ����y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                       ,2,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cn_unit) || cv_msg_comma              -- �e���v�z�y���z
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
--//+UPD END 2009/02/19 CT041 S.Son
                       ,3,NVL(SUM(DECODE(month_no,5,m_rate,0)  ),0) || cv_msg_comma                -- �|���y���z
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
                       ,NULL) AS month_data
      FROM  
            xxcsm_tmp_sales_plan_cs       -- ���i�v�惊�X�g_CS�P�ʃ��[�N�e�[�u��
      WHERE
            item_nm  = iv_param          -- ���i���v�E����l���E�����l���E���_�v
;
-- ==========================================================
-- �N�v�y�J�[�\���z
-- ==========================================================
    CURSOR  get_year_data_cur0(
                         in_item_param      IN NUMBER       -- �������ڋ敪�y0:����1:����2:�e���v�z3:�|���z
                        ,iv_param           IN VARCHAR2     -- �ϐ��y�ݒ�\�l�FA,C,D�z
                        )
    IS
      SELECT   DISTINCT
               DECODE(in_item_param
                    ,0,NVL(y_amount,0) || CHR(10)                                 -- ���ʍ��v
--//+UPD START 2009/02/19 CT041 S.Son
/*
                    ,1,ROUND(NVL(y_sales,0) / cn_unit,2) ||  CHR(10)              -- ���㍇�v
                    ,2,ROUND(NVL(y_margin,0) / cn_unit,2)|| CHR(10)               -- �e���v�z���v
*/
                    ,1,ROUND(NVL(y_sales,0) / cn_unit) ||  CHR(10)              -- ���㍇�v
                    ,2,ROUND(NVL(y_margin,0) / cn_unit)|| CHR(10)               -- �e���v�z���v
--//+UPD END 2009/02/19 CT041 S.Son
                    ,3,NVL(y_rate,0) ||  CHR(10)                                  -- �|�����v
                    ,NULL) AS year_data
      FROM  
            xxcsm_tmp_sales_plan_cs       -- ���i�v�惊�X�g_CS�P�ʃ��[�N�e�[�u��
      WHERE
            item_cd  = iv_param          -- ���i�E���i�Q�E���i�敪�P��
;   
-- ==========================================================
-- �N�v�y�J�[�\���z
-- ==========================================================
    CURSOR  get_year_data_cur1(
                         in_item_param      IN NUMBER       -- �������ڋ敪�y0:����1:����2:�e���v�z3:�|���z
                        ,iv_param           IN VARCHAR2     -- �ϐ��y�ݒ�\�l�F���i���v,����l��,�����l��,���_�v�z
                        )
    IS
      SELECT   DISTINCT
               DECODE(in_item_param
                    ,0,NVL(y_amount,0) || CHR(10)                                -- ���ʍ��v
--//+UPD START 2009/02/19 CT041 S.Son
/*
                    ,1,ROUND(NVL(y_sales,0) / cn_unit,2) || CHR(10)              -- ���㍇�v
                    ,2,ROUND(NVL(y_margin,0) / cn_unit,2)|| CHR(10)              -- �e���v�z���v
*/
                    ,1,ROUND(NVL(y_sales,0) / cn_unit) || CHR(10)              -- ���㍇�v
                    ,2,ROUND(NVL(y_margin,0) / cn_unit)|| CHR(10)              -- �e���v�z���v
--//+UPD END 2009/02/19 CT041 S.Son
                    ,3,NVL(y_rate,0) ||  CHR(10)                                 -- �|�����v
                    ,NULL) AS year_data
      FROM  
            xxcsm_tmp_sales_plan_cs       -- ���i�v�惊�X�g_CS�P�ʃ��[�N�e�[�u��
      WHERE
            item_nm  = iv_param          -- ���i���v�E����l���E�����l���E���_�v
;   
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
--##################  �Œ蕔 END   #####################################
    -- ������
    in_param := 0;
    
    <<col_loop>>
    WHILE (in_param < 4 ) LOOP
      lb_loop_end := FALSE;
      
      IF (in_param = 0) THEN
          -- ���ʁy���ږ��z
          lv_item_col := cv_msg_duble || lv_prf_cd_amount_val || cv_msg_duble || cv_msg_comma;

      ELSIF (in_param = 1) THEN
          -- ����y���ږ��z
          lv_item_col := cv_msg_duble || lv_prf_cd_sales_val || cv_msg_duble || cv_msg_comma;

      ELSIF (in_param = 2) THEN
          -- �e���v�z�y���ږ��z
          lv_item_col := cv_msg_duble || lv_prf_cd_margin_val || cv_msg_duble || cv_msg_comma;

      ELSIF (in_param = 3) THEN
          -- �|���y���ږ��z
          lv_item_col := cv_msg_duble || lv_prf_cd_rate_val || cv_msg_duble || cv_msg_comma; 
          
      END IF;    
      
      -- ���s�̐ݒ�
      IF (in_param = 0) THEN
            IF (iv_first) THEN
                -- ���ʍs�����s�̏ꍇ�A���_�R�[�h|���_����|���i�R�[�h|���i����
                lv_col_data     := lv_col_data || iv_head || lv_item_col;
            ELSE
                -- ���ʍs�̏ꍇ�A��|��|�R�[�h|����
                lv_col_data     := lv_col_data || cv_msg_linespace || iv_head || lv_item_col;
            END IF;
      ELSE
            -- ��L�ȊO�̏ꍇ�A��|��|��|��
            lv_col_data     := lv_col_data || cv_msg_linespace || cv_msg_linespace || lv_item_col;
            
      END IF;

      -- ���ԏ��
      <<month_loop>>
      IF (in_kind = 0) THEN
          FOR rec_month IN get_month_data_cur0(in_param,iv_parament) LOOP
            lb_loop_end := TRUE;
            
            lv_col_data := lv_col_data || rec_month.month_data;

          END LOOP month_loop;
      ELSIF (in_kind = 1) THEN
         FOR rec_month IN get_month_data_cur1(in_param,iv_parament) LOOP
            lb_loop_end := TRUE;
            
            lv_col_data := lv_col_data || rec_month.month_data;

          END LOOP month_loop;
      END IF;
      
      -- ���ԏ�񂪑��݂���ꍇ
      IF (lb_loop_end) THEN
        -- �N�ԏ��
        <<year_loop>>
        IF (in_kind = 0) THEN
            FOR rec_year IN get_year_data_cur0(in_param,iv_parament) LOOP
                lb_loop_end := FALSE;
                lv_col_data := lv_col_data || rec_year.year_data;

            END LOOP year_loop;
        ELSIF (in_kind = 1) THEN
            FOR rec_year IN get_year_data_cur1(in_param,iv_parament) LOOP
                lb_loop_end := FALSE;
                lv_col_data := lv_col_data || rec_year.year_data;
            END LOOP year_loop;

        END IF;
        
        IF (lb_loop_end) THEN
            lv_col_data := lv_col_data || cv_sum_zero;
        END IF;
      -- ���ԏ�񂪑��݂��Ȃ��ꍇ
      ELSE
          lv_col_data := lv_col_data || cv_all_zero;
      END IF;
      -- ���̍���
      in_param := in_param + 1;
          
    END LOOP col_loop;
    
    ov_col_data := lv_col_data;

--#################################  �Œ��O������  #############################
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_month_data_cur0%ISOPEN) THEN
         CLOSE get_month_data_cur0;
      END IF;
      
      IF (get_year_data_cur0%ISOPEN) THEN
         CLOSE get_year_data_cur0;
      END IF;
      
      IF (get_month_data_cur1%ISOPEN) THEN
         CLOSE get_month_data_cur1;
      END IF;
      
      IF (get_year_data_cur1%ISOPEN) THEN
         CLOSE get_year_data_cur1;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_month_data_cur0%ISOPEN) THEN
         CLOSE get_month_data_cur0;
      END IF;
      
      IF (get_year_data_cur0%ISOPEN) THEN
         CLOSE get_year_data_cur0;
      END IF;
      
      IF (get_month_data_cur1%ISOPEN) THEN
         CLOSE get_month_data_cur1;
      END IF;
      
      IF (get_year_data_cur1%ISOPEN) THEN
         CLOSE get_year_data_cur1;
      END IF;
--        
--#####################################  �Œ蕔 END   ###########################
--  
  END get_col_data;
--  
  
  /*****************************************************************************
   * Procedure Name   : deal_csv_data
   * Description      : �y���_�P�ʁz�o�̓f�[�^�̒��o
   ****************************************************************************/
  PROCEDURE deal_csv_data(
        iv_kyoten_cd      IN  VARCHAR2                                          -- ���_�R�[�h
       ,iv_kyoten_nm      IN  VARCHAR2                                          -- ���_����
--//+ADD START 2009/02/20 CT028 S.Son
       ,ov_line_info      OUT  VARCHAR2
--//+ADD END 2009/02/20 CT028 S.Son
       ,ov_errbuf         OUT NOCOPY VARCHAR2                                   -- �G���[�E���b�Z�[�W
       ,ov_retcode        OUT NOCOPY VARCHAR2                                   -- ���^�[���E�R�[�h
       ,ov_errmsg         OUT NOCOPY VARCHAR2)                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'deal_csv_data';    -- �v���O������ 
    
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
    
    -- �{�f�B�w�b�_���i���_�R�[�h�b���_���́j
    lv_line_head                VARCHAR2(210);
    
    -- �����i5��|6��|7��|8��|9��|10��|11��|12��|1��|2��|3��|04���j
    lv_month_info                VARCHAR2(4000);
    
    -- �N�ԏ��i���v�j
    lv_year_info                VARCHAR2(4000);
    
    -- ���ږ���
    lv_item_info                VARCHAR2(4000);
    
    -- �e���v�ϐ�
    lv_temp_item                VARCHAR2(6000);
    
    -- ���i���
    lv_item_data                VARCHAR2(6000);
    
    -- ���i�Q���
    lv_group4_data              VARCHAR2(6000);
    
    -- ���i�敪���
    lv_group1_data              VARCHAR2(6000);
    
    -- ���i�R�[�h
    lv_item_cd                  VARCHAR2(10);
    
    -- ���i�Q�R�[�h
    lv_group4_cd                VARCHAR2(10);
 --
    lv_group4_nm                VARCHAR2(100);
 --
    
    -- ���i�敪�R�[�h
    lv_group1_cd                VARCHAR2(10);
    
    -- ���_���
    lv_kyoten_data              VARCHAR2(2000);
    
    -- ���_�R�[�h|���_����
    lv_kyoten_info              VARCHAR2(4000);
    
    -- ���i�Q�W��
    lv_item_group               VARCHAR2(50);
    
    -- ���f�p
    lb_loop_end                 BOOLEAN := FALSE;
    
    ln_counts                   NUMBER := 0;
    
    lv_first_rec                BOOLEAN := TRUE;

    

-- ==========================================================
-- ���i�R�[�h�E���i�Q�R�[�h�E���i�敪���擾�y�J�[�\���z
-- ==========================================================
    CURSOR get_code_cur(iv_param  IN VARCHAR2)
    IS 
      SELECT DISTINCT
             item_cd                -- ���i�R�[�h 
            ,item_nm                -- ���i����
            ,group_cd_4             -- ���i�Q�R�[�h
            ,group_nm_4             -- ���i�Q����
            ,group_cd_1             -- ���i�敪�R�[�h
            ,group_nm_1             -- ���i�敪����
      FROM  
            xxcsm_tmp_sales_plan_cs       -- ���i�v�惊�X�g_CS�P�ʃ��[�N�e�[�u��
      WHERE
            item_cd    IS NOT NULL -- ���i�R�[�h 
      AND   group_cd_4 IS NOT NULL -- ���i�Q�R�[�h
      AND   group_cd_1 = iv_param  -- ���i�敪�R�[�h
      ORDER BY 
--//+UPD START 2009/02/26 CT062 S.Son
              --item_cd       ASC
              --,group_cd_4   ASC
               group_cd_4       ASC
              ,item_cd          ASC
--//+UPD END 2009/02/26 CT062 S.Son
                ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ������
    lv_item_data      := NULL;  -- ���i���
    lv_group4_data    := NULL;  -- ���i�Q���
    lv_group1_data    := NULL;  -- ���i�敪���
    lv_kyoten_data    := NULL;  -- ���_���
    -- ���i�QA
    lv_item_group   := cv_group_A;
    
    -- 
    lv_kyoten_data := cv_msg_duble || iv_kyoten_cd || cv_msg_duble || cv_msg_comma;
    lv_kyoten_data := lv_kyoten_data || cv_msg_duble || iv_kyoten_nm || cv_msg_duble || cv_msg_comma;
    
    -- �f�[�^���݃`�F�b�N
    SELECT
          count(1)
    INTO  
          ln_counts
    FROM  
          xxcsm_tmp_sales_plan_cs
    WHERE 
          rownum = 1;                         -- 1�s��   

    -- ������0�̏ꍇ�A�������X�L�b�v���܂��B                                
    IF (ln_counts = 0) THEN
      RETURN;
    END IF;

    <<loop_ACD>>
    WHILE(lv_item_group IS NOT NULL) LOOP
    
        -- ������
        lv_item_cd      := NULL;  -- ���i
        lv_group4_cd    := NULL;  -- ���i�Q
        lv_group1_cd    := NULL;  -- ���i�敪

        <<rec_code_loop>>
        FOR rec_code IN get_code_cur(lv_item_group) LOOP
            
            lb_loop_end := TRUE;
            
            lv_temp_item := NULL;
            lv_line_head := NULL;
--//+UPD START 2009/02/19 CT030 S.Son
/*
            -- ======================================================
            -- �y�����i���z
            -- ======================================================
            IF ((lv_item_cd IS NULL) OR (lv_item_cd <> rec_code.item_cd)) THEN
                -- �Ώی����y���Z�z
                gn_target_cnt := gn_target_cnt + 1;
                IF (lv_first_rec) THEN
                    -- ���_�R�[�h|���_����
                    lv_line_head := lv_kyoten_data;
                END IF;
                
                -- ���i�R�[�h|���i����
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.item_cd || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.item_nm || cv_msg_duble || cv_msg_comma;

                -- ���i���i���ʁE����E�e���v�z�E�|���j
                get_col_data(
                             rec_code.item_cd
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
                
                lv_first_rec := FALSE;
                IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
                    -- �G���[�����y���Z�z 
                    gn_error_cnt := gn_error_cnt + 1 ;

                    -- ���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- ���팏���y���Z�z 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
                  --
                  RAISE global_api_others_expt;
                END IF;
                
                -- ���i���
                lv_item_data := lv_item_data||lv_temp_item;

                -- ���i�R�[�h
                lv_item_cd   := rec_code.item_cd;
                
            END IF;
*/
            -- ======================================================
            -- �y�����i�Q���z
            -- ======================================================
--//+UPD START 2009/02/19 CT030 S.Son
          --IF ((lv_group4_cd IS NULL) OR (lv_group4_cd <> rec_code.group_cd_4)) THEN
            IF ((lv_group4_cd IS NOT NULL) AND (lv_group4_cd <> rec_code.group_cd_4)) THEN
--//+UPD END 2009/02/19 CT030 S.Son
--//+DEL START 2009/02/18 CT028 S.Son
                -- �Ώی����y���Z�z
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/18 CT028 S.Son
                -- �R�[�h|����
                lv_line_head := cv_msg_duble || lv_group4_cd || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_group4_nm || cv_msg_duble || cv_msg_comma;

                -- ���i�Q�i���ʁE����E�e���v�z�E�|���j
                get_col_data(
--//+UPD START 2009/02/19 CT030 S.Son
                           --rec_code.group_cd_4
                             lv_group4_cd
--//+UPD START 2009/02/19 CT030 S.Son
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );

                IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
--//+DEL START 2009/02/18 CT028 S.Son
/*                  -- �G���[�����y���Z�z 
                    gn_error_cnt := gn_error_cnt + 1 ;

                    -- ���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- ���팏���y���Z�z 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
--//+DEL START 2009/02/18 CT028 S.Son
                  RAISE global_api_others_expt;
                END IF;
                -- ���i�Q���
                lv_group4_data := lv_group4_data || lv_temp_item;
--//+ADD START 2009/02/19 CT030 S.Son
                IF (lv_group4_data IS NOT NULL) THEN                
                    -- ���i�Q���̏o��
                    fnd_file.put_line(
                                      which  => FND_FILE.OUTPUT
                                     ,buff   => lv_group4_data
                                     );
                    -- ������
                    lv_group4_data    := NULL;  -- ���i�Q���
                END IF;
--//+ADD END 2009/02/19 CT030 S.Son
--//+DEL START 2009/02/19 CT030 S.Son
                -- ���i�Q�R�[�h
--                lv_group4_cd := rec_code.group_cd_4;
--//+DEL END 2009/02/19 CT030 S.Son
            END IF;
            -- ======================================================
            -- �y�����i���z
            -- ======================================================
            IF ((lv_item_cd IS NULL) OR (lv_item_cd <> rec_code.item_cd)) THEN
--//+DEL START 2009/02/18 CT028 S.Son
                -- �Ώی����y���Z�z
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/18 CT028 S.Son
                IF (lv_first_rec) THEN
                    -- ���_�R�[�h|���_����
                    lv_line_head := lv_kyoten_data;
--//+ADD START 2009/02/19 CT030 S.Son
                ELSE
                    lv_line_head := NULL;
--//+ADD END 2009/02/19 CT030 S.Son
                END IF;
                
                -- ���i�R�[�h|���i����
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.item_cd || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.item_nm || cv_msg_duble || cv_msg_comma;

                -- ���i���i���ʁE����E�e���v�z�E�|���j
                get_col_data(
                             rec_code.item_cd
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
                
                lv_first_rec := FALSE;
                IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
--//+DEL START 2009/02/18 CT028 S.Son
                    -- �G���[�����y���Z�z 
                  /*gn_error_cnt := gn_error_cnt + 1 ;

                    -- ���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- ���팏���y���Z�z 
                    gn_normal_cnt := gn_normal_cnt + 1 ;*/
--//+DEL END 2009/02/18 CT028 S.Son
                  --
                  RAISE global_api_others_expt;
                END IF;
                
                -- ���i���
                lv_item_data := lv_item_data||lv_temp_item;
--//+ADD START 2009/02/19 CT030 S.Son
                IF (lv_item_data IS NOT NULL) THEN
                    -- ���i���̏o��
                    fnd_file.put_line(
                                      which  => FND_FILE.OUTPUT
                                     ,buff   => lv_item_data
                                     );
                    -- ������
                    lv_item_data      := NULL;  -- ���i���
                END IF;
--//+ADD END 2009/02/19 CT030 S.Son
                -- ���i�R�[�h
                lv_item_cd   := rec_code.item_cd;
                
            END IF;
--//+UPD END 2009/02/19 CT030 S.Son
            -- ======================================================
            -- �y�����i�敪���z
            -- ======================================================
            IF ((lv_group1_cd IS NULL) OR (lv_group1_cd <> rec_code.group_cd_1)) THEN
--//+DEL START 2009/02/18 CT028 S.Son
                -- �Ώی����y���Z�z
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/18 CT028 S.Son
                -- �R�[�h|����
                lv_line_head := cv_msg_duble || rec_code.group_cd_1 || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.group_nm_1 || cv_msg_duble || cv_msg_comma;

                -- ���i�敪���i���ʁE����E�e���v�z�E�|���j
                get_col_data(
                             rec_code.group_cd_1
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );

                IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
--//+DEL START 2009/02/18 CT028 S.Son
/*                  -- �G���[�����y���Z�z 
                    gn_error_cnt := gn_error_cnt + 1 ;

                    -- ���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- ���팏���y���Z�z 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
--//+DEL END 2009/02/18 CT028 S.Son
                  RAISE global_api_others_expt;
                END IF;
                
                -- ���i�敪���
                lv_group1_data := lv_group1_data || lv_temp_item;
                
                -- ���i�敪�R�[�h(1��)
                lv_group1_cd   := rec_code.group_cd_1;

            END IF;
--//+ADD START 2009/02/19 CT030 S.Son
                lv_group4_cd   := rec_code.group_cd_4;
                lv_group4_nm   := rec_code.group_nm_4;
--//+ADD END 2009/02/19 CT030 S.Son
        END LOOP rec_code_loop;
        
        IF (lb_loop_end) THEN
--//+DEL START 2009/02/19 CT030 S.Son
/*            IF (lv_item_data IS NOT NULL) THEN
                -- ���i���̏o��
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT
                                 ,buff   => lv_item_data
                                 );
                -- ������
                lv_item_data      := NULL;  -- ���i���
            END IF;
            
            IF (lv_group4_data IS NOT NULL) THEN                
                -- ���i�Q���̏o��
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT
                                 ,buff   => lv_group4_data
                                 );
                -- ������
                lv_group4_data    := NULL;  -- ���i�Q���
            END IF;
            */
--//+DEL END 2009/02/19 CT030 S.Son
--//+ADD START 2009/02/19 CT030 S.Son
            IF lv_group4_cd IS NOT NULL THEN
                lv_line_head := cv_msg_duble || lv_group4_cd || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_group4_nm || cv_msg_duble || cv_msg_comma;

                -- ���i�Q�i���ʁE����E�e���v�z�E�|���j
                get_col_data(
                             lv_group4_cd
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );

                IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
                  RAISE global_api_others_expt;
                END IF;
                -- ���i�Q���
                lv_group4_data := lv_group4_data || lv_temp_item;
                IF (lv_group4_data IS NOT NULL) THEN                
                    -- ���i�Q���̏o��
                    fnd_file.put_line(
                                      which  => FND_FILE.OUTPUT
                                     ,buff   => lv_group4_data
                                     );
                    -- ������
                    lv_group4_data    := NULL;  -- ���i�Q���
                END IF;
            END IF;
--//+ADD END 2009/02/19 CT030 S.Son
            IF (lv_group1_data IS NOT NULL) THEN
                -- ���i�敪���̏o��
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT
                                 ,buff   => lv_group1_data
                                 );
                -- ������
                lv_group1_data    := NULL;  -- ���i�敪���
            END IF;
        
        END IF;
        
        -- ���f�E�ݒ�E�W�v
        IF (lv_item_group = cv_group_A ) THEN
            -- �y���i�QA�����i�QC�z
            lv_item_group := cv_group_C;
            
        ELSIF (lv_item_group = cv_group_C ) THEN
            IF (lb_loop_end) THEN
                -- ======================================================
                -- �y�����i���v���z
                -- ======================================================
                -- ������
                lv_temp_item := NULL;
                lv_line_head := NULL;
                
                -- ��|����
                lv_line_head := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_prf_cd_sum_val || cv_msg_duble || cv_msg_comma;
--//+DEL START 2009/02/18 CT028 S.Son
                -- �Ώی����y���Z�z
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/18 CT028 S.Son
                -- ���i���v���i���ʁE����E�e���v�z�E�|���j
                get_col_data(
                             lv_prf_cd_sum_val
                            ,1
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
                IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
--//+DEL START 2009/02/18 CT028 S.Son
/*                  -- �G���[�����y���Z�z 
                    gn_error_cnt := gn_error_cnt + 1 ;

                    -- ���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- ���팏���y���Z�z 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
--//+DEL END 2009/02/18 CT028 S.Son
                  RAISE global_api_others_expt;
                END IF;
                -- ���i���v���̏o��
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT                                                     
                                 ,buff   => lv_temp_item
                                 );
            END IF;
            -- �y���i�QC�����i�QD�z
            lv_item_group := cv_group_D;
            
        ELSIF (lv_item_group = cv_group_D) THEN

            -- ======================================================
            -- �y������l�����z
            -- ======================================================
            -- ������
            ln_counts := 0;
            
            -- ����l����񂪑��݂��邩�ǂ���
            SELECT
                count(1)
            INTO
                ln_counts
            FROM
                xxcsm_tmp_sales_plan_cs
            WHERE
                item_cd  = cv_group_N
            AND rownum   = 1; -- 1�s��
            
            IF (ln_counts > 0) THEN
                -- ������
                lv_temp_item := NULL;
                lv_line_head := NULL;
                
                -- ��|����
                lv_line_head := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_prf_cd_down_sales_val || cv_msg_duble || cv_msg_comma;
--//+DEL START 2009/02/18 CT028 S.Son
                -- �Ώی����y���Z�z
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/18 CT028 S.Son
                -- ����l�����i���ʁE����E�e���v�z�E�|���j
                get_col_data(
                             lv_prf_cd_down_sales_val
                            ,1
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );

                IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
--//+DEL START 2009/02/18 CT028 S.Son
/*                  -- �G���[�����y���Z�z 
                    gn_error_cnt := gn_error_cnt + 1 ;

                    -- ���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- ���팏���y���Z�z 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
--//+DEL END 2009/02/18 CT028 S.Son
                  RAISE global_api_others_expt;
                END IF;
                
                -- ����l�����̏o��
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT
                                 ,buff   => lv_temp_item
                                 );
                                 
              -- ======================================================
              -- �y�������l�����z
              -- ======================================================
                -- ������
                lv_temp_item := NULL;
                lv_line_head := NULL;
                
                -- ��|����
                lv_line_head := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_prf_cd_down_pay_val || cv_msg_duble || cv_msg_comma;
--//+DEL START 2009/02/18 CT028 S.Son
                -- �Ώی����y���Z�z
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/18 CT028 S.Son
                -- �����l�����i���ʁE����E�e���v�z�E�|���j
                get_col_data(
                             lv_prf_cd_down_pay_val
                            ,1
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );

                IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
--//+DEL START 2009/02/18 CT028 S.Son
/*                  -- �G���[�����y���Z�z 
                    gn_error_cnt := gn_error_cnt + 1 ;

                    -- ���b�Z�[�W���o��
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- ���팏���y���Z�z 
                  gn_normal_cnt := gn_normal_cnt + 1 ;
*/
--//+DEL END 2009/02/18 CT028 S.Son
                  RAISE global_api_others_expt;
                END IF;
                
                -- �����l�����̏o��
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT                                                     
                                 ,buff   => lv_temp_item
                                 );
            END IF;
            -- ======================================================
            -- �y�����_�v���z
            -- ======================================================
            -- ������
            lv_temp_item := NULL;
            lv_line_head := NULL;
            
            -- ��|����
            lv_line_head := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
            lv_line_head := lv_line_head || cv_msg_duble || lv_prf_cd_p_sum_val || cv_msg_duble || cv_msg_comma;
--//+DEL START 2009/02/18 CT028 S.Son
            -- �Ώی����y���Z�z
          --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/18 CT028 S.Son
            -- ���_�v���i���ʁE����E�e���v�z�E�|���j
            get_col_data(
                         lv_prf_cd_p_sum_val
                        ,1
                        ,lv_line_head
                        ,lv_first_rec
                        ,lv_errbuf 
                        ,lv_retcode
                        ,lv_errmsg
                        ,lv_temp_item
                        );
            IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
--//+DEL START 2009/02/18 CT028 S.Son
/*              -- �G���[�����y���Z�z 
                gn_error_cnt := gn_error_cnt + 1 ;

                -- ���b�Z�[�W���o��
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
             
            ELSIF (lv_retcode = cv_status_normal) THEN
                -- ���팏���y���Z�z 
                gn_normal_cnt := gn_normal_cnt + 1 ;
*/
--//+DEL END 2009/02/18 CT028 S.Son
              RAISE global_api_others_expt;
            END IF;
--//+ADD START 2009/02/20 CT028 S.Son
            IF ov_line_info IS NULL THEN
              ov_line_info := ov_line_info||lv_temp_item;
            END IF;
--//+ADD END 2009/02/20 CT028 S.Son
            -- ���_�v���̏o��
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT                                                     
                             ,buff   => lv_temp_item || CHR(10)
                             );
            -- LOOP�����͏I��
            lv_item_group := NULL;
        END IF;
        
    END LOOP loop_ACD;

--#################################  �Œ��O������  #############################
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_code_cur%ISOPEN) THEN
         CLOSE get_code_cur;
      END IF;
      
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_code_cur%ISOPEN) THEN
         CLOSE get_code_cur;
      END IF;
      
--        
--#####################################  �Œ蕔 END   ###########################
--  
  END deal_csv_data;
--

   /*****************************************************************************
   * Procedure Name   : deal_all_data
   * Description      : ���_���ɏ������J��Ԃ�
   ****************************************************************************/
  PROCEDURE deal_all_data(
--//+ADD START 2009/02/20 CT028 S.Son
        ov_line_info   OUT  VARCHAR2
--//+ADD END 2009/02/20 CT028 S.Son
       ,ov_errbuf      OUT NOCOPY VARCHAR2                                      -- �G���[�E���b�Z�[�W
       ,ov_retcode     OUT NOCOPY VARCHAR2                                      -- ���^�[���E�R�[�h
       ,ov_errmsg      OUT NOCOPY VARCHAR2)                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
      -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)  := 'deal_all_data';        -- �v���O������

    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_kyoten_cd              VARCHAR2(10);             -- ���_�R�[�h
    lv_kyoten_nm              VARCHAR2(200);            -- ���_����
    lb_loop_end               BOOLEAN   := FALSE;       -- LOOP�����p
    lv_kyoten_data            VARCHAR2(4000);           -- ���_�̃{�f�B���
    ln_count                  NUMBER;                   -- �v���p
    
    lv_get_loc_tab            xxcsm_common_pkg.g_kyoten_ttype;  -- ���_�R�[�h���X�g
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
  
  -- ================================================
  -- �y���_�R�[�h���X�g�z�擾����
  -- ================================================
  xxcsm_common_pkg.get_kyoten_cd_lv6(gv_kyotencd
                                     ,gv_kaisou
--//ADD START 2009/05/07 T1_0858 M.Ohtsuki
                                     ,gn_taisyoym
--//ADD END   2009/05/07 T1_0858 M.Ohtsuki
                                     ,lv_get_loc_tab
                                     ,lv_retcode
                                     ,lv_errbuf
                                     ,lv_errmsg
                                    );
                                                                  
    IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
        RAISE global_api_others_expt;
    END IF;

                             
  -- ================================================
  -- �y���_�R�[�h���X�g�z���_���ɉ��L�������J��Ԃ�
  -- ================================================
  <<kyoten_list_loop>>
  FOR ln_count IN 1..lv_get_loc_tab.COUNT LOOP  
    BEGIN
        
        -- ���_�R�[�h
        lv_kyoten_cd := lv_get_loc_tab(ln_count).kyoten_cd;
        
        -- ���_����
        lv_kyoten_nm := lv_get_loc_tab(ln_count).kyoten_nm;
--//+ADD START 2009/02/18 CT028 S.Son
        --�Ώی�����ݒ�
        gn_target_cnt := gn_target_cnt + 1;
--//+ADD END 2009/02/18 CT028 S.Son
        -- ================================================
        -- �y�`�F�b�N�����z
        -- ================================================
        do_check(
                 lv_kyoten_cd
                ,lv_errbuf
                ,lv_retcode
                ,lv_errmsg
                );
                
        IF (lv_retcode = cv_status_warn) THEN  -- �߂�l���x���̏ꍇ
            -- ���̃f�[�^�Ɉړ����܂�
            RAISE global_skip_expt;
        ELSIF (lv_retcode = cv_status_error) THEN -- �߂�l���ُ�̏ꍇ
            RAISE global_process_expt;
        END IF;

        -- ================================================
        -- �y���_�f�[�^�����z
        -- ================================================
        deal_item_data(
                     lv_kyoten_cd
                    ,lv_errbuf
                    ,lv_retcode
                    ,lv_errmsg
                );
                
        IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
          RAISE global_process_expt;
        END IF;
--//+ADD START 2009/02/18 CT028 S.Son
        --���팏�����Z
        gn_normal_cnt := gn_normal_cnt + 1;
--//+ADD END 2009/02/18 CT028 S.Son
        -- ================================================
        -- �y���o�́z
        -- ================================================
        deal_csv_data(
                     lv_kyoten_cd
                    ,lv_kyoten_nm
--//+ADD START 2009/02/20 CT028 S.Son
                    ,ov_line_info
--//+ADD END 2009/02/20 CT028 S.Son
                    ,lv_errbuf
                    ,lv_retcode
                    ,lv_errmsg
                    );

        IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ 
          RAISE global_process_expt;
        END IF;
        
        
        lb_loop_end  := TRUE;
        
        -- �Đݒ�
        gn_index := 0;
        -- �O���_�̃f�[�^���폜����
        DELETE FROM xxcsm_tmp_sales_plan_cs;
    --  
    --#################################  �X�L�b�v��O������  START#############################
    --
    EXCEPTION
        WHEN global_skip_expt THEN 
--//+ADD START 2009/02/10 CT008 T.Tsukino
--            NULL;
--//+DEL START 2009/02/18 CT028 S.Son
        --gn_target_cnt := gn_target_cnt + 1 ;                                                      -- �Ώی��������Z���܂�
--//+DEL END 2009/02/18 CT028 S.Son
          gn_warn_cnt   := gn_warn_cnt + 1 ;                                                        -- �X�L�b�v���������Z���܂�
--
          fnd_file.put_line(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errmsg
                           );
          ov_retcode := cv_status_warn;
--//+ADD END 2009/02/10 CT008 T.Tsukino
    --  
    --#################################  �X�L�b�v��O������  END#############################
    --
    END;
    --
  END LOOP kyoten_list_loop;
--  
--#################################  �Œ��O������  #############################
--
  EXCEPTION
--//+ADD START 2009/02/12 CT008 T.Tsukino
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--//+ADD END 2009/02/12 CT008 T.Tsukino
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
  END deal_all_data;
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
    lv_line_data  VARCHAR2(4000); 
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    
    -- �w�b�_���
    lv_data_head                VARCHAR2(4000);
--//+ADD START 2009/02/12 CT008 T.Tsukino   
    lv_nodata_msg               VARCHAR2(4000);
--//+ADD START 2009/02/12 CT008 T.Tsukino   
--//+ADD START 2009/02/20 CT028 S.Son   
    lv_line_info                VARCHAR2(4000);
--//+ADD END 2009/02/20 CT028 S.Son   
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--//+ADD START 2009/02/20 CT028 S.Son   
    lv_line_info := NULL;
--//+ADD END 2009/02/20 CT028 S.Son   
    -- �w�b�_���̒��o
    lv_data_head := xxccp_common_pkg.get_msg(                                   -- ���_�R�[�h�̏o��
                      iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm1_msg_00093                      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_year                            -- �g�[�N���R�[�h1�i�Ώ۔N�x�j
                     ,iv_token_value1 => gn_taisyoym                            -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_genka_nm                        -- �g�[�N���R�[�h2�i�����j
                     ,iv_token_value2 => gv_genkanm                             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_sysdate                         -- �g�[�N���R�[�h3�i�Ɩ����t�j
--//+UPD START 2009/02/19 CT030 S.Son   
                   --,iv_token_value3 => gd_process_date                        -- �g�[�N���l3
                     ,iv_token_value3 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')        -- �g�[�N���l3
--//+UPD END 2009/02/19 CT030 S.Son   
                     );
     -- �w�b�_���̏o��
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     
                     ,buff   => lv_data_head
                     );
    
    -- �{�f�B�����擾�ideal_all_data���Ăяo���j        
    deal_all_data(
                   lv_line_info
                  ,lv_errbuf
                  ,lv_retcode
                  ,lv_errmsg
                  );
--//+ADD START 2009/02/12 CT008 T.Tsukino                  
--    IF (lv_retcode <> cv_status_normal) THEN  -- �߂�l���ُ�̏ꍇ
      IF (lv_retcode = cv_status_error) THEN  -- �߂�l���ُ�̏ꍇ
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN -- �߂�l���x���̏ꍇ
        ov_retcode := lv_retcode;  
      END IF;
--//+UPD START 2009/02/20 CT028 S.Son   
      IF (gn_normal_cnt = 0) OR (lv_line_info IS NULL) THEN
--//+UPD END 2009/02/20 CT028 S.Son   
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcsm
                         ,iv_name         => cv_csm1_msg_10001
                        );
      
      -- �f�[�^�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_nodata_msg
         );
      END IF;
--//+ADD START 2009/02/12   CT008 T.Tsukino
--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
--//+ADD START 2009/02/10 CT008 T.Tsukino
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--//+ADD END 2009/02/10 CT008 T.Tsukino
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
  END write_csv_file;
--

  /*****************************************************************************
   * Procedure Name   : submain
   * Description      : ��������
   ****************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    gn_target_cnt := 0;                          -- �Ώی����J�E���^�̏�����
    gn_normal_cnt := 0;                          -- ���팏���J�E���^�̏�����
    gn_error_cnt  := 0;                          -- �G���[�����J�E���^�̏�����
    gn_warn_cnt   := 0;                          -- �X�L�b�v�����J�E���^�̏�����

-- ��������
    init(                                        -- init���R�[��
       lv_errbuf                                 -- �G���[�E���b�Z�[�W
      ,lv_retcode                                -- ���^�[���E�R�[�h
      ,lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode <> cv_status_normal) THEN     -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;

-- �f�[�^�̏o��
    write_csv_file(                              -- write_csv_file���R�[��
       lv_errbuf                                 -- �G���[�E���b�Z�[�W
      ,lv_retcode                                -- ���^�[���E�R�[�h
      ,lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN       -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
--//+ADD START 2009/02/10 CT008 T.Tsukino
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
--//+ADD END 2009/02/10 CT008 T.Tsukino      
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
                iv_kyoten_cd     IN     VARCHAR2,                --   ���_�R�[�h
                iv_cost_kind     IN     VARCHAR2,                --   �������
--//+UPD START E_�{�ғ�_09949 K.Taniguchi
--                iv_kyoten_kaisou IN     VARCHAR2                 --   �K�w
                iv_kyoten_kaisou IN     VARCHAR2,                --   �K�w
                iv_new_old_cost_class
                                 IN     VARCHAR2                 --   �V�������敪
--//+UPD END E_�{�ғ�_09949 K.Taniguchi
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
    gv_kyotencd     := iv_kyoten_cd;                    -- ���_�R�[�h
    gn_taisyoym     := TO_NUMBER(iv_taisyo_ym);         -- �Ώ۔N�x
    gv_genkacd      := iv_cost_kind;                    -- �������
    gv_kaisou       := iv_kyoten_kaisou;                -- �K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    gv_new_old_cost_class := iv_new_old_cost_class;     -- �V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi


-- ��������
    submain(                               -- submain���R�[��
        lv_errbuf                          -- �G���[�E���b�Z�[�W
       ,lv_retcode                         -- ���^�[���E�R�[�h
       ,lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
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
        gn_target_cnt := 0;               -- �Ώی����J�E���^�̏�����
        gn_normal_cnt := 0;               -- ���팏���J�E���^�̏�����
        gn_error_cnt  := 1;               -- �G���[�����J�E���^�̏�����
        gn_warn_cnt   := 0;               -- �X�L�b�v�����J�E���^�̏�����
   END IF;
--//+ADD START 2009/02/13 CT008 T.Shimoji
--��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
      );
--//+ADD END 2009/02/13 CT008 T.Shimoji
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
--//+ADD START 2009/02/13 CT008 T.Shimoji
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_ccp1_msg_90005;
--//+ADD END 2009/02/13 CT008 T.Shimoji
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
--  
END XXCSM002A11C;
/
