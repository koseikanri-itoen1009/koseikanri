CREATE OR REPLACE PACKAGE BODY XXCSM004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A06C(Body)
 * Description      : EBS(�t�@�C���A�b�v���[�hIF)�Ɏ捞�܂ꂽ�Y��|�C���g�f�[�^��
 *                  : �V�K�l���|�C���g�ڋq�ʗ����e�[�u���Ɏ捞�݂܂��B
 * MD.050           : MD050_CSM_004_A06_�Y��|�C���g�ꊇ�捞
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
 *  check_year_month       �N���`�F�b�N(A-4)
 *  delete_old_data        �f�[�^�폜(A-5)
 *  check_item             ���ڑÓ����`�F�b�N(A-7)
 *  insert_data            �o�^����(A-8)
 *  loop_main              LOOP�A�Y��|�C���g�f�[�^�擾�A�Z�[�u�|�C���g�̐ݒ�(A-3,A-6)
 *                            �Echeck_year_month
 *                            �Edelete_old_data
 *                            �Echeck_item
 *                            �Einsert_data
 *  final                  �I������(A-9)
 *  submain                ���C�������v���V�[�W��
 *                            �Einit
 *                            �Eget_if_data
 *                            �Eloop_main
 *                            �Efinal
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �Emain
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/03    1.0   SCS M.Ohtsuki    �V�K�쐬
 *  2009/04/06    1.1   SCS M.Ohtsuki    [��QT1_0241]�J�n���擾NVL�Ή�
 *  2009/04/09    1.2   SCS M.Ohtsuki    [��QT1_0416]�Ɩ����t�ƃV�X�e�����t��r�̕s�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
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
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- �z��O�G���[���b�Z�[�W
--
--################################  �Œ蕔 END   ##################################
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM004A06C';                               -- �p�b�P�[�W��
  cv_param_msg_1            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00101';                           -- �p�����[�^�o�͗p���b�Z�[�W
  cv_param_msg_2            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00102';                           -- �p�����[�^�o�͗p���b�Z�[�W
  cv_file_name              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00109';                           -- �C���^�[�t�F�[�X�t�@�C����
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                                          -- �J���}
  --�G���[���b�Z�[�W�R�[�h
  cv_csm_msg_005            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                           -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_csm_msg_022            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00022';                           -- �t�@�C���A�b�v���[�hIF�e�[�u�����b�N�擾�G���[���b�Z�[�W
  cv_csm_msg_108            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00108';                           -- �t�@�C���A�b�v���[�h����
  cv_csm_msg_139            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10139';                           -- �l���N���`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_140            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10140';                           -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u�����b�N�擾�G���[���b�Z�[�W
  cv_csm_msg_141            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10141';                           -- �N���󔒃`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_142            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10142';                           -- �|�C���g�捞�s�\���ԃ��b�Z�[�W
  cv_csm_msg_143            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10143';                           -- ���_�R�[�h�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_144            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10144';                           -- �ڋq�R�[�h�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_145            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10145';                           -- �]�ƈ��`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_146            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10146';                           -- �|�C���g�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_147            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10147';                           -- �l���E�Љ�敪�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_148            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10148';                           -- �p�~���_�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_149            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10149';                           -- �Y��|�C���g�f�[�^�t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_151            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10151';                           -- �Y��|�C���g���ڑ����`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_152            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10152';                           -- �o�^�f�[�^0�����b�Z�[�W
--
  --�g�[�N���R�[�h
  cv_tkn_prf_nm             CONSTANT VARCHAR2(100) := 'PROF_NAME';                                  -- �v���t�@�C����
  cv_tkn_count              CONSTANT VARCHAR2(100) := 'COUNT';                                      -- ��������
  cv_tkn_file_id            CONSTANT VARCHAR2(100) := 'FILE_ID';                                    -- �t�@�C��ID
  cv_tkn_format             CONSTANT VARCHAR2(100) := 'FORMAT';                                     -- �t�H�[�}�b�g
  cv_tkn_up_name            CONSTANT VARCHAR2(100) := 'UPLOAD_NAME';                                -- �t�@�C���A�b�v���[�h����
  cv_tkn_file_name          CONSTANT VARCHAR2(100) := 'FILE_NAME';                                  -- �t�@�C����
  cv_tkn_yyyymm             CONSTANT VARCHAR2(100) := 'YYYYMM';                                     -- �N��
  cv_tkn_emp_cd             CONSTANT VARCHAR2(100) := 'EMPLOYEE_CD';                                -- �]�ƈ��R�[�h
  cv_tkn_loc_cd             CONSTANT VARCHAR2(100) := 'LOCATION_CD';                                -- ���_�R�[�h
  cv_tkn_cust_cd            CONSTANT VARCHAR2(100) := 'CUSTOMER_CD';                                -- �ڋq�R�[�h
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(100) := 'ERR_MSG';                                    -- SQL�G���[���b�Z�[�W
  --�A�v���P�[�V�����Z�k��
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                                      -- �A�v���P�[�V�����Z�k��
  cv_chk_warning            CONSTANT VARCHAR2(1)   := '1';                                          -- �x��
  cv_chk_normal             CONSTANT VARCHAR2(1)   := '0';                                          -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  TYPE gr_def_info_rtype IS RECORD                                                                  -- ���R�[�h�^��錾
      (meaning    VARCHAR2(100)                                                                     -- ���ږ�
      ,attribute  VARCHAR2(100)                                                                     -- ���ڑ���
      ,essential  VARCHAR2(100)                                                                     -- �K�{�t���O
      ,figures    NUMBER                                                                            -- ���ڂ̒���
      );
  TYPE gt_def_info_ttype IS TABLE OF gr_def_info_rtype                                              -- �e�[�u���^�̐錾
    INDEX BY BINARY_INTEGER;
--
  TYPE gt_check_data_ttype IS TABLE OF VARCHAR2(4000)                                               -- �e�[�u���^�̐錾
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  --�e�[�u���^�ϐ��̐錾
  gt_def_info_tab           gt_def_info_ttype;                                                      -- �e�[�u���^�ϐ��̐錾
  --
  gn_counter                NUMBER;                                                                 -- ���������J�E���^�[
  gn_file_id                NUMBER;                                                                 -- �p�����[�^(�t�@�C��ID)�i�[�p�ϐ�
  gv_format                 VARCHAR2(100);                                                          -- �p�����[�^(�t�H�[�}�b�g)�i�[�p�ϐ�
  gn_item_num               NUMBER;                                                                 -- �Y��|�C���g���ڐ��i�[�p
  gn_set_of_bks_id          NUMBER;                                                                 -- ��v����ID�i�[�p
  gv_appl_ar                VARCHAR2(100);                                                          -- AR�A�v���P�[�V�����Z�k���i�[�p
  gv_subject_year           VARCHAR2(100);                                                          -- �Ώ۔N�x�i�[�p
  gd_process_date           DATE;                                                                   -- �Ɩ����t
  gv_warnig_flg             VARCHAR2(1);                                                            -- �x���t���O
  gv_check_flag             VARCHAR2(1);                                                            -- �`�F�b�N�t���O
  gv_low_type               VARCHAR2(10);                                                           -- �Ƒԁi�����ށj
  gn_canncel_flg            NUMBER;                                                                 -- �p�~���_�`�F�b�N
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    ov_errbuf               OUT NOCOPY VARCHAR2                                                     -- �G���[�E���b�Z�[�W
   ,ov_retcode              OUT NOCOPY VARCHAR2                                                     -- ���^�[���E�R�[�h
   ,ov_errmsg               OUT NOCOPY VARCHAR2                                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';                                       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode              VARCHAR2(1);                                                            -- ���^�[���E�R�[�h
    lv_errbuf               VARCHAR2(4000);                                                         -- �G���[�E���b�Z�[�W
    lv_errmsg               VARCHAR2(4000);                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn_value            VARCHAR2(4000);                                                         -- �g�[�N���l
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--�v���t�@�C���擾�p
    cv_item_num             CONSTANT VARCHAR2(100) := 'XXCSM1_VENDING_PNT_ITEM_NUM';                -- �Y��|�C���g�f�[�^���ڐ�
    cv_set_of_bks_id        CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                           -- ��v����ID
--
    cv_upload_obj           CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';                     -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
    cv_vending_item         CONSTANT VARCHAR2(100) := 'XXCSM1_VENDING_PNT_ITEM';                    -- �Y��|�C���g�f�[�^���ڒ�`
    cv_null_ok              CONSTANT VARCHAR2(100) := 'NULL_OK';                                    -- �C�Ӎ���
    cv_null_ng              CONSTANT VARCHAR2(100) := 'NULL_NG';                                    -- �K�{����
    cv_varchar              CONSTANT VARCHAR2(100) := 'VARCHAR2';                                   -- ������
    cv_number               CONSTANT VARCHAR2(100) := 'NUMBER';                                     -- ���l
    cv_date                 CONSTANT VARCHAR2(100) := 'DATE';                                       -- ���t
    cv_varchar_cd           CONSTANT VARCHAR2(100) := '0';                                          -- �����񍀖�
    cv_number_cd            CONSTANT VARCHAR2(100) := '1';                                          -- ���l����
    cv_date_cd              CONSTANT VARCHAR2(100) := '2';                                          -- ���t����
    cv_not_null             CONSTANT VARCHAR2(100) := '1';                                          -- �K�{
    cv_appl_ar              CONSTANT VARCHAR2(100) := 'AR';                                         -- �A�v���P�[�V�����Z�k��
--
    -- *** ���[�J���ϐ� ***
    ln_cnt                  NUMBER;                                                                 -- �J�E���^
    lv_up_name              VARCHAR2(1000);                                                         -- �A�b�v���[�h���̏o�͗p
    lv_in_file_id           VARCHAR2(1000);                                                         -- �t�@�C���h�c�o�͗p
    lv_in_format            VARCHAR2(1000);                                                         -- �t�H�[�}�b�g�o�͗p
    lv_upload_obj           VARCHAR2(100);                                                          -- �t�@�C���A�b�v���[�h����
--
    get_err_expt            EXCEPTION;
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR   get_def_info_cur                                                                       -- �f�[�^���ڒ�`�擾�p�J�[�\��
    IS
      SELECT   flv.meaning                                               meaning                    -- ���e
              ,DECODE(flv.attribute1,cv_varchar,cv_varchar_cd
                                    ,cv_number,cv_number_cd,cv_date_cd)  attribute                  -- ���ڑ���
              ,DECODE(flv.attribute2,cv_not_null,cv_null_ng,cv_null_ok)  essential                  -- �K�{�t���O
              ,TO_NUMBER(flv.attribute3)                                 figures                    -- ���ڂ̒���
      FROM     fnd_lookup_values  flv                                                               -- �N�C�b�N�R�[�h�l
      WHERE    flv.lookup_type        = cv_vending_item                                             -- �Y��|�C���g�f�[�^���ڒ�`
        AND    flv.language           = USERENV('LANG')                                             -- ����('JA')
        AND    flv.enabled_flag       = 'Y'                                                         -- �g�p�\�t���O
--//+UPD START 2009/04/09 T1_0416 M.Ohtsuki
--        AND    flv.start_date_active <= gd_process_date                                             -- �K�p�J�n��
--        AND    NVL(flv.end_date_active,SYSDATE)   >= gd_process_date                                -- �K�p�I����
--��������������������������������������������������������������������������������������������������
        AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date                        -- �K�p�J�n��
        AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date                        -- �K�p�I����
--//+UPD END   2009/04/09 T1_0416 M.Ohtsuki
      ORDER BY flv.lookup_code   ASC;                                                               -- ���b�N�A�b�v�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode    := cv_status_normal;
    lv_tkn_value  := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --A-1 �@�Ɩ����t�̎擾
    --==============================================================
--
    gd_process_date := xxccp_common_pkg2.get_process_date;                                          -- �Ɩ����t�擾
--
    --==============================================================
    --A-1 �A�v���t�@�C���l�擾
    --==============================================================
--
    gn_item_num      := FND_PROFILE.VALUE(cv_item_num);                                             -- �Y��|�C���g�f�[�^���ڐ�
    gn_set_of_bks_id := FND_PROFILE.VALUE(cv_set_of_bks_id);                                        -- ��v����ID
--
    IF (gn_item_num IS NULL) THEN                                                                   -- �Y��|�C���g�f�[�^���ڐ��̎擾���s
      lv_tkn_value    := cv_item_num;
    ELSIF (gn_set_of_bks_id IS NULL) THEN                                                           -- ��v����ID�̎擾���s
      lv_tkn_value    := cv_set_of_bks_id;
    END IF;
--
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm                             -- XXCSM
                                           ,iv_name         => cv_csm_msg_005                       -- �v���t�@�C���擾�G���[���b�Z�[�W
                                           ,iv_token_name1  => cv_tkn_prf_nm                        -- PROF_NAME
                                           ,iv_token_value1 => lv_tkn_value                         -- �v���t�@�C������
                                           );
      lv_errbuf := lv_errmsg;
      RAISE get_err_expt;
    END IF;
--
    --==============================================================
    --A-1  �BAR�A�v���P�[�V����ID�̎擾
    --==============================================================
--
    gv_appl_ar := xxccp_common_pkg.get_application(cv_appl_ar);                                     -- AR�A�v���P�[�V����ID�擾
--
    --==============================================================
    --A-1  �C�Y��|�C���g�f�[�^��`���擾
    --==============================================================
--
    ln_cnt := 0;                                                                                    -- �ϐ��̏�����
    <<def_info_loop>>                                                                               -- �e�[�u����`�擾LOOP
    FOR rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      gt_def_info_tab(ln_cnt).meaning   := rec.meaning;                                             -- ���ږ�
      gt_def_info_tab(ln_cnt).attribute := rec.attribute;                                           -- ���ڑ���
      gt_def_info_tab(ln_cnt).essential := rec.essential;                                           -- �K�{�t���O
      gt_def_info_tab(ln_cnt).figures   := rec.figures;                                             -- ���ڂ̒���
    END LOOP def_info_loop;
--
    --==============================================================
    --A-1  �D�t�@�C���A�b�v���[�h���̂̎擾
    --==============================================================
--
    SELECT   flv.meaning  meaning
    INTO     lv_upload_obj
    FROM     fnd_lookup_values flv
    WHERE    flv.lookup_type        = cv_upload_obj                                                 -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
      AND    flv.lookup_code        = TO_CHAR(gv_format)
      AND    flv.language           = USERENV('LANG')                                               -- ����('JA')
      AND    flv.enabled_flag       = 'Y'                                                           -- �g�p�\�t���O
--//+UPD START 2009/04/06 T1_0241 M.Ohtsuki
--      AND    flv.start_date_active <= gd_process_date                                               -- �K�p�J�n��
--���������������������������������������������������������������������������������������������������K�p�J�n��NVL�Ή�
      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date                          -- �K�p�J�n��
--//+UPD END   2009/04/06 T1_0241 M.Ohtsuki
--//+UPD START 2009/04/09 T1_0416 M.Ohtsuki
--      AND    NVL(flv.end_date_active,SYSDATE)   >= gd_process_date;                                 -- �K�p�I����
--���������������������������������������������������������������������������������������������������K�p�J�n��NVL�Ή�
      AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date;                                 -- �K�p�I����
--//+UPD END   2009/04/09 T1_0416 M.Ohtsuki
--
    --==============================================================
    --A-1 �EIN�p�����[�^�̏o��
    --==============================================================
--
    lv_up_name    := xxccp_common_pkg.get_msg(                                                      -- �A�b�v���[�h���̂̏o��
                       iv_application  => cv_xxcsm                                                  -- XXCSM
                      ,iv_name         => cv_csm_msg_108                                            -- �t�@�C���A�b�v���[�h����
                      ,iv_token_name1  => cv_tkn_up_name                                            -- UPLOAD_NAME
                      ,iv_token_value1 => lv_upload_obj                                             -- �A�b�v���[�h����
                      );
    lv_in_file_id := xxccp_common_pkg.get_msg(                                                      -- �t�@�C��ID�̏o��
                       iv_application  => cv_xxcsm                                                  -- XXCSM
                      ,iv_name         => cv_param_msg_1                                            -- �R���J�����g���̓p�����[�^���b�Z�[�W(�t�@�C��ID)
                      ,iv_token_name1  => cv_tkn_file_id                                            -- FILE_ID
                      ,iv_token_value1 => gn_file_id                                                -- �t�@�C��ID1
                      );
    lv_in_format  := xxccp_common_pkg.get_msg(                                                      -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_xxcsm                                                  -- XXCSM
                      ,iv_name         => cv_param_msg_2                                            -- �R���J�����g���̓p�����[�^���b�Z�[�W(�t�H�[�}�b�g)
                      ,iv_token_name1  => cv_tkn_format                                             -- FORMAT
                      ,iv_token_value1 => gv_format                                                 -- �t�H�[�}�b�g
                      );
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     -- �o�͂ɕ\��
                     ,buff   => lv_up_name    || CHR(10) ||
                                lv_in_file_id || CHR(10) ||
                                lv_in_format
                                );
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ���O�ɕ\��
                     ,buff   => lv_up_name    || CHR(10) ||
                                lv_in_file_id || CHR(10) ||
                                lv_in_format
                                );
--
  EXCEPTION
    WHEN get_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
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
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
   ***********************************************************************************/
--
  PROCEDURE get_if_data(
    ov_errbuf     OUT NOCOPY   VARCHAR2                                                             -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY   VARCHAR2                                                             -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY   VARCHAR2)                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';                                      -- �v���O������
--
    lv_errbuf         VARCHAR2(4000);                                                               -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);                                                                  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(4000);                                                               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_cnt_a          NUMBER;                                                                       -- �J�E���^��錾
    ln_cnt_b          NUMBER;                                                                       -- �J�E���^��錾
    ln_item_cnt       NUMBER;                                                                       -- �J�E���^��錾
    lv_file_name      VARCHAR2(100);                                                                -- �t�@�C�����i�[�p
    lv_created_by     VARCHAR2(100);                                                                -- �쐬�Ҋi�[�p
    lv_creation_date  VARCHAR2(100);                                                                -- �쐬���i�[�p
    lv_fname_op       VARCHAR2(100);                                                                -- �t�@�C�����o�͗p
--
    lt_data_item_tab  gt_check_data_ttype;                                                          -- �e�[�u���^�ϐ���錾
    lt_if_data_tab    xxccp_common_pkg2.g_file_data_tbl;                                            -- �e�[�u���^�ϐ���錾
--
    get_if_data_expt  EXCEPTION;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --A-2 �Ώۃf�[�^���b�N�̎擾
    --==============================================================
--
    BEGIN
      SELECT   fui.file_name         file_name                                                      -- �t�@�C����
              ,fui.created_by        created_by                                                     -- �쐬��
              ,fui.creation_date     creation_date                                                  -- �쐬��
      INTO     lv_file_name   
              ,lv_created_by
              ,lv_creation_date
      FROM     xxccp_mrp_file_ul_interface  fui                                                     -- �t�@�C���A�b�v���[�hIF�e�[�u��
      WHERE    fui.file_id = gn_file_id                                                             -- �t�@�C��ID
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN OTHERS THEN                                                                              -- ���b�N�Ɏ��s�����ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm                           -- XXCSM
                                             ,iv_name         => cv_csm_msg_022                     -- �t�@�C���A�b�v���[�hIF���b�N�擾�G���[���b�Z�[�W
                                             );
        lv_errbuf := lv_errmsg;
        RAISE get_if_data_expt;
    END;
--
    lv_fname_op := xxccp_common_pkg.get_msg(                                                        -- �t�@�C�����̏o��
                      iv_application  => cv_xxcsm                                                   -- XXCSM
                     ,iv_name         => cv_file_name                                               -- �C���^�[�t�F�[�X�t�@�C����
                     ,iv_token_name1  => cv_tkn_file_name                                           -- FILENAME
                     ,iv_token_value1 => lv_file_name                                               -- �t�@�C����
                     );
--
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     -- �o�͂ɕ\��
                     ,buff   => lv_fname_op || CHR(10)
                     );
--
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ���O�ɕ\��
                     ,buff   => lv_fname_op || CHR(10)
                     );
--
    xxccp_common_pkg2.blob_to_varchar2(                                                             -- BLOB�f�[�^�ϊ����ʊ֐�
                                   in_file_id    => gn_file_id                                      -- IN�p�����[�^(�t�@�C��ID)
                                   ,ov_file_data => lt_if_data_tab                                  -- �e�[�u���^�ϐ�
                                   ,ov_errbuf    => lv_errbuf                                       -- �G���[�E���b�Z�[�W
                                   ,ov_retcode   => lv_retcode                                      -- ���^�[���E�R�[�h
                                   ,ov_errmsg    => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
                                   );
--
    gn_target_cnt := lt_if_data_tab.COUNT;                                                          -- �����Ώی������i�[
    ln_cnt_a      := 0;                                                                             -- �J�E���^��������
--
    <<ins_wk_loop>>                                                                                 -- ���[�N�e�[�u���o�^LOOP
    LOOP
      EXIT WHEN ln_cnt_a >= gn_target_cnt;
      ln_cnt_a := ln_cnt_a + 1;                                                                     -- �����J�E���^���C���N�������g
      --���ڐ��̃`�F�b�N
      ln_item_cnt := (LENGTHB(lt_if_data_tab(ln_cnt_a)) -
                     (LENGTHB(REPLACE(lt_if_data_tab(ln_cnt_a),cv_msg_comma,''))) + 1);             -- �f�[�^���ڐ����i�[
      --
      IF (gn_item_num <> ln_item_cnt) THEN                                                          -- ���ڐ�����v���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm                            -- �A�v���P�[�V�����Z�k��
                                            ,iv_name         => cv_csm_msg_149                      -- ���b�Z�[�W�R�[�h
                                            );
        lv_errbuf := lv_errmsg;
        RAISE get_if_data_expt;
      END IF;
      --
      ln_cnt_b := 0;                                                                                -- �J�E���^��������
--
      <<get_column_loop>>                                                                           -- ���ڒl�擾LOOP
      LOOP
        EXIT WHEN ln_cnt_b >= gn_item_num;                                                          -- ���ڐ���LOOP
        ln_cnt_b := ln_cnt_b + 1;                                                                   -- �J�E���^���C���N�������g
        lt_data_item_tab(ln_cnt_b) := xxccp_common_pkg.char_delim_partition(                        -- �f���~�^�����ϊ����ʊ֐�
                                                       iv_char     =>  lt_if_data_tab(ln_cnt_a)
                                                      ,iv_delim    =>  cv_msg_comma
                                                      ,in_part_num =>  (ln_cnt_b)
                                                       );                                           -- �ϐ��ɍ��ڂ̒l���i�[
--
      END LOOP get_column_loop;
      INSERT INTO  
        xxcsm_wk_vending_pnt(                                                                       -- �Y��|�C���g���[�N�e�[�u��
          year_month                                                                                -- �l���N��
         ,customer_cd                                                                               -- �ڋq�R�[�h
         ,location_cd                                                                               -- ���_�R�[�h
         ,employee_cd                                                                               -- �]�ƈ��R�[�h
         ,get_intro_kbn                                                                             -- �l���E�Љ�敪
         ,point                                                                                     -- �|�C���g
          )
        VALUES(
          lt_data_item_tab(1)                                                                       -- �l���N��
         ,lt_data_item_tab(2)                                                                       -- �ڋq�R�[�h
         ,lt_data_item_tab(3)                                                                       -- ���_�R�[�h
         ,lt_data_item_tab(4)                                                                       -- �]�ƈ��R�[�h
         ,lt_data_item_tab(5)                                                                       -- �l���E�Љ�敪
         ,lt_data_item_tab(6)                                                                       -- �|�C���g
        );
    END LOOP ins_wk_loop;
--
  EXCEPTION
    WHEN get_if_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
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
  END  get_if_data;
--
  /**********************************************************************************
   * Procedure Name   :  check_year_month
   * Description      :  �N���`�F�b�N(A-4)
   ***********************************************************************************/
--
  PROCEDURE check_year_month(
    iv_year_month   IN  VARCHAR2                                                                    -- �N��
   ,ov_errbuf       OUT NOCOPY VARCHAR2                                                             -- �G���[�E���b�Z�[�W
   ,ov_retcode      OUT NOCOPY VARCHAR2                                                             -- ���^�[���E�R�[�h
   ,ov_errmsg       OUT NOCOPY VARCHAR2)                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'check_year_month';                                   -- �v���O������
    cv_open         CONSTANT VARCHAR2(1)   := 'O';                                                  -- �X�e�[�^�X(O = �I�[�v��)
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf       VARCHAR2(4000);                                                                 -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);                                                                    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(4000);                                                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_year_month   VARCHAR2(1000);                                                                 -- �N���i�[�p
    ln_cnt          NUMBER;                                                                         -- �����m�F�p
    ld_year_month   DATE;                                                                           -- �t�H�[�}�b�g�`�F�b�N�p
--
    check_err_expt  EXCEPTION;                                                                      -- �`�F�b�N�G���[��O
--
  BEGIN
--
    ov_retcode      := cv_status_normal;                                                            -- �ϐ��̏�����
    lv_year_month   := iv_year_month;                                                               -- IN�p�����[�^�̊i�[
--
    --�N�����󔒂̏ꍇ�̓G���[
    IF (lv_year_month IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm_msg_141                                              -- ���b�Z�[�W�R�[�h
                    );
      lv_errbuf := lv_errmsg;
      RAISE check_err_expt;
    END IF;
--
    --�N����'YYYYMM'�`���ŔN���Ƃ��đ��݂��鎖�B����ȊO�̓G���[
    BEGIN
      SELECT TO_DATE(lv_year_month,'YYYYMM')
      INTO   ld_year_month
      FROM   DUAL;
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm_msg_139                                              -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_yyyymm                                               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_year_month                                               -- �g�[�N���l1
                    );
      lv_errbuf := lv_errmsg;
      RAISE check_err_expt;
    END;
--
    --�N�����o�^�E�C���\�ȉ�v���Ԃł��鎖�B����ȊO�̓G���[
    BEGIN
      SELECT  gps.period_year                                                                       -- �Ώ۔N�x
      INTO    gv_subject_year
      FROM     gl_period_statuses   gps                                                             -- ��v���ԃX�e�[�^�X�e�[�u��
      WHERE    gps.set_of_books_id = gn_set_of_bks_id                                               -- ��v����ID
        AND    gps.application_id  = gv_appl_ar                                                     -- �A�v���P�[�V����ID
        AND    gps.closing_status  = cv_open                                                        -- �X�e�[�^�X = �I�[�v��
        AND    gps.period_name     = TO_CHAR(ld_year_month,'YYYY-MM');                                               -- �N��
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_csm_msg_142                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_yyyymm                                             -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_year_month                                             -- �g�[�N���l1
                      );
        lv_errbuf := lv_errmsg;
        RAISE check_err_expt;
    END;
  EXCEPTION
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN check_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END check_year_month;
--
  /**********************************************************************************
   * Procedure Name   :  delete_old_data
   * Description      :  �f�[�^�폜(A-5)
   ***********************************************************************************/
--
  PROCEDURE delete_old_data(
    iv_year_month   IN  VARCHAR2                                                                    -- �N��
   ,ov_errbuf       OUT NOCOPY VARCHAR2                                                             -- �G���[�E���b�Z�[�W
   ,ov_retcode      OUT NOCOPY VARCHAR2                                                             -- ���^�[���E�R�[�h
   ,ov_errmsg       OUT NOCOPY VARCHAR2)                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'delete_old_data';                                    -- �v���O������
    cn_jyuki        CONSTANT NUMBER(1)   := 2;                                                      -- �f�[�^�敪(�Y��|�C���g = 2)
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf       VARCHAR2(4000);                                                                 -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);                                                                    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(4000);                                                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_month_no     NUMBER;                                                                         -- ���i�[�p
    ln_cnt          NUMBER;                                                                         -- �����m�F�p
    ld_year_month   DATE;                                                                           -- �t�H�[�}�b�g�`�F�b�N�p
--
    CURSOR data_lock_cur(in_month_no IN NUMBER)                                                     -- ���b�N�擾�p�J�[�\��
    IS
      SELECT  ncp.year_month
      FROM    xxcsm_new_cust_point_hst  ncp                                                         -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u��
      WHERE   ncp.subject_year = TO_NUMBER(gv_subject_year)                                         -- �Ώ۔N�x
        AND   ncp.month_no     = in_month_no                                                        -- ��
        AND   ncp.data_kbn     = cn_jyuki                                                           -- �f�[�^�敪
      FOR UPDATE NOWAIT;
--
    lock_err_expt   EXCEPTION;                                                                      -- ���b�N�G���[��O
--
  BEGIN
--
    ln_month_no := TO_NUMBER(SUBSTR(iv_year_month,5));                                              -- �����i�[
      --==============================================================
      --  A-5   �V�K�l���|�C���g�ڋq�ʗ����e�[�u�������f�[�^�̃��b�N
      --==============================================================
--
    BEGIN
      OPEN  data_lock_cur(ln_month_no);
      CLOSE data_lock_cur;
    EXCEPTION
      WHEN OTHERS THEN
        IF (data_lock_cur%ISOPEN) THEN
          CLOSE data_lock_cur;
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_csm_msg_140                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_yyyymm                                             -- �g�[�N���R�[�h1
                      ,iv_token_value1 => iv_year_month                                             -- �g�[�N���l1
                      );
        lv_errbuf := lv_errmsg;
        RAISE lock_err_expt;
    END;
--
      --==============================================================
      --  A-5   �V�K�l���|�C���g�ڋq�ʗ����e�[�u��
      --==============================================================
--
    DELETE  FROM  xxcsm_new_cust_point_hst    ncp                                                   -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u��
    WHERE   ncp.subject_year = TO_NUMBER(gv_subject_year)                                           -- �Ώ۔N�x
      AND   ncp.month_no     = ln_month_no                                                          -- ��
      AND   ncp.data_kbn     = cn_jyuki;                                                            -- �f�[�^�敪
--
  EXCEPTION
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN lock_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END delete_old_data;
--
  /**********************************************************************************
   * Procedure Name   : check_item
   * Description      : ���ڑÓ����`�F�b�N(A-7)
   ***********************************************************************************/
--
  PROCEDURE check_item(
    ir_data_rec   IN  xxcsm_wk_vending_pnt%ROWTYPE                                                  -- �Ώۃ��R�[�h
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item';                                           -- �v���O������
    cv_location   CONSTANT VARCHAR2(100) := '1';                                                    -- �ڋq�敪(1 = ���_�R�[�h) 
    cv_cust_show  CONSTANT VARCHAR2(100) := 'XXCSM1_SHOWCASE_CUST_STATUS';                          -- �ڋq���
    cv_flg_y      CONSTANT VARCHAR2(100) := 'Y';                                                    -- �L���t���O
    cv_canncel    CONSTANT VARCHAR2(100) := '90';                                                   -- ���~����
    cv_minus      CONSTANT VARCHAR2(100) := '-';                                                    -- �}�C�i�X
    cn_zero       CONSTANT NUMBER := 0;
--
    lv_errbuf     VARCHAR2(4000);                                                                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);                                                                      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(4000);                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_location   VARCHAR2(100);
    lv_point      VARCHAR2(100);
    ln_check_cnt  NUMBER;
    ln_loc_cnt    NUMBER;
    ln_emp_cnt    NUMBER;
--
    lt_check_data_tab gt_check_data_ttype;                                                          -- �e�[�u���^�ϐ��̐錾
    chk_warning_expt  EXCEPTION;
--
  BEGIN
--
    ov_retcode    := cv_status_normal;                                                              -- �ϐ��̏�����
    lv_location   := NULL;                                                                          -- �ϐ��̏�����
    ln_check_cnt  := 0;                                                                             -- �ϐ��̏�����
    ln_loc_cnt    := 0;                                                                             -- �ϐ��̏�����
    gv_low_type   := NULL;                                                                          -- �ϐ��̏�����
--
    IF (SUBSTR(ir_data_rec.point,1,1)  = cv_minus) THEN                                             -- �|�C���g���}�C�i�X�̏ꍇ
      lv_point   := SUBSTR(ir_data_rec.point,2);                                                    -- �|�C���g�̐�Βl������ϐ��Ɋi�[
    ELSE
      lv_point   := ir_data_rec.point;                                                              -- �|�C���g��ϐ��Ɋi�[
    END IF;
--
    lt_check_data_tab(1)  := ir_data_rec.year_month;                                                -- �l���N��
    lt_check_data_tab(2)  := ir_data_rec.customer_cd;                                               -- �ڋq�R�[�h
    lt_check_data_tab(3)  := ir_data_rec.location_cd;                                               -- ���_�R�[�h
    lt_check_data_tab(4)  := ir_data_rec.employee_cd;                                               -- �]�ƈ��R�[�h
    lt_check_data_tab(5)  := ir_data_rec.get_intro_kbn;                                             -- �l���E�Љ�敪
    lt_check_data_tab(6)  := lv_point;                                                              -- �|�C���g
--
    ln_check_cnt := 0;                                                                              -- �J�E���^�̏�����
--
    --==============================================================
    --A-7 �@���ڑÓ����`�F�b�N
    --==============================================================
--
    <<chk_column_loop>>                                                                             -- ���ڑÓ����`�F�b�NLOOP
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      ln_check_cnt := ln_check_cnt + 1;                                                             -- �J�E���^�����Z
      xxccp_common_pkg2.upload_item_check(
                        iv_item_name    => gt_def_info_tab(ln_check_cnt).meaning                    -- ���ږ���
                       ,iv_item_value   => lt_check_data_tab(ln_check_cnt)                          -- ���ڂ̒l
                       ,in_item_len     => gt_def_info_tab(ln_check_cnt).figures                    -- ���ڂ̒���(��������)
                       ,in_item_decimal => cn_zero                                                  -- ���ڂ̒���(�����_�ȉ�)
                       ,iv_item_nullflg => gt_def_info_tab(ln_check_cnt).essential                  -- �K�{�t���O
                       ,iv_item_attr    => gt_def_info_tab(ln_check_cnt).attribute                  -- ���ڂ̑���
                       ,ov_errbuf       => lv_errbuf
                       ,ov_retcode      => lv_retcode
                       ,ov_errmsg       => lv_errmsg 
                       );
      IF (lv_retcode <> cv_status_normal) THEN                                                      -- �߂�l���ُ�̏ꍇ
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm                                                 -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_csm_msg_151                                           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_yyyymm                                            -- �g�[�N���R�[�h1
                       ,iv_token_name2  => cv_tkn_emp_cd                                            -- �g�[�N���R�[�h2
                       ,iv_token_name3  => cv_tkn_loc_cd                                            -- �g�[�N���R�[�h3
                       ,iv_token_name4  => cv_tkn_cust_cd                                           -- �g�[�N���R�[�h4
                       ,iv_token_name5  => cv_tkn_sqlerrm                                           -- �g�[�N���R�[�h5
                       ,iv_token_value1 => ir_data_rec.year_month                                   -- �l���N��
                       ,iv_token_value2 => ir_data_rec.employee_cd                                  -- �]�ƈ��R�[�h
                       ,iv_token_value3 => ir_data_rec.location_cd                                  -- ���_�R�[�h
                       ,iv_token_value4 => ir_data_rec.customer_cd                                  -- �ڋq�R�[�h
                       ,iv_token_value5 => lv_errmsg                                                -- ���ʊ֐�����̃��b�Z�[�W
                       );
         fnd_file.put_line(
                           which  => FND_FILE.OUTPUT                                                -- �o�͂ɕ\��
                          ,buff   => lv_errmsg                                                      -- ���[�U�[�E�G���[���b�Z�[�W
                          );
        gv_check_flag := cv_chk_warning;                                                            -- �`�F�b�N�t���O��ON
        RAISE chk_warning_expt;
      END IF;
    END LOOP chk_column_loop;
--
    --==============================================================
    --A-7 �A�]�ƈ��R�[�h�`�F�b�N
    --==============================================================
--
    SELECT   COUNT(1)
    INTO     ln_emp_cnt
    FROM     per_people_f            ppf                                                            -- �]�ƈ��}�X�^
            ,per_periods_of_service  pps                                                            -- �]�ƈ��T�[�r�X�}�X�^
    WHERE    ppf.person_id = pps.person_id                                                          -- �]�ƈ�ID
      AND    pps.date_start <= gd_process_date                                                      -- ���ДN����
      AND    NVL(pps.actual_termination_date,gd_process_date) >= gd_process_date                    -- �ސE�N����
      AND    ppf.employee_number = ir_data_rec.employee_cd;                                         -- �]�ƈ��R�[�h
--
    IF (ln_emp_cnt = 0) THEN                                                                        -- �f�[�^0���̏ꍇ
       lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm_msg_145                                             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_yyyymm                                              -- �g�[�N���R�[�h1
                     ,iv_token_name2  => cv_tkn_emp_cd                                              -- �g�[�N���R�[�h2
                     ,iv_token_name3  => cv_tkn_loc_cd                                              -- �g�[�N���R�[�h3
                     ,iv_token_name4  => cv_tkn_cust_cd                                             -- �g�[�N���R�[�h4
                     ,iv_token_value1 => ir_data_rec.year_month                                     -- �g�[�N���l1
                     ,iv_token_value2 => ir_data_rec.employee_cd                                    -- �g�[�N���l2
                     ,iv_token_value3 => ir_data_rec.location_cd                                    -- �g�[�N���l3
                     ,iv_token_value4 => ir_data_rec.customer_cd                                    -- �g�[�N���l4
                     );
       fnd_file.put_line(
                         which  => FND_FILE.OUTPUT                                                  -- �o�͂ɕ\��
                        ,buff   => lv_errmsg                                                        -- ���[�U�[�E�G���[���b�Z�[�W
                        );
      gv_check_flag := cv_chk_warning;                                                              -- �`�F�b�N�t���O��ON
      RAISE chk_warning_expt;
    END IF;
--
    --==============================================================
    --A-7 �B���_�R�[�h�`�F�b�N
    --==============================================================
--
    -- ���_�R�[�h���݃`�F�b�N
    SELECT   COUNT(1)                                                                               -- ����
    INTO     ln_loc_cnt
    FROM     hz_cust_accounts     hca                                                               -- �ڋq�}�X�^
    WHERE    hca.customer_class_code = cv_location                                                  -- �ڋq�敪
      AND    hca.account_number      = ir_data_rec.location_cd                                      -- �ڋq�R�[�h
      AND    ROWNUM = 1;
--
    IF (ln_loc_cnt = 0) THEN                                                                        -- �f�[�^0���̏ꍇ
       lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm_msg_143                                             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_yyyymm                                              -- �g�[�N���R�[�h1
                     ,iv_token_name2  => cv_tkn_emp_cd                                              -- �g�[�N���R�[�h2
                     ,iv_token_name3  => cv_tkn_loc_cd                                              -- �g�[�N���R�[�h3
                     ,iv_token_name4  => cv_tkn_cust_cd                                             -- �g�[�N���R�[�h4
                     ,iv_token_value1 => ir_data_rec.year_month                                     -- �g�[�N���l1
                     ,iv_token_value2 => ir_data_rec.employee_cd                                    -- �g�[�N���l2
                     ,iv_token_value3 => ir_data_rec.location_cd                                    -- �g�[�N���l3
                     ,iv_token_value4 => ir_data_rec.customer_cd                                    -- �g�[�N���l4
                     );
       fnd_file.put_line(
                         which  => FND_FILE.OUTPUT                                                  -- �o�͂ɕ\��
                        ,buff   => lv_errmsg                                                        -- ���[�U�[�E�G���[���b�Z�[�W
                        );
      gv_check_flag := cv_chk_warning;                                                              -- �`�F�b�N�t���O��ON
      RAISE chk_warning_expt;
    ELSE
      -- �p�~���_�`�F�b�N
      BEGIN
        SELECT  hca.account_number                                                                  -- ���_�R�[�h
        INTO    lv_location
        FROM    hz_cust_accounts     hca                                                            -- �ڋq�}�X�^
               ,hz_parties           hpa                                                            -- �p�[�e�B�}�X�^
        WHERE   hca.customer_class_code = cv_location                                               -- �ڋq�敪
          AND   hca.account_number      = ir_data_rec.location_cd                                   -- �ڋq�R�[�h
          AND   hca.party_id            = hpa.party_id                                              -- �p�[�e�BID
          AND   hpa.duns_number_c       = cv_canncel                                                -- �ڋq�X�e�[�^�X
          AND   ROWNUM = 1;                                                                         -- 1����
--
        IF (lv_location IS NOT NULL) THEN                                                           -- �p�~���_�̏ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm                                                -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_csm_msg_148                                          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_yyyymm                                           -- �g�[�N���R�[�h1
                        ,iv_token_name2  => cv_tkn_emp_cd                                           -- �g�[�N���R�[�h2
                        ,iv_token_name3  => cv_tkn_loc_cd                                           -- �g�[�N���R�[�h3
                        ,iv_token_name4  => cv_tkn_cust_cd                                          -- �g�[�N���R�[�h4
                        ,iv_token_value1 => ir_data_rec.year_month                                  -- �g�[�N���l1
                        ,iv_token_value2 => ir_data_rec.employee_cd                                 -- �g�[�N���l2
                        ,iv_token_value3 => ir_data_rec.location_cd                                 -- �g�[�N���l3
                        ,iv_token_value4 => ir_data_rec.customer_cd                                 -- �g�[�N���l4
                        );
           fnd_file.put_line(
                             which  => FND_FILE.OUTPUT                                              -- �o�͂ɕ\��
                            ,buff   => lv_errmsg                                                    -- ���[�U�[�E�G���[���b�Z�[�W
                            );
           gn_canncel_flg := 1;                                                                     -- �p�~���_�t���O��ON
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN                                                                     -- �p�~���_�ł͖����ꍇ
          NULL;
      END;
    END IF;
--
    --==============================================================
    --A-7 �C�ڋq�R�[�h�`�F�b�N
    --==============================================================
--
    BEGIN
      SELECT   xca.business_low_type   business_low_type                                            -- �Ƒ�(������)
      INTO     gv_low_type
      FROM     hz_cust_accounts     hca                                                             -- �ڋq�}�X�^
              ,xxcmm_cust_accounts  xca                                                             -- �ǉ��ڋq���e�[�u��
              ,hz_parties           hpa                                                             -- �p�[�e�B�}�X�^
      WHERE    hca.account_number       =  ir_data_rec.customer_cd                                  -- �ڋq�R�[�h
        AND    hca.cust_account_id      =  xca.customer_id                                          -- �ڋqID
        AND    xca.start_tran_date     <=  gd_process_date                                          -- ��������
        AND    (xca.stop_approval_date >=  ADD_MONTHS(TO_DATE(ir_data_rec.year_month,'RRRRMM'),1)   -- ���~���ϓ�
               OR xca.stop_approval_date IS NULL)
        AND    hca.party_id             = hpa.party_id                                              -- �p�[�e�BID
        AND    NOT EXISTS
                 (SELECT  flv.lookup_code     lookup_code                                           -- ���b�N�A�b�v�R�[�h
                  FROM    fnd_lookup_values   flv                                                   -- �N�C�b�N�R�[�h�l
                  WHERE   flv.lookup_type  = cv_cust_show                                           -- �ڋq���
                    AND   flv.enabled_flag = cv_flg_y                                               -- �L���t���O
                    AND   flv.language     = USERENV('LANG')                                        -- ����
                    AND   NVL(flv.start_date_active,gd_process_date)  <= gd_process_date            -- �J�n��
                    AND   NVL(flv.end_date_active,gd_process_date)    >= gd_process_date            -- �I����
                    AND   hpa.duns_number_c = flv.lookup_code
                  )
        AND     ROWNUM = 1;
--
    EXCEPTION                                                                                       -- �Ƒ�(������)���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_csm_msg_144                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_yyyymm                                             -- �g�[�N���R�[�h1
                      ,iv_token_name2  => cv_tkn_emp_cd                                             -- �g�[�N���R�[�h2
                      ,iv_token_name3  => cv_tkn_loc_cd                                             -- �g�[�N���R�[�h3
                      ,iv_token_name4  => cv_tkn_cust_cd                                            -- �g�[�N���R�[�h4
                      ,iv_token_value1 => ir_data_rec.year_month                                    -- �g�[�N���l1
                      ,iv_token_value2 => ir_data_rec.employee_cd                                   -- �g�[�N���l2
                      ,iv_token_value3 => ir_data_rec.location_cd                                   -- �g�[�N���l3
                      ,iv_token_value4 => ir_data_rec.customer_cd                                   -- �g�[�N���l4
                      );
        fnd_file.put_line(
                          which  => FND_FILE.OUTPUT                                                 -- �o�͂ɕ\��
                         ,buff   => lv_errmsg                                                       -- ���[�U�[�E�G���[���b�Z�[�W
                         );
        gv_check_flag := cv_chk_warning;                                                            -- �`�F�b�N�t���O��ON
        RAISE chk_warning_expt;
    END;
--
    --==============================================================
    --A-7 �E�l���E�Љ�敪�`�F�b�N
    --==============================================================
--
    IF (ir_data_rec.get_intro_kbn <> '0'
        AND ir_data_rec.get_intro_kbn <> '1') THEN                                                  -- �l���E�Љ�敪��'0'�A'1'�ȊO
       lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csm_msg_147                                             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_yyyymm                                              -- �g�[�N���R�[�h1
                     ,iv_token_name2  => cv_tkn_emp_cd                                              -- �g�[�N���R�[�h2
                     ,iv_token_name3  => cv_tkn_loc_cd                                              -- �g�[�N���R�[�h3
                     ,iv_token_name4  => cv_tkn_cust_cd                                             -- �g�[�N���R�[�h4
                     ,iv_token_value1 => ir_data_rec.year_month                                     -- �g�[�N���l1
                     ,iv_token_value2 => ir_data_rec.employee_cd                                    -- �g�[�N���l2
                     ,iv_token_value3 => ir_data_rec.location_cd                                    -- �g�[�N���l3
                     ,iv_token_value4 => ir_data_rec.customer_cd                                    -- �g�[�N���l4
                     );
       fnd_file.put_line(
                         which  => FND_FILE.OUTPUT                                                  -- �o�͂ɕ\��
                        ,buff   => lv_errmsg                                                        -- ���[�U�[�E�G���[���b�Z�[�W
                        );
      gv_check_flag := cv_chk_warning;                                                              -- �`�F�b�N�t���O��ON
      RAISE chk_warning_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN chk_warning_expt THEN
      ov_retcode := cv_status_warn;
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
  END check_item;
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : �f�[�^�o�^ (A-8)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_data_rec   IN  xxcsm_wk_vending_pnt%ROWTYPE                                                  -- �Ώۃ��R�[�h
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data';                                          -- �v���O������
    cv_achieve    CONSTANT VARCHAR2(100) := '0';                                                    -- �V�K�]���Ώۋ敪(�B�� = 0)
    cv_first_day  CONSTANT VARCHAR2(100) := '01';                                                   -- ���
    cn_jyuki      CONSTANT NUMBER := 2;                                                             -- �f�[�^�敪(�Y��|�C���g = 2)
--
    lv_errbuf     VARCHAR2(4000);                                                                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);                                                                      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(4000);                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
/***************************************************************************************************
  �������v���O�����͍��ڂ̑Ó����`�F�b�N���s�����߁A�C���T�[�g���͈Öٕϊ����s����B
****************************************************************************************************/
    INSERT INTO
      xxcsm_new_cust_point_hst(                                                                     -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u��
        employee_number                                                                             -- �]�ƈ��R�[�h
       ,subject_year                                                                                -- �Ώ۔N�x
       ,month_no                                                                                    -- ��
       ,account_number                                                                              -- �ڋq�R�[�h
       ,data_kbn                                                                                    -- �f�[�^�敪
       ,year_month                                                                                  -- �N��
       ,point                                                                                       -- �|�C���g
       ,post_cd                                                                                     -- �����R�[�h
       ,duties_cd                                                                                   -- �E���R�[�h
       ,qualificate_cd                                                                              -- ���i�R�[�h
       ,location_cd                                                                                 -- ���_�R�[�h
       ,get_intro_kbn                                                                               -- �l���E�Љ�敪
       ,get_custom_date                                                                             -- �ڋq�l����
       ,custom_condition_cd                                                                         -- �ڋq�ƑԃR�[�h
       ,business_low_type                                                                           -- �Ƒԁi�����ށj
       ,evaluration_kbn                                                                             -- �V�K�]���Ώۋ敪
       ,created_by                                                                                  -- �쐬��
       ,creation_date                                                                               -- �쐬��
       ,last_updated_by                                                                             -- �ŏI�X�V��
       ,last_update_date                                                                            -- �ŏI�X�V��
       ,last_update_login                                                                           -- �ŏI�X�V���O�C��
       ,request_id                                                                                  -- �v��ID
       ,program_application_id                                                                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                                                                                  -- �R���J�����g�E�v���O����ID
       ,program_update_date                                                                         -- �v���O�����X�V��
       )
      VALUES(
        ir_data_rec.employee_cd                                                                     -- �]�ƈ��R�[�h
       ,TO_NUMBER(gv_subject_year)                                                                  -- �Ώ۔N�x
       ,TO_NUMBER(SUBSTR(ir_data_rec.year_month,5))                                                 -- ��
       ,ir_data_rec.customer_cd                                                                     -- �ڋq�R�[�h
       ,cn_jyuki                                                                                    -- �f�[�^�敪
       ,TO_NUMBER(ir_data_rec.year_month)                                                           -- �N��
       ,TO_NUMBER(ir_data_rec.point)                                                                -- �|�C���g
       ,NULL                                                                                        -- �����R�[�h
       ,NULL                                                                                        -- �E���R�[�h
       ,NULL                                                                                        -- ���i�R�[�h
       ,ir_data_rec.location_cd                                                                     -- ���_�R�[�h
       ,NVL(ir_data_rec.get_intro_kbn,'0')                                                          -- �l���E�Љ�敪
       ,TO_DATE(ir_data_rec.year_month || cv_first_day,'YYYYMMDD')                                  -- �ڋq�l����
       ,NULL                                                                                        -- �ڋq�ƑԃR�[�h
       ,gv_low_type                                                                                 -- �Ƒԁi�����ށj
       ,cv_achieve                                                                                  -- �V�K�]���Ώۋ敪
       ,cn_created_by                                                                               -- �쐬��
       ,cd_creation_date                                                                            -- �쐬��
       ,cn_last_updated_by                                                                          -- �ŏI�X�V��
       ,cd_last_update_date                                                                         -- �ŏI�X�V��
       ,cn_last_update_login                                                                        -- �ŏI�X�V���O�C��
       ,cn_request_id                                                                               -- �v��ID
       ,cn_program_application_id                                                                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id                                                                               -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                                                                      -- �v���O�����X�V��
       );
/***************************************************************************************************
****************************************************************************************************/
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
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �N�Ԍv��f�[�^�擾�A�Z�[�u�|�C���g�̐ݒ� (A-3,A-6)
   ***********************************************************************************/
--
  PROCEDURE loop_main(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    cv_prg_name          CONSTANT VARCHAR2(100) := 'loop_main';                                     -- �v���O������
    cv_null              CONSTANT VARCHAR2(100) := 'Null';                                          -- NULL
    sub_proc_other_expt  EXCEPTION;
--
    lv_errbuf            VARCHAR2(4000);                                                            -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                                               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_year_month        VARCHAR2(100);                                                             -- ���f�p_�l���N��
    lv_location_cd       VARCHAR2(100);                                                             -- ���f�p_���_�R�[�h
    lv_employee_cd       VARCHAR2(100);                                                             -- ���f�p_�]�ƈ��R�[�h
    lv_customer_cd       VARCHAR2(100);                                                             -- ���f�p_�ڋq�R�[�h
    ln_nodata_cnt        VARCHAR2(100);
--
    lr_data_rec          xxcsm_wk_vending_pnt%ROWTYPE;                                              -- �e�[�u���^�ϐ���錾
--
    CURSOR get_data_cur                                                                             -- �Y��|�C���g�f�[�^�擾�J�[�\��
    IS
      SELECT    wvp.year_month                            year_month                                -- �l���N��
               ,wvp.customer_cd                           customer_cd                               -- �ڋq�R�[�h
               ,wvp.location_cd                           location_cd                               -- ���_�R�[�h
               ,wvp.employee_cd                           employee_cd                               -- �]�ƈ��R�[�h
               ,wvp.get_intro_kbn                         get_intro_kbn                             -- �l���E�Љ�敪
               ,wvp.point                                 point                                     -- �|�C���g
      FROM      xxcsm_wk_vending_pnt                      wvp                                       -- �Y��|�C���g�f�[�^���[�N�e�[�u��
      ORDER BY  wvp.year_month                            ASC                                       -- �l���N��
               ,wvp.location_cd                           ASC                                       -- ���_�R�[�h
               ,wvp.employee_cd                           ASC                                       -- �]�ƈ��R�[�h
               ,wvp.customer_cd                           ASC;                                      -- �ڋq�R�[�h
--
    get_data_rec  get_data_cur%ROWTYPE;                                                             -- �Y��|�C���g�f�[�^�擾 ���R�[�h�^
  BEGIN
--
    ov_retcode    := cv_status_normal;                                                              -- �ϐ��̏�����
--
    gn_normal_cnt := 0;                                                                             -- ���팏���̏�����
    gn_warn_cnt   := 0;                                                                             -- �X�L�b�v�����̏�����
    gn_counter    := 0;                                                                             -- �����̏�����
    ln_nodata_cnt := 0;                                                                             -- �f�[�^0���`�F�b�N�p�J�E���^�[��������
    gv_check_flag := cv_chk_normal;                                                                 -- �`�F�b�N�t���O�̏�����
--
    OPEN get_data_cur;
    <<main_loop>>                                                                                   -- ���C������LOOP
    LOOP
      FETCH get_data_cur INTO get_data_rec;
      EXIT WHEN get_data_cur%NOTFOUND;                                                              -- �Ώۃf�[�^�����������J��Ԃ�
--
      IF ((get_data_cur%ROWCOUNT = 1)                                                               -- 1����
         OR (lv_year_month  <> NVL(get_data_rec.year_month,cv_null))) THEN                          -- �l���N���u���C�N��
--
        IF (get_data_cur%ROWCOUNT <> 1) THEN                                                        -- 1���ڈȊO
          IF (ln_nodata_cnt = 0) THEN                                                               -- �N���P�ʂ̓o�^������0���������ꍇ
--
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm                                              -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_csm_msg_152                                        -- �f�[�^0�����b�Z�[�W
                          ,iv_token_name1  => cv_tkn_yyyymm                                         -- �g�[�N���R�[�h1
                          ,iv_token_value1 => lv_year_month                                         -- �l���N��
                          );
            lv_errbuf := lv_errmsg;
--
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT                                             -- �o�͂ɕ\��
                             ,buff   => lv_errmsg                                                   -- ���[�U�[�E�G���[���b�Z�[�W
                             );
--
          ELSE
            ln_nodata_cnt := 0;                                                                     -- �f�[�^0���`�F�b�N�p�J�E���^�[��������
          END IF;
        END IF; 
    --==============================================================
    -- A-4 �N���`�F�b�N
    --==============================================================
--
        check_year_month(                                                                           -- �N���`�F�b�N���R�[��
            iv_year_month => get_data_rec.year_month
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
           );
--
        IF (lv_retcode <> cv_status_normal) THEN                                                    -- �߂�l������ȊO�̏ꍇ
            RAISE sub_proc_other_expt;
        END IF;
--
    --==============================================================
    -- A-5 �V�K�l���|�C���g�ڋq�ʗ����e�[�u�������f�[�^�̍폜
    --==============================================================
--
        delete_old_data(                                                                            -- �f�[�^�폜���R�[��
            iv_year_month => get_data_rec.year_month
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
           );
--
        IF (lv_retcode <> cv_status_normal) THEN                                                    -- �߂�l������ȊO�̏ꍇ
          RAISE sub_proc_other_expt;
        END IF;
      END IF;
--
      IF ((get_data_cur%ROWCOUNT = 1)                                                               -- 1����
         OR (lv_year_month  <> NVL(get_data_rec.year_month,cv_null))                                -- �l���N���u���C�N��
         OR (lv_location_cd <> NVL(get_data_rec.location_cd,cv_null))                               -- ���_�R�[�h�u���C�N��
         OR (lv_employee_cd <> NVL(get_data_rec.employee_cd,cv_null))                               -- �]�ƈ��R�[�h�u���C�N��
         OR (lv_customer_cd <> NVL(get_data_rec.customer_cd,cv_null))) THEN                         -- �ڋq�R�[�h�u���C�N��
--
        IF (gv_check_flag = cv_chk_normal)THEN                                                      -- �`�F�b�N�t���O���i���� = 0)�̏ꍇ
          gn_normal_cnt := (gn_normal_cnt + gn_counter);                                            -- ���폈�����������Z
        ELSIF (gv_check_flag = cv_chk_warning) THEN                                                 -- �`�F�b�N�t���O���i�G���[ = 1)�̏ꍇ
          gn_error_cnt := (gn_error_cnt + gn_counter);                                              -- �X�L�b�v���������Z
        END IF;
--
        gv_check_flag  := cv_chk_normal;                                                            -- �`�F�b�N�t���O�̏�����
        gn_counter := 0;                                                                            -- ����������������
--
    --==============================================================
    -- A-6 �Z�[�u�|�C���g�̐ݒ�
    --==============================================================
--
        SAVEPOINT check_warning;                                                                    -- �Z�[�u�|�C���g�̐ݒ�
--
      END IF;
    --==============================================================
    -- A-7 ���ڑÓ����`�F�b�N
    --==============================================================
--
      IF (gv_check_flag = cv_chk_normal) THEN                                                       -- �`�F�b�N�t���O��(����=0)�̏ꍇ
        lr_data_rec.year_month      := get_data_rec.year_month;                                     -- �l���N��
        lr_data_rec.location_cd     := get_data_rec.location_cd;                                    -- ���_�R�[�h
        lr_data_rec.customer_cd     := get_data_rec.customer_cd;                                    -- �ڋq�R�[�h
        lr_data_rec.employee_cd     := get_data_rec.employee_cd;                                    -- �]�ƈ��R�[�h
        lr_data_rec.get_intro_kbn   := get_data_rec.get_intro_kbn;                                  -- �l���E�Љ�敪
        lr_data_rec.point           := get_data_rec.point;                                          -- �|�C���g
--
        check_item(                                                                                 -- check_item���R�[��
           ir_data_rec => lr_data_rec
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
          );
--
        IF (lv_retcode = cv_status_error) THEN                                                      -- �߂�l���G���[�̏ꍇ
          RAISE sub_proc_other_expt;
        END IF;
--
        IF (lv_retcode = cv_status_warn) THEN                                                       -- �߂�l���x���̏ꍇ
          gv_warnig_flg := cv_status_warn;
          ln_nodata_cnt := 0;                                                                       -- �f�[�^0���J�E���^�[�̏�����
          ROLLBACK TO check_warning;                                                                -- �Z�[�u�|�C���g�փ��[���o�b�N
        END IF;
--
--
    --==============================================================
    -- A-8 �f�[�^�o�^
    --==============================================================
--

        IF (gv_check_flag = cv_chk_normal) THEN                                                     -- �`�F�b�N�t���O��(����=0)�̏ꍇ
          insert_data(                                                                              -- insert_data���R�[��
            ir_data_rec => lr_data_rec
           ,ov_errbuf   => lv_errbuf
           ,ov_retcode  => lv_retcode
           ,ov_errmsg   => lv_errmsg
           );
--
          IF (lv_retcode <> cv_status_normal) THEN                                                  -- �߂�l������ȊO�̏ꍇ
            RAISE sub_proc_other_expt;
          END IF;
          ln_nodata_cnt := (ln_nodata_cnt + 1);                                                     -- �f�[�^0���`�F�b�N�p�J�E���^�[�����Z
        END IF;
      END IF;
--
      lv_year_month  := get_data_rec.year_month;                                                    -- �l���N����ϐ��ɕێ�
      lv_location_cd := get_data_rec.location_cd;                                                   -- ���_�R�[�h��ϐ��ɕێ�
      lv_employee_cd := get_data_rec.employee_cd;                                                   -- �]�ƈ��R�[�h��ϐ��ɕێ�
      lv_customer_cd := get_data_rec.customer_cd;                                                   -- �ڋq�R�[�h��ϐ��ɕێ�
--
      gn_counter     := gn_counter + 1;                                                             -- �������������Z
--
    END LOOP main_loop;
--
    IF (ln_nodata_cnt = 0) THEN                                                                     -- �N���P�ʂ̓o�^������0���������ꍇ
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm_msg_152                                              -- �f�[�^0�����b�Z�[�W
                    ,iv_token_name1  => cv_tkn_yyyymm                                               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_year_month                                               -- �l���N��
                    );
      lv_errbuf := lv_errmsg;
--
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT                                                   -- �o�͂ɕ\��
                       ,buff   => lv_errmsg                                                         -- ���[�U�[�E�G���[���b�Z�[�W
                       );
--
    END IF;
--
    IF (gv_check_flag = cv_chk_normal)THEN                                                          -- �`�F�b�N�t���O���i���� = 0)�̏ꍇ
      gn_normal_cnt := (gn_normal_cnt + gn_counter);                                                -- ���폈�����������Z
    ELSIF (gv_check_flag = cv_chk_warning) THEN                                                     -- �`�F�b�N�t���O���i�G���[ = 1)�̏ꍇ
      gn_error_cnt := (gn_error_cnt + gn_counter);                                                  -- �X�L�b�v���������Z
    END IF;
--
    CLOSE  get_data_cur;
--
    IF ((gn_error_cnt >= 1)                                                                         -- �X�L�b�v�����f�[�^�����݂���ꍇ
      OR (gn_canncel_flg = 1 )) THEN                                                                -- �p�~���_�����݂����ꍇ
      ov_retcode := cv_status_warn;                                                                 -- �I���X�e�[�^�X���x���ɐݒ�
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_other_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode    := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : final
   * Description      : �I������ (A-9)
   ***********************************************************************************/
  PROCEDURE final(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'final';                                                -- �v���O������
    lv_errbuf     VARCHAR2(4000);                                                                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);                                                                      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(4000);                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
      --==============================================================
      --  A-9    �̔��v�惏�[�N�e�[�u���f�[�^�폜
      --==============================================================
--
    DELETE  FROM    xxcsm_wk_vending_pnt;                                                           -- �Y��|�C���g�f�[�^���[�N�e�[�u��
--
      --==============================================================
      --  A-9    �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
      --==============================================================
--
    DELETE  FROM    xxccp_mrp_file_ul_interface  fui                                                -- �t�@�C���A�b�v���[�hIF�e�[�u��
    WHERE   fui.file_id = gn_file_id;                                                               -- �t�@�C��ID
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
  END final;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                                              -- �v���O������
    lv_errbuf     VARCHAR2(4000);                                                                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);                                                                      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(4000);                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode     := cv_status_normal;                                                             -- ���^�[���R�[�h��������
--
    gn_target_cnt  := 0;                                                                            -- �����J�E���^�̏�����
    gn_normal_cnt  := 0;                                                                            -- �����J�E���^�̏�����
    gn_error_cnt   := 0;                                                                            -- �����J�E���^�̏�����
    gn_warn_cnt    := 0;                                                                            -- �����J�E���^�̏�����
    gn_canncel_flg := 0;                                                                            -- �p�~���_�t���O�̏�����
--
    init(                                                                                           -- init���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ȏ�̏ꍇ
      RAISE global_process_expt;
    END IF;
--
    get_if_data(                                                                                    -- get_if_data���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ȏ�̏ꍇ
      RAISE global_process_expt;
    END IF;
--
    loop_main(                                                                                      -- loop_main���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ȏ�̏ꍇ
      RAISE global_process_expt;
    END IF;
--
    final(                                                                                          -- final���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;
    ov_retcode := lv_retcode;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
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
  END submain;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,retcode       OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,iv_file_id    IN         VARCHAR2                                                               -- �t�@�C��ID
   ,iv_format     IN         VARCHAR2                                                               -- �t�H�[�}�b�g�p�^�[��
    )
--
  IS
--
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- �������b�Z�[�W�p�g�[�N����
--
    lv_errbuf          VARCHAR2(4000);                                                              -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                                                 -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);                                                               -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
    xxccp_common_pkg.put_log_header(                                                                -- �w�b�_�[���̏o��
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
    gn_file_id := TO_NUMBER(iv_file_id);                                                            -- IN�p�����[�^���i�[
    gv_format  := iv_format;                                                                        -- IN�p�����[�^���i�[
--
    submain(                                                                                        -- submain���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''                                                                                 -- ��s�̑}��
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    IF (gv_warnig_flg = cv_status_warn
      AND lv_retcode = cv_status_normal) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''                                                                                 -- ��s�̑}��
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
       which  => FND_FILE.OUTPUT
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
END XXCSM004A06C;
/

