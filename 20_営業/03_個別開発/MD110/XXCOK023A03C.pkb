CREATE OR REPLACE PACKAGE BODY XXCOK023A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A03C(body)
 * Description      : �^����\�Z�y�щ^������т����_�ʕi�ڕʁi�P�i�ʁj���ʂ�CSV�f�[�^�`���ŗv���o�͂��܂��B
 * MD.050           : �^����\�Z�ꗗ�\�o�� MD050_COK_023_A03
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                  ��������(A-1)
 *  put_file_date         �v���o�͏���(A-7 �` A-9)
 *  put_file_set          �o�̓f�[�^�̕ҏW����(A-7 �` A-9)
 *  get_base_data         ���_���o����(A-2)
 *  get_put_file_data     �v���o�͑Ώۃf�[�^�̎擾�E�o�͏���(A-2 �` A-6)
 *  submain               ���C�������v���V�[�W��
 *  main                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.0   SCS T.Taniguchi  �V�K�쐬
 *  2009/02/06    1.1   SCS T.Taniguchi  [��QCOK_017] �N�C�b�N�R�[�h�r���[�̗L�����E�������̔���ǉ�
 *  2009/03/02    1.2   SCS T.Taniguchi  [��QCOK_069] ���̓p�����[�^�u�E�Ӄ^�C�v�v�ɂ��A���_�̎擾�͈͂𐧌�
 *  2009/05/15    1.3   SCS A.Yano       [��QT1_1001] �o�͂������z�P�ʂ��~�ɏC��
 *  2009/09/03    1.4   S.Moriyama       [��Q0001257] OPM�i�ڃ}�X�^�擾�����ǉ�
 *
 *****************************************************************************************/
--
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1) := '.';
-- �O���[�o���ϐ�
  gv_out_msg              VARCHAR2(2000) DEFAULT NULL;
  gv_sep_msg              VARCHAR2(2000) DEFAULT NULL;
  gv_exec_user            VARCHAR2(100)  DEFAULT NULL;
  gv_conc_name            VARCHAR2(30)   DEFAULT NULL;
  gv_conc_status          VARCHAR2(30)   DEFAULT NULL;
  gn_target_cnt           NUMBER DEFAULT 0;       -- �Ώی���
  gn_normal_cnt           NUMBER DEFAULT 0;       -- ���팏��
  gn_error_cnt            NUMBER DEFAULT 0;       -- �G���[����
  gn_warn_cnt             NUMBER DEFAULT 0;       -- �X�L�b�v����
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(12) := 'XXCOK023A03C'; -- �p�b�P�[�W��
  -- ���b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; -- �G���[�I�����b�Z�[�W
  cv_msg_xxccp1_90000       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; -- �Ώی����o��
  cv_msg_xxccp1_90001       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; -- ���������o��
  cv_msg_xxccp1_90002       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; -- �G���[�����o��
  cv_msg_xxccp1_90003       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003'; -- �X�L�b�v�����o��
  cv_msg_xxcok1_10184       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10184'; -- �Ώۃf�[�^����
  cv_msg_xxcok1_00003       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003'; -- �v���t�@�C���擾�G���[
  cv_msg_xxcok1_00013       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00013'; -- �݌ɑg�DID�擾�G���[
  cv_msg_xxcok1_00052       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00052'; -- �E��ID�擾�G���[
  cv_msg_xxcok1_10182       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10182'; -- ���_�擾�G���[
  cv_msg_xxcok1_10183       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10183'; -- ���i���擾�G���[
  cv_msg_xxcok1_00014       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00014'; -- �����擾�G���[(�l�Z�b�g�擾)
  cv_msg_xxcok1_00018       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00018'; -- �R���J�����g���̓p�����[�^(���_�R�[�h)
  cv_msg_xxcok1_00019       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00019'; -- �R���J�����g���̓p�����[�^2(�\�Z�N�x)
  cv_msg_xxcok1_00012       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00012'; -- �������_�G���[
  cv_msg_xxcok1_10367       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10367'; -- �v���o�̓G���[
  cv_msg_xxcok1_00015       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015'; -- �N�C�b�N�R�[�h�擾�G���[
  cv_msg_xxcok1_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; -- �Ɩ��������t�擾�G���[
  -- �g�[�N��
  cv_year                   CONSTANT VARCHAR2(4)  := 'YEAR';           -- �\�Z�N�x
  cv_resp_name              CONSTANT VARCHAR2(9)  := 'RESP_NAME';      -- �E�Ӗ�
  cv_profile                CONSTANT VARCHAR2(7)  := 'PROFILE';        -- �v���t�@�C���E�I�v�V������
  cv_location_code          CONSTANT VARCHAR2(13) := 'LOCATION_CODE';  -- ���_�R�[�h
  cv_item_code              CONSTANT VARCHAR2(9)  := 'ITEM_CODE';      -- �i�ڃR�[�h
  cv_flex_value             CONSTANT VARCHAR2(14) := 'FLEX_VALUE_SET'; -- �l�Z�b�g��
  cv_org_code               CONSTANT VARCHAR2(8)  := 'ORG_CODE';       -- �݌ɑg�D�R�[�h
  cv_count                  CONSTANT VARCHAR2(5)  := 'COUNT';          -- ��������
  cv_user_id                CONSTANT VARCHAR2(7)  := 'USER_ID';        -- ���[�U�[ID
  cv_token_lookup_value_set CONSTANT VARCHAR2(16) := 'LOOKUP_VALUE_SET';
  -- application_short_name
  cv_appl_name_xxcok        CONSTANT VARCHAR2(5)  := 'XXCOK'; -- �A�v���P�[�V�����V���[�g�l�[��(XXCOK)
  cv_appl_name_xxccp        CONSTANT VARCHAR2(5)  := 'XXCCP'; -- �A�v���P�[�V�����V���[�g�l�[��(XXCCP)
  -- �J�X�^���E�v���t�@�C��
  cv_pro_organization_code  CONSTANT VARCHAR2(21)  := 'XXCOK1_ORG_CODE_SALES';    -- �݌ɑg�D�R�[�h
  cv_pro_head_office_code   CONSTANT VARCHAR2(20)  := 'XXCOK1_AFF2_DEPT_HON';     -- �{�Ђ̕���R�[�h
 -- �l�Z�b�g��
  cv_flex_st_name_department  CONSTANT VARCHAR2(15) := 'XX03_DEPARTMENT';           -- ����
  cv_flex_st_name_bd_month    CONSTANT VARCHAR2(25) := 'XXCOK1_BUDGET_MONTH_ORDER'; -- �\�Z��
  -- ���̑�
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';          -- �t���O('Y')
  cv_yyyymmdd                 CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD'; -- ���t�t�H�[�}�b�g
  cv_cust_cd_base             CONSTANT VARCHAR2(1)   := '1';          -- �ڋq�敪('1':���_)
  cv_put_code_line            CONSTANT VARCHAR2(1)   := '1';          -- �o�͋敪('1':����)
  cv_put_code_sum             CONSTANT VARCHAR2(1)   := '2';          -- �o�͋敪('2':���_�v)
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';          -- �J���}
  cv_kbn_koguchi              CONSTANT VARCHAR2(1)   := '1';          -- �����敪('1':����)
  cv_kbn_syatate              CONSTANT VARCHAR2(1)   := '0';          -- �����敪('0':�ԗ�)
  cn_number_0                 CONSTANT NUMBER        := 0;
  cn_number_1                 CONSTANT NUMBER        := 1;
  cv_month01                  CONSTANT VARCHAR2(2)   := '01';         -- 1��
  cv_month05                  CONSTANT VARCHAR2(2)   := '05';         -- 5��
  cv_resp_name_val            CONSTANT VARCHAR2(100) := fnd_global.resp_name; -- �E�Ӗ�
  cv_resp_type_0              CONSTANT VARCHAR2(1)   := '0';          -- ��Ǖ����S���ҐE��
  cv_resp_type_1              CONSTANT VARCHAR2(1)   := '1';          -- �{������S���ҐE��
  cv_resp_type_2              CONSTANT VARCHAR2(1)   := '2';          -- ���_����_�S���ҐE��
  -- �Q�ƃ^�C�v
  cv_lookup_type_put_val      CONSTANT VARCHAR2(28)  := 'XXCOK1_COST_BUDGET_PUT_VALUE';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_base_code            VARCHAR2(4)  DEFAULT NULL; -- ���̓p�����[�^�̋��_�R�[�h
  gv_budget_year          VARCHAR2(4)  DEFAULT NULL; -- ���̓p�����[�^�̗\�Z�N�x
  gv_org_code             VARCHAR2(3)  DEFAULT NULL; -- �݌ɑg�D�R�[�h
  gv_head_office_code     VARCHAR2(4)  DEFAULT NULL; -- �{�Е���R�[�h
  gn_org_id               NUMBER       DEFAULT NULL; -- �݌ɑg�DID
  gn_resp_id              NUMBER       DEFAULT NULL; -- ���O�C���E��ID
  gn_user_id              NUMBER       DEFAULT NULL; -- ���O�C�����[�U�[ID
  gn_put_count            NUMBER       DEFAULT 0;    -- ���׏o�̓J�E���g
  gv_target_year          VARCHAR2(4)  DEFAULT NULL; -- �Ώ۔N�x
  gd_process_date         DATE         DEFAULT NULL; -- �Ɩ��������t
  gv_resp_type            VARCHAR2(1)  DEFAULT NULL; -- �E�Ӄ^�C�v
--
  -- ===============================
  -- ���R�[�h�^�C�v�̐錾��
  -- ===============================
--
  -- ���_���̃��R�[�h�^�C�v
  TYPE base_rec IS RECORD(
    base_code        VARCHAR2(4), -- ���_�R�[�h
    base_name        VARCHAR2(50) -- ���_��
  );
--
  -- �^����\�Z�ꗗ�\�o�͂̃��R�[�h�^�C�v
  TYPE budget_rec IS RECORD(
    base_code          VARCHAR2(4),  -- ���_�R�[�h
    base_name          VARCHAR2(50), -- ���_��
    budget_item_code   VARCHAR2(7),  -- �\�Z_���i�R�[�h
    budget_item_name   VARCHAR2(60), -- �\�Z_���i��(����)
    budget_month       VARCHAR2(2)   -- �\�Z_��
  );
--
  -- ===============================
  -- �e�[�u���^�C�v�̐錾��
  -- ===============================
--
  -- ���_���̃e�[�u���^�C�v
  TYPE base_tbl IS TABLE OF base_rec INDEX BY BINARY_INTEGER;
--
  -- �^����\�Z�ꗗ�\�o�͂̃e�[�u���^�C�v
  TYPE budget_tbl IS TABLE OF budget_rec INDEX BY BINARY_INTEGER;
--
  -- ���z�E���ʂ̃e�[�u���^�C�v
  TYPE number_tbl IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
  g_default_value  number_tbl;   -- ���ʒl�̃f�t�H���g
--
  /**********************************************************************************
   * Procedure Name   : put_file_date
   * Description      : �v���o�͏���(A-7 �` A-9)
   ***********************************************************************************/
  PROCEDURE put_file_date(
    ov_errbuf           OUT   VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT   VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT   VARCHAR2,   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_header_data      IN    VARCHAR2,   -- �o�̓��R�[�h�̌��o������
    i_month_data_ttype  IN    number_tbl) -- ���ʂ̒l
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'put_file_date'; -- �v���O������
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_file_value     VARCHAR2(500) DEFAULT NULL;
    ln_index_cunt     NUMBER        DEFAULT 0;
    ln_half_term      NUMBER        DEFAULT 0;
    ln_yearly         NUMBER        DEFAULT 0;
    lb_retcode        BOOLEAN;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ���ʂ̃f�[�^���ݒ肳��Ă��Ȃ��ꍇ
    IF ( i_month_data_ttype.COUNT = 0 ) THEN
      lv_file_value := iv_header_data;
    -- ���ʂ̒l��A������
    ELSE
      -- ���ʃf�[�^�̘A�����[�v
      -- ���[�v�̉񐔂ɑΉ����錎�l�́A���L�̒ʂ�ɂȂ�
      --�u1 �� ���R�[�h�̃w�b�_�����v�A�u2 �� 5���v�A�u3 �� 6���v�A�u4 �� 7���v�A�u5 �� 8���v�A�u6 �� 9���v�A
      --�u7 �� 10���v�A�u8 �� �O���v�v�A�u9 �� 11���v�A�u10 �� 12���v�A�u11 �� 1���v�A�u12 �� 2���v�A
      --�u13 �� 3���v�A�u14 �� 4���v�A�u15 �� �N�Ԍv�v
--
      -- �f�[�^��A�����āA�o�̓��R�[�h���쐬
      <<month_value_loop>>
      FOR i IN 1..15 LOOP
        IF ( i = 1 ) THEN -- �w�b�_
          lv_file_value := iv_header_data;
        ELSIF ( i = 8 ) THEN  -- �O���v
          lv_file_value := lv_file_value || cv_comma || ln_half_term;
        ELSIF ( i = 15 ) THEN -- �N�Ԍv
          lv_file_value := lv_file_value || cv_comma || ln_yearly;
        ELSE
          -- ���ʃf�[�^��index��5������̃f�[�^���ŏ��ɂȂ�ׁA2��ڂ̃��[�v��蔭�Ԃ���
          ln_index_cunt := ln_index_cunt + 1;
          -- �O���W�v
          ln_half_term  := ln_half_term + i_month_data_ttype(ln_index_cunt);
          -- �N�ԏW�v
          ln_yearly     := ln_yearly + i_month_data_ttype(ln_index_cunt);
          -- ���ʃf�[�^��A��
          lv_file_value := lv_file_value || cv_comma || i_month_data_ttype(ln_index_cunt);
        END IF;
      END LOOP month_value_loop;
    END IF;
--
    -- ===============================
    -- �^����\�Z�ꗗ�\�f�[�^�o��
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT,
                    iv_message  => lv_file_value,  --�o�̓f�[�^
                    in_new_line => cn_number_0     -- ���s��
                  );
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_file_date;
--
  /**********************************************************************************
   * Procedure Name   : put_file_set
   * Description      : �o�̓f�[�^�̕ҏW����(A-7 �` A-9)
   ***********************************************************************************/
  PROCEDURE put_file_set(
    ov_errbuf                   OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_put_code                 IN  VARCHAR2 DEFAULT NULL, -- �o�̓t���O(1:���ׁA2:���_�v)
    iv_back_base_code           IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h(�O��l�̑ޔ�)
    iv_base_code                IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h
    iv_base_name                IN  VARCHAR2 DEFAULT NULL, -- ���_��
    iv_item_code                IN  VARCHAR2 DEFAULT NULL, -- ���i�R�[�h
    iv_item_short_name          IN  VARCHAR2 DEFAULT NULL, -- ���i��(����)
    i_budget_qty_tyype          IN  number_tbl,            -- �\�Z_����
    i_budget_amt_tyype          IN  number_tbl,            -- �\�Z_���z
    i_result_syatate_qty_tyype  IN  number_tbl,            -- ����(�ԗ�)_����
    i_result_syatate_amt_tyype  IN  number_tbl,            -- ����(�ԗ�)_���z
    i_result_koguchi_qty_tyype  IN  number_tbl,            -- ����(����)_����
    i_result_koguchi_amt_tyype  IN  number_tbl,            -- ����(����)_���z
    i_sum_result_qty_tyype      IN  number_tbl,            -- ���ьv_����
    i_sum_result_qmt_tyype      IN  number_tbl,            -- ���ьv_���z
    i_sum_syatate_amt_tyype     IN  number_tbl,            -- ���_�v_�ԗ����z
    i_sum_koguchi_amt_tyype     IN  number_tbl,            -- ���_�v_�������z
    i_sum_budget_amt_tyype      IN  number_tbl,            -- ���_�v_�\�Z���z
    i_sum_result_amt_tyype      IN  number_tbl,            -- ���_�v_���ы��z
    i_sum_diff_amt_tyype        IN  number_tbl)            -- ���_�v_���z���z
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(12) := 'put_file_set'; -- �v���O������
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_target_cnt NUMBER         DEFAULT 0;     -- �N�C�b�N�R�[�h�f�[�^�擾����
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�J�[�\�� ***
    -- ���o���擾�J�[�\��
    CURSOR put_value_cur
    IS
      SELECT attribute1 AS put_val
      FROM   xxcok_lookups_v
      WHERE  lookup_type                              = cv_lookup_type_put_val
      AND    NVL( start_date_active,gd_process_date ) <= gd_process_date  -- �K�p�J�n��
      AND    NVL( end_date_active,gd_process_date )   >= gd_process_date  -- �K�p�I����
      ORDER BY TO_NUMBER(lookup_code)
    ;
    TYPE put_value_ttype IS TABLE OF put_value_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    put_value_tab put_value_ttype;
--
    -- *** ���[�J���ϐ� ***
    lb_retcode  BOOLEAN      DEFAULT TRUE;  -- ���b�Z�[�W�o�͊֐��߂�l
    -- *** ��O ***
    put_data_expt            EXCEPTION;     -- �v���o�̓G���[
    no_data_expt             EXCEPTION;      -- �f�[�^�擾�G���[
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    OPEN  put_value_cur;
    FETCH put_value_cur BULK COLLECT INTO put_value_tab;
    CLOSE put_value_cur;
    -- ===============================================
    -- �Ώی����擾
    -- ===============================================
    ln_target_cnt := put_value_tab.COUNT;
    IF ( ln_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
    -- ===============================
    -- ���׏o��
    -- ===============================
    IF ( iv_put_code = cv_put_code_line ) THEN
      -- 1���ڂ܂��͋��_���ς������o�͂���(���o������)
      IF ( iv_back_base_code <> iv_base_code )
        OR ( gn_put_count = 0 ) THEN
        -- ���_���ڍs�o��
        put_file_date(
          ov_errbuf           => lv_errbuf,       -- �G���[�E���b�Z�[�W
          ov_retcode          => lv_retcode,      -- ���^�[���E�R�[�h
          ov_errmsg           => lv_errmsg,       -- ���[�U�[�E�G���[�E���b�Z�[�W
          iv_header_data      => put_value_tab(1).put_val
                                 || iv_base_code
                                 || cv_comma
                                 || iv_base_name, -- ���R�[�h�̃w�b�_��
          i_month_data_ttype  => g_default_value  -- ���ʂ̒l
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE put_data_expt;
        END IF;
        -- ���o���o��(�P��)
        put_file_date(
          ov_errbuf           => lv_errbuf,                -- �G���[�E���b�Z�[�W
          ov_retcode          => lv_retcode,               -- ���^�[���E�R�[�h
          ov_errmsg           => lv_errmsg,                -- ���[�U�[�E�G���[�E���b�Z�[�W
          iv_header_data      => put_value_tab(2).put_val, -- ���R�[�h�̃w�b�_��
          i_month_data_ttype  => g_default_value           -- ���ʂ̒l
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE put_data_expt;
        END IF;
        -- �s���o��
        put_file_date(
          ov_errbuf           => lv_errbuf,                -- �G���[�E���b�Z�[�W
          ov_retcode          => lv_retcode,               -- ���^�[���E�R�[�h
          ov_errmsg           => lv_errmsg,                -- ���[�U�[�E�G���[�E���b�Z�[�W
          iv_header_data      => put_value_tab(3).put_val, -- ���R�[�h�̃w�b�_��
          i_month_data_ttype  => g_default_value           -- ���ʂ̒l
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE put_data_expt;
        END IF;
      END IF;
      -- ����(�ԗ�) ���ʍs�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                   -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,                  -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                   -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => iv_item_code
                               || cv_comma
                               || iv_item_short_name
                               || put_value_tab(4).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_result_syatate_qty_tyype   -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ����(�ԗ�) ���z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                  -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,                 -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(5).put_val,   -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_result_syatate_amt_tyype  -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ����(����) ���ʍs�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                  -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,                 -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(6).put_val,   -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_result_koguchi_qty_tyype  -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ����(����) ���z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                  -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,                 -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(5).put_val,   -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_result_koguchi_amt_tyype  -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- �\�Z ���ʍs�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,               -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(7).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_budget_qty_tyype        -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- �\�Z ���z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,               -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(5).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_budget_amt_tyype        -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ���ьv ���ʍs�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,               -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(8).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_sum_result_qty_tyype    -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ���ьv ���z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,               -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(5).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_sum_result_qmt_tyype    -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
    END IF;
    -- ===============================
    -- ���_�v�o��
    -- ===============================
    IF ( iv_put_code = cv_put_code_sum ) THEN
      -- ���_�v_�ԗ����z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,               -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(9).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_sum_syatate_amt_tyype   -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ���_�v_�������z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                 -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,                -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                 -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(10).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_sum_koguchi_amt_tyype    -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ���_�v_�\�Z���z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                 -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,                -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                 -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(11).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_sum_budget_amt_tyype     -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ���_�v_���ы��z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                 -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,                -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                 -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(12).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_sum_result_amt_tyype     -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
      -- ���_�v_���z(�\-��)���z�s�o��
      put_file_date(
        ov_errbuf           => lv_errbuf,                 -- �G���[�E���b�Z�[�W
        ov_retcode          => lv_retcode,                -- ���^�[���E�R�[�h
        ov_errmsg           => lv_errmsg,                 -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_header_data      => put_value_tab(13).put_val, -- ���R�[�h�̃w�b�_��
        i_month_data_ttype  => i_sum_diff_amt_tyype       -- ���ʂ̒l
      );
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE put_data_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** �f�[�^�擾��O ***
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00015
                    , iv_token_name1  => cv_token_lookup_value_set
                    , iv_token_value1 => cv_lookup_type_put_val
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �v���o�͗�O ***
    WHEN put_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_10367
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_file_set;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : ���_���o����(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf           OUT     VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT     VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT     VARCHAR2, -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    o_budget_ttype      OUT     base_tbl) -- ���_���
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'get_base_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    ln_base_index     NUMBER       DEFAULT 1;    -- ���_���p�C���f�b�N�X
    lv_resp_nm        VARCHAR2(40) DEFAULT NULL; -- �E�Ӗ�
    ln_admin_resp_id  NUMBER       DEFAULT NULL; -- ��Ǖ����S����
    ln_main_resp_id   NUMBER       DEFAULT NULL; -- �{������S����
    ln_sales_resp_id  NUMBER       DEFAULT NULL; -- ���_����S����
    lv_belong_base_cd VARCHAR2(4)  DEFAULT NULL; -- �������_
    lb_retcode        BOOLEAN      DEFAULT TRUE; -- ���b�Z�[�W�o�͊֐��߂�l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���_���J�[�\��
    CURSOR base_name_cur(
      iv_base_code IN VARCHAR2) -- ���_�R�[�h
    IS
      SELECT account_name AS base_name
      FROM   hz_cust_accounts
      WHERE  account_number      = iv_base_code
      AND    customer_class_code = cv_cust_cd_base -- ���_
    ;
    -- ���_���J�[�\�����R�[�h�^
    base_name_rec base_name_cur%ROWTYPE;
    -- �S���_�J�[�\��
    CURSOR all_base_cur
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- ���_�R�[�h
              hca.account_name            AS base_name  -- ���_��
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl ffvv,
              hz_cust_accounts hca
      WHERE   ffvnh.parent_flex_value IN
          (SELECT  ffvnh.child_flex_value_high
          FROM    fnd_flex_value_norm_hierarchy ffvnh,
                  fnd_flex_values_vl ffvv
          WHERE   ffvnh.parent_flex_value IN
              (SELECT  ffvnh.child_flex_value_high
              FROM    fnd_flex_value_norm_hierarchy ffvnh,
                      fnd_flex_values_vl ffvv
              WHERE   ffvnh.parent_flex_value IN
                  (SELECT  ffvnh.child_flex_value_high
                  FROM    fnd_flex_value_norm_hierarchy ffvnh,
                          fnd_flex_values_vl ffvv
                  WHERE   ffvnh.parent_flex_value IN
                      (SELECT  ffvnh.child_flex_value_high
                      FROM    fnd_flex_value_norm_hierarchy ffvnh,
                              fnd_flex_values_vl ffvv
                      WHERE   ffvnh.parent_flex_value = gv_head_office_code -- �{�Е���R�[�h
                      AND     ffvv.value_category         = cv_flex_st_name_department
                      AND     ffvnh.child_flex_value_high = ffvv.flex_value
                      )
                  AND     ffvv.value_category         = cv_flex_st_name_department
                  AND     ffvnh.child_flex_value_high = ffvv.flex_value
                  )
              AND     ffvv.value_category         = cv_flex_st_name_department
              AND     ffvnh.child_flex_value_high = ffvv.flex_value
              )
          AND     ffvv.value_category         = cv_flex_st_name_department
          AND     ffvnh.child_flex_value_high = ffvv.flex_value
          )
      AND     ffvv.value_category         = cv_flex_st_name_department
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- ���_
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- �S���_�J�[�\�����R�[�h�^
    all_base_rec all_base_cur%ROWTYPE;
    -- �z�����_�J�[�\��
    CURSOR child_base_cur(
      iv_base_code IN VARCHAR2) -- ���_�R�[�h
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- ���_�R�[�h
              hca.account_name            AS base_name  -- ���_��
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl ffvv,
              hz_cust_accounts hca
      WHERE   ffvnh.parent_flex_value = (SELECT ffvnh.parent_flex_value
                                         FROM   fnd_flex_value_sets ffvs,
                                                fnd_flex_value_norm_hierarchy ffvnh
                                         WHERE  ffvs.flex_value_set_name    = cv_flex_st_name_department
                                         AND    ffvs.flex_value_set_id      = ffvnh.flex_value_set_id
                                         AND    ffvnh.child_flex_value_high = iv_base_code -- �������_�R�[�h
                                        )
      AND     ffvv.value_category         = cv_flex_st_name_department
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- ���_
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- �z�����_�J�[�\�����R�[�h�^
    child_base_rec child_base_cur%ROWTYPE;
--
    -- *** ���[�J���E��O ***
    no_resp_id_expt   EXCEPTION;
    no_resp_data_expt EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ���_���̎擾
    -- ===============================
    -- ���̓p�����[�^�̋��_�����擾
    IF (gv_base_code IS NOT NULL) THEN
      <<base_name_loop>>
      FOR base_name_rec IN base_name_cur( gv_base_code ) LOOP
        o_budget_ttype(ln_base_index).base_code := gv_base_code;            -- ���_�R�[�h
        o_budget_ttype(ln_base_index).base_name := base_name_rec.base_name; -- ���_��
      END LOOP base_name_loop;
      -- ���_��񂪎擾�ł��Ȃ������ꍇ
      IF ( o_budget_ttype(1).base_name IS NULL ) THEN
        -- �G���[����
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_10182,
                       iv_token_name1  => cv_resp_name,
                       iv_token_value1 => cv_resp_name_val,
                       iv_token_name2  => cv_location_code,
                       iv_token_value2 => gv_base_code
                     );
        lv_errbuf := lv_errmsg;
--
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE no_resp_data_expt;
      END IF;
    -- �E�ӕʂɋ��_���擾
    ELSE
      -- ===============================
      -- �E�ӕʂ̋��_�擾����
      -- ===============================
      ----------------------------
      -- ��Ǖ����S���ҐE�ӂ̏ꍇ
      ----------------------------
      IF ( gv_resp_type = cv_resp_type_0 ) THEN
        -- �S���_�R�[�h�Ƌ��_�����擾
        <<all_base_loop>>
        FOR all_base_rec IN all_base_cur LOOP
          o_budget_ttype(ln_base_index).base_code := all_base_rec.base_code; -- ���_�R�[�h
          o_budget_ttype(ln_base_index).base_name := all_base_rec.base_name; -- ���_��
          ln_base_index := ln_base_index + 1;
        END LOOP all_base_loop;
      ----------------------------
      -- �{������S���ҐE�ӂ̏ꍇ
      ----------------------------
      ELSE
        -- �������_�擾
        lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( SYSDATE , cn_created_by );
        IF ( lv_belong_base_cd IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcok,
                         iv_name         => cv_msg_xxcok1_00012,
                         iv_token_name1  => cv_user_id,
                         iv_token_value1 => cn_created_by
                       );
--
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which    => FND_FILE.LOG
                          , iv_message  => lv_errmsg
                          , in_new_line => cn_number_0
                          );
            RAISE no_resp_data_expt;
        END IF;
--
        IF ( gv_resp_type = cv_resp_type_1 ) THEN
          -- ���O�C�����[�U�[�̎����_���z���̋��_���擾
          <<child_base_loop>>
          FOR child_base_rec IN child_base_cur( lv_belong_base_cd ) LOOP
            o_budget_ttype(ln_base_index).base_code := child_base_rec.base_code; -- ���_�R�[�h
            o_budget_ttype(ln_base_index).base_name := child_base_rec.base_name; -- ���_��
            ln_base_index := ln_base_index + 1;
          END LOOP child_base_loop;
        ----------------------------
        -- ���_����_�S���ҐE�ӂ̏ꍇ
        ----------------------------
        ELSE
          -- �����_���擾
          o_budget_ttype(ln_base_index).base_code   := lv_belong_base_cd;        -- ���_�R�[�h
          <<resp_loop>>
          FOR base_name_rec IN base_name_cur( lv_belong_base_cd ) LOOP
            o_budget_ttype(ln_base_index).base_name := base_name_rec.base_name;  -- ���_��
          END LOOP resp_loop;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    --*** �E��ID�擾�G���[ ***
    WHEN no_resp_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_00052,
                      iv_token_name1  => cv_resp_name,
                      iv_token_value1 => lv_resp_nm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���_�擾��O ***
    WHEN no_resp_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_base_data;
--
  /**********************************************************************************
   * Procedure Name   : get_put_file_data
   * Description      : �v���o�͑Ώۃf�[�^�̎擾�E�o�͏���(A-2 �` A-9)
   ***********************************************************************************/
  PROCEDURE get_put_file_data(
    ov_errbuf     OUT  VARCHAR2, -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT  VARCHAR2, -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT  VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(17) := 'get_put_file_data'; -- �v���O������
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_budget_year              xxcok_dlv_cost_calc_budget.budget_year%TYPE         DEFAULT NULL;
    lt_base_code                xxcok_dlv_cost_calc_budget.base_code%TYPE           DEFAULT NULL;
    lt_cs_qty                   xxcok_dlv_cost_calc_budget.cs_qty%TYPE              DEFAULT NULL;
    lt_budget_amt               xxcok_dlv_cost_calc_budget.dlv_cost_budget_amt%TYPE DEFAULT NULL;
    lv_line_put_flg             VARCHAR2(1)    DEFAULT NULL; -- ���׏o�̓t���O
    l_base_ttype                base_tbl;
    l_budget_ttype              budget_tbl;
    l_base_loop_index           NUMBER         DEFAULT NULL;
    ln_index                    NUMBER         DEFAULT NULL;
    -- �W�v�p�ϐ�
    ln_sum_result_qty           NUMBER;         -- ���ьv_����
    ln_sum_result_qmt           NUMBER;         -- ���ьv_���z
    ln_sum_syatate_amt          NUMBER;         -- ���_�v_�ԗ����z
    ln_sum_koguchi_amt          NUMBER;         -- ���_�v_�������z
    ln_sum_budget_amt           NUMBER;         -- ���_�v_�\�Z���z
    ln_sum_result_amt           NUMBER;         -- ���_�v_���ы��z
    ln_sum_diff_amt             NUMBER;         -- ���_�v_���z���z
    l_budget_qty_tyype          number_tbl;     -- �\�Z_����
    l_budget_amt_tyype          number_tbl;     -- �\�Z_���z
    l_result_syatate_qty_tyype  number_tbl;     -- ����(�ԗ�)_����
    l_result_syatate_amt_tyype  number_tbl;     -- ����(�ԗ�)_���z
    l_result_koguchi_qty_tyype  number_tbl;     -- ����(����)_����
    l_result_koguchi_amt_tyype  number_tbl;     -- ����(����)_���z
    l_sum_result_qty_tyype      number_tbl;     -- ���ьv_����
    l_sum_result_qmt_tyype      number_tbl;     -- ���ьv_���z
    l_sum_syatate_amt_tyype     number_tbl;     -- ���_�v_�ԗ����z
    l_sum_koguchi_amt_tyype     number_tbl;     -- ���_�v_�������z
    l_sum_budget_amt_tyype      number_tbl;     -- ���_�v_�\�Z���z
    l_sum_result_amt_tyype      number_tbl;     -- ���_�v_���ы��z
    l_sum_diff_amt_tyype        number_tbl;     -- ���_�v_���z���z
    l_default_value             number_tbl;     -- ���ʂ̃f�t�H���g�l
    lb_retcode  BOOLEAN         DEFAULT TRUE;   -- ���b�Z�[�W�o�͊֐��߂�l
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �^����\�Z�J�[�\��
    CURSOR budget_data_cur(
      iv_base_code IN VARCHAR2)
    IS
      SELECT xdccb.budget_year    AS budget_year,      -- �\�Z�N�x
             xdccb.base_code      AS base_code,        -- ���_�R�[�h
             xdccb.item_code      AS item_code,        -- ���i�R�[�h
             item.item_short_name AS item_short_name   -- ���i��(����)
      FROM   xxcok_dlv_cost_calc_budget xdccb,         -- �^����\�Z�e�[�u��
            (SELECT iimb.item_no,                      -- �i�ڃR�[�h
                    ximb.item_short_name,              -- ����
                    xsibh.policy_group                 -- ����Q�R�[�h
             FROM   ic_item_mst_b              iimb,   -- opm�i�ڃ}�X�^
                    xxcmn_item_mst_b           ximb,   -- opm�i�ڃA�h�I���}�X�^
                    mtl_system_items_b         msib,   -- �i�ڃ}�X�^
                    xxcmm_system_items_b_hst   xsibh   -- �c�������i�ڃA�h�I���}�X�^�i�ύX�����j
             WHERE  ximb.item_id          = iimb.item_id
             AND    iimb.item_no          = msib.segment1
             AND    msib.organization_id  = gn_org_id
             AND    xsibh.item_id         = iimb.item_id
             AND    xsibh.item_code       = msib.segment1
             AND    xsibh.apply_flag      = cv_flag_y
             AND    xsibh.policy_group IS NOT NULL
-- 2009/09/03 Ver.1.4 [��Q0001257] SCS S.Moriyama ADD START
             AND    gd_process_date BETWEEN ximb.start_date_active
                                    AND NVL ( ximb.end_date_active , gd_process_date )
-- 2009/09/03 Ver.1.4 [��Q0001257] SCS S.Moriyama ADD END
             AND    (xsibh.apply_date,xsibh.item_id) IN (SELECT MAX( xsibh.apply_date ), -- �K�p��
                                                                item_id                  -- �i��ID
                                                         FROM   xxcmm_system_items_b_hst xsibh
                                                         WHERE  xsibh.policy_group IS NOT NULL
                                                         AND    xsibh.apply_flag   = cv_flag_y
                                                         GROUP BY item_id
                                                        )
            )item
      WHERE    xdccb.budget_year = gv_budget_year -- ���̓p�����[�^�̗\�Z�N�x
      AND      xdccb.base_code   = iv_base_code
      AND      xdccb.item_code   = item.item_no(+)
      GROUP BY xdccb.budget_year,
               xdccb.base_code,
               xdccb.item_code,
               item.item_short_name,
               SUBSTRB( item.policy_group,1,3 )
      ORDER BY SUBSTRB( item.policy_group,1,3 ),
               xdccb.item_code
    ;
    -- �^����\�Z�J�[�\�����R�[�h�^
    budget_data_rec budget_data_cur%ROWTYPE;
    -- �\�Z���J�[�\��
    CURSOR budget_month_cur
    IS
      SELECT ffv.flex_value            AS month,   -- ��
             TO_NUMBER(ffv.attribute1) AS order_no -- ������
      FROM   fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv
      WHERE  ffvs.flex_value_set_name = cv_flex_st_name_bd_month  --'XXCOK1_BUDGET_MONTH_ORDER'
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffv.enabled_flag         = cv_flag_y
      ORDER BY TO_NUMBER(ffv.attribute1)
    ;
    -- �^����\�Z�J�[�\�����R�[�h�^
    budget_month_rec budget_month_cur%ROWTYPE;
    -- �^������уJ�[�\��
    CURSOR result_info_cur(
      i_budget_year IN xxcok_dlv_cost_calc_budget.budget_year%TYPE, -- �\�Z�N�x
      i_month       IN VARCHAR2,                                    -- ��
      i_base_code   IN VARCHAR2,                                    -- ���_�R�[�h
      i_item_code   IN xxcok_dlv_cost_calc_budget.item_code%TYPE)   -- ���i�R�[�h
    IS
      SELECT small_amt_type, -- �����敪
             sum_cs_qty,     -- ���ѐ���
             sum_amt         -- ���ы��z
      FROM   xxcok_dlv_cost_result_sum
      WHERE  target_year  = i_budget_year
      AND    target_month = TO_CHAR(i_month,'FM00')
      AND    base_code    = i_base_code
      AND    item_code    = i_item_code
      ORDER BY small_amt_type
    ;
    -- �^������уJ�[�\�����R�[�h�^
    result_info_rec result_info_cur%ROWTYPE;
    -- ��O
    no_data_expt             EXCEPTION; -- ���������G���[
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ���_�f�[�^�̎擾(A-2.)
    -- ===============================
    get_base_data(
      ov_errbuf      => lv_errbuf,    -- �G���[�E���b�Z�[�W
      ov_retcode     => lv_retcode,   -- ���^�[���E�R�[�h
      ov_errmsg      => lv_errmsg,    -- ���[�U�[�E�G���[�E���b�Z�[�W
      o_budget_ttype => l_base_ttype  -- ���_���
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- �擾�ΏۂƂȂ�N�x��ݒ肷��
    gv_target_year := gv_budget_year;
--
    l_base_loop_index := l_base_ttype.FIRST;
    -- �擾�������_�̐������[�v���܂�
    <<base_loop>>
    WHILE ( l_base_loop_index IS NOT NULL ) LOOP
      -- ���_���ς������A���_�v�s���o�͂���
      IF ( l_base_ttype(l_base_loop_index).base_code <> lt_base_code )
        AND ( lv_line_put_flg = cv_flag_y )
        AND ( l_base_loop_index <> 1 ) THEN
        -- ===============================
        -- ���_�v���ڊi�[�E�v���o�͏���(A-7)
        -- ===============================
        put_file_set(
          ov_errbuf                   => lv_errbuf,               -- �G���[�E���b�Z�[�W
          ov_retcode                  => lv_retcode,              -- ���^�[���E�R�[�h
          ov_errmsg                   => lv_errmsg,               -- ���[�U�[�E�G���[�E���b�Z�[�W
          iv_put_code                 => cv_put_code_sum,         -- �o�̓t���O(1:���ׁA2:���_�v)
          i_budget_qty_tyype          => l_default_value,         -- �\�Z_����
          i_budget_amt_tyype          => l_default_value,         -- �\�Z_���z
          i_result_syatate_qty_tyype  => l_default_value,         -- ����(�ԗ�)_����
          i_result_syatate_amt_tyype  => l_default_value,         -- ����(�ԗ�)_���z
          i_result_koguchi_qty_tyype  => l_default_value,         -- ����(����)_����
          i_result_koguchi_amt_tyype  => l_default_value,         -- ����(����)_���z
          i_sum_result_qty_tyype      => l_default_value,         -- ���ьv_����
          i_sum_result_qmt_tyype      => l_default_value,         -- ���ьv_���z
          i_sum_syatate_amt_tyype     => l_sum_syatate_amt_tyype, -- ���_�v_�ԗ����z
          i_sum_koguchi_amt_tyype     => l_sum_koguchi_amt_tyype, -- ���_�v_�������z
          i_sum_budget_amt_tyype      => l_sum_budget_amt_tyype,  -- ���_�v_�\�Z���z
          i_sum_result_amt_tyype      => l_sum_result_amt_tyype,  -- ���_�v_���ы��z
          i_sum_diff_amt_tyype        => l_sum_diff_amt_tyype     -- ���_�v_���z���z
        );
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      -- ������
      lv_line_put_flg     := NULL;      -- ���׏o�̓t���O
      ln_sum_syatate_amt  := 0;         -- ���_�v_�ԗ����z
      ln_sum_koguchi_amt  := 0;         -- ���_�v_�������z
      ln_sum_budget_amt   := 0;         -- ���_�v_�\�Z���z
      ln_sum_result_amt   := 0;         -- ���_�v_���ы��z
      ln_sum_diff_amt     := 0;         -- ���_�v_���z���z
      l_sum_syatate_amt_tyype.DELETE;   -- ���_�v_�ԗ����z
      l_sum_koguchi_amt_tyype.DELETE;   -- ���_�v_�������z
      l_sum_budget_amt_tyype.DELETE;    -- ���_�v_�\�Z���z
      l_sum_result_amt_tyype.DELETE;    -- ���_�v_���ы��z
      l_sum_diff_amt_tyype.DELETE;      -- ���_�v_���z���z
      -- ===============================
      -- �^����\�Z�f�[�^�̎擾(A-3.)
      -- ===============================
      <<budget_loop>>
      FOR budget_data_rec IN budget_data_cur( l_base_ttype(l_base_loop_index).base_code ) LOOP
        -- ���i��(����)���擾�ł��Ȃ������ꍇ
        IF ( budget_data_rec.item_short_name IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcok,
                         iv_name         => cv_msg_xxcok1_10183,
                         iv_token_name1  => cv_item_code,
                         iv_token_value1 => budget_data_rec.item_code
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
        END IF;
        -- �Ώی����J�E���g
        gn_target_cnt := gn_target_cnt + 1;
        -- ===============================
        -- �\�Z���̎擾(A-4.)
        -- ===============================
        --������
        ln_index := NULL;
        -- ���ʃ��[�v
        <<budget_month_loop>>
        FOR budget_month_rec IN budget_month_cur LOOP
          -- �擾�������������C���f�b�N�X�Ƃ��Ďg�p����
          ln_index := budget_month_rec.order_no;
          -- ������
          lt_cs_qty     := 0;
          lt_budget_amt := 0;
          BEGIN
            -- ���ʂ̉^����\�Z���ʁE���z�̒l���擾����
            SELECT NVL(cs_qty,0), -- �\�Z����
                   NVL(dlv_cost_budget_amt,0)      -- �\�Z���z
            INTO   lt_cs_qty,
                   lt_budget_amt
            FROM   xxcok_dlv_cost_calc_budget
            WHERE  budget_year  = budget_data_rec.budget_year
            AND    base_code    = l_base_ttype(l_base_loop_index).base_code
            AND    item_code    = budget_data_rec.item_code
            AND    target_month = TO_CHAR(budget_month_rec.month,'FM00')
            ;
          EXCEPTION
            --*** �f�[�^�擾�G���[ ***
            WHEN NO_DATA_FOUND THEN
              -- �Ώی��̃f�[�^���Ȃ��ꍇ�A���z�E���ʂ�0��ݒ肷��
              lt_cs_qty     := 0;
              lt_budget_amt := 0;
          END;
          -- ���_�R�[�h�E���_���y�сA�\�Z�f�[�^�̏��i�R�[�h�E���i��(����)�E���E���ʁE���z��PL/SQL�\�ɒl���Z�b�g���܂��B
          l_budget_ttype(ln_index).base_code        := l_base_ttype(l_base_loop_index).base_code; -- ���_�R�[�h
          l_budget_ttype(ln_index).base_name        := l_base_ttype(l_base_loop_index).base_name; -- ���_��
          l_budget_ttype(ln_index).budget_item_code := budget_data_rec.item_code;                 -- �\�Z_���i�R�[�h
          l_budget_ttype(ln_index).budget_item_name := budget_data_rec.item_short_name;           -- �\�Z_���i��(����)
          l_budget_ttype(ln_index).budget_month     := TO_CHAR(budget_month_rec.month, 'FM00');   -- �\�Z_��
          l_budget_qty_tyype(ln_index)              := lt_cs_qty;                                 -- �\�Z_����
--�y2009/05/15 A.Yano Ver.1.3 START�z------------------------------------------------------
--          l_budget_amt_tyype(ln_index)              := lt_budget_amt;                             -- �\�Z_���z
          l_budget_amt_tyype(ln_index)              := ROUND( lt_budget_amt, -3 ) / 1000;         -- �\�Z_���z
--�y2009/05/15 A.Yano Ver.1.3 END  �z------------------------------------------------------
          -- ���ѐ��ʁE���z�f�t�H���g�ݒ�
          l_result_syatate_qty_tyype(ln_index) := 0; -- ����(�ԗ�)_����
          l_result_syatate_amt_tyype(ln_index) := 0; -- ����(�ԗ�)_���z
          l_result_koguchi_qty_tyype(ln_index) := 0; -- ����(����)_����
          l_result_koguchi_amt_tyype(ln_index) := 0; -- ����(����)_���z
          -- ���ьv���ڂ̏�����
          ln_sum_result_qty := 0;
          ln_sum_result_qmt := 0;
          -- ===============================
          -- �^������я��擾����(A-5.)
          -- ===============================
          -- 5������12���́A�\�Z�N�x��Ώ۔N�x�ɂ�
          -- 1������4���́A�\�Z�N�x�̗��N��Ώ۔N�x�Ƃ���
          IF TO_CHAR(budget_month_rec.month,'FM00') = cv_month01 THEN
            gv_target_year := gv_budget_year + 1;
          ELSIF TO_CHAR(budget_month_rec.month,'FM00') = cv_month05 THEN
            gv_target_year := gv_budget_year;
          END IF;
--
          <<result_info_loop>>
          FOR result_info_rec IN result_info_cur(
            gv_target_year,                            -- �\�Z�N�x
            budget_month_rec.month,                    -- ��
            l_base_ttype(l_base_loop_index).base_code, -- ���_�R�[�h
            budget_data_rec.item_code                  -- ���i�R�[�h
            ) LOOP
            -- ===============================
            -- ���ѐ��ʁE���ы��z�i�[����(A-6)
            -- ===============================
            -- �����敪�ʂɐ��ʁE���z��ݒ�
            IF ( result_info_rec.small_amt_type = cv_kbn_syatate ) THEN
              l_result_syatate_qty_tyype(ln_index) := result_info_rec.sum_cs_qty;  -- ����(�ԗ�)_����
--�y2009/05/15 A.Yano Ver.1.3 START�z------------------------------------------------------
--              l_result_syatate_amt_tyype(ln_index) := result_info_rec.sum_amt;     -- ����(�ԗ�)_���z
              l_result_syatate_amt_tyype(ln_index) := ROUND( result_info_rec.sum_amt, -3 ) / 1000;     -- ����(�ԗ�)_���z
--�y2009/05/15 A.Yano Ver.1.3 END  �z------------------------------------------------------
              -- ���ьv���ڂ̏W�v
              ln_sum_result_qty := ln_sum_result_qty + result_info_rec.sum_cs_qty; -- ���ьv_����
--�y2009/05/15 A.Yano Ver.1.3 START�z------------------------------------------------------
--              ln_sum_result_qmt := ln_sum_result_qmt + result_info_rec.sum_amt;    -- ���ьv_���z
              ln_sum_result_qmt := ln_sum_result_qmt + ROUND( result_info_rec.sum_amt, -3 ) / 1000;    -- ���ьv_���z
--�y2009/05/15 A.Yano Ver.1.3 END  �z------------------------------------------------------
            ELSIF ( result_info_rec.small_amt_type = cv_kbn_koguchi ) THEN
              l_result_koguchi_qty_tyype(ln_index) := result_info_rec.sum_cs_qty;  -- ����(����)_����
--�y2009/05/15 A.Yano Ver.1.3 START�z------------------------------------------------------
--              l_result_koguchi_amt_tyype(ln_index) := result_info_rec.sum_amt;     -- ����(����)_���z
              l_result_koguchi_amt_tyype(ln_index) := ROUND( result_info_rec.sum_amt, -3 ) / 1000;     -- ����(����)_���z
--�y2009/05/15 A.Yano Ver.1.3 END  �z------------------------------------------------------
              -- ���ьv���ڂ̏W�v
              ln_sum_result_qty := ln_sum_result_qty + result_info_rec.sum_cs_qty; -- ���ьv_����
--�y2009/05/15 A.Yano Ver.1.3 START�z------------------------------------------------------
--              ln_sum_result_qmt := ln_sum_result_qmt + result_info_rec.sum_amt;    -- ���ьv_���z
              ln_sum_result_qmt := ln_sum_result_qmt + ROUND( result_info_rec.sum_amt, -3 ) / 1000;    -- ���ьv_���z
--�y2009/05/15 A.Yano Ver.1.3 END  �z------------------------------------------------------
            ELSE
              -- ���ьv���ڂ̏W�v
              ln_sum_result_qty := ln_sum_result_qty + 0;
              ln_sum_result_qmt := ln_sum_result_qmt + 0;
            END IF;
          END LOOP;
          -- ���ьv���ڂ̏W�v�l���i�[
          l_sum_result_qty_tyype(ln_index) := ln_sum_result_qty; -- ���ьv_����
          l_sum_result_qmt_tyype(ln_index) := ln_sum_result_qmt; -- ���ьv_���z
          -- ���_�v���ڂ̏W�v
          ln_sum_syatate_amt := l_result_syatate_amt_tyype(ln_index);     -- ���_�v_�ԗ����z
          ln_sum_koguchi_amt := l_result_koguchi_amt_tyype(ln_index);     -- ���_�v_�������z
          ln_sum_budget_amt  := l_budget_amt_tyype(ln_index);             -- ���_�v_�\�Z���z
          ln_sum_result_amt  := l_sum_result_qmt_tyype(ln_index);         -- ���_�v_���ы��z
          ln_sum_diff_amt    := ln_sum_budget_amt - ln_sum_result_amt;    -- ���_�v_���z���z
          -- ���_�v���ڂ̏W�v���i�[
          -- ��x�����׍s���o�͂��Ă��Ȃ��܂��́A���_���ς�����ꍇ�͎擾�����l���i�[
          IF ( gn_put_count = 0 )
            OR ( l_base_ttype(l_base_loop_index).base_code <> lt_base_code ) THEN
            -- ���_�v_�ԗ����z
            l_sum_syatate_amt_tyype(ln_index) := ln_sum_syatate_amt;
            -- ���_�v_�������z
            l_sum_koguchi_amt_tyype(ln_index) := ln_sum_koguchi_amt;
            -- ���_�v_�\�Z���z
            l_sum_budget_amt_tyype(ln_index)  := ln_sum_budget_amt;
            -- ���_�v_���ы��z
            l_sum_result_amt_tyype(ln_index)  := ln_sum_result_amt;
            -- ���_�v_���z���z
            l_sum_diff_amt_tyype(ln_index)    := ln_sum_diff_amt;
          ELSE
            -- ���_�v_�ԗ����z
            l_sum_syatate_amt_tyype(ln_index) := NVL(l_sum_syatate_amt_tyype(ln_index),0) + ln_sum_syatate_amt;
            -- ���_�v_�������z
            l_sum_koguchi_amt_tyype(ln_index) := NVL(l_sum_koguchi_amt_tyype(ln_index),0) + ln_sum_koguchi_amt;
            -- ���_�v_�\�Z���z
            l_sum_budget_amt_tyype(ln_index)  := NVL(l_sum_budget_amt_tyype(ln_index),0) + ln_sum_budget_amt;
            -- ���_�v_���ы��z
            l_sum_result_amt_tyype(ln_index)  := NVL(l_sum_result_amt_tyype(ln_index),0) + ln_sum_result_amt;
            -- ���_�v_���z���z
            l_sum_diff_amt_tyype(ln_index)    := NVL(l_sum_diff_amt_tyype(ln_index),0) + ln_sum_diff_amt;
          END IF;
        END LOOP budget_month_loop;
--
        IF ( ln_index IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcok,
                         iv_name         => cv_msg_xxcok1_00014,
                         iv_token_name1  => cv_flex_value,
                         iv_token_value1 => cv_flex_st_name_bd_month
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
        ELSE
          -- ===============================
          -- �^����\�Z�ꗗ�\�̗v���o�͏���(A-8)
          -- ===============================
          put_file_set(
            ov_errbuf                   => lv_errbuf,                          -- �G���[�E���b�Z�[�W
            ov_retcode                  => lv_retcode,                         -- ���^�[���E�R�[�h
            ov_errmsg                   => lv_errmsg,                          -- ���[�U�[�E�G���[�E���b�Z�[�W
            iv_put_code                 => cv_put_code_line,                   -- �o�̓t���O(1:���ׁA2:���_�v)
            iv_back_base_code           => lt_base_code,                       -- ���_�R�[�h(�O��l�̑ޔ�)
            iv_base_code                => l_budget_ttype(1).base_code,        -- ���_�R�[�h
            iv_base_name                => l_budget_ttype(1).base_name,        -- ���_��
            iv_item_code                => l_budget_ttype(1).budget_item_code, -- ���i�R�[�h
            iv_item_short_name          => l_budget_ttype(1).budget_item_name, -- ���i��(����)
            i_budget_qty_tyype          => l_budget_qty_tyype,                 -- �\�Z_����
            i_budget_amt_tyype          => l_budget_amt_tyype,                 -- �\�Z_���z
            i_result_syatate_qty_tyype  => l_result_syatate_qty_tyype,         -- ����(�ԗ�)_����
            i_result_syatate_amt_tyype  => l_result_syatate_amt_tyype,         -- ����(�ԗ�)_���z
            i_result_koguchi_qty_tyype  => l_result_koguchi_qty_tyype,         -- ����(����)_����
            i_result_koguchi_amt_tyype  => l_result_koguchi_amt_tyype,         -- ����(����)_���z
            i_sum_result_qty_tyype      => l_sum_result_qty_tyype,             -- ���ьv_����
            i_sum_result_qmt_tyype      => l_sum_result_qmt_tyype,             -- ���ьv_���z
            i_sum_syatate_amt_tyype     => l_default_value,                    -- ���_�v_�ԗ����z
            i_sum_koguchi_amt_tyype     => l_default_value,                    -- ���_�v_�������z
            i_sum_budget_amt_tyype      => l_default_value,                    -- ���_�v_�\�Z���z
            i_sum_result_amt_tyype      => l_default_value,                    -- ���_�v_���ы��z
            i_sum_diff_amt_tyype        => l_default_value                     -- ���_�v_���z���z
          );
        END IF;
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ���׏o�͌������J�E���g
        gn_put_count := gn_put_count + 1;
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
        -- ������
        lv_line_put_flg := cv_flag_y;  -- ���׏o�̓t���O
        lt_base_code    := l_budget_ttype(1).base_code;
        l_budget_ttype.DELETE;
      END LOOP budget_loop;
      -- ���̃C���f�b�N�X��ԍ����擾
      l_base_loop_index := l_base_ttype.NEXT( l_base_loop_index );
    END LOOP base_loop;
--
    -- ���׏o�͂����ꍇ�A���_�v�s���o�͂���
    IF ( gn_put_count > 0 )
      AND ( lv_line_put_flg = cv_flag_y ) THEN
      -- ===============================
      -- �ŏI���_�v�s�̗v���o�͏���(A-9)
      -- ===============================
      put_file_set(
        ov_errbuf                   => lv_errbuf,               -- �G���[�E���b�Z�[�W
        ov_retcode                  => lv_retcode,              -- ���^�[���E�R�[�h
        ov_errmsg                   => lv_errmsg,               -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_put_code                 => cv_put_code_sum,         -- �o�̓t���O(1:���ׁA2:���_�v)
        i_budget_qty_tyype          => l_default_value,         -- �\�Z_����
        i_budget_amt_tyype          => l_default_value,         -- �\�Z_���z
        i_result_syatate_qty_tyype  => l_default_value,         -- ����(�ԗ�)_����
        i_result_syatate_amt_tyype  => l_default_value,         -- ����(�ԗ�)_���z
        i_result_koguchi_qty_tyype  => l_default_value,         -- ����(����)_����
        i_result_koguchi_amt_tyype  => l_default_value,         -- ����(����)_���z
        i_sum_result_qty_tyype      => l_default_value,         -- ���ьv_����
        i_sum_result_qmt_tyype      => l_default_value,         -- ���ьv_���z
        i_sum_syatate_amt_tyype     => l_sum_syatate_amt_tyype, -- ���_�v_�ԗ����z
        i_sum_koguchi_amt_tyype     => l_sum_koguchi_amt_tyype, -- ���_�v_�������z
        i_sum_budget_amt_tyype      => l_sum_budget_amt_tyype,  -- ���_�v_�\�Z���z
        i_sum_result_amt_tyype      => l_sum_result_amt_tyype,  -- ���_�v_���ы��z
        i_sum_diff_amt_tyype        => l_sum_diff_amt_tyype     -- ���_�v_���z���z
      );
    END IF;
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** �f�[�^�擾��O ***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_put_file_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- �\�Z�N�x
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- �E�Ӄ^�C�v
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(4) := 'init'; -- �v���O������
--
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
    lv_profile_nm   VARCHAR2(30) DEFAULT NULL; -- �v���t�@�C�����̂̊i�[�p
    lb_retcode      BOOLEAN;
--
    -- *** ���[�J���E��O ***
    no_profile_expt EXCEPTION; -- �v���t�@�C���l�擾�G���[
    no_org_id_expt  EXCEPTION; -- �݌ɑg�DID�擾�G���[
    no_process_date EXCEPTION; -- �Ɩ����t�擾�G���[
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- ���̓p�����[�^�̑ޔ�
    -- ===============================
    gv_base_code   := iv_base_code;   -- ���_�R�[�h
    gv_budget_year := iv_budget_year; -- �\�Z�N�x
    gv_resp_type   := iv_resp_type;   -- �E�Ӄ^�C�v
--
    -- ===============================
    -- ���̓p�����[�^�̏o��
    -- ===============================
    -- �R���J�����g���̓p�����[�^���b�Z�[�W�o��(1:���_�R�[�h)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00018,
                    iv_token_name1  => cv_location_code,
                    iv_token_value1 => gv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_0     -- ���s��
                  );
    -- �R���J�����g���̓p�����[�^���b�Z�[�W�o��(2:�\�Z�N�x)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00019,
                    iv_token_name1  => cv_year,
                    iv_token_value1 => gv_budget_year
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_1     -- ���s��
                  );
    -- ===============================
    -- �v���t�@�C���l�擾
    -- ===============================
    -- �J�X�^���E�v���t�@�C���̍݌ɑg�D�R�[�h���擾���܂��B
    gv_org_code := fnd_profile.value(cv_pro_organization_code);
    IF ( gv_org_code IS NULL ) THEN
      lv_profile_nm := cv_pro_organization_code;
      RAISE no_profile_expt;
    END IF;
    -- �J�X�^���E�v���t�@�C���̖{�Ђ̕���R�[�h���擾���܂��B
    gv_head_office_code := fnd_profile.value(cv_pro_head_office_code);
    IF ( gv_head_office_code IS NULL ) THEN
      lv_profile_nm := cv_pro_head_office_code;
      RAISE no_profile_expt;
    END IF;
    -- ===============================
    -- �݌ɑg�DID�̎擾
    -- ===============================
    gn_org_id := xxcoi_common_pkg.get_organization_id(gv_org_code);
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00013
                    , iv_token_name1  => cv_org_code
                    , iv_token_value1 => gv_org_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_org_id_expt;
    END IF;
    -- ===============================
    -- ���O�C�����̏��擾
    -- ===============================
    gn_resp_id := fnd_global.resp_id; -- �E��ID
    gn_user_id := fnd_global.user_id; -- ���[�U�[ID
    -- =============================================
    -- �Ɩ��������t�擾
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_process_date;
    END IF;
--
  EXCEPTION
    --*** �v���t�@�C���l�擾�G���[ ***
    WHEN no_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcok,
                     iv_name         => cv_msg_xxcok1_00003,
                     iv_token_name1  => cv_profile,
                     iv_token_value1 => lv_profile_nm
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** �݌ɑg�DID�擾�G���[ ***
    WHEN no_org_id_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** �Ɩ����t�擾�擾�G���[ ***
    WHEN no_process_date THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h��
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2,              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- ���_�R�[�h
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- �\�Z�N�x
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- �E�Ӄ^�C�v
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(7) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      ov_errbuf      => lv_errbuf,      -- �G���[�E���b�Z�[�W
      ov_retcode     => lv_retcode,     -- ���^�[���E�R�[�h
      ov_errmsg      => lv_errmsg,      -- ���[�U�[�E�G���[�E���b�Z�[�W
      iv_base_code   => iv_base_code,   -- ���_�R�[�h
      iv_budget_year => iv_budget_year, -- �\�Z�N�x
      iv_resp_type   => iv_resp_type    -- �E�Ӄ^�C�v
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- �v���o�͑Ώۃf�[�^�擾����(A2�`A6)
    -- ===============================
    get_put_file_data(
      lv_errbuf,  -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode, -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf         OUT VARCHAR2, -- �G���[�E���b�Z�[�W --# �Œ� #
    retcode        OUT VARCHAR2, -- ���^�[���E�R�[�h   --# �Œ� #
    iv_base_code   IN  VARCHAR2, -- 1.���_�R�[�h
    iv_budget_year IN  VARCHAR2, -- 2.�\�Z�N�x
    iv_resp_type   IN  VARCHAR2  -- 3.�E�Ӄ^�C�v
  )
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(4)  := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(16)   DEFAULT NULL; -- ���b�Z�[�W�R�[�h
    lb_retcode      BOOLEAN;
--
  BEGIN
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    , iv_which   => 'LOG'-- ���O�o��
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- submain�̌Ăяo��
    -- ===============================
    submain(
      ov_errbuf      => lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode     => lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg      => lv_errmsg,      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_base_code   => iv_base_code,   -- ���_�R�[�h
      iv_budget_year => iv_budget_year, -- �\�Z�N�x
      iv_resp_type   => iv_resp_type    -- �E�Ӄ^�C�v
    );
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errmsg      -- ���b�Z�[�W
                    , in_new_line => cn_number_0    -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errbuf      -- ���b�Z�[�W
                    , in_new_line => cn_number_1    -- ���s
                    );
      -- �Ώی����E���������E�G���[�����̐ݒ�
      gn_error_cnt  := 1;
    END IF;
    -- ���׏o�͌�����0���̏ꍇ
    IF ( gn_put_count = 0 ) AND ( lv_retcode = cv_status_normal ) THEN
      -- �Ώۃf�[�^�����̃��b�Z�[�W�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_10184,
                      iv_token_name1  => cv_year,
                      iv_token_value1 => gv_budget_year
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.LOG,   -- LOG
                     iv_message  => gv_out_msg,     -- ���b�Z�[�W
                     in_new_line => cn_number_1     -- ���s��
                    );
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90000,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_0     -- ���s��
                  );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90001,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_0     -- ���s��
                  );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90002,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_1     -- ���s��
                  );
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal )   THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn )  THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG,   -- LOG
                    iv_message  => gv_out_msg,     -- ���b�Z�[�W
                    in_new_line => cn_number_0     -- ���s��
                  );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK023A03C;
/
