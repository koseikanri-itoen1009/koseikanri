CREATE OR REPLACE PACKAGE BODY XXCSM002A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A08C(body)
 * Description      : ���ʏ��i�v��(�c�ƌ���)�`�F�b�N���X�g�o��
 * MD.050           : ���ʏ��i�v��(�c�ƌ���)�`�F�b�N���X�g�o�� MD050_CSM_002_A08
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                        ��������(A-1)
 *  do_check                    �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-3)
 *                              �������σf�[�^���݃`�F�b�N(A-4)
 *  item_plan_select            ���i�v��f�[�^���o(A-5)
 *  group3_month_count          ���i�Q�ʌ��ʏW�v(A-6)
 *                              ���ʏ��i�Q�f�[�^�o�^(A-7)
 *  group1_month_count          ���i�敪���ʏW�v(A-8)
 *                              ���ʏ��i�敪�f�[�^�o�^(A-9)
 *  all_item_month_count        ���i���v���ʏW�v(A-10)
 *                              ���ʏ��i���v�f�[�^�o�^(A-11)
 *  item_month_count            ���i�ʌ��ʏW�v(A-12)
 *                              ���ʏ��i�ʃf�[�^�o�^(A-13)
 *  reduce_price_count          �l�����ʏW�v(A-14)
 *                              ���ʒl���f�[�^�o�^(A-15)
 *  kyoten_month_count          ���_�ʌ��ʏW�v(A-16)
 *                              ���ʋ��_�ʃf�[�^�AH��o�^(A-17)
 *  write_csv_file              �`�F�b�N���X�g�f�[�^�o��(A-18)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   S.Son            �V�K�쐬
 *  2009/02/12    1.1   SCS H.Yoshitake [��QCT_013]  �ގ��@�\���쓝��Ή�
 *  2009/02/13    1.2   SCS S.Son       [��QCT_015]  �V���i�Ή�
 *  2009/02/16    1.3   SCS S.Son       [��QCT_021]  ����0�̕s��Ή�
 *  2009/02/19    1.4   SCS K.Yamada    [��QCT_037]  �G���[�����s��̑Ή�
 *                                      [��QCT_038]  �N�Ԕ���0�s��̑Ή�
 *                                      [��QCT_048]  �w�b�_�o�͕s��̑Ή�
 *  2009/02/27    1.5   SCS T.Tsukino   [��QCT_070]  �Ώ�0�����̃w�b�_�o�͕s��Ή�
 *  2009/05/07    1.6   SCS M.Ohtsuki   [��QT1_0858] ���ʊ֐��C���ɔ����p�����[�^�̒ǉ�
 *  2009/05/21    1.7   SCS M.Ohtsuki   [��QT1_1101] ������z�s��(�l���z�܂�)
 *  2009/07/13    1.8   SCS M.Ohtsuki   [SCS��Q�Ǘ��ԍ�0000657] �w�b�_�o�͎��s�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_comma              constant varchar2(1) := ',';
  --
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
  --���b�Z�[�W�[�R�[�h
  cv_msg_10003              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';       --�R���J�����g���̓p�����[�^���b�Z�[�W(�Ώ۔N�x)
  cv_msg_00048              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';       --�R���J�����g���̓p�����[�^���b�Z�[�W(���_�R�[�h)
  cv_msg_10004              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10004';       --�R���J�����g���̓p�����[�^���b�Z�[�W(�K�w)
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --�z��O�G���[���b�Z�[�W
  cv_chk_err_00005          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';       --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_chk_err_00087          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';       --���i�v�斢�ݒ胁�b�Z�[�W
  cv_chk_err_00098          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00098';       --���ʏ��i�v��(�c�ƌ���)�`�F�b�N���X�g�w�b�_�p���b�Z�[�W
  cv_chk_err_00088          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';       --���i�v��P�i�ʈ��������������b�Z�[�W
  cv_chk_err_10001          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';       --�擾�f�[�^0���G���[���b�Z�[�W
  --�g�[�N��
  cv_tkn_prof               CONSTANT VARCHAR2(100) := 'PROF_NAME';               --�J�X�^���E�v���t�@�C���E�I�v�V�����̉p��
  cv_tkn_kyoten_cd          CONSTANT VARCHAR2(100) := 'KYOTEN_CD';               --���_�R�[�h
  cv_tkn_kyoten_nm          CONSTANT VARCHAR2(100) := 'KYOTEN_NM';               --���_��
  cv_tkn_year               CONSTANT VARCHAR2(100) := 'TAISYOU_YM';               --�Ώ۔N�x
  cv_tkn_yyyy               CONSTANT VARCHAR2(100) := 'YYYY';                    --���̓p�����[�^�Ώ۔N�x
  cv_tkn_level              CONSTANT VARCHAR2(100) := 'HIERARCHY_LEVEL';         --���̓p�����[�^�̊K�w
  cv_tkn_nichiji            CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';         --�쐬����  
  --
  cv_language_ja            CONSTANT VARCHAR2(2)   := USERENV('LANG');           --����(���{��)
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                       --�t���OY
  cv_whick_log              CONSTANT VARCHAR2(3)   := 'LOG';                       --���O

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
  gn_seq_no        NUMBER;                    -- �o�͏�
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
  year_plan_check_expt          EXCEPTION;              --�N�ԏ��i�v��f�[�^���݃`�F�b�N
  assin_end_check_expt          EXCEPTION;              --���i�v��P�i�ʈ������������`�F�b�N
  kyoten_skip_expt              EXCEPTION;              --���_�P�ʂŃX�L�b�v

  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCSM002A08C';                -- �p�b�P�[�W��
  cv_item_sum_profile            CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';     --���i���v�v���t�@�C����
  cv_sales_dis_profile           CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';     --����l���v���t�@�C����
  cv_receipt_dis_profile         CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';     --�����l���v���t�@�C����
  cv_h_standard_profile          CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_4';     --H��v���t�@�C����
  cv_amount_profile              CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_1';      --���ʃv���t�@�C����
  cv_budget_profile              CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';      --����v���t�@�C����
  cv_margin_profile              CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6';     --�e���v�z�v���t�@�C����
  cv_credit_profile              CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_4';      --�|���v���t�@�C����
  cv_group_d                     CONSTANT VARCHAR2(1)   := 'D';                           --���i�R�[�h1��D(���̑�)
  cv_location_1                  CONSTANT VARCHAR2(1)   := '1';                            --���̓p�����[�^���_�R�[�h�f1�f
  cv_location_1_nm               CONSTANT VARCHAR2(100)   := '�S���_';                     --���̓p�����[�^���_�R�[�h�f1�f
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_item_sum_name       VARCHAR2(50);         --���i���v(�v���t�@�C����)
  gv_sales_dis_name      VARCHAR2(50);         --����l��(�v���t�@�C����)
  gv_receipt_dis_name    VARCHAR2(50);         --�����l��(�v���t�@�C����)
  gv_h_standard_name     VARCHAR2(50);         --H�(�v���t�@�C����)
  gv_amount_name         VARCHAR2(50);         --����(�v���t�@�C����)
  gv_budget_name         VARCHAR2(50);         --����(�v���t�@�C����)
  gv_margin_name         VARCHAR2(50);         --�e���v�z(�v���t�@�C����)
  gv_credit_name         VARCHAR2(50);         --�|��(�v���t�@�C����)
  gn_subject_year        NUMBER;               --���̓p�����[�^�D�Ώ۔N�x
  gv_location_cd         VARCHAR2(4);          --���̓p�����[�^�D���_�R�[�h
  gv_hierarchy_level     VARCHAR2(2);          --���̓p�����[�^�D�K�w
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';            -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn_value      VARCHAR2(4000);  --�g�[�N���l

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
    lv_pram_year          VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��(�Ώ۔N�x)
    lv_pram_location      VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��(���_�R�[�h)
    lv_pram_level         VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��(�K�w)
    

    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** ���[�J���ϐ������� ***

    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--�@���̓p�����[�^�����b�Z�[�W�o��
    --�Ώ۔N�x
    lv_pram_year := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_msg_10003
                                            ,iv_token_name1  => cv_tkn_yyyy
                                            ,iv_token_value1 => gn_subject_year
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_year);
    --���_�R�[�h
    lv_pram_location := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_msg_00048
                                            ,iv_token_name1  => cv_tkn_kyoten_cd
                                            ,iv_token_value1 => gv_location_cd
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_location);
    --�K�w
    lv_pram_level := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_msg_10004
                                           ,iv_token_name1  => cv_tkn_level
                                           ,iv_token_value1 => gv_hierarchy_level
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_level);
--�B �v���t�@�C���l�擾
    --�`�F�b�N���X�g���ږ�(���i���v)
    gv_item_sum_name := FND_PROFILE.VALUE(cv_item_sum_profile);
    IF gv_item_sum_name IS NULL THEN
        lv_tkn_value := cv_item_sum_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --�`�F�b�N���X�g���ږ�(����l��)
    gv_sales_dis_name := FND_PROFILE.VALUE(cv_sales_dis_profile);
    IF gv_sales_dis_name IS NULL THEN
        lv_tkn_value := cv_sales_dis_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --�`�F�b�N���X�g���ږ�(�����l��)
    gv_receipt_dis_name := FND_PROFILE.VALUE(cv_receipt_dis_profile);
    IF gv_receipt_dis_name IS NULL THEN
        lv_tkn_value := cv_receipt_dis_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --�`�F�b�N���X�g���ږ�(H�)
    gv_h_standard_name := FND_PROFILE.VALUE(cv_h_standard_profile);
    IF gv_h_standard_name IS NULL THEN
        lv_tkn_value := cv_h_standard_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --���i�v�惊�X�g���ږ�(����)
    gv_amount_name := FND_PROFILE.VALUE(cv_amount_profile);
    IF gv_amount_name IS NULL THEN
        lv_tkn_value := cv_amount_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --���i�v�惊�X�g���ږ�(����)
    gv_budget_name := FND_PROFILE.VALUE(cv_budget_profile);
    IF gv_budget_name IS NULL THEN
        lv_tkn_value := cv_budget_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --�`�F�b�N���X�g���ږ�(�e���v�z)
    gv_margin_name := FND_PROFILE.VALUE(cv_margin_profile);
    IF gv_margin_name IS NULL THEN
        lv_tkn_value := cv_margin_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    
    --���i�v�惊�X�g���ږ�(�|��)
    gv_credit_name := FND_PROFILE.VALUE(cv_credit_profile);
    IF gv_credit_name IS NULL THEN
        lv_tkn_value := cv_credit_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  * Procedure Name   : do_check
  * Description      : �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-3)
  *                  : �������σf�[�^���݃`�F�b�N(A-4)            
  ****************************************************************************/
  PROCEDURE do_check (
       iv_kyoten_cd     IN  VARCHAR2                  --A-2�Ŏ擾�������_�R�[�h
      ,ov_errbuf     OUT NOCOPY VARCHAR2              -- ���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode    OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
      ,ov_errmsg     OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--

--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'do_check'; -- �v���O������
    
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
    -- �f�[�^���݃`�F�b�N�p
    ln_counts                 NUMBER(1,0) := 0;
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================

--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

    -- =========================================================================
    -- �N�ԏ��i�v��f�[�^���݃`�F�b�N(A-3)
    -- =========================================================================
      -- �Đݒ�
    ln_counts := 0;
    BEGIN
      SELECT   COUNT(xiph.plan_year)
      INTO     ln_counts
      FROM     xxcsm_item_plan_lines          xipl                     -- ���i�v�斾�׃e�[�u��
               ,xxcsm_item_plan_headers       xiph                     -- ���i�v��w�b�_�e�[�u��
      WHERE    xiph.plan_year = gn_subject_year
      AND      xiph.location_cd = iv_kyoten_cd
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id
      AND      ROWNUM = 1;      
      -- ������0�̏ꍇ�A�G���[���b�Z�[�W���o���āA���������~���܂��B
      IF (ln_counts = 0) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_chk_err_00087                  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_year                       -- �g�[�N���R�[�h1�i�Ώ۔N�x�j
                      ,iv_token_value1 => gn_subject_year                   -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_kyoten_cd                  -- �g�[�N���R�[�h2�i���_�R�[�h�j
                      ,iv_token_value2 => iv_kyoten_cd                      -- �g�[�N���l2
                     );
          lv_errbuf := lv_errmsg;
          RAISE year_plan_check_expt;
      END IF;
    END;
    
    -- =========================================================================
    -- �������σf�[�^���݃`�F�b�N(A-4)
    -- =========================================================================
      -- �Đݒ�
    ln_counts := 0;
    BEGIN
      SELECT COUNT(xiph.plan_year)
      INTO   ln_counts
      FROM     xxcsm_item_plan_lines          xipl                     -- ���i�v�斾�׃e�[�u��
               ,xxcsm_item_plan_headers       xiph                     -- ���i�v��w�b�_�e�[�u��
      WHERE    xiph.plan_year = gn_subject_year
      AND      xiph.location_cd = iv_kyoten_cd
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id
--//+UPD START 2009/02/13 CT015 S.Son
    --AND      xipl.item_kbn = '1'                                     --���i�敪(1�F���i�P�i)
      AND      xipl.item_kbn <> '0'                                    --���i�敪(1�F���i�P�i�A2�F�V���i)
--//+UPD END 2009/02/13 CT015 S.Son
      AND      ROWNUM = 1;      
      
      IF (ln_counts = 0) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_chk_err_00088                  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_year                       -- �g�[�N���R�[�h1�i�Ώ۔N�x�j
                      ,iv_token_value1 => gn_subject_year                   -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_kyoten_cd                  -- �g�[�N���R�[�h2�i���_�R�[�h�j
                      ,iv_token_value2 => iv_kyoten_cd                      -- �g�[�N���l2
                     );
          lv_errbuf := lv_errmsg;
          RAISE assin_end_check_expt;
      END IF;
    END;
--
  EXCEPTION
    -- *** �N�ԏ��i�v��f�[�^���݃`�F�b�N ***
    WHEN year_plan_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** �������σf�[�^���݃`�F�b�N ***
    WHEN assin_end_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������  #############################

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
--#####################################  �Œ蕔 END   ###########################
--
  END do_check;
--
  /****************************************************************************
  * Procedure Name   : group3_month_count
  * Description      : ���i�Q�ʌ��ʏW�v(A-6)
  *                  : ���ʏ��i�Q�f�[�^�o�^(A-7)
  ****************************************************************************/
  PROCEDURE group3_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2�Ŏ擾�������_�R�[�h
      ,iv_kyoten_nm     IN  VARCHAR2                     --A-2�Ŏ擾�������_����
      ,iv_group3_cd     IN  VARCHAR2                     --A-5�Ŏ擾��������Q�R�[�h3
      ,iv_group3_nm     IN  VARCHAR2                     --A-5�Ŏ擾��������Q��3
      ,ov_errbuf        OUT NOCOPY VARCHAR2              -- ���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode       OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--

--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'group3_month_count'; -- �v���O������
    
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
    ln_month_sale_budget       NUMBER;         --���ʏ��i�Q�ʔ���
    ln_month_amount            NUMBER;         --���ʏ��i�Q�ʐ���
    ln_month_sub_margin        NUMBER;         --���ʏ��i�Q�ʑe���v��������
    ln_year_month              NUMBER;         --�N��
    ln_month_margin            NUMBER;         --���ʏ��i�Q�ʑe���v�z
    ln_month_credit_bunbo      NUMBER;         --���ʏ��i�Q�ʊ|������
    ln_month_credit            NUMBER;         --���ʏ��i�Q�ʊ|��
    ln_year_sale_budget        NUMBER;         --�N�ԏ��i�Q�ʔ���
    ln_year_amount             NUMBER;         --�N�ԏ��i�Q�ʐ���
    ln_year_margin             NUMBER;         --�N�ԏ��i�Q�ʑe���v�z
    ln_year_credit_bunbo       NUMBER;         --�N�ԏ��i�Q�ʊ|������
    ln_year_credit             NUMBER;         --�N�ԏ��i�Q�ʊ|��
    ln_sale_budget_5           NUMBER;         --5������
    ln_sale_budget_6           NUMBER;         --6������
    ln_sale_budget_7           NUMBER;         --7������
    ln_sale_budget_8           NUMBER;         --8������
    ln_sale_budget_9           NUMBER;         --9������
    ln_sale_budget_10          NUMBER;         --10������
    ln_sale_budget_11          NUMBER;         --11������
    ln_sale_budget_12          NUMBER;         --12������
    ln_sale_budget_1           NUMBER;         --1������
    ln_sale_budget_2           NUMBER;         --2������
    ln_sale_budget_3           NUMBER;         --3������
    ln_sale_budget_4           NUMBER;         --4������
    ln_amount_5                NUMBER;         --5������
    ln_amount_6                NUMBER;         --6������
    ln_amount_7                NUMBER;         --7������
    ln_amount_8                NUMBER;         --8������
    ln_amount_9                NUMBER;         --9������
    ln_amount_10               NUMBER;         --10������
    ln_amount_11               NUMBER;         --11������
    ln_amount_12               NUMBER;         --12������
    ln_amount_1                NUMBER;         --1������
    ln_amount_2                NUMBER;         --2������
    ln_amount_3                NUMBER;         --3������
    ln_amount_4                NUMBER;         --4������
    ln_margin_5                NUMBER;         --5���e���v�z
    ln_margin_6                NUMBER;         --6���e���v�z
    ln_margin_7                NUMBER;         --7���e���v�z
    ln_margin_8                NUMBER;         --8���e���v�z
    ln_margin_9                NUMBER;         --9���e���v�z
    ln_margin_10               NUMBER;         --10���e���v�z
    ln_margin_11               NUMBER;         --11���e���v�z
    ln_margin_12               NUMBER;         --12���e���v�z
    ln_margin_1                NUMBER;         --1���e���v�z
    ln_margin_2                NUMBER;         --2���e���v�z
    ln_margin_3                NUMBER;         --3���e���v�z
    ln_margin_4                NUMBER;         --4���e���v�z
    ln_credit_5                NUMBER;         --5���|��
    ln_credit_6                NUMBER;         --6���|��
    ln_credit_7                NUMBER;         --7���|��
    ln_credit_8                NUMBER;         --8���|��
    ln_credit_9                NUMBER;         --9���|��
    ln_credit_10               NUMBER;         --10���|��
    ln_credit_11               NUMBER;         --11���|��
    ln_credit_12               NUMBER;         --12���|��
    ln_credit_1                NUMBER;         --1���|��
    ln_credit_2                NUMBER;         --2���|��
    ln_credit_3                NUMBER;         --3���|��
    ln_credit_4                NUMBER;         --4���|��
    ln_month_no                NUMBER;         --��
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
    --���i�Q���ʃf�[�^���o
    CURSOR   group3_month_cur
    IS
      SELECT  SUM(xipl.sales_budget)  sales_budget_sum                 --������z
             ,SUM(xipl.amount)        amount_sum                       --����
             ,SUM(xipl.amount * xcgv.now_business_cost) sub_margin     --�e���v����
             ,SUM(xipl.amount * xcgv.now_unit_price)    credit_bunbo   --�|������
             ,xipl.year_month                                          --�N��
      FROM    xxcsm_item_plan_lines       xipl                         -- ���i�v�斾�׃e�[�u��
             ,xxcsm_item_plan_headers     xiph                         -- ���i�v��w�b�_�e�[�u��
             ,xxcsm_commodity_group3_v    xcgv                         -- ����Q�R�[�h�R�r���[
      WHERE   xiph.plan_year = gn_subject_year                         --�Ώ۔N�x
      AND     xiph.location_cd = iv_kyoten_cd                          --���_�R�[�h
      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
      AND     xipl.item_group_no LIKE REPLACE(iv_group3_cd,'*','_')    --����Q�R�[�h3��     
--//+UPD START 2009/02/13 CT015 S.Son
    --AND     xipl.item_kbn = '1'                                      --���i�敪(1�F���i�P�i)
      AND     xipl.item_kbn <> '0'                                     --���i�敪(1�F���i�P�i�A2�F�V���i)
--//+UPD END 2009/02/13 CT015 S.Son
      AND     xipl.item_no = xcgv.item_cd
      GROUP BY xipl.year_month
      ORDER BY xipl.year_month
    ;
    group3_month_cur_rec group3_month_cur%ROWTYPE;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--���[�J���ϐ�������
    ln_month_sale_budget    := 0;              --���ʏ��i�Q�ʔ���
    ln_month_amount         := 0;              --���ʏ��i�Q�ʐ���
    ln_month_margin         := 0;              --���ʏ��i�Q�ʑe���v�z
    ln_month_credit_bunbo   := 0;              --���ʏ��i�Q�ʊ|������
    ln_month_credit         := 0;              --���ʏ��i�Q�ʊ|��
    ln_month_sub_margin     := 0;              --���ʏ��i�Q�ʑe���v����
    ln_year_sale_budget     := 0;              --�N�ԏ��i�Q�ʔ���
    ln_year_amount          := 0;              --�N�ԏ��i�Q�ʐ���
    ln_year_margin          := 0;              --�N�ԏ��i�Q�ʑe���v�z
    ln_year_credit_bunbo    := 0;              --�N�ԏ��i�Q�ʊ|������
    ln_year_credit          := 0;              --�N�ԏ��i�Q�ʊ|��
    
    OPEN group3_month_cur;
    <<group3_month_loop>>
    LOOP
      FETCH group3_month_cur INTO group3_month_cur_rec;
      EXIT WHEN group3_month_cur%NOTFOUND;
        ln_month_sale_budget    :=  group3_month_cur_rec.sales_budget_sum;                          --���ʏ��i�Q�ʔ���
        ln_month_amount         :=  group3_month_cur_rec.amount_sum;                                --���ʏ��i�Q�ʐ���
        ln_month_sub_margin     :=  group3_month_cur_rec.sub_margin;                                --���ʏ��i�Q�ʑe���v����
        ln_month_credit_bunbo   :=  group3_month_cur_rec.credit_bunbo;                              --���ʏ��i�Q�ʊ|������
        ln_year_month           :=  group3_month_cur_rec.year_month;                                --�N��
        --���i�Q���ʃf�[�^�Z�o
        ln_month_margin         := ln_month_sale_budget - ln_month_sub_margin;                      --���ʏ��i�Q�ʑe���v�z
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --���ʏ��i�Q�ʊ|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_sale_budget     := ln_year_sale_budget + ln_month_sale_budget;                      --�N�ԏ��i�Q�ʔ���
        ln_year_amount          := ln_year_amount + ln_month_amount;                                --�N�ԏ��i�Q�ʐ���
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --�N�ԏ��i�Q�ʑe���v�z
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --�N�ԏ��i�Q�ʊ|������
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit        := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --�N�ԏ��i�Q�ʊ|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        --�e���f�[�^�ۑ�
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP group3_month_loop;
    CLOSE group3_month_cur;
--
--//+ADD START 2009/02/19 CT038 K.Yamada
    IF ln_year_sale_budget <> 0 THEN
--//+ADD END   2009/02/19 CT038 K.Yamada
      --���ʏ��i�Q�f�[�^�o�^
      --1�s�ځF����
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,iv_group3_cd
      ,iv_group3_nm
      ,gv_amount_name
      ,NVL(ln_amount_5,0)
      ,NVL(ln_amount_6,0)
      ,NVL(ln_amount_7,0)
      ,NVL(ln_amount_8,0)
      ,NVL(ln_amount_9,0)
      ,NVL(ln_amount_10,0)
      ,NVL(ln_amount_11,0)
      ,NVL(ln_amount_12,0)
      ,NVL(ln_amount_1,0)
      ,NVL(ln_amount_2,0)
      ,NVL(ln_amount_3,0)
      ,NVL(ln_amount_4,0)
      ,NVL(ln_year_amount,0)
      );
      --2�s�ځF����
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_budget_name
      ,NVL(ROUND(ln_sale_budget_5/1000),0)
      ,NVL(ROUND(ln_sale_budget_6/1000),0)
      ,NVL(ROUND(ln_sale_budget_7/1000),0)
      ,NVL(ROUND(ln_sale_budget_8/1000),0)
      ,NVL(ROUND(ln_sale_budget_9/1000),0)
      ,NVL(ROUND(ln_sale_budget_10/1000),0)
      ,NVL(ROUND(ln_sale_budget_11/1000),0)
      ,NVL(ROUND(ln_sale_budget_12/1000),0)
      ,NVL(ROUND(ln_sale_budget_1/1000),0)
      ,NVL(ROUND(ln_sale_budget_2/1000),0)
      ,NVL(ROUND(ln_sale_budget_3/1000),0)
      ,NVL(ROUND(ln_sale_budget_4/1000),0)
      ,NVL(ROUND(ln_year_sale_budget/1000),0)
      );
      --3�s�ځF�e���v�z
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_margin_name
      ,NVL(ROUND(ln_margin_5/1000),0)
      ,NVL(ROUND(ln_margin_6/1000),0)
      ,NVL(ROUND(ln_margin_7/1000),0)
      ,NVL(ROUND(ln_margin_8/1000),0)
      ,NVL(ROUND(ln_margin_9/1000),0)
      ,NVL(ROUND(ln_margin_10/1000),0)
      ,NVL(ROUND(ln_margin_11/1000),0)
      ,NVL(ROUND(ln_margin_12/1000),0)
      ,NVL(ROUND(ln_margin_1/1000),0)
      ,NVL(ROUND(ln_margin_2/1000),0)
      ,NVL(ROUND(ln_margin_3/1000),0)
      ,NVL(ROUND(ln_margin_4/1000),0)
      ,NVL(ROUND(ln_year_margin/1000),0)
      );
      --4�s�ځF�|��
      gn_seq_no := gn_seq_no + 1;
      INSERT INTO xxcsm_tmp_month_item_plan
      (
        seq_no
       ,location_cd
       ,location_nm
       ,code
       ,name
       ,kbn_nm
       ,plan_data5
       ,plan_data6
       ,plan_data7
       ,plan_data8
       ,plan_data9
       ,plan_data10
       ,plan_data11
       ,plan_data12
       ,plan_data1
       ,plan_data2
       ,plan_data3
       ,plan_data4
       ,plan_year
      )
      VALUES
      (
       gn_seq_no
      ,iv_kyoten_cd
      ,iv_kyoten_nm
      ,''
      ,''
      ,gv_credit_name
      ,NVL(ln_credit_5,0)
      ,NVL(ln_credit_6,0)
      ,NVL(ln_credit_7,0)
      ,NVL(ln_credit_8,0)
      ,NVL(ln_credit_9,0)
      ,NVL(ln_credit_10,0)
      ,NVL(ln_credit_11,0)
      ,NVL(ln_credit_12,0)
      ,NVL(ln_credit_1,0)
      ,NVL(ln_credit_2,0)
      ,NVL(ln_credit_3,0)
      ,NVL(ln_credit_4,0)
      ,NVL(ln_year_credit,0)
      );
--//+ADD START 2009/02/19 CT038 K.Yamada
    END IF;
--//+ADD END   2009/02/19 CT038 K.Yamada
--
--#################################  �Œ��O������  #############################
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
--#####################################  �Œ蕔 END   ###########################
--
  END group3_month_count;
--
  /****************************************************************************
  * Procedure Name   : group1_month_count
  * Description      : ���i�敪���ʏW�v(A-8)
  *                  : ���ʏ��i�敪�f�[�^�o�^(A-9)
  ****************************************************************************/
  PROCEDURE group1_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     -- A-2�Ŏ擾�������_�R�[�h
      ,iv_kyoten_nm     IN  VARCHAR2                     -- A-2�Ŏ擾�������_����
      ,iv_group1_cd     IN  VARCHAR2                     -- A-5�Ŏ擾��������Q�R�[�h1
      ,iv_group1_nm     IN  VARCHAR2                     -- A-5�Ŏ擾��������Q��1
      ,ov_errbuf        OUT NOCOPY VARCHAR2              -- ���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode       OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--

--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'group1_month_count'; -- �v���O������
    
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
    ln_month_sale_budget       NUMBER;         --���ʏ��i�敪����
    ln_month_amount            NUMBER;         --���ʏ��i�敪����
    ln_month_sub_margin        NUMBER;         --���ʏ��i�敪�e���v����
    ln_year_month              NUMBER;         --�N��
    ln_month_margin            NUMBER;         --���ʏ��i�敪�e���v�z
    ln_month_credit_bunbo      NUMBER;         --���ʏ��i�敪�|������
    ln_month_credit            NUMBER;         --���ʏ��i�敪�|��
    ln_year_sale_budget        NUMBER;         --�N�ԏ��i�敪����
    ln_year_amount             NUMBER;         --�N�ԏ��i�敪����
    ln_year_margin             NUMBER;         --�N�ԏ��i�敪�e���v�z
    ln_year_credit_bunbo       NUMBER;         --�N�ԏ��i�敪�|������
    ln_year_credit             NUMBER;         --�N�ԏ��i�敪�|��
    ln_sale_budget_5           NUMBER;         --5������
    ln_sale_budget_6           NUMBER;         --6������
    ln_sale_budget_7           NUMBER;         --7������
    ln_sale_budget_8           NUMBER;         --8������
    ln_sale_budget_9           NUMBER;         --9������
    ln_sale_budget_10          NUMBER;         --10������
    ln_sale_budget_11          NUMBER;         --11������
    ln_sale_budget_12          NUMBER;         --12������
    ln_sale_budget_1           NUMBER;         --1������
    ln_sale_budget_2           NUMBER;         --2������
    ln_sale_budget_3           NUMBER;         --3������
    ln_sale_budget_4           NUMBER;         --4������
    ln_amount_5                NUMBER;         --5������
    ln_amount_6                NUMBER;         --6������
    ln_amount_7                NUMBER;         --7������
    ln_amount_8                NUMBER;         --8������
    ln_amount_9                NUMBER;         --9������
    ln_amount_10               NUMBER;         --10������
    ln_amount_11               NUMBER;         --11������
    ln_amount_12               NUMBER;         --12������
    ln_amount_1                NUMBER;         --1������
    ln_amount_2                NUMBER;         --2������
    ln_amount_3                NUMBER;         --3������
    ln_amount_4                NUMBER;         --4������
    ln_margin_5                NUMBER;         --5���e���v�z
    ln_margin_6                NUMBER;         --6���e���v�z
    ln_margin_7                NUMBER;         --7���e���v�z
    ln_margin_8                NUMBER;         --8���e���v�z
    ln_margin_9                NUMBER;         --9���e���v�z
    ln_margin_10               NUMBER;         --10���e���v�z
    ln_margin_11               NUMBER;         --11���e���v�z
    ln_margin_12               NUMBER;         --12���e���v�z
    ln_margin_1                NUMBER;         --1���e���v�z
    ln_margin_2                NUMBER;         --2���e���v�z
    ln_margin_3                NUMBER;         --3���e���v�z
    ln_margin_4                NUMBER;         --4���e���v�z
    ln_credit_5                NUMBER;         --5���|��
    ln_credit_6                NUMBER;         --6���|��
    ln_credit_7                NUMBER;         --7���|��
    ln_credit_8                NUMBER;         --8���|��
    ln_credit_9                NUMBER;         --9���|��
    ln_credit_10               NUMBER;         --10���|��
    ln_credit_11               NUMBER;         --11���|��
    ln_credit_12               NUMBER;         --12���|��
    ln_credit_1                NUMBER;         --1���|��
    ln_credit_2                NUMBER;         --2���|��
    ln_credit_3                NUMBER;         --3���|��
    ln_credit_4                NUMBER;         --4���|��
    ln_month_no                NUMBER;         --��
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
    --���i�敪���ʃf�[�^���o
    CURSOR   group1_month_cur
    IS
      SELECT  SUM(xipl.sales_budget)  sales_budget_sum               --������z
             ,SUM(xipl.amount)        amount_sum                     --����
             ,SUM(xipl.amount * xcgv.now_business_cost) sub_margin   --
             ,SUM(xipl.amount * xcgv.now_unit_price)    credit_bunbo --
             ,xipl.year_month                                        --�N��
      FROM    xxcsm_item_plan_lines       xipl                       -- ���i�v�斾�׃e�[�u��
             ,xxcsm_item_plan_headers     xiph                       -- ���i�v��w�b�_�e�[�u��
             ,xxcsm_commodity_group3_v    xcgv                       -- ����Q�R�[�h�R�r���[
      WHERE   xiph.plan_year = gn_subject_year                       --�Ώ۔N�x
      AND     xiph.location_cd = iv_kyoten_cd                        --���_�R�[�h
      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
      AND     xipl.item_group_no LIKE iv_group1_cd||'%'              --����Q�R�[�h1��
--//+UPD START 2009/02/13 CT015 S.Son
    --AND     xipl.item_kbn = '1'                                    --���i�敪(1�F���i�P�i)
      AND     xipl.item_kbn <> '0'                                   --���i�敪(1�F���i�P�i�A2�F�V���i)
--//+UPD END 2009/02/13 CT015 S.Son
      AND     xipl.item_no = xcgv.item_cd                           
      GROUP BY xipl.year_month
      ORDER BY xipl.year_month
    ;
    group1_month_cur_rec group1_month_cur%ROWTYPE;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--���[�J���ϐ�������
    ln_month_sale_budget    := 0;              --���ʏ��i�敪����
    ln_month_amount         := 0;              --���ʏ��i�敪����
    ln_month_margin         := 0;              --���ʏ��i�敪�e���v�z
    ln_month_credit_bunbo   := 0;              --���ʏ��i�敪�|������
    ln_month_credit         := 0;              --���ʏ��i�敪�|��
    ln_month_sub_margin     := 0;              --���ʏ��i�敪�e���v����
    ln_year_sale_budget     := 0;              --�N�ԏ��i�敪����
    ln_year_amount          := 0;              --�N�ԏ��i�敪����
    ln_year_margin          := 0;              --�N�ԏ��i�敪�e���v�z
    ln_year_credit_bunbo    := 0;              --�N�ԏ��i�敪�|������
    ln_year_credit          := 0;              --�N�ԏ��i�敪�|��
    
    OPEN group1_month_cur;
    <<group1_month_loop>>
    LOOP
      FETCH group1_month_cur INTO group1_month_cur_rec;
      EXIT WHEN group1_month_cur%NOTFOUND;
        ln_month_sale_budget    :=  group1_month_cur_rec.sales_budget_sum;                          --���ʏ��i�敪����
        ln_month_amount         :=  group1_month_cur_rec.amount_sum;                                --���ʏ��i�敪����
        ln_month_sub_margin     :=  group1_month_cur_rec.sub_margin;
        ln_month_credit_bunbo   :=  group1_month_cur_rec.credit_bunbo;
        ln_year_month           :=  group1_month_cur_rec.year_month;                                --�N��
        --���i�敪���ʃf�[�^�Z�o
        ln_month_margin         := ln_month_sale_budget - ln_month_sub_margin;                      --���ʏ��i�敪�e���v�z
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --���ʏ��i�敪�|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_sale_budget     := ln_year_sale_budget + ln_month_sale_budget;                      --�N�ԏ��i�敪����
        ln_year_amount          := ln_year_amount + ln_month_amount;                                --�N�ԏ��i�敪����
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --�N�ԏ��i�敪�e���v�z
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --�N�ԏ��i�敪�|������
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit        := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --�N�ԏ��i�敪�|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        --�e���f�[�^�ۑ�
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP group1_month_loop;
    CLOSE group1_month_cur;
--
    --���ʏ��i�敪�f�[�^�o�^
    --1�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,iv_group1_cd
    ,iv_group1_nm
    ,gv_amount_name
    ,NVL(ln_amount_5,0)
    ,NVL(ln_amount_6,0)
    ,NVL(ln_amount_7,0)
    ,NVL(ln_amount_8,0)
    ,NVL(ln_amount_9,0)
    ,NVL(ln_amount_10,0)
    ,NVL(ln_amount_11,0)
    ,NVL(ln_amount_12,0)
    ,NVL(ln_amount_1,0)
    ,NVL(ln_amount_2,0)
    ,NVL(ln_amount_3,0)
    ,NVL(ln_amount_4,0)
    ,NVL(ln_year_amount,0)
    );
    --2�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_sale_budget_5/1000),0)
    ,NVL(ROUND(ln_sale_budget_6/1000),0)
    ,NVL(ROUND(ln_sale_budget_7/1000),0)
    ,NVL(ROUND(ln_sale_budget_8/1000),0)
    ,NVL(ROUND(ln_sale_budget_9/1000),0)
    ,NVL(ROUND(ln_sale_budget_10/1000),0)
    ,NVL(ROUND(ln_sale_budget_11/1000),0)
    ,NVL(ROUND(ln_sale_budget_12/1000),0)
    ,NVL(ROUND(ln_sale_budget_1/1000),0)
    ,NVL(ROUND(ln_sale_budget_2/1000),0)
    ,NVL(ROUND(ln_sale_budget_3/1000),0)
    ,NVL(ROUND(ln_sale_budget_4/1000),0)
    ,NVL(ROUND(ln_year_sale_budget/1000),0)
    );
    --3�s�ځF�e���v�z
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_margin_5/1000),0)
    ,NVL(ROUND(ln_margin_6/1000),0)
    ,NVL(ROUND(ln_margin_7/1000),0)
    ,NVL(ROUND(ln_margin_8/1000),0)
    ,NVL(ROUND(ln_margin_9/1000),0)
    ,NVL(ROUND(ln_margin_10/1000),0)
    ,NVL(ROUND(ln_margin_11/1000),0)
    ,NVL(ROUND(ln_margin_12/1000),0)
    ,NVL(ROUND(ln_margin_1/1000),0)
    ,NVL(ROUND(ln_margin_2/1000),0)
    ,NVL(ROUND(ln_margin_3/1000),0)
    ,NVL(ROUND(ln_margin_4/1000),0)
    ,NVL(ROUND(ln_year_margin/1000),0)
    );
    --4�s�ځF�|��
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,NVL(ln_credit_5,0)
    ,NVL(ln_credit_6,0)
    ,NVL(ln_credit_7,0)
    ,NVL(ln_credit_8,0)
    ,NVL(ln_credit_9,0)
    ,NVL(ln_credit_10,0)
    ,NVL(ln_credit_11,0)
    ,NVL(ln_credit_12,0)
    ,NVL(ln_credit_1,0)
    ,NVL(ln_credit_2,0)
    ,NVL(ln_credit_3,0)
    ,NVL(ln_credit_4,0)
    ,NVL(ln_year_credit,0)
    );
--
--#################################  �Œ��O������  #############################
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
--#####################################  �Œ蕔 END   ###########################
--
  END group1_month_count;
--
  /****************************************************************************
  * Procedure Name   : all_item_month_count
  * Description      : ���i���v���ʏW�v(A-10)
  *                  : ���ʏ��i���v�f�[�^�o�^(A-11)
  ****************************************************************************/
  PROCEDURE all_item_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     -- A-2�Ŏ擾�������_�R�[�h
      ,iv_kyoten_nm     IN  VARCHAR2                     -- A-2�Ŏ擾�������_����
      ,ov_errbuf        OUT NOCOPY VARCHAR2              -- ���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode       OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--

--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'all_item_month_count'; -- �v���O������
    
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
    ln_month_sale_budget       NUMBER;         --���ʏ��i���v����
    ln_month_amount            NUMBER;         --���ʏ��i���v����
    ln_month_sub_margin        NUMBER;         --���ʏ��i���v�e���v����
    ln_year_month              NUMBER;         --�N��
    ln_month_margin            NUMBER;         --���ʏ��i���v�e���v�z
    ln_month_credit_bunbo      NUMBER;         --���ʏ��i���v�|������
    ln_month_credit            NUMBER;         --���ʏ��i���v�|��
    ln_year_sale_budget        NUMBER;         --�N�ԏ��i���v����
    ln_year_amount             NUMBER;         --�N�ԏ��i���v����
    ln_year_margin             NUMBER;         --�N�ԏ��i���v�e���v�z
    ln_year_credit_bunbo       NUMBER;         --�N�ԏ��i���v�|������
    ln_year_credit             NUMBER;         --�N�ԏ��i���v�|��
    ln_sale_budget_5           NUMBER;         --5������
    ln_sale_budget_6           NUMBER;         --6������
    ln_sale_budget_7           NUMBER;         --7������
    ln_sale_budget_8           NUMBER;         --8������
    ln_sale_budget_9           NUMBER;         --9������
    ln_sale_budget_10          NUMBER;         --10������
    ln_sale_budget_11          NUMBER;         --11������
    ln_sale_budget_12          NUMBER;         --12������
    ln_sale_budget_1           NUMBER;         --1������
    ln_sale_budget_2           NUMBER;         --2������
    ln_sale_budget_3           NUMBER;         --3������
    ln_sale_budget_4           NUMBER;         --4������
    ln_amount_5                NUMBER;         --5������
    ln_amount_6                NUMBER;         --6������
    ln_amount_7                NUMBER;         --7������
    ln_amount_8                NUMBER;         --8������
    ln_amount_9                NUMBER;         --9������
    ln_amount_10               NUMBER;         --10������
    ln_amount_11               NUMBER;         --11������
    ln_amount_12               NUMBER;         --12������
    ln_amount_1                NUMBER;         --1������
    ln_amount_2                NUMBER;         --2������
    ln_amount_3                NUMBER;         --3������
    ln_amount_4                NUMBER;         --4������
    ln_margin_5                NUMBER;         --5���e���v�z
    ln_margin_6                NUMBER;         --6���e���v�z
    ln_margin_7                NUMBER;         --7���e���v�z
    ln_margin_8                NUMBER;         --8���e���v�z
    ln_margin_9                NUMBER;         --9���e���v�z
    ln_margin_10               NUMBER;         --10���e���v�z
    ln_margin_11               NUMBER;         --11���e���v�z
    ln_margin_12               NUMBER;         --12���e���v�z
    ln_margin_1                NUMBER;         --1���e���v�z
    ln_margin_2                NUMBER;         --2���e���v�z
    ln_margin_3                NUMBER;         --3���e���v�z
    ln_margin_4                NUMBER;         --4���e���v�z
    ln_credit_5                NUMBER;         --5���|��
    ln_credit_6                NUMBER;         --6���|��
    ln_credit_7                NUMBER;         --7���|��
    ln_credit_8                NUMBER;         --8���|��
    ln_credit_9                NUMBER;         --9���|��
    ln_credit_10               NUMBER;         --10���|��
    ln_credit_11               NUMBER;         --11���|��
    ln_credit_12               NUMBER;         --12���|��
    ln_credit_1                NUMBER;         --1���|��
    ln_credit_2                NUMBER;         --2���|��
    ln_credit_3                NUMBER;         --3���|��
    ln_credit_4                NUMBER;         --4���|��
    ln_month_no                NUMBER;         --��
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
    --���i���v���ʃf�[�^���o
    CURSOR   all_item_month_cur
    IS
      SELECT  SUM(xipl.sales_budget)  sales_budget_sum               --������z
             ,SUM(xipl.amount)        amount_sum                     --����
             ,SUM(xipl.amount * now_business_cost)  sub_margin       --�e���v����
             ,SUM(xipl.amount * now_unit_price)     credit_bunbo     --�|������
             ,xipl.year_month                                        --�N��
      FROM    xxcsm_item_plan_lines       xipl                       -- ���i�v�斾�׃e�[�u��
             ,xxcsm_item_plan_headers     xiph                       -- ���i�v��w�b�_�e�[�u��
             ,xxcsm_commodity_group3_v    xcgv                       -- ����Q�R�[�h�R�r���[
      WHERE   xiph.plan_year = gn_subject_year                       --�Ώ۔N�x
      AND     xiph.location_cd = iv_kyoten_cd                        --���_�R�[�h
      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
      AND     xipl.item_group_no NOT LIKE cv_group_d||'%'            --����Q�R�[�h1����D(���̑��ȊO)
--//+UPD START 2009/02/13 CT015 S.Son
    --AND     xipl.item_kbn = '1'                                    --���i�敪(1�F���i�P�i)
      AND     xipl.item_kbn <> '0'                                   --���i�敪(1�F���i�P�i�A2�F�V���i)
--//+UPD END 2009/02/13 CT015 S.Son
      AND     xipl.item_no = xcgv.item_cd
      GROUP BY xipl.year_month
      ORDER BY xipl.year_month
    ;
    all_item_month_cur_rec all_item_month_cur%ROWTYPE;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--���[�J���ϐ�������
    ln_month_sale_budget    := 0;              --���ʏ��i���v����
    ln_month_amount         := 0;              --���ʏ��i���v����
    ln_month_margin         := 0;              --���ʏ��i���v�e���v�z
    ln_month_credit_bunbo   := 0;              --���ʏ��i���v�|������
    ln_month_credit         := 0;              --���ʏ��i���v�|��
    ln_month_sub_margin     := 0;              --���ʏ��i���v�e���v����
    ln_year_sale_budget     := 0;              --�N�ԏ��i���v����
    ln_year_amount          := 0;              --�N�ԏ��i���v����
    ln_year_margin          := 0;              --�N�ԏ��i���v�e���v�z
    ln_year_credit_bunbo    := 0;              --�N�ԏ��i���v�|������
    ln_year_credit          := 0;              --�N�ԏ��i���v�|��

    OPEN all_item_month_cur;
    <<all_item_month_loop>>
    LOOP
      FETCH all_item_month_cur INTO all_item_month_cur_rec;
      EXIT WHEN all_item_month_cur%NOTFOUND;
        ln_month_sale_budget    :=  all_item_month_cur_rec.sales_budget_sum;                        --���ʏ��i���v����
        ln_month_amount         :=  all_item_month_cur_rec.amount_sum;                              --���ʏ��i���v����
        ln_month_sub_margin     :=  all_item_month_cur_rec.sub_margin;
        ln_month_credit_bunbo   :=  all_item_month_cur_rec.credit_bunbo;
        ln_year_month           :=  all_item_month_cur_rec.year_month;                              --�N��
        --���i���v���ʃf�[�^�Z�o
        ln_month_margin         := ln_month_sale_budget - ln_month_sub_margin;                      --���ʏ��i���v�e���v�z
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --���ʏ��i���v�|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_sale_budget     := ln_year_sale_budget + ln_month_sale_budget;                      --�N�ԏ��i���v����
        ln_year_amount          := ln_year_amount + ln_month_amount;                                --�N�ԏ��i���v����
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --�N�ԏ��i���v�e���v�z
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --�N�ԏ��i���v�|������
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit        := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --�N�ԏ��i���v�|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        --�e���f�[�^�ۑ�
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP all_item_month_loop;
    CLOSE all_item_month_cur;
--
    --���ʏ��i���v�f�[�^�o�^
    --1�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,gv_item_sum_name
    ,gv_amount_name
    ,NVL(ln_amount_5,0)
    ,NVL(ln_amount_6,0)
    ,NVL(ln_amount_7,0)
    ,NVL(ln_amount_8,0)
    ,NVL(ln_amount_9,0)
    ,NVL(ln_amount_10,0)
    ,NVL(ln_amount_11,0)
    ,NVL(ln_amount_12,0)
    ,NVL(ln_amount_1,0)
    ,NVL(ln_amount_2,0)
    ,NVL(ln_amount_3,0)
    ,NVL(ln_amount_4,0)
    ,NVL(ln_year_amount,0)
    );
    --2�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,ROUND(ln_sale_budget_5/1000)
    ,ROUND(ln_sale_budget_6/1000)
    ,ROUND(ln_sale_budget_7/1000)
    ,ROUND(ln_sale_budget_8/1000)
    ,ROUND(ln_sale_budget_9/1000)
    ,ROUND(ln_sale_budget_10/1000)
    ,ROUND(ln_sale_budget_11/1000)
    ,ROUND(ln_sale_budget_12/1000)
    ,ROUND(ln_sale_budget_1/1000)
    ,ROUND(ln_sale_budget_2/1000)
    ,ROUND(ln_sale_budget_3/1000)
    ,ROUND(ln_sale_budget_4/1000)
    ,ROUND(ln_year_sale_budget/1000)
    );
    --3�s�ځF�e���v�z
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,ROUND(ln_margin_5/1000)
    ,ROUND(ln_margin_6/1000)
    ,ROUND(ln_margin_7/1000)
    ,ROUND(ln_margin_8/1000)
    ,ROUND(ln_margin_9/1000)
    ,ROUND(ln_margin_10/1000)
    ,ROUND(ln_margin_11/1000)
    ,ROUND(ln_margin_12/1000)
    ,ROUND(ln_margin_1/1000)
    ,ROUND(ln_margin_2/1000)
    ,ROUND(ln_margin_3/1000)
    ,ROUND(ln_margin_4/1000)
    ,ROUND(ln_year_margin/1000)
    );
    --4�s�ځF�|��
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,NVL(ln_credit_5,0)
    ,NVL(ln_credit_6,0)
    ,NVL(ln_credit_7,0)
    ,NVL(ln_credit_8,0)
    ,NVL(ln_credit_9,0)
    ,NVL(ln_credit_10,0)
    ,NVL(ln_credit_11,0)
    ,NVL(ln_credit_12,0)
    ,NVL(ln_credit_1,0)
    ,NVL(ln_credit_2,0)
    ,NVL(ln_credit_3,0)
    ,NVL(ln_credit_4,0)
    ,NVL(ln_year_credit,0)
    );
--
--#################################  �Œ��O������  #############################
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
--#####################################  �Œ蕔 END   ###########################
--
  END all_item_month_count;
--
  /****************************************************************************
  * Procedure Name   : item_month_count
  * Description      : ���i�ʌ��ʏW�v(A-12)
  *                  : ���ʏ��i�ʃf�[�^�o�^(A-13)
  ****************************************************************************/
  PROCEDURE item_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2�Ŏ擾�������_�R�[�h
      ,iv_kyoten_nm     IN  VARCHAR2                     --A-2�Ŏ擾�������_����
      ,iv_item_cd       IN  VARCHAR2                     --A-5�Ŏ擾�����i�ڃR�[�h
      ,iv_item_nm       IN  VARCHAR2                     --A-5�Ŏ擾�����i�ږ�
      ,in_amount_year   IN  NUMBER                       --A-5�Ŏ擾��������
      ,in_budget_year   IN  NUMBER                       --A-5�Ŏ擾��������
      ,in_cost          IN  NUMBER                       --A-5�Ŏ擾�����c�ƌ���
      ,in_price         IN  NUMBER                       --A-5�Ŏ擾�����艿
      ,ov_errbuf        OUT NOCOPY VARCHAR2              --���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode       OUT NOCOPY VARCHAR2              --���^�[���E�R�[�h
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W
  IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--

--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'item_month_count'; -- �v���O������
    
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
    ln_month_sale_budget       NUMBER;         --���ʏ��i�ʔ���
    ln_month_amount            NUMBER;         --���ʏ��i�ʐ���
    ln_year_month              NUMBER;         --�N��
    ln_month_margin            NUMBER;         --���ʏ��i�ʑe���v�z
    ln_month_credit_bunbo      NUMBER;         --���ʏ��i�ʊ|������
    ln_month_credit            NUMBER;         --���ʏ��i�ʊ|��
    ln_year_sale_budget        NUMBER;         --�N�ԏ��i�ʔ���
    ln_year_amount             NUMBER;         --�N�ԏ��i�ʐ���
    ln_year_margin             NUMBER;         --�N�ԏ��i�ʑe���v�z
    ln_year_credit_bunbo       NUMBER;         --�N�ԏ��i�ʊ|������
    ln_year_credit             NUMBER;         --�N�ԏ��i�ʊ|��
    ln_cost                    NUMBER;         --�c�ƌ���
    ln_price                   NUMBER;         --�艿
    ln_sale_budget_5           NUMBER;         --5������
    ln_sale_budget_6           NUMBER;         --6������
    ln_sale_budget_7           NUMBER;         --7������
    ln_sale_budget_8           NUMBER;         --8������
    ln_sale_budget_9           NUMBER;         --9������
    ln_sale_budget_10          NUMBER;         --10������
    ln_sale_budget_11          NUMBER;         --11������
    ln_sale_budget_12          NUMBER;         --12������
    ln_sale_budget_1           NUMBER;         --1������
    ln_sale_budget_2           NUMBER;         --2������
    ln_sale_budget_3           NUMBER;         --3������
    ln_sale_budget_4           NUMBER;         --4������
    ln_amount_5                NUMBER;         --5������
    ln_amount_6                NUMBER;         --6������
    ln_amount_7                NUMBER;         --7������
    ln_amount_8                NUMBER;         --8������
    ln_amount_9                NUMBER;         --9������
    ln_amount_10               NUMBER;         --10������
    ln_amount_11               NUMBER;         --11������
    ln_amount_12               NUMBER;         --12������
    ln_amount_1                NUMBER;         --1������
    ln_amount_2                NUMBER;         --2������
    ln_amount_3                NUMBER;         --3������
    ln_amount_4                NUMBER;         --4������
    ln_margin_5                NUMBER;         --5���e���v�z
    ln_margin_6                NUMBER;         --6���e���v�z
    ln_margin_7                NUMBER;         --7���e���v�z
    ln_margin_8                NUMBER;         --8���e���v�z
    ln_margin_9                NUMBER;         --9���e���v�z
    ln_margin_10               NUMBER;         --10���e���v�z
    ln_margin_11               NUMBER;         --11���e���v�z
    ln_margin_12               NUMBER;         --12���e���v�z
    ln_margin_1                NUMBER;         --1���e���v�z
    ln_margin_2                NUMBER;         --2���e���v�z
    ln_margin_3                NUMBER;         --3���e���v�z
    ln_margin_4                NUMBER;         --4���e���v�z
    ln_credit_5                NUMBER;         --5���|��
    ln_credit_6                NUMBER;         --6���|��
    ln_credit_7                NUMBER;         --7���|��
    ln_credit_8                NUMBER;         --8���|��
    ln_credit_9                NUMBER;         --9���|��
    ln_credit_10               NUMBER;         --10���|��
    ln_credit_11               NUMBER;         --11���|��
    ln_credit_12               NUMBER;         --12���|��
    ln_credit_1                NUMBER;         --1���|��
    ln_credit_2                NUMBER;         --2���|��
    ln_credit_3                NUMBER;         --3���|��
    ln_credit_4                NUMBER;         --4���|��
    ln_month_no                NUMBER;         --��
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
    --���i�ʌ��ʃf�[�^���o
    CURSOR   item_month_cur
    IS
      SELECT  xipl.sales_budget                                      --������z
             ,xipl.amount                                            --����
             ,xipl.year_month                                        --�N��
      FROM    xxcsm_item_plan_lines       xipl                       -- ���i�v�斾�׃e�[�u��
             ,xxcsm_item_plan_headers     xiph                       -- ���i�v��w�b�_�e�[�u��
      WHERE   xiph.plan_year = gn_subject_year                       --�Ώ۔N�x
      AND     xiph.location_cd = iv_kyoten_cd                        --���_�R�[�h
      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
      AND     xipl.item_no = iv_item_cd                              --���i�R�[�h
--//+UPD START 2009/02/13 CT015 S.Son
    --AND     xipl.item_kbn = '1'                                    --���i�敪(1�F���i�P�i)
      AND     xipl.item_kbn <> '0'                                   --���i�敪(1�F���i�P�i�A2�F�V���i)
--//+UPD END 2009/02/13 CT015 S.Son
      ORDER BY xipl.year_month
    ;
    item_month_cur_rec item_month_cur%ROWTYPE;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--���[�J���ϐ�������
    ln_month_sale_budget    := 0;               --���ʏ��i�ʔ���
    ln_month_amount         := 0;               --���ʏ��i�ʐ���
    ln_month_margin         := 0;               --���ʏ��i�ʑe���v�z
    ln_month_credit_bunbo   := 0;               --���ʏ��i�ʊ|������
    ln_month_credit         := 0;               --���ʏ��i�ʊ|��
    ln_year_sale_budget     := in_budget_year;  --�N�ԏ��i�ʔ���
    ln_year_amount          := in_amount_year;  --�N�ԏ��i�ʐ���
    ln_year_margin          := 0;               --�N�ԏ��i�ʑe���v�z
    ln_year_credit_bunbo    := 0;               --�N�ԏ��i�ʊ|������
    ln_year_credit          := 0;               --�N�ԏ��i�ʊ|��
    ln_cost                 := in_cost;         --�c�ƌ���
    ln_price                := in_price;        --�艿
--
    OPEN item_month_cur;
    <<item_month_loop>>
    LOOP
      FETCH item_month_cur INTO item_month_cur_rec;
      EXIT WHEN item_month_cur%NOTFOUND;
        ln_month_sale_budget    :=  item_month_cur_rec.sales_budget;                                --���ʏ��i�ʔ���
        ln_month_amount         :=  item_month_cur_rec.amount;                                      --���ʏ��i�ʐ���
        ln_year_month           :=  item_month_cur_rec.year_month;                                  --�N��
        --���i�ʌ��ʃf�[�^�Z�o
        ln_month_margin         := ln_month_sale_budget -(ln_month_amount * ln_cost);               --���ʏ��i�ʑe���v�z
        ln_month_credit_bunbo   := ln_month_amount * ln_price;                                      --���ʏ��i�ʊ|������
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --���ʏ��i�ʊ|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --�N�ԏ��i�ʑe���v�z
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --�N�ԏ��i�ʊ|������
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit        := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --�N�ԏ��i�ʊ|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        --�e���f�[�^�ۑ�
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP item_month_loop;
    CLOSE item_month_cur;
--
    --���ʏ��i�ʃf�[�^�o�^
    --1�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,iv_item_cd
    ,iv_item_nm
    ,gv_amount_name
    ,NVL(ln_amount_5,0)
    ,NVL(ln_amount_6,0)
    ,NVL(ln_amount_7,0)
    ,NVL(ln_amount_8,0)
    ,NVL(ln_amount_9,0)
    ,NVL(ln_amount_10,0)
    ,NVL(ln_amount_11,0)
    ,NVL(ln_amount_12,0)
    ,NVL(ln_amount_1,0)
    ,NVL(ln_amount_2,0)
    ,NVL(ln_amount_3,0)
    ,NVL(ln_amount_4,0)
    ,NVL(ln_year_amount,0)
    );
    --2�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_sale_budget_5/1000),0)
    ,NVL(ROUND(ln_sale_budget_6/1000),0)
    ,NVL(ROUND(ln_sale_budget_7/1000),0)
    ,NVL(ROUND(ln_sale_budget_8/1000),0)
    ,NVL(ROUND(ln_sale_budget_9/1000),0)
    ,NVL(ROUND(ln_sale_budget_10/1000),0)
    ,NVL(ROUND(ln_sale_budget_11/1000),0)
    ,NVL(ROUND(ln_sale_budget_12/1000),0)
    ,NVL(ROUND(ln_sale_budget_1/1000),0)
    ,NVL(ROUND(ln_sale_budget_2/1000),0)
    ,NVL(ROUND(ln_sale_budget_3/1000),0)
    ,NVL(ROUND(ln_sale_budget_4/1000),0)
    ,NVL(ROUND(ln_year_sale_budget/1000),0)
    );
    --3�s�ځF�e���v�z
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_margin_5/1000),0)
    ,NVL(ROUND(ln_margin_6/1000),0)
    ,NVL(ROUND(ln_margin_7/1000),0)
    ,NVL(ROUND(ln_margin_8/1000),0)
    ,NVL(ROUND(ln_margin_9/1000),0)
    ,NVL(ROUND(ln_margin_10/1000),0)
    ,NVL(ROUND(ln_margin_11/1000),0)
    ,NVL(ROUND(ln_margin_12/1000),0)
    ,NVL(ROUND(ln_margin_1/1000),0)
    ,NVL(ROUND(ln_margin_2/1000),0)
    ,NVL(ROUND(ln_margin_3/1000),0)
    ,NVL(ROUND(ln_margin_4/1000),0)
    ,NVL(ROUND(ln_year_margin/1000),0)
    );
    --4�s�ځF�|��
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,NVL(ln_credit_5,0)
    ,NVL(ln_credit_6,0)
    ,NVL(ln_credit_7,0)
    ,NVL(ln_credit_8,0)
    ,NVL(ln_credit_9,0)
    ,NVL(ln_credit_10,0)
    ,NVL(ln_credit_11,0)
    ,NVL(ln_credit_12,0)
    ,NVL(ln_credit_1,0)
    ,NVL(ln_credit_2,0)
    ,NVL(ln_credit_3,0)
    ,NVL(ln_credit_4,0)
    ,NVL(ln_year_credit,0)
    );
    
--
--#################################  �Œ��O������  #############################
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
--#####################################  �Œ蕔 END   ###########################
--
  END item_month_count;
--
  /****************************************************************************
  * Procedure Name   : reduce_price_count
  * Description      : �l�����ʏW�v(A-14)
  *                  : ���ʒl���f�[�^�o�^(A-15)
  ****************************************************************************/
  PROCEDURE reduce_price_count (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2�Ŏ擾�������_�R�[�h
      ,iv_kyoten_nm     IN  VARCHAR2                     --A-2�Ŏ擾�������_����
      ,ov_errbuf        OUT NOCOPY VARCHAR2              --���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode       OUT NOCOPY VARCHAR2              --���^�[���E�R�[�h
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W
  IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'reduce_price_count'; -- �v���O������
--
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
    ln_month_sales_discount       NUMBER;         --���ʔ���l��
    ln_month_receipt_discount     NUMBER;         --���ʓ����l��
    ln_month_no                   NUMBER;         --��
    ln_year_sales_discount        NUMBER;         --�N�Ԕ���l��
    ln_year_receipt_discount      NUMBER;         --�N�ԓ����l��
    ln_sales_discount_5           NUMBER;         --5������l��
    ln_sales_discount_6           NUMBER;         --6������l��
    ln_sales_discount_7           NUMBER;         --7������l��
    ln_sales_discount_8           NUMBER;         --8������l��
    ln_sales_discount_9           NUMBER;         --9������l��
    ln_sales_discount_10          NUMBER;         --10������l��
    ln_sales_discount_11          NUMBER;         --11������l��
    ln_sales_discount_12          NUMBER;         --12������l��
    ln_sales_discount_1           NUMBER;         --1������l��
    ln_sales_discount_2           NUMBER;         --2������l��
    ln_sales_discount_3           NUMBER;         --3������l��
    ln_sales_discount_4           NUMBER;         --4������l��
    ln_receipt_discount_5         NUMBER;         --5�������l��
    ln_receipt_discount_6         NUMBER;         --6�������l��
    ln_receipt_discount_7         NUMBER;         --7�������l��
    ln_receipt_discount_8         NUMBER;         --8�������l��
    ln_receipt_discount_9         NUMBER;         --9�������l��
    ln_receipt_discount_10        NUMBER;         --10�������l��
    ln_receipt_discount_11        NUMBER;         --11�������l��
    ln_receipt_discount_12        NUMBER;         --12�������l��
    ln_receipt_discount_1         NUMBER;         --1�������l��
    ln_receipt_discount_2         NUMBER;         --2�������l��
    ln_receipt_discount_3         NUMBER;         --3�������l��
    ln_receipt_discount_4         NUMBER;         --4�������l��
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
    --�l�����ʃf�[�^���o
    CURSOR   reduce_price_cur
    IS
      SELECT  xiplb.sales_discount                                   --����l��
             ,xiplb.receipt_discount                                 --�����l��
             ,xiplb.month_no                                         --�N��
      FROM    xxcsm_item_plan_loc_bdgt    xiplb                      -- ���i�v�拒�_�ʗ\�Z�e�[�u��
             ,xxcsm_item_plan_headers     xiph                       -- ���i�v��w�b�_�e�[�u��
      WHERE   xiph.plan_year = gn_subject_year                       --�Ώ۔N�x
      AND     xiph.location_cd = iv_kyoten_cd                        --���_�R�[�h
      AND     xiph.item_plan_header_id = xiplb.item_plan_header_id
    ;
    reduce_price_cur_rec reduce_price_cur%ROWTYPE;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--���[�J���ϐ�������
    ln_month_sales_discount    := 0;              --���ʔ���l��
    ln_month_receipt_discount  := 0;              --���ʓ����l��
    ln_year_sales_discount     := 0;              --�N�Ԕ���l��
    ln_year_receipt_discount   := 0;              --�N�ԓ����l��

    OPEN reduce_price_cur;
    <<reduce_price_loop>>
    LOOP
      FETCH reduce_price_cur INTO reduce_price_cur_rec;
      EXIT WHEN reduce_price_cur%NOTFOUND;
        ln_month_sales_discount     :=  reduce_price_cur_rec.sales_discount;                         --���ʔ���l��
        ln_month_receipt_discount   :=  reduce_price_cur_rec.receipt_discount;                       --���ʓ����l��
        ln_month_no                 :=  reduce_price_cur_rec.month_no;                               --��
        --�l���N�ԃf�[�^�Z�o
        ln_year_sales_discount      := ln_year_sales_discount + ln_month_sales_discount;              --�N�Ԕ���l��
        ln_year_receipt_discount    := ln_year_receipt_discount + ln_month_receipt_discount;          --�N�ԓ����l��
        
        --�e���f�[�^�ۑ�
        IF    ln_month_no = 5 THEN
          ln_sales_discount_5        := ln_month_sales_discount;
          ln_receipt_discount_5      := ln_month_receipt_discount;
        ELSIF ln_month_no = 6 THEN
          ln_sales_discount_6        := ln_month_sales_discount;
          ln_receipt_discount_6      := ln_month_receipt_discount;
        ELSIF ln_month_no = 7 THEN
          ln_sales_discount_7        := ln_month_sales_discount;
          ln_receipt_discount_7      := ln_month_receipt_discount;
        ELSIF ln_month_no = 8 THEN
          ln_sales_discount_8        := ln_month_sales_discount;
          ln_receipt_discount_8      := ln_month_receipt_discount;
        ELSIF ln_month_no = 9 THEN
          ln_sales_discount_9        := ln_month_sales_discount;
          ln_receipt_discount_9      := ln_month_receipt_discount;
        ELSIF ln_month_no = 10 THEN
          ln_sales_discount_10        := ln_month_sales_discount;
          ln_receipt_discount_10      := ln_month_receipt_discount;
        ELSIF ln_month_no = 11 THEN
          ln_sales_discount_11        := ln_month_sales_discount;
          ln_receipt_discount_11      := ln_month_receipt_discount;
        ELSIF ln_month_no = 12 THEN
          ln_sales_discount_12        := ln_month_sales_discount;
          ln_receipt_discount_12      := ln_month_receipt_discount;
        ELSIF ln_month_no = 1 THEN
          ln_sales_discount_1        := ln_month_sales_discount;
          ln_receipt_discount_1      := ln_month_receipt_discount;
        ELSIF ln_month_no = 2 THEN
          ln_sales_discount_2        := ln_month_sales_discount;
          ln_receipt_discount_2      := ln_month_receipt_discount;
        ELSIF ln_month_no = 3 THEN
          ln_sales_discount_3        := ln_month_sales_discount;
          ln_receipt_discount_3      := ln_month_receipt_discount;
        ELSIF ln_month_no = 4 THEN
          ln_sales_discount_4        := ln_month_sales_discount;
          ln_receipt_discount_4      := ln_month_receipt_discount;
        END IF;
    END LOOP reduce_price_loop;
    CLOSE reduce_price_cur;
--
    --���ʔ���l���f�[�^�o�^
    --1�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,gv_sales_dis_name
    ,gv_amount_name
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    );
    --2�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_sales_discount_5/1000),0)
    ,NVL(ROUND(ln_sales_discount_6/1000),0)
    ,NVL(ROUND(ln_sales_discount_7/1000),0)
    ,NVL(ROUND(ln_sales_discount_8/1000),0)
    ,NVL(ROUND(ln_sales_discount_9/1000),0)
    ,NVL(ROUND(ln_sales_discount_10/1000),0)
    ,NVL(ROUND(ln_sales_discount_11/1000),0)
    ,NVL(ROUND(ln_sales_discount_12/1000),0)
    ,NVL(ROUND(ln_sales_discount_1/1000),0)
    ,NVL(ROUND(ln_sales_discount_2/1000),0)
    ,NVL(ROUND(ln_sales_discount_3/1000),0)
    ,NVL(ROUND(ln_sales_discount_4/1000),0)
    ,NVL(ROUND(ln_year_sales_discount/1000),0)
    );
    --3�s�ځF�e���v�z
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_sales_discount_5/1000),0)
    ,NVL(ROUND(ln_sales_discount_6/1000),0)
    ,NVL(ROUND(ln_sales_discount_7/1000),0)
    ,NVL(ROUND(ln_sales_discount_8/1000),0)
    ,NVL(ROUND(ln_sales_discount_9/1000),0)
    ,NVL(ROUND(ln_sales_discount_10/1000),0)
    ,NVL(ROUND(ln_sales_discount_11/1000),0)
    ,NVL(ROUND(ln_sales_discount_12/1000),0)
    ,NVL(ROUND(ln_sales_discount_1/1000),0)
    ,NVL(ROUND(ln_sales_discount_2/1000),0)
    ,NVL(ROUND(ln_sales_discount_3/1000),0)
    ,NVL(ROUND(ln_sales_discount_4/1000),0)
    ,NVL(ROUND(ln_year_sales_discount/1000),0)
    );
    --4�s�ځF�|��
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    );
    --���ʓ����l���f�[�^�o�^
    --1�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,gv_receipt_dis_name
    ,gv_amount_name
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    );
    --2�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_receipt_discount_5/1000),0)
    ,NVL(ROUND(ln_receipt_discount_6/1000),0)
    ,NVL(ROUND(ln_receipt_discount_7/1000),0)
    ,NVL(ROUND(ln_receipt_discount_8/1000),0)
    ,NVL(ROUND(ln_receipt_discount_9/1000),0)
    ,NVL(ROUND(ln_receipt_discount_10/1000),0)
    ,NVL(ROUND(ln_receipt_discount_11/1000),0)
    ,NVL(ROUND(ln_receipt_discount_12/1000),0)
    ,NVL(ROUND(ln_receipt_discount_1/1000),0)
    ,NVL(ROUND(ln_receipt_discount_2/1000),0)
    ,NVL(ROUND(ln_receipt_discount_3/1000),0)
    ,NVL(ROUND(ln_receipt_discount_4/1000),0)
    ,NVL(ROUND(ln_year_receipt_discount/1000),0)
    );
    --3�s�ځF�e���v�z
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_receipt_discount_5/1000),0)
    ,NVL(ROUND(ln_receipt_discount_6/1000),0)
    ,NVL(ROUND(ln_receipt_discount_7/1000),0)
    ,NVL(ROUND(ln_receipt_discount_8/1000),0)
    ,NVL(ROUND(ln_receipt_discount_9/1000),0)
    ,NVL(ROUND(ln_receipt_discount_10/1000),0)
    ,NVL(ROUND(ln_receipt_discount_11/1000),0)
    ,NVL(ROUND(ln_receipt_discount_12/1000),0)
    ,NVL(ROUND(ln_receipt_discount_1/1000),0)
    ,NVL(ROUND(ln_receipt_discount_2/1000),0)
    ,NVL(ROUND(ln_receipt_discount_3/1000),0)
    ,NVL(ROUND(ln_receipt_discount_4/1000),0)
    ,NVL(ROUND(ln_year_receipt_discount/1000),0)
    );
    --4�s�ځF�|��
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
    );
    
--
--#################################  �Œ��O������  #############################
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
--#####################################  �Œ蕔 END   ###########################
--
  END reduce_price_count;
--
  /****************************************************************************
  * Procedure Name   : kyoten_month_count
  * Description      : ���_�ʌ��ʏW�v(A-16)
  *                  : ���ʋ��_�ʃf�[�^�AH��o�^(A-17)
  ****************************************************************************/
  PROCEDURE kyoten_month_count (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2�Ŏ擾�������_�R�[�h
      ,iv_kyoten_nm     IN  VARCHAR2                     --A-2�Ŏ擾�������_����
      ,ov_errbuf        OUT NOCOPY VARCHAR2              --���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode       OUT NOCOPY VARCHAR2              --���^�[���E�R�[�h
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W
  IS
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'kyoten_month_count'; -- �v���O������
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
    ln_month_sale_budget       NUMBER;         --���ʋ��_�ʔ���
    ln_month_amount            NUMBER;         --���ʋ��_�ʐ���
    ln_month_sub_margin        NUMBER;         --���ʋ��_�ʑe���v����
    ln_month_h_standard        NUMBER;         --���ʋ��_��H��Z�o�p�f�[�^
    ln_year_month              NUMBER;         --�N��
    ln_month_margin            NUMBER;         --���ʋ��_�ʑe���v�z
    ln_month_credit_bunbo      NUMBER;         --���ʋ��_�ʊ|������
    ln_month_credit            NUMBER;         --���ʋ��_�ʊ|��
    ln_year_sale_budget        NUMBER;         --�N�ԋ��_�ʔ���
    ln_year_amount             NUMBER;         --�N�ԋ��_�ʐ���
    ln_year_margin             NUMBER;         --�N�ԋ��_�ʑe���v�z
    ln_year_credit_bunbo       NUMBER;         --�N�ԋ��_�ʊ|������
    ln_year_credit             NUMBER;         --�N�ԋ��_�ʊ|��
    ln_year_h_standard         NUMBER;         --�N�ԋ��_��H��Z�o�p����
    ln_cost                    NUMBER;         --�c�ƌ���
    ln_price                   NUMBER;         --�艿
    ln_sale_budget_5           NUMBER;         --5������
    ln_sale_budget_6           NUMBER;         --6������
    ln_sale_budget_7           NUMBER;         --7������
    ln_sale_budget_8           NUMBER;         --8������
    ln_sale_budget_9           NUMBER;         --9������
    ln_sale_budget_10          NUMBER;         --10������
    ln_sale_budget_11          NUMBER;         --11������
    ln_sale_budget_12          NUMBER;         --12������
    ln_sale_budget_1           NUMBER;         --1������
    ln_sale_budget_2           NUMBER;         --2������
    ln_sale_budget_3           NUMBER;         --3������
    ln_sale_budget_4           NUMBER;         --4������
    ln_amount_5                NUMBER;         --5������
    ln_amount_6                NUMBER;         --6������
    ln_amount_7                NUMBER;         --7������
    ln_amount_8                NUMBER;         --8������
    ln_amount_9                NUMBER;         --9������
    ln_amount_10               NUMBER;         --10������
    ln_amount_11               NUMBER;         --11������
    ln_amount_12               NUMBER;         --12������
    ln_amount_1                NUMBER;         --1������
    ln_amount_2                NUMBER;         --2������
    ln_amount_3                NUMBER;         --3������
    ln_amount_4                NUMBER;         --4������
    ln_margin_5                NUMBER;         --5���e���v�z
    ln_margin_6                NUMBER;         --6���e���v�z
    ln_margin_7                NUMBER;         --7���e���v�z
    ln_margin_8                NUMBER;         --8���e���v�z
    ln_margin_9                NUMBER;         --9���e���v�z
    ln_margin_10               NUMBER;         --10���e���v�z
    ln_margin_11               NUMBER;         --11���e���v�z
    ln_margin_12               NUMBER;         --12���e���v�z
    ln_margin_1                NUMBER;         --1���e���v�z
    ln_margin_2                NUMBER;         --2���e���v�z
    ln_margin_3                NUMBER;         --3���e���v�z
    ln_margin_4                NUMBER;         --4���e���v�z
    ln_credit_5                NUMBER;         --5���|��
    ln_credit_6                NUMBER;         --6���|��
    ln_credit_7                NUMBER;         --7���|��
    ln_credit_8                NUMBER;         --8���|��
    ln_credit_9                NUMBER;         --9���|��
    ln_credit_10               NUMBER;         --10���|��
    ln_credit_11               NUMBER;         --11���|��
    ln_credit_12               NUMBER;         --12���|��
    ln_credit_1                NUMBER;         --1���|��
    ln_credit_2                NUMBER;         --2���|��
    ln_credit_3                NUMBER;         --3���|��
    ln_credit_4                NUMBER;         --4���|��
    ln_h_standard              NUMBER;         --H�
    ln_month_no                NUMBER;         --��
--//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
    ln_discount                NUMBER;         --�l���z
--//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
    --���_�ʌ��ʃf�[�^���o
    CURSOR   kyoten_month_cur
    IS
      SELECT  SUM(xipl.sales_budget)  sales_budget_sum               --������z
             ,SUM(xipl.amount)        amount_sum                     --����
             ,SUM(xipl.amount * xcgv.now_business_cost)  sub_margin  --�e���v����
             ,SUM(xipl.amount * xcgv.now_unit_price)  credit_bunbo   --�|������
             ,SUM(xipl.amount * xcgv.now_item_cost) h_standard       --H��Z�o�p����
             ,xipl.year_month                                        --�N��
--//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
             ,xiph.item_plan_header_id              haeder_id        --�w�b�_ID
--//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
      FROM    xxcsm_item_plan_lines       xipl                       --���i�v�斾�׃e�[�u��
             ,xxcsm_item_plan_headers     xiph                       --���i�v��w�b�_�e�[�u��
             ,xxcsm_commodity_group3_v    xcgv                       --����Q�R�[�h�R�r���[
      WHERE   xiph.plan_year = gn_subject_year                       --�Ώ۔N�x
      AND     xiph.location_cd = iv_kyoten_cd                        --���_�R�[�h
      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
--//+UPD START 2009/02/13 CT015 S.Son
    --AND     xipl.item_kbn = '1'                                    --���i�敪(1�F���i�P�i)
      AND     xipl.item_kbn <> '0'                                   --���i�敪(1�F���i�P�i�A2�F�V���i)
--//+UPD END 2009/02/13 CT015 S.Son
      AND     xipl.item_no = xcgv.item_cd
      GROUP BY xipl.year_month
--//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
             ,xiph.item_plan_header_id
--//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
      ORDER BY xipl.year_month
    ;
    kyoten_month_cur_rec kyoten_month_cur%ROWTYPE;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

--���[�J���ϐ�������
    ln_month_sale_budget    := 0;              --���ʋ��_�ʔ���
    ln_month_amount         := 0;              --���ʋ��_�ʐ���
    ln_month_margin         := 0;              --���ʋ��_�ʑe���v�z
    ln_month_credit_bunbo   := 0;              --���ʋ��_�ʊ|������
    ln_month_credit         := 0;              --���ʋ��_�ʊ|��
    ln_month_sub_margin     := 0;              --���ʋ��_�ʑe���v����
    ln_month_h_standard     := 0;
    ln_year_amount          := 0;              --�N�ԋ��_�ʐ���
    ln_year_sale_budget     := 0;              --�N�ԋ��_�ʔ���
    ln_year_margin          := 0;              --�N�ԋ��_�ʑe���v�z
    ln_year_credit_bunbo    := 0;              --�N�ԋ��_�ʊ|������
    ln_year_credit          := 0;              --�N�ԋ��_�ʊ|��
    ln_year_h_standard      := 0;
    ln_h_standard           := 0;              --H�
--//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
    ln_discount             := 0;              --�l���z
--//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
--
    OPEN kyoten_month_cur;
    <<kyoten_month_loop>>
    LOOP
      FETCH kyoten_month_cur INTO kyoten_month_cur_rec;
      EXIT WHEN kyoten_month_cur%NOTFOUND;
--//+ADD START 2009/05/21 T1_1101 M.Ohtsuki
        SELECT (xiplb.sales_discount + xiplb.receipt_discount)  discount                            --(����l�� + �����l��)
        INTO   ln_discount
        FROM   xxcsm_item_plan_loc_bdgt    xiplb                                                    -- ���i�v�拒�_�ʗ\�Z�e�[�u��
        WHERE  xiplb.item_plan_header_id  = kyoten_month_cur_rec.haeder_id                          -- �w�b�_ID
        AND    xiplb.year_month           = kyoten_month_cur_rec.year_month;                        -- �N��
--//+ADD END   2009/05/21 T1_1101 M.Ohtsuki
--//+UPD START 2009/05/21 T1_1101 M.Ohtsuki
--        ln_month_sale_budget    :=  kyoten_month_cur_rec.sales_budget_sum;                          --���ʋ��_���v����
--��������������������������������������������������������������������������������������������������
        ln_month_sale_budget    :=  (kyoten_month_cur_rec.sales_budget_sum + ln_discount);          --���ʋ��_���v����
--//+UPD END   2009/05/21 T1_1101 M.Ohtsuki
        ln_month_amount         :=  kyoten_month_cur_rec.amount_sum;                                --���ʋ��_���v����
        ln_month_sub_margin     :=  kyoten_month_cur_rec.sub_margin;
        ln_month_credit_bunbo   :=  kyoten_month_cur_rec.credit_bunbo;
        ln_month_h_standard     :=  kyoten_month_cur_rec.h_standard;
        ln_year_month           :=  kyoten_month_cur_rec.year_month;                                --�N��
        --���_���v���ʃf�[�^�Z�o
        ln_month_margin         := ln_month_sale_budget - ln_month_sub_margin;                      --���ʋ��_���v�e���v�z
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_month_credit_bunbo = 0 THEN
          ln_month_credit := 0;
        ELSE
          ln_month_credit       := ROUND((ln_month_sale_budget / ln_month_credit_bunbo) * 100,2);   --���ʋ��_���v�|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_sale_budget     := ln_year_sale_budget + ln_month_sale_budget;                      --�N�ԋ��_���v����
        ln_year_amount          := ln_year_amount + ln_month_amount;                                --�N�ԋ��_���v����
        ln_year_margin          := ln_year_margin + ln_month_margin;                                --�N�ԋ��_���v�e���v�z
        ln_year_credit_bunbo    := ln_year_credit_bunbo + ln_month_credit_bunbo;                    --�N�ԋ��_���v�|������
--//+ADD START 2009/02/16 CT021 S.Son
        IF ln_year_credit_bunbo = 0 THEN
          ln_year_credit := 0;
        ELSE
          ln_year_credit          := ROUND((ln_year_sale_budget / ln_year_credit_bunbo) * 100,2);     --�N�ԋ��_���v�|��
        END IF;
--//+ADD END 2009/02/16 CT021 S.Son
        ln_year_h_standard      := ln_year_h_standard + ln_month_h_standard;                        --H��Z�o�p�N�Ԍ���
        
        --�e���f�[�^�ۑ�
        ln_month_no := SUBSTR(ln_year_month,5,2);
        IF    ln_month_no = 5 THEN
          ln_sale_budget_5 := ln_month_sale_budget;
          ln_amount_5      := ln_month_amount;
          ln_margin_5      := ln_month_margin;
          ln_credit_5      := ln_month_credit;
        ELSIF ln_month_no = 6 THEN
          ln_sale_budget_6 := ln_month_sale_budget;
          ln_amount_6      := ln_month_amount;
          ln_margin_6      := ln_month_margin;
          ln_credit_6      := ln_month_credit;
        ELSIF ln_month_no = 7 THEN
          ln_sale_budget_7 := ln_month_sale_budget;
          ln_amount_7      := ln_month_amount;
          ln_margin_7      := ln_month_margin;
          ln_credit_7      := ln_month_credit;
        ELSIF ln_month_no = 8 THEN
          ln_sale_budget_8 := ln_month_sale_budget;
          ln_amount_8      := ln_month_amount;
          ln_margin_8      := ln_month_margin;
          ln_credit_8      := ln_month_credit;
        ELSIF ln_month_no = 9 THEN
          ln_sale_budget_9 := ln_month_sale_budget;
          ln_amount_9      := ln_month_amount;
          ln_margin_9      := ln_month_margin;
          ln_credit_9      := ln_month_credit;
        ELSIF ln_month_no = 10 THEN
          ln_sale_budget_10 := ln_month_sale_budget;
          ln_amount_10      := ln_month_amount;
          ln_margin_10      := ln_month_margin;
          ln_credit_10      := ln_month_credit;
        ELSIF ln_month_no = 11 THEN
          ln_sale_budget_11 := ln_month_sale_budget;
          ln_amount_11      := ln_month_amount;
          ln_margin_11      := ln_month_margin;
          ln_credit_11      := ln_month_credit;
        ELSIF ln_month_no = 12 THEN
          ln_sale_budget_12 := ln_month_sale_budget;
          ln_amount_12      := ln_month_amount;
          ln_margin_12      := ln_month_margin;
          ln_credit_12      := ln_month_credit;
        ELSIF ln_month_no = 1 THEN
          ln_sale_budget_1 := ln_month_sale_budget;
          ln_amount_1      := ln_month_amount;
          ln_margin_1      := ln_month_margin;
          ln_credit_1      := ln_month_credit;
        ELSIF ln_month_no = 2 THEN
          ln_sale_budget_2 := ln_month_sale_budget;
          ln_amount_2      := ln_month_amount;
          ln_margin_2      := ln_month_margin;
          ln_credit_2      := ln_month_credit;
        ELSIF ln_month_no = 3 THEN
          ln_sale_budget_3 := ln_month_sale_budget;
          ln_amount_3      := ln_month_amount;
          ln_margin_3      := ln_month_margin;
          ln_credit_3      := ln_month_credit;
        ELSIF ln_month_no = 4 THEN
          ln_sale_budget_4 := ln_month_sale_budget;
          ln_amount_4      := ln_month_amount;
          ln_margin_4      := ln_month_margin;
          ln_credit_4      := ln_month_credit;
        END IF;
    END LOOP kyoten_month_loop;
    CLOSE kyoten_month_cur;
--
    --H��̎Z�o
    ln_h_standard := ln_year_sale_budget - ln_year_h_standard;
    --���ʋ��_�ʃf�[�^�o�^
    --1�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,gv_amount_name
    ,NVL(ln_amount_5,0)
    ,NVL(ln_amount_6,0)
    ,NVL(ln_amount_7,0)
    ,NVL(ln_amount_8,0)
    ,NVL(ln_amount_9,0)
    ,NVL(ln_amount_10,0)
    ,NVL(ln_amount_11,0)
    ,NVL(ln_amount_12,0)
    ,NVL(ln_amount_1,0)
    ,NVL(ln_amount_2,0)
    ,NVL(ln_amount_3,0)
    ,NVL(ln_amount_4,0)
    ,NVL(ln_year_amount,0)
    );
    --2�s�ځF����
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_budget_name
    ,NVL(ROUND(ln_sale_budget_5/1000),0)
    ,NVL(ROUND(ln_sale_budget_6/1000),0)
    ,NVL(ROUND(ln_sale_budget_7/1000),0)
    ,NVL(ROUND(ln_sale_budget_8/1000),0)
    ,NVL(ROUND(ln_sale_budget_9/1000),0)
    ,NVL(ROUND(ln_sale_budget_10/1000),0)
    ,NVL(ROUND(ln_sale_budget_11/1000),0)
    ,NVL(ROUND(ln_sale_budget_12/1000),0)
    ,NVL(ROUND(ln_sale_budget_1/1000),0)
    ,NVL(ROUND(ln_sale_budget_2/1000),0)
    ,NVL(ROUND(ln_sale_budget_3/1000),0)
    ,NVL(ROUND(ln_sale_budget_4/1000),0)
    ,NVL(ROUND(ln_year_sale_budget/1000),0)
    );
    --3�s�ځF�e���v�z
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_margin_name
    ,NVL(ROUND(ln_margin_5/1000),0)
    ,NVL(ROUND(ln_margin_6/1000),0)
    ,NVL(ROUND(ln_margin_7/1000),0)
    ,NVL(ROUND(ln_margin_8/1000),0)
    ,NVL(ROUND(ln_margin_9/1000),0)
    ,NVL(ROUND(ln_margin_10/1000),0)
    ,NVL(ROUND(ln_margin_11/1000),0)
    ,NVL(ROUND(ln_margin_12/1000),0)
    ,NVL(ROUND(ln_margin_1/1000),0)
    ,NVL(ROUND(ln_margin_2/1000),0)
    ,NVL(ROUND(ln_margin_3/1000),0)
    ,NVL(ROUND(ln_margin_4/1000),0)
    ,NVL(ROUND(ln_year_margin/1000),0)
    );
    --4�s�ځF�|��
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,''
    ,gv_credit_name
    ,ln_credit_5
    ,ln_credit_6
    ,ln_credit_7
    ,ln_credit_8
    ,ln_credit_9
    ,ln_credit_10
    ,ln_credit_11
    ,ln_credit_12
    ,ln_credit_1
    ,ln_credit_2
    ,ln_credit_3
    ,ln_credit_4
    ,ln_year_credit
    );
    --H��̓o�^
    gn_seq_no := gn_seq_no + 1;
    INSERT INTO xxcsm_tmp_month_item_plan
    (
      seq_no
     ,location_cd
     ,location_nm
     ,code
     ,name
     ,kbn_nm
     ,plan_data5
     ,plan_data6
     ,plan_data7
     ,plan_data8
     ,plan_data9
     ,plan_data10
     ,plan_data11
     ,plan_data12
     ,plan_data1
     ,plan_data2
     ,plan_data3
     ,plan_data4
     ,plan_year
    )
    VALUES
    (
     gn_seq_no
    ,iv_kyoten_cd
    ,iv_kyoten_nm
    ,''
    ,gv_h_standard_name
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,ROUND(ln_h_standard/1000)
    );
--
--#################################  �Œ��O������  #############################
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
--#####################################  �Œ蕔 END   ###########################
--
  END kyoten_month_count;
--
  /****************************************************************************
  * Procedure Name   : item_plan_select
  * Description      : ���i�v��f�[�^���o(A-5)
  ****************************************************************************/
  PROCEDURE item_plan_select (
       iv_kyoten_cd     IN  VARCHAR2                     --A-2�Ŏ擾�������_�R�[�h
      ,iv_kyoten_nm     IN  VARCHAR2
      ,ov_errbuf        OUT NOCOPY VARCHAR2              -- ���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode       OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
      ,ov_errmsg        OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'item_plan_select'; -- �v���O������
--
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
    lv_group1_cd                  VARCHAR2(4);         --����Q�R�[�h1
    lv_group1_nm                  VARCHAR2(100);       --����Q����1
    lv_group3_cd                  VARCHAR2(4);         --����Q�R�[�h
    lv_group3_nm                  VARCHAR2(100);       --����Q����3
    lv_item_cd                    VARCHAR2(32);        --�i�ڃR�[�h
    lv_item_nm                    VARCHAR2(100);       --�i�ږ���
    ln_base_price                 NUMBER;              --�W������
    ln_bus_price                  NUMBER;              --�c�ƌ���
    ln_con_price                  NUMBER;              --�艿
    ln_sales_budget_sum           NUMBER;              --������z
    ln_amount_sum                 NUMBER;              --����
    ln_kyoten_h_standard_you      NUMBER;              --���_��H��Z�o�p�f�[�^
    ln_item_h_standard_you        NUMBER;              --���i��H��Z�o�p�f�[�^
    lv_group3_cd_pre              VARCHAR2(4);         --�ۑ��p����Q�R�[�h3
    lv_group1_cd_pre              VARCHAR2(4);         --�ۑ��p����Q�R�[�h1
    lv_group3_nm_pre              VARCHAR2(100);       --�ۑ��p����Q��3
    lv_group1_nm_pre              VARCHAR2(100);       --�ۑ��p����Q��1
    lv_kyoten_cd                  VARCHAR2(4);         --A-2�Ŏ擾�������_�R�[�h
    lv_kyoten_nm                  VARCHAR2(100);       --A-2�Ŏ擾�������_��
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
    CURSOR   item_plan_select_cur
    IS
      SELECT  xcgv.group1_cd                             --����Q�R�[�h1
             ,xcgv.group1_nm                             --����Q����1
             ,xcgv.group3_cd                             --����Q�R�[�h3
             ,xcgv.group3_nm                             --����Q����3
             ,xcgv.item_cd                               --�i�ڃR�[�h
             ,xcgv.item_nm                               --�i�ږ���
             ,xcgv.now_item_cost                         --�W������
             ,xcgv.now_business_cost                     --�c�ƌ���
             ,xcgv.now_unit_price                        --�艿
             ,SUM(xipl.sales_budget)  sales_budget_sum   --������z
             ,SUM(xipl.amount)        amount_sum         --����
      FROM    xxcsm_commodity_group3_v    xcgv           --����Q3�r���[
             ,xxcsm_item_plan_lines       xipl           -- ���i�v�斾�׃e�[�u��
             ,xxcsm_item_plan_headers     xiph           -- ���i�v��w�b�_�e�[�u��
      WHERE   xiph.plan_year = gn_subject_year           --�Ώ۔N�x
      AND     xiph.location_cd = iv_kyoten_cd            --���_�R�[�h
      AND     xiph.item_plan_header_id = xipl.item_plan_header_id
--//+UPD START 2009/02/13 CT015 S.Son
    --AND     xipl.item_kbn = '1'                        --���i�敪(1�F���i�P�i)
      AND     xipl.item_kbn <> '0'                       --���i�敪(1�F���i�P�i�A2�F�V���i)
--//+UPD END 2009/02/13 CT015 S.Son
      AND     xipl.item_no = xcgv.item_cd
      GROUP BY   xcgv.group1_cd 
                ,xcgv.group1_nm 
                ,xcgv.group3_cd 
                ,xcgv.group3_nm 
                ,xcgv.item_cd   
                ,xcgv.item_nm   
                ,xcgv.now_item_cost
                ,xcgv.now_business_cost 
                ,xcgv.now_unit_price 
      ORDER BY   xcgv.group1_cd
                ,xcgv.group3_cd
                ,xcgv.item_cd
    ;
    item_plan_select_cur_rec item_plan_select_cur%ROWTYPE;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  ===============================
--  ���[�J���E�ϐ�������
--  ===============================
    lv_group3_cd_pre  := NULL;             --�ۑ��p����Q�R�[�h3
    lv_group1_cd_pre  := NULL;             --�ۑ��p����Q�R�[�h1
    lv_kyoten_cd      := iv_kyoten_cd;     --A-2�Ŏ擾�������_�R�[�h
    lv_kyoten_nm      := iv_kyoten_nm;     --A-2�Ŏ擾�������_��
--
    --���i�v��f�[�^�i�ڒP�ʂ�LOOP
    OPEN item_plan_select_cur;
    <<item_plan_select_loop>>
    LOOP
      FETCH item_plan_select_cur INTO item_plan_select_cur_rec;
      EXIT WHEN item_plan_select_cur%NOTFOUND;
        lv_group1_cd        := item_plan_select_cur_rec.group1_cd;        --����Q�R�[�h1
        lv_group1_nm        := item_plan_select_cur_rec.group1_nm;        --����Q����1
        lv_group3_cd        := item_plan_select_cur_rec.group3_cd;        --����Q�R�[�h3
        lv_group3_nm        := item_plan_select_cur_rec.group3_nm;        --����Q����3
        lv_item_cd          := item_plan_select_cur_rec.item_cd;          --�i�ڃR�[�h
        lv_item_nm          := item_plan_select_cur_rec.item_nm;          --�i�ږ���
        ln_base_price       := item_plan_select_cur_rec.now_item_cost;    --�W������
        ln_bus_price        := item_plan_select_cur_rec.now_business_cost;--�c�ƌ���
        ln_con_price        := item_plan_select_cur_rec.now_unit_price;   --�艿
        ln_sales_budget_sum := item_plan_select_cur_rec.sales_budget_sum; --������z
        ln_amount_sum       := item_plan_select_cur_rec.amount_sum;       --����
--
        --����Q�R�[�h1�͕ς���Ă��Ȃ��ꍇ
        IF (lv_group1_cd_pre IS NOT NULL) AND (lv_group1_cd = lv_group1_cd_pre ) THEN
          --����Q�R�[�h3�͕ς������A���i�Q�v�݂̂����܂��B
          IF (lv_group3_cd_pre IS NOT NULL) AND (lv_group3_cd_pre <> lv_group3_cd) THEN
            --  ===============================
            --  ���i�Q���ʏW�v(A-6)
            --  ���ʏ��i�Q�f�[�^�o�^(A-7)
            --  ===============================
            group3_month_count (
                                lv_kyoten_cd               --A-2�Ŏ擾�������_�R�[�h
                               ,lv_kyoten_nm               --A-2�Ŏ擾�������_����
                               ,lv_group3_cd_pre               --A-5�Ŏ擾��������Q�R�[�h3
                               ,lv_group3_nm_pre               --A-5�Ŏ擾��������Q��3
                               ,lv_errbuf                  -- ���ʁE�G���[�E���b�Z�[�W
                               ,lv_retcode                 -- ���^�[���E�R�[�h
                               ,lv_errmsg);                -- ���[�U�[�E�G���[�E���b�Z�[�W
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_expt;
            END IF;
          END IF;
        --����Q�R�[�h1���ς�����ꍇ�F���i�Q�v�A���i�敪�v���W�v���܂��B
        ELSIF (lv_group1_cd_pre IS NOT NULL) AND (lv_group1_cd <> lv_group1_cd_pre ) THEN
          --  ===============================
          --  ���i�Q���ʏW�v(A-6)
          --  ���ʏ��i�Q�f�[�^�o�^(A-7)
          --  ===============================
          group3_month_count (
                              lv_kyoten_cd               --A-2�Ŏ擾�������_�R�[�h
                             ,lv_kyoten_nm               --A-2�Ŏ擾�������_����
                             ,lv_group3_cd_pre               --A-5�Ŏ擾��������Q�R�[�h3
                             ,lv_group3_nm_pre               --A-5�Ŏ擾��������Q��3
                             ,lv_errbuf                  --���ʁE�G���[�E���b�Z�[�W
                             ,lv_retcode                 --���^�[���E�R�[�h
                             ,lv_errmsg);                --���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
          END IF;
          --  ===============================
          --  ���i�敪���ʏW�v(A-8)
          --  ���ʏ��i�敪�f�[�^�o�^(A-9)
          --  ===============================
          group1_month_count (
                              lv_kyoten_cd              --A-2�Ŏ擾�������_�R�[�h
                             ,lv_kyoten_nm              --A-2�Ŏ擾�������_����
                             ,lv_group1_cd_pre              --A-5�Ŏ擾��������Q�R�[�h1
                             ,lv_group1_nm_pre              --A-5�Ŏ擾��������Q��1
                             ,lv_errbuf                 --���ʁE�G���[�E���b�Z�[�W
                             ,lv_retcode                --���^�[���E�R�[�h
                             ,lv_errmsg);               --���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
          END IF;
          --����Q�R�[�h1��D�ɕς�����ꍇ�F���i���v���W�v���܂��B
          IF (lv_group1_cd = cv_group_d) THEN
            --  ===============================
            --  ���i���v���ʏW�v(A-10)
            --  ���ʏ��i���v�f�[�^�o�^(A-11)
            --  ===============================
            all_item_month_count (
                                  lv_kyoten_cd              --A-2�Ŏ擾�������_�R�[�h
                                 ,lv_kyoten_nm              --A-2�Ŏ擾�������_����
                                 ,lv_errbuf                 --���ʁE�G���[�E���b�Z�[�W
                                 ,lv_retcode                --���^�[���E�R�[�h
                                 ,lv_errmsg);               --���[�U�[�E�G���[�E���b�Z�[�W
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
        --�i�ڃR�[�h�P�ʂň��LOOP���āA�������ɏ��i�v����񂵂܂��B
        --  ===============================
        --  ���i�ʌ��ʏW�v(A-12)
        --  ���ʏ��i�ʃf�[�^�o�^(A-13)
        --  ===============================
--//+ADD START 2009/02/19 CT038 K.Yamada
        IF ln_sales_budget_sum <> 0 THEN
--//+ADD END   2009/02/19 CT038 K.Yamada
          item_month_count (
                            lv_kyoten_cd                --A-2�Ŏ擾�������_�R�[�h
                           ,lv_kyoten_nm                --A-2�Ŏ擾�������_����
                           ,lv_item_cd                  --A-5�Ŏ擾�����i�ڃR�[�h
                           ,lv_item_nm                  --A-5�Ŏ擾�����i�ږ�
                           ,ln_amount_sum               --A-5�Ŏ擾��������
                           ,ln_sales_budget_sum         --A-5�Ŏ擾��������
                           ,ln_bus_price                --A-5�Ŏ擾�����c�ƌ���
                           ,ln_con_price                --A-5�Ŏ擾�����艿
                           ,lv_errbuf                   --���ʁE�G���[�E���b�Z�[�W
                           ,lv_retcode                  --���^�[���E�R�[�h
                           ,lv_errmsg);                 --���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
          END IF;
--//+ADD START 2009/02/19 CT038 K.Yamada
        END IF;
--//+ADD END   2009/02/19 CT038 K.Yamada
        lv_group3_cd_pre := lv_group3_cd;
        lv_group3_nm_pre := lv_group3_nm;
        lv_group1_cd_pre := lv_group1_cd;
        lv_group1_nm_pre := lv_group1_nm;
    END LOOP item_plan_select_loop;
--*** �Ō�̏��i�Q�v ***
      --  ===============================
      --  ���i�Q���ʏW�v(A-6)
      --  ���ʏ��i�Q�f�[�^�o�^(A-7)
      --  ===============================
      group3_month_count (
                          lv_kyoten_cd               --A-2�Ŏ擾�������_�R�[�h
                         ,lv_kyoten_nm               --A-2�Ŏ擾�������_����
                         ,lv_group3_cd_pre           --A-5�Ŏ擾��������Q�R�[�h3
                         ,lv_group3_nm_pre           --A-5�Ŏ擾��������Q��3
                         ,lv_errbuf                  --���ʁE�G���[�E���b�Z�[�W
                         ,lv_retcode                 --���^�[���E�R�[�h
                         ,lv_errmsg);                --���[�U�[�E�G���[�E���b�Z�[�W
      -- ��O����
      IF (lv_retcode <> cv_status_normal) THEN
        --(�G���[����)
        RAISE global_api_expt;
      END IF;
      --  ===============================
      --  ���i�敪���ʏW�v(A-8)
      --  ���ʏ��i�敪�f�[�^�o�^(A-9)
      --  ===============================
      group1_month_count (
                          lv_kyoten_cd              --A-2�Ŏ擾�������_�R�[�h
                         ,lv_kyoten_nm              --A-2�Ŏ擾�������_����
                         ,lv_group1_cd_pre              --A-5�Ŏ擾��������Q�R�[�h1
                         ,lv_group1_nm_pre              --A-5�Ŏ擾��������Q��1
                         ,lv_errbuf                 --���ʁE�G���[�E���b�Z�[�W
                         ,lv_retcode                --���^�[���E�R�[�h
                         ,lv_errmsg);               --���[�U�[�E�G���[�E���b�Z�[�W
      -- ��O����
      IF (lv_retcode <> cv_status_normal) THEN
        --(�G���[����)
        RAISE global_api_expt;
      END IF;
    IF (lv_group1_cd <> cv_group_d) THEN
      --  ===============================
      --  ���i���v���ʏW�v(A-10)
      --  ���ʏ��i���v�f�[�^�o�^(A-11)
      --  ===============================
      all_item_month_count (
                            lv_kyoten_cd              --A-2�Ŏ擾�������_�R�[�h
                           ,lv_kyoten_nm              --A-2�Ŏ擾�������_����
                           ,lv_errbuf                 --���ʁE�G���[�E���b�Z�[�W
                           ,lv_retcode                --���^�[���E�R�[�h
                           ,lv_errmsg);               --���[�U�[�E�G���[�E���b�Z�[�W
      -- ��O����
      IF (lv_retcode <> cv_status_normal) THEN
        --(�G���[����)
        RAISE global_api_expt;
      END IF;
    END IF;
    --  ===============================
    --  �l�����ʏW�v(A-14)
    --  ���ʒl���f�[�^�o�^(A-15)
    --  ===============================
    reduce_price_count (
                        lv_kyoten_cd              --A-2�Ŏ擾�������_�R�[�h
                       ,lv_kyoten_nm              --A-2�Ŏ擾�������_����
                       ,lv_errbuf                 --���ʁE�G���[�E���b�Z�[�W
                       ,lv_retcode                --���^�[���E�R�[�h
                       ,lv_errmsg);               --���[�U�[�E�G���[�E���b�Z�[�W
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      RAISE global_api_expt;
    END IF;
    --  ===============================
    --  ���_�ʌ��ʏW�v(A-16)
    --  ���ʋ��_�ʃf�[�^�AH��o�^(A-17)
    --  ===============================
    kyoten_month_count (
                        lv_kyoten_cd            --A-2�Ŏ擾�������_�R�[�h
                       ,lv_kyoten_nm            --A-2�Ŏ擾�������_����
                       ,lv_errbuf               --���ʁE�G���[�E���b�Z�[�W
                       ,lv_retcode              --���^�[���E�R�[�h
                       ,lv_errmsg );            --���[�U�[�E�G���[�E���b�Z�[�W
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      RAISE global_api_expt;
    END IF;
    CLOSE item_plan_select_cur;
--
--#################################  �Œ��O������  #############################
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
--#####################################  �Œ蕔 END   ###########################
--
  END item_plan_select;
--
   /****************************************************************************
   * Procedure Name   : write_csv_file
   * Description      : �`�F�b�N���X�g�f�[�^�o��(A-18)
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
--//+ADD START 2009/02/19 CT048 K.Yamada
    -- ===============================
    -- ���[�U�[��`���[�J���萔
    -- ===============================
    cv_1st_location                 CONSTANT VARCHAR2(1)   := '0';             -- ���_�R�[�h�����l
--//+ADD END   2009/02/19 CT048 K.Yamada

    -- ===============================
    -- ���[�U�[��`���[�J���ϐ�
    -- ===============================
    -- �w�b�_���
    lv_data_head                   VARCHAR2(4000);   --�w�b�_
    -- �{�f�B���
    lv_data_body                   VARCHAR2(30000);  --�{�f�B
    lv_item_plan_data              VARCHAR2(4000);   --�s���
    lv_location_nm                 VARCHAR2(100);    --���̓p�����[�^���_��
    lv_code                        VARCHAR2(100);    --�R�[�h
    lv_name                        VARCHAR2(100);    --����
    lv_kbn_nm                      VARCHAR2(100);    --�o�͋敪��
    lt_plan_data5                  xxcsm_tmp_month_item_plan.plan_data5%TYPE;    --5���f�[�^
    lt_plan_data6                  xxcsm_tmp_month_item_plan.plan_data6%TYPE;    --6���f�[�^
    lt_plan_data7                  xxcsm_tmp_month_item_plan.plan_data7%TYPE;    --7���f�[�^
    lt_plan_data8                  xxcsm_tmp_month_item_plan.plan_data8%TYPE;    --8���f�[�^
    lt_plan_data9                  xxcsm_tmp_month_item_plan.plan_data9%TYPE;    --9���f�[�^
    lt_plan_data10                 xxcsm_tmp_month_item_plan.plan_data10%TYPE;    --10���f�[�^
    lt_plan_data11                 xxcsm_tmp_month_item_plan.plan_data11%TYPE;    --11���f�[�^
    lt_plan_data12                 xxcsm_tmp_month_item_plan.plan_data12%TYPE;    --12���f�[�^
    lt_plan_data1                  xxcsm_tmp_month_item_plan.plan_data1%TYPE;    --1���f�[�^
    lt_plan_data2                  xxcsm_tmp_month_item_plan.plan_data2%TYPE;    --2���f�[�^
    lt_plan_data3                  xxcsm_tmp_month_item_plan.plan_data3%TYPE;    --3���f�[�^
    lt_plan_data4                  xxcsm_tmp_month_item_plan.plan_data4%TYPE;    --4���f�[�^
    lt_plan_year                   xxcsm_tmp_month_item_plan.plan_year%TYPE;    --�N�ԃf�[�^
--//+ADD START 2009/02/19 CT048 K.Yamada
    lt_location_cd                 xxcsm_tmp_month_item_plan.location_cd%TYPE;    --���_�R�[�h
    lt_pre_location_cd             xxcsm_tmp_month_item_plan.location_cd%TYPE;    --���_�R�[�h
    lt_location_nm                 xxcsm_tmp_month_item_plan.location_nm%TYPE;    --���_��
--//+ADD END   2009/02/19 CT048 K.Yamada
--
--============================================
--���[�J���E�J�[�\��
--============================================ 
    CURSOR  check_list_data_cur
    IS
      SELECT    code                         --�o�̓R�[�h
               ,name                         --�o�͖�
               ,kbn_nm                       --�o�͋敪��
               ,plan_data5                   --5���f�[�^
               ,plan_data6                   --6���f�[�^
               ,plan_data7                   --7���f�[�^
               ,plan_data8                   --8���f�[�^
               ,plan_data9                   --9���f�[�^
               ,plan_data10                  --10���f�[�^
               ,plan_data11                  --11���f�[�^
               ,plan_data12                  --12���f�[�^
               ,plan_data1                   --1���f�[�^
               ,plan_data2                   --2���f�[�^
               ,plan_data3                   --3���f�[�^
               ,plan_data4                   --4���f�[�^
               ,plan_year                    --�N�ԃf�[�^
--//+ADD START 2009/02/19 CT048 K.Yamada
               ,location_cd                  --���_�R�[�h
               ,location_nm                  --���_��
--//+ADD END   2009/02/19 CT048 K.Yamada
      FROM      xxcsm_tmp_month_item_plan     --���ʏ��i�v�惏�[�N�e�[�u��
      ORDER BY  seq_no           --�o�͏�
    ;
    check_list_data_cur_rec  check_list_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

    lv_data_head := NULL;
    lv_data_body := NULL;
    lv_item_plan_data := NULL;
--//+ADD START 2009/02/19 CT048 K.Yamada
    lt_pre_location_cd := cv_1st_location;    --���_�R�[�h
--//+ADD END   2009/02/19 CT048 K.Yamada
--//+ADD START 2009/02/19 CT048 K.Yamada
    -- �c�Ɗ�敔�u�S���_�v�̏ꍇ
    IF (gv_location_cd = cv_location_1) THEN
--//+ADD END   2009/02/19 CT048 K.Yamada
    -- �w�b�_���̒��o
      BEGIN
        SELECT location_nm 
        INTO   lv_location_nm
        FROM   xxcsm_location_all_v  
        WHERE location_cd = gv_location_cd;
      END;
      lv_data_head := xxccp_common_pkg.get_msg(                                   -- ���_�R�[�h�̏o��
                        iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_chk_err_00098                       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_kyoten_cd                       -- �g�[�N���R�[�h1�i���_�R�[�h�j
                       ,iv_token_value1 => gv_location_cd                         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_kyoten_nm                       -- �g�[�N���R�[�h2�i���_�R�[�h���́j
                       ,iv_token_value2 => lv_location_nm                         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_year                            -- �g�[�N���R�[�h3�i�Ώ۔N�x�j
                       ,iv_token_value3 => gn_subject_year                        -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_nichiji                         -- �g�[�N���R�[�h4�i�Ɩ����t�j
                       ,iv_token_value4 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')  -- �g�[�N���l4
                       );
       -- �w�b�_���̏o��
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_data_head
                       );
--//+ADD START 2009/02/19 CT048 K.Yamada
    END IF;
--//+ADD END   2009/02/19 CT048 K.Yamada
--
    -- =========================================================================
    -- �{�f�B���̏o��
    -- =========================================================================
    OPEN check_list_data_cur;
    LOOP
      FETCH check_list_data_cur INTO check_list_data_cur_rec;
      EXIT WHEN check_list_data_cur%NOTFOUND;
        lv_code        := check_list_data_cur_rec.code;                  --�o�̓R�[�h
        lv_name        := check_list_data_cur_rec.name;                  --�o�͖�
        lv_kbn_nm      := check_list_data_cur_rec.kbn_nm;                --�o�͋敪��
        lt_plan_data5  := check_list_data_cur_rec.plan_data5;            --5���f�[�^
        lt_plan_data6  := check_list_data_cur_rec.plan_data6;            --6���f�[�^
        lt_plan_data7  := check_list_data_cur_rec.plan_data7;            --7���f�[�^
        lt_plan_data8  := check_list_data_cur_rec.plan_data8;            --8���f�[�^
        lt_plan_data9  := check_list_data_cur_rec.plan_data9;            --9���f�[�^
        lt_plan_data10 := check_list_data_cur_rec.plan_data10;           --10���f�[�^
        lt_plan_data11 := check_list_data_cur_rec.plan_data11;           --11���f�[�^
        lt_plan_data12 := check_list_data_cur_rec.plan_data12;           --12���f�[�^
        lt_plan_data1  := check_list_data_cur_rec.plan_data1;            --1���f�[�^
        lt_plan_data2  := check_list_data_cur_rec.plan_data2;            --2���f�[�^
        lt_plan_data3  := check_list_data_cur_rec.plan_data3;            --3���f�[�^
        lt_plan_data4  := check_list_data_cur_rec.plan_data4;            --4���f�[�^
        lt_plan_year   := check_list_data_cur_rec.plan_year;             --�N�ԃf�[�^
--//+ADD START 2009/02/19 CT048 K.Yamada
        lt_location_cd := check_list_data_cur_rec.location_cd;           --���_�R�[�h
        lt_location_nm := check_list_data_cur_rec.location_nm;           --���_��
--//+ADD END   2009/02/19 CT048 K.Yamada
        --�s���ݒ�
        lv_item_plan_data := lv_code||cv_msg_comma||lv_name||cv_msg_comma||lv_kbn_nm||cv_msg_comma||lt_plan_data5||
                           cv_msg_comma||lt_plan_data6||cv_msg_comma||lt_plan_data7||cv_msg_comma||lt_plan_data8||
                           cv_msg_comma||lt_plan_data9||cv_msg_comma||lt_plan_data10||cv_msg_comma||lt_plan_data11||
                           cv_msg_comma||lt_plan_data12||cv_msg_comma||lt_plan_data1||cv_msg_comma||lt_plan_data2||
                           cv_msg_comma||lt_plan_data3||cv_msg_comma||lt_plan_data4||cv_msg_comma||lt_plan_year;
        --�s�����{�f�B���ɒǉ�
--//+ADD START 2009/02/19 CT048 K.Yamada
      -- �c�Ɗ�敔�u�S���_�v�łȂ��ꍇ
      IF (gv_location_cd <> cv_location_1) THEN
        -- ���_�R�[�h���ς������
        IF (lt_location_cd <> lt_pre_location_cd) THEN
          -- �Q�ڈȍ~�̋��_�̏ꍇ
          IF (lt_pre_location_cd <> cv_1st_location) THEN
            -- �P�s�󂯂�
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ''
                             );
          END IF;
          -- ���_���̃w�b�_���o��
          lv_data_head := xxccp_common_pkg.get_msg(                                   -- ���_�R�[�h�̏o��
                            iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_chk_err_00098                       -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_kyoten_cd                       -- �g�[�N���R�[�h1�i���_�R�[�h�j
                           ,iv_token_value1 => lt_location_cd                         -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_kyoten_nm                       -- �g�[�N���R�[�h2�i���_�R�[�h���́j
                           ,iv_token_value2 => lt_location_nm                         -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_year                            -- �g�[�N���R�[�h3�i�Ώ۔N�x�j
                          ,iv_token_value3 => gn_subject_year                        -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_nichiji                         -- �g�[�N���R�[�h4�i�Ɩ����t�j
                           ,iv_token_value4 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')  -- �g�[�N���l4
                           );
           -- �w�b�_���̏o��
          fnd_file.put_line(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_data_head
                           );
          lt_pre_location_cd := lt_location_cd;
        END IF;
      END IF;
--//+ADD END   2009/02/19 CT048 K.Yamada
        -- �{�f�B���̏o��
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_item_plan_data
                       );
    END LOOP;
    CLOSE check_list_data_cur;
    IF lv_item_plan_data IS NULL THEN
--//+ADD START   2009/07/13 0000657 M.Ohtsuki
    IF (gv_location_cd <> cv_location_1) THEN                                                       --�u�S���_�v�ȊO�̏ꍇ
--//+ADD END     2009/07/13 0000657 M.Ohtsuki
--//+ADD START   2009/02/27 CT070 T.Tsukino
      BEGIN
        SELECT location_nm 
        INTO   lv_location_nm
        FROM   xxcsm_location_all_v  
        WHERE location_cd = gv_location_cd;
      END;
      lv_data_head := xxccp_common_pkg.get_msg(                                   -- ���_�R�[�h�̏o��
                        iv_application  => cv_xxcsm                               -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_chk_err_00098                       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_kyoten_cd                       -- �g�[�N���R�[�h1�i���_�R�[�h�j
                       ,iv_token_value1 => gv_location_cd                         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_kyoten_nm                       -- �g�[�N���R�[�h2�i���_�R�[�h���́j
                       ,iv_token_value2 => lv_location_nm                         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_year                            -- �g�[�N���R�[�h3�i�Ώ۔N�x�j
                       ,iv_token_value3 => gn_subject_year                        -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_nichiji                         -- �g�[�N���R�[�h4�i�Ɩ����t�j
                       ,iv_token_value4 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')  -- �g�[�N���l4
                       );
       -- �w�b�_���̏o��
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_data_head
                       );
--//+ADD END     2009/02/27 CT070 T.Tsukino
--//+ADD START   2009/07/13 0000657 M.Ohtsuki
      END IF;
--//+ADD END     2009/07/13 0000657 M.Ohtsuki
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_10001
                                           );
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_errmsg
                       );
      --//+ADD START 2009/02/12 CT013 H.Yoshitake
      -- �߂�X�e�[�^�X�x���ݒ�
      ov_retcode := cv_status_warn;
      --//+ADD END   2009/02/12 CT013 H.Yoshitake
    END IF;
--
--#################################  �Œ��O������  #############################
--
  EXCEPTION
    WHEN global_api_expt THEN
      IF (check_list_data_cur%ISOPEN) THEN
        CLOSE check_list_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (check_list_data_cur%ISOPEN) THEN
        CLOSE check_list_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (check_list_data_cur%ISOPEN) THEN
        CLOSE check_list_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ###########################
--
  END write_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT NOCOPY VARCHAR2,     --  �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,     --  ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';          -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                   --�G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                      --���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_location_cd            VARCHAR2(4);                      --�S���_�擾�������_�R�[�h
    lv_location_nm            VARCHAR2(100);                    --�S���_�擾�������_����
    lv_get_loc_tab            xxcsm_common_pkg.g_kyoten_ttype;  --���_�R�[�h���X�g
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    gn_seq_no      := 0;                --�V�[�P���X�ԍ�
    -- ���[�J���ϐ�������
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
          lv_errbuf         -- �G���[�E���b�Z�[�W
         ,lv_retcode        -- ���^�[���E�R�[�h
         ,lv_errmsg );
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �S���_�擾(A-2)(���ʊ֐����Ăяo��)
    -- ===============================
    xxcsm_common_pkg.get_kyoten_cd_lv6(
                                      iv_kyoten_cd      => gv_location_cd
                                     ,iv_kaisou         => gv_hierarchy_level
--//ADD START 2009/05/07 T1_0858 M.Ohtsuki
                                     ,iv_subject_year   => gn_subject_year
--//ADD END   2009/05/07 T1_0858 M.Ohtsuki
                                     ,o_kyoten_list_tab => lv_get_loc_tab
                                     ,ov_retcode        => lv_retcode
                                     ,ov_errbuf         => lv_errbuf 
                                     ,ov_errmsg         => lv_errmsg 
                                     );
    -- ��O����(�擾�����f�[�^��0���̏ꍇ�A�G���[�R�[�h��WARNING�ŁA
    --         �`�F�b�N���X�g�̃w�b�_�ƑΏۃf�[�^�����̃��b�Z�[�W�����o�͂��A����I�����܂��B)
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    <<kyoten_list_loop>>
    FOR ln_count IN 1..lv_get_loc_tab.COUNT LOOP
      BEGIN
        -- ���_�R�[�h
        lv_location_cd := lv_get_loc_tab(ln_count).kyoten_cd;
        -- ���_����
        lv_location_nm := lv_get_loc_tab(ln_count).kyoten_nm;
        --�Ώی�����ݒ�
        gn_target_cnt := gn_target_cnt + 1;
        -- ===================================
        --�N�ԏ��i�v��f�[�^���݃`�F�b�N(A-3)
        --�������σf�[�^���݃`�F�b�N(A-4)
        -- ===================================
        do_check (
                  lv_location_cd                  --A-2�Ŏ擾�������_�R�[�h
                 ,lv_errbuf                       --�G���[�E���b�Z�[�W
                 ,lv_retcode                      --���^�[���E�R�[�h
                 ,lv_errmsg );                    --���[�U�[�E�G���[�E���b�Z�[�W
        -- ��O����
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE kyoten_skip_expt;
        END IF;
        --*** ���̓p�����[�^�D���_�R�[�h��'1'�̏ꍇ�A���_�v�AH������o���܂��B ***
        IF (gv_location_cd = cv_location_1) THEN
          --  ===============================
          --  ���_�ʌ��ʏW�v(A-16)
          --  ���ʋ��_�ʃf�[�^�AH��o�^(A-17)
          --  ===============================
          kyoten_month_count (
                              lv_location_cd                  --A-2�Ŏ擾�������_�R�[�h
                             ,lv_location_nm                  --A-2�Ŏ擾�������_����
                             ,lv_errbuf                       --���ʁE�G���[�E���b�Z�[�W
                             ,lv_retcode                      --���^�[���E�R�[�h
                             ,lv_errmsg );                    --���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
          END IF;
        ELSE
          --*** ���̓p�����[�^�D���_�R�[�h��1�ȊO�̏ꍇ ***
          -- ===================================
          -- ���i�v��f�[�^�𒊏o(A-5)
          -- ===================================
          item_plan_select (
                            lv_location_cd            --A-2�Ŏ擾�������_�R�[�h
                           ,lv_location_nm            --A-2�Ŏ擾�������_��
                           ,lv_errbuf                 --���ʁE�G���[�E���b�Z�[�W
                           ,lv_retcode                --���^�[���E�R�[�h
                           ,lv_errmsg);               --���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
        END IF;
        gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
        WHEN kyoten_skip_expt THEN
          fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg        --�G���[���b�Z�[�W
          );
--//+UPD START 2009/02/19 CT037 K.Yamada
--          gn_error_cnt := gn_error_cnt + 1;
          gn_warn_cnt := gn_warn_cnt + 1;
--//+UPD END   2009/02/19 CT037 K.Yamada
          ov_retcode := cv_status_warn;
      END;
    END LOOP kyoten_list_loop;
    -- ===================================
    -- �`�F�b�N���X�g�f�[�^�o��(A-18)
    -- ===================================
    write_csv_file (
                    lv_errbuf                --���ʁE�G���[�E���b�Z�[�W
                   ,lv_retcode               --���^�[���E�R�[�h
                   ,lv_errmsg);              --���[�U�[�E�G���[�E���b�Z�[�W
    -- ��O����
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
    ov_retcode := lv_retcode;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf                  OUT  NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W
    retcode                 OUT  NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h
    iv_subject_year         IN   VARCHAR2,            --   �Ώ۔N�x
    iv_location_cd          IN   VARCHAR2,            --   ���_�R�[�h
    iv_hierarchy_level      IN   VARCHAR2             --   �K�w
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_whick_log
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
    --���̓p�����[�^
    gn_subject_year    := TO_NUMBER(iv_subject_year);
    gv_location_cd     := iv_location_cd;
    gv_hierarchy_level := iv_hierarchy_level;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf        -- �G���[�E���b�Z�[�W 
      ,lv_retcode       -- ���^�[���E�R�[�h  
      ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
--
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_xxcsm
                                                ,iv_name         => cv_msg_00111
                                               );
      END IF;
    --�G���[�o��
      fnd_file.put_line(
--//+UPD START 2009/02/12 CT013 SCS H.Yoshitake
--         which  => FND_FILE.LOG
         which  => FND_FILE.OUTPUT
--//+UPD END   2009/02/12 CT013 SCS H.Yoshitake
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
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
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSM002A08C;
/
