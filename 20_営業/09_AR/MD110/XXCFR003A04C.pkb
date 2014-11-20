CREATE OR REPLACE PACKAGE BODY XXCFR003A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A04C(body)
 * Description      : EDI�������f�[�^�쐬
 * MD.050           : MD050_CFR_003_A04_EDI�������f�[�^�쐬
 * MD.070           : MD050_CFR_003_A04_EDI�������f�[�^�쐬
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                   (A-1)
 *  get_fixed_value        p �Œ�l�擾����                             (A-2)
 *  get_edi_arcode         p EDI�����Ώێ擾���[�v����                  (A-3)
 *  get_edi_date           p EDI�f�[�^�擾���[�v����                    (A-4)(A-5)(A-6)
 *                           EDI�o�̓t�@�C���쐬����                    (A-7)(A-8)(A-9)
 *  pad_edi_char           f EDI�����ϊ��֐�
 *  set_edi_char           p EDI�����񐮌`����
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/21    1.0   SCS ��� �b      ����쐬
 *  2009/02/16    1.1   SCS ��� �b      [��QCFR_004] �ΏہE�x�������o�͕s��Ή�,
 *                                       [��QCFR_005] ���P���o�͕s��Ή�
 *  2009/02/25    1.2   SCS ��� �b      [��QCFR_017] EDI�Œ茅�����f�[�^�s��Ή�
 *  2009/05/07    1.3   SCS ���� �L��    [��QT1_0757] �G���[���|�R�[�h1(������)�ݒ�ڋq���b�Z�[�W�ǉ�
 *  2009/05/08    1.3   SCS ���� �L��    [��QT1_0687] �\���G���A�ǉ��A�t�b�^�擾�����C��
 *  2009/05/22    1.4   SCS ���� �L��    [��QT1_1127] EDI�������̃`�F�[���X�R�[�h�ւ̒l�̐ݒ�Ή�
 *  2009/05/26    1.4   SCS ���� �L��    [��QT1_1128] EDI�������̐�������Ŋz�^�x������Ŋz�����C��
                                                       �G���[���|�R�[�h1(������)�ݒ�ڋq���b�Z�[�W�o�͉ӏ��ύX
 *  2009/05/26    1.4   SCS ���� �L��    [��QT1_1121] EDI�������̎d����R�[�h�^�����R�[�h�擾�����C��  
 *  2009/06/16    1.5   SCS ���� �L��    [��QT1_1337,T1_1338,T1_1339]
                                                       �����R�[�h�ݒ菈���C��
                                                       ��������Ŋz�^�x������Ŋz�o�͏����C��
                                                       ���R�[�h�����C��
                                                       �������z���v,�l�������v,�ԕi���v,�ԕi���v�̏W�v�P�ʏC�� 
                                                       ����惌�R�[�h�ʔԐݒ菈���C��   
                                                       �ō��z���R�[�h�o�͏����C��
 *  2009/06/23    1.6   SCS ���� �L��    [��QT1_1379] EDI�������̓`�[�ԍ��`�F�b�N�����Ή�
 *  2009/10/15    1.7   SCS ���� �L��     AR�d�l�ύXIE558�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  edi_func_h_expt  EXCEPTION;      -- EDI�w�b�_�t�^�֐��G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A04C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- �A�v���P�[�V�����Z�k��(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- �A�v���P�[�V�����Z�k��(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- �A�v���P�[�V�����Z�k��(XXCFR)
--
  -- ���b�Z�[�W�ԍ�
--
  cv_msg_003a04_001  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_003a04_002  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; -- �l�擾�G���[���b�Z�[�W
  cv_msg_003a04_003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; -- ���ʊ֐��G���[���b�Z�[�W
  cv_msg_003a04_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_003a04_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- �Ώۃf�[�^��0�����b�Z�[�W
  cv_msg_003a04_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_003a04_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00047'; -- �t�@�C���̏ꏊ���������b�Z�[�W
  cv_msg_003a04_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00048'; -- �t�@�C�����I�[�v���ł��Ȃ����b�Z�[�W
  cv_msg_003a04_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00049'; -- �t�@�C���ɏ����݂ł��Ȃ����b�Z�[
  cv_msg_003a04_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00054'; -- �t�@�C�������݂��Ă��郁�b�Z�[�W
  cv_msg_003a04_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00053'; -- EDI�ݒ�G���[���b�Z�[�W
  cv_msg_003a04_019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00069'; -- EDI�t�@�C���o�̓��b�Z�[�W
  cv_msg_003a04_020  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00035'; -- �o�̓t�@�C�����R�[�h�����b�Z�[�W
  cv_msg_003a04_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00068'; -- EDI�I�[�o�[�t���[���b�Z�[�W
  cv_msg_003a04_022  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00070'; -- �t�@�C���o�͌���
-- Modify 2009.05.07 Ver1.3 Start
  cv_msg_003a04_023  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00073'; -- �G���[���|�R�[�h1(������)�ݒ�ڋq�w�b�_���b�Z�[�W
  cv_msg_003a04_024  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00074'; -- �G���[���|�R�[�h1(������)�ݒ�ڋq���׃��b�Z�[�W
-- Modify 2009.05.07 Ver1.3 End
-- Modify 2009.06.23 Ver1.6 Start
  cv_msg_003a04_025  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00075'; -- �G���[�`�[�ԍ����b�Z�[�W
  cv_msg_003a04_026  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00076'; -- �t�@�C���o�͂Ȃ����b�Z�[�W  
-- Modify 2009.06.23 Ver1.6 End
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_data        CONSTANT VARCHAR2(15) := 'DATA';             -- �l��
  cv_tkn_func        CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- ���ʊ֐���
  cv_tkn_code        CONSTANT VARCHAR2(15) := 'CODE';             -- ���|�R�[�h�P�i�������j
  cv_tkn_name        CONSTANT VARCHAR2(15) := 'NAME';             -- ���|�R�[�h�P�i�������j��
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_rec         CONSTANT VARCHAR2(15) := 'REC_COUNT';        -- �t�@�C�������R�[�h��
  cv_tkn_item        CONSTANT VARCHAR2(15) := 'ITEM';             -- ����
  cv_tkn_rec_num     CONSTANT VARCHAR2(15) := 'FILE_REC_NUM';     -- �I�[�o�[�t���[���R�[�h�ʔ�
  cv_tkn_slip_num    CONSTANT VARCHAR2(15) := 'SLIP_NUM';         -- �`�[�ԍ�
  cv_tkn_slip_rec    CONSTANT VARCHAR2(15) := 'SLIP_REC_NUM';     -- �`�[�ԍ��ʔ�
--
  -- ���{�ꎫ��
  cv_dict_date        CONSTANT VARCHAR2(100) := 'CFR000A00003';    -- ���t�p�����[�^�ϊ��֐�
  cv_dict_output_dept CONSTANT VARCHAR2(100) := 'CFR003A04001';    -- EDI�o�͋��_��
  cv_dict_data_code   CONSTANT VARCHAR2(100) := 'CFR003A04002';    -- �f�[�^��R�[�h
  cv_dict_h_func      CONSTANT VARCHAR2(100) := 'CFR003A04003';    -- EDI�w�b�_�t�^�֐�
  cv_dict_f_func      CONSTANT VARCHAR2(100) := 'CFR003A04004';    -- EDI�t�b�^�t�^�֐�
  cv_dict_arcode1     CONSTANT VARCHAR2(100) := 'CFR003A02003';    -- ���|�R�[�h1(������)
  cv_dict_slip_type   CONSTANT VARCHAR2(100) := 'CFR003A04005';    -- �`�[�敪
  cv_dict_chain_code  CONSTANT VARCHAR2(100) := 'CFR003A04006';    -- �`�F�[���X�R�[�h
  cv_dict_chain_name  CONSTANT VARCHAR2(100) := 'CFR003A04007';    -- �`�F�[���X����
  cv_dict_file_name   CONSTANT VARCHAR2(100) := 'CFR003A04008';    -- �t�@�C����
--
  --�v���t�@�C��
  cv_org_id               CONSTANT VARCHAR2(30) := 'ORG_ID';                         -- �g�DID
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';               -- ��v����ID
  cv_comp_kana_name       CONSTANT VARCHAR2(35) := 'XXCFR1_INVOICE_ITOEN_KANA_NAME'; -- XXCFR:�����������J�i��
  cv_edi_data_filepath    CONSTANT VARCHAR2(35) := 'XXCFR1_EDI_FILEPATH';            -- XXCFR:EDI�t�@�C���i�[�p�X
  cv_edi_output_dept      CONSTANT VARCHAR2(35) := 'XXCFR1_EDI_OUTPUT_DEPT';         -- XXCFR:EDI�o�͋��_
  cv_edi_data_type        CONSTANT VARCHAR2(35) := 'XXCFR1_INV_EDI_DATA_SET';        -- XXCFR:EDI�����o�͍���
-- Modify 2009.05.26 Ver1.4 Start
  cv_comp_code            CONSTANT VARCHAR2(35) := 'XXCFR1_INVOICE_VENDER_CODE';     -- XXCFR:EDI�����������R�[�h
-- Modify 2009.05.26 Ver1.4 End
--
  -- �Q�ƃ^�C�v
  cv_invoice_grp_code     CONSTANT VARCHAR2(30) := 'XXCMM_INVOICE_GRP_CODE'; -- ���|�R�[�h�P�i�������j
  cv_discount_code        CONSTANT VARCHAR2(35) := 'XXCFR1_EDI_RETURN_CODE'; -- EDI�l���R�[�h
--
  -- �����ϊ��t�H�[�}�b�g����p
  cv_str_format_n CONSTANT VARCHAR2(10) := 'N';  -- ���l
  cv_str_format_s CONSTANT VARCHAR2(10) := 'S'; -- �����񔼊p
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  cv_flag_yes        CONSTANT VARCHAR2(1)  := 'Y';         -- �t���O�i�x�j
  cv_flag_no         CONSTANT VARCHAR2(1)  := 'N';         -- �t���O�i�m�j
--
  cv_line_type_l     CONSTANT VARCHAR2(4)  := 'LINE';     -- ���׃^�C�v(=LINE)
  cn_period_months   CONSTANT NUMBER       := 12;         -- ���o�Ώۊ��ԁi���j
--
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';         -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ymds   CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';       -- ���t�t�H�[�}�b�g�i�N�����X���b�V���t�j
  cv_format_date_hms    CONSTANT VARCHAR2(6)  := 'HHMISS';           -- ���ԃt�H�[�}�b�g�iHHMISS�j
--
  cd_min_date           CONSTANT DATE         := TO_DATE('1900/01/01',cv_format_date_ymds);
  cd_max_date           CONSTANT DATE         := TO_DATE('9999/12/31',cv_format_date_ymds);
--
  cv_start_mode_b       CONSTANT VARCHAR2(1) := '0'; -- ��ԃo�b�`
  cv_start_mode_h       CONSTANT VARCHAR2(1) := '1'; -- �蓮
--
  -- �������o�͋敪
  cv_inv_prt_type       CONSTANT VARCHAR2(1)  := '3';                       -- 3.EDI
--
  -- ����ԕi�敪�i�ԕi�j
  cv_sold_return_type_r CONSTANT VARCHAR2(1)  := '2';                       -- 2.�ԕi
--
    -- ����ŋ敪
    cv_syohizei_kbn_te  CONSTANT VARCHAR2(1)  := '1';                      -- �O��
--
-- Modify 2009.06.23 Ver1.6 Start
  cv_slip_no_chk_i      CONSTANT VARCHAR2(1)  := 'I';                      -- �[�i�`�[�ԍ��`�F�b�N�p
-- Modify 2009.06.23 Ver1.6 End
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_start_mode_flg           VARCHAR2(1) := '0'; -- �N���t���O
  gn_org_id                   NUMBER;             -- �g�DID
  gn_set_of_bks_id            NUMBER;             -- ��v����ID
  gv_comp_kana_name           VARCHAR2(100);      -- �����������J�i��
  gv_edi_data_filepath        VARCHAR2(500);      -- XXCFR:EDI�t�@�C���i�[�p�X
  gv_edi_output_dept          VARCHAR2(10) ;      -- XXCFR:EDI�o�͋��_
  gv_discount_code            VARCHAR2(10);       -- XXCFR:EDI�l���R�[�h
-- Modify 2009.05.26 Ver1.4 Start  
  gv_comp_code                VARCHAR2(30);       -- XXCFR:EDI�����������R�[�h
-- Modify 2009.05.26 Ver1.4 End
--
  gv_edi_output_dept_name     VARCHAR2(100) := NULL;     -- EDI�o�͋��_��
  gv_edi_data_code            VARCHAR2(10)  := NULL;     -- �f�[�^��R�[�h
  gv_edi_operation_code       VARCHAR2(10)  := NULL;     -- �Ɩ��n��R�[�h
  gv_edi_chain_code           VARCHAR2(500);             -- �`�F�[���X
  gv_edi_chain_name           VARCHAR2(500);             -- �`�F�[���X����
  gv_edi_data_filename        VARCHAR2(500);             -- EDI�t�@�C����
  gv_ar_code_name             VARCHAR2(500);             -- ���|�R�[�h�P�i�������j����
--
  gd_process_date             DATE;              -- �Ɩ��������t
  gd_target_date              DATE;              -- �p�����[�^�D�����i�f�[�^�^�ϊ��p�j
  gn_output_cnt               NUMBER := '0';     -- �t�@�C���o�͌���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- EDI���ڏ��擾�J�[�\��
  CURSOR get_edi_item_cur
  IS
  SELECT flvv.attribute1 edi_length
        ,flvv.attribute2 data_type
        ,flvv.attribute3 err_msg_flg
        ,flvv.meaning data_name
  FROM   FND_LOOKUP_VALUES_VL flvv-- �N�C�b�N�R�[�h(EDI�����o�͍���)
  WHERE  flvv.lookup_type =cv_edi_data_type
  ORDER BY flvv.lookup_code;
  --===============================================================
  -- �O���[�o���^�C�v
  --===============================================================
  TYPE edi_item_ttype      IS TABLE OF get_edi_item_cur%ROWTYPE INDEX BY PLS_INTEGER; -- EDI�����o�͍��ڏ��
--
  gt_edi_item_tab              edi_item_ttype;                                       -- EDI�����o�͍��ڏ��
--
  /**********************************************************************************
   * Function Name    : pad_edi_char
   * Description      : EDI�����ϊ��֐�
   ***********************************************************************************/
  FUNCTION pad_edi_char(
    iv_string_data      IN VARCHAR2,  -- �ϊ��Ώە�����	
    iv_data_format      IN VARCHAR2,  -- �t�H�[�}�b�g
    in_length           IN NUMBER   ) -- ����
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pad_edi_char'; -- �v���O������
--
    -- �󔒕⊮������
    cv_trn_format_n CONSTANT VARCHAR2(1) := '0';  -- ���l
    cv_trn_format_s CONSTANT VARCHAR2(1) := ' ';  -- �����񔼊p
    cv_minus        CONSTANT VARCHAR2(1) := '-';  -- �}�C�i�X�L��
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_format    VARCHAR2(2)   := NULL ; -- �󔒕⊮����
    ln_data_num  NUMBER        := NULL ; -- ���l�i�[�ϐ�
    lv_in_str    VARCHAR2(500) := NULL ; 
    lv_ret_str   VARCHAR2(500) := NULL ; -- �߂�l
--
  BEGIN
--
    -- ====================================================
    -- EDI�����ϊ��֐��������W�b�N�̋L�q
    -- ===================================================
--
    -- �󔒕⊮�����̐ݒ�
    CASE
      WHEN iv_data_format = cv_str_format_n THEN
        lv_format := cv_trn_format_n;
      WHEN iv_data_format = cv_str_format_s THEN
        lv_format := cv_trn_format_s;
      ELSE
        NULL;
    END CASE;
--
    lv_in_str := NVL(iv_string_data,lv_format);
    lv_ret_str := lv_in_str;
--
    -- �����񒷔���
    IF (LENGTHB(lv_in_str) < in_length) THEN
--
      -- �@���l�^�̏ꍇ
      IF iv_data_format = cv_str_format_n THEN
        -- NUMBER�^�ɕϊ�
        ln_data_num := TO_NUMBER(NVL(lv_in_str,lv_format));
        lv_ret_str := LPAD(TO_CHAR(ABS(ln_data_num)),in_length,lv_format);
        IF ln_data_num < 0 THEN
          lv_ret_str := cv_minus || SUBSTR(lv_ret_str,2);
        END IF;
      -- �A������^�̏ꍇ
      ELSIF iv_data_format = cv_str_format_s THEN
        lv_ret_str := lv_in_str;
        <<data_loop>>
        LOOP
          IF LENGTHB(lv_ret_str) < in_length THEN
            lv_ret_str := lv_ret_str || cv_trn_format_s;
          ELSE
            EXIT;
          END IF;
        END LOOP data_loop;
      ELSE
        NULL;
      END IF;
    END IF;
--
    RETURN lv_ret_str;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END pad_edi_char;
--
  /**********************************************************************************
   * Procedure Name   : set_edi_char
   * Description      : EDI�����񐮌`����
   ***********************************************************************************/
  PROCEDURE set_edi_char(
    iv_order_num   IN NUMBER,        -- ���ڏ�
    iv_string_data IN VARCHAR2,      -- �ϊ��Ώە�����
    iv_rec_num     IN VARCHAR2,      -- ���R�[�h�ʔ�
    iv_slip_num    IN VARCHAR2,      -- �`�[�ԍ�
    iv_slip_rec    IN VARCHAR2,      -- �`�[�sNo
    ov_ret_str     OUT VARCHAR2,     -- �߂�l
    ov_errbuf      OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_edi_char'; -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_data_num        NUMBER        := NULL ; -- ���l�i�[�ϐ�
    lv_type            VARCHAR2(10)  := NULL ; -- �f�[�^�^
    lv_flg             VARCHAR2(10)  := NULL ; -- ���b�Z�[�W�o�̓t���O
    lv_in_str          VARCHAR2(5000) := NULL ; 
    ln_length          NUMBER        := NULL ; -- ������
    lv_ret_str         VARCHAR2(500) := NULL ; -- �߂�l
    lv_overflow_msg    VARCHAR2(5000);         -- EDI�o�̓t�@�C�������I�[�o�[�t���[���b�Z�[�W
--
  BEGIN
--
    -- ====================================================
    -- EDI�����ϊ��֐��������W�b�N�̋L�q
    -- ===================================================
--
    -- �����񒷎擾����
    ln_length := gt_edi_item_tab(iv_order_num).edi_length;
    IF ln_length IS NULL THEN
      -- �x��
      ov_retcode := cv_status_warn;
    END IF;
--
    -- �f�[�^�^�擾����
    lv_type := gt_edi_item_tab(iv_order_num).data_type;
    IF lv_type IS NULL THEN
      lv_type := cv_str_format_s;
    END IF;
--
    -- �x�����b�Z�[�W�o�̓t���O�擾����
    lv_flg := gt_edi_item_tab(iv_order_num).err_msg_flg;
    IF lv_flg IS NULL THEN
      lv_flg := cv_flag_no;
    END IF;
--
    lv_in_str := iv_string_data;
    -- �����񒷔���
    IF (LENGTHB(lv_in_str) > ln_length) THEN
      -- �w�茅�ɂĒl�؎̂�
      ov_ret_str := SUBSTRB(lv_in_str
                           ,1
                           ,ln_length);
      IF lv_flg = cv_flag_yes THEN
        -- �I���X�e�[�^�X���x���ɕύX
        ov_retcode := cv_status_warn;
        -- �x�����b�Z�[�W�o��
        lv_overflow_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                            ,cv_msg_003a04_021    -- EDI�I�[�o�[�t���[���b�Z�[�W
                                                            ,cv_tkn_item          -- �g�[�N��'ITEM'
                                                            ,gt_edi_item_tab(iv_order_num).data_name
                                                            ,cv_tkn_file          -- �g�[�N��'FILE_NAME'
                                                            ,gv_edi_data_filename -- �t�@�C����
                                                            ,cv_tkn_rec_num       -- �g�[�N��'FILE_REC_NUM'
                                                            ,iv_rec_num           -- �W�v���[�v�J�E���^
                                                            ,cv_tkn_slip_num      -- �g�[�N��'SLIP_NUM'
                                                            ,iv_slip_num          -- �`�[�ԍ�
                                                            ,cv_tkn_slip_rec      -- �g�[�N��'SLIP_REC_NUM'
                                                            ,iv_slip_rec)         -- �`�[�sNo
                           ,1
                           ,5000);
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_overflow_msg
        );
      END IF;
    ELSE
      ov_ret_str := lv_in_str;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      ov_ret_str := NULL;
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
--
--###################################  �Œ蕔 END   #########################################
--
  END set_edi_char;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date          IN  VARCHAR2,     -- ����
    iv_ar_code1             IN  VARCHAR2,     -- ���|�R�[�h�P(������)
    iv_start_mode           IN  VARCHAR2,     -- �N���敪
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���̓p�����[�^�D�N���敪���Z�b�g
    gv_start_mode_flg := iv_start_mode;
--
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- �蓮�N���̏ꍇ
    IF (iv_start_mode = cv_start_mode_h) THEN
      -- �p�����[�^�D������DATE�^�ɕϊ�����
      gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
      IF (gd_target_date IS NULL) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a04_003 -- ���ʊ֐��G���[
                                                      ,cv_tkn_func       -- �g�[�N��'FUNC_NAME'
                                                      ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                         ,cv_dict_date))
                                                      -- ���t�p�����[�^�ϊ��֐�
                            ,1
                            ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_out             -- ���b�Z�[�W�o��
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date
                                                              ,cv_format_date_ymds) -- ����
                                   ,iv_conc_param2  => iv_ar_code1                  -- ���|�R�[�h�P�i�������j
                                   ,iv_conc_param3  => iv_start_mode                -- �N���敪
                                   ,ov_errbuf       => ov_errbuf                    -- �G���[�E���b�Z�[�W
                                   ,ov_retcode      => ov_retcode                   -- ���^�[���E�R�[�h
                                   ,ov_errmsg       => ov_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log             -- ���O�o��
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date
                                                              ,cv_format_date_ymds) -- ����
                                   ,iv_conc_param2  => iv_ar_code1                  -- ���|�R�[�h�P�i�������j
                                   ,iv_conc_param3  => iv_start_mode                -- �N���敪
                                   ,ov_errbuf       => ov_errbuf                    -- �G���[�E���b�Z�[�W
                                   ,ov_retcode      => ov_retcode                   -- ���^�[���E�R�[�h
                                   ,ov_errmsg       => ov_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_fixed_value
   * Description      : �Œ�l�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_fixed_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fixed_value'; -- �v���O������
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
    cv_flex_value_set_name        CONSTANT VARCHAR2(15) := 'XX03_DEPARTMENT';
    cv_lookup_type                CONSTANT VARCHAR2(21) := 'XXCOS1_DATA_TYPE_CODE';
    cv_lookup_code                CONSTANT VARCHAR2(3)  := '110';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- �擾�G���[��
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                       -- ��v����ID
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- �g�DID
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:�����������J�i���擾
    gv_comp_kana_name := FND_PROFILE.VALUE(cv_comp_kana_name);
    -- �擾�G���[��
    IF (gv_comp_kana_name IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_comp_kana_name))
                                                       -- XXCFR:�����������J�i��
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.05.26 Ver1.4 Start
    -- �v���t�@�C������XXCFR:EDI�����������R�[�h�擾
    gv_comp_code := FND_PROFILE.VALUE(cv_comp_code);
    -- �擾�G���[��
    IF (gv_comp_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_comp_code))
                                                       -- XXCFR:EDI�����������R�[�h
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.05.26 Ver1.4 End
    -- �v���t�@�C������XXCFR:EDI�t�@�C���i�[�p�X�擾
    gv_edi_data_filepath := FND_PROFILE.VALUE(cv_edi_data_filepath);
    -- �擾�G���[��
    IF (gv_edi_data_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_edi_data_filepath))
                                                       -- XXCFR:EDI�t�@�C���i�[�p�X
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:EDI�o�͋��_�擾
    gv_edi_output_dept := FND_PROFILE.VALUE(cv_edi_output_dept);
    -- �擾�G���[��
    IF (gv_edi_output_dept IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_edi_output_dept))
                                                       -- XXCFR:EDI�o�͋��_
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- EDI�o�͋��_���擾����
    BEGIN
      SELECT ffvv.description   edi_output_dept_name             -- �E�v
      INTO gv_edi_output_dept_name
      FROM fnd_flex_value_sets  ffvs,                            -- �l�Z�b�g
           fnd_flex_values_vl   ffvv                             -- �l�Z�b�g�l�r���[
      WHERE ffvs.flex_value_set_name = cv_flex_value_set_name
      AND   ffvs.flex_value_set_id   = ffvv.flex_value_set_id
      AND   ffvv.flex_value          = gv_edi_output_dept;
    EXCEPTION
      WHEN OTHERS THEN
        gv_edi_output_dept_name := NULL;
    END;
    -- �擾�G���[��
    IF (gv_edi_output_dept_name IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_002 -- �l�擾�G���[
                                                    ,cv_tkn_data       -- �g�[�N��'DATA'
                                                    ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                        ,cv_dict_output_dept ))
                                                                                        -- XXCFR:EDI�o�͋��_��
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �Ɩ��������t�擾����
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
    -- �擾�G���[��
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_013 -- �Ɩ��������t�擾�G���[
                                                    )
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �f�[�^��R�[�h�擾����
    BEGIN
      SELECT ffvv.meaning    data_code,                          -- �f�[�^��R�[�h
             ffvv.attribute1 operation_code                      -- �Ɩ��n��R�[�h
      INTO gv_edi_data_code,
           gv_edi_operation_code
      FROM fnd_lookup_values_vl  ffvv                            -- �N�C�b�N�R�[�h�r���[
      WHERE ffvv.lookup_type = cv_lookup_type
        AND ffvv.lookup_code = cv_lookup_code
        AND ffvv.enabled_flag = cv_flag_yes
        AND gd_process_date BETWEEN NVL(ffvv.start_date_active ,cd_min_date) AND
                                    NVL(ffvv.end_date_active ,cd_max_date);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- �擾�G���[��
    IF (gv_edi_data_code IS NULL) OR (gv_edi_operation_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_002 -- �l�擾�G���[
                                                    ,cv_tkn_data       -- �g�[�N��'DATA'
                                                    ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                        ,cv_dict_data_code ))
                                                                                        -- XXCFR:EDI�l���R�[�h
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_fixed_value;
--
  /**********************************************************************************
   * Procedure Name   : get_edi_date
   * Description      : EDI�f�[�^�擾���[�v�����EEDI�o�̓t�@�C���쐬����
                        (A-4)(A-5)(A-6)(A-7)(A-8)(A-9)
   ***********************************************************************************/
  PROCEDURE get_edi_date(
    iv_target_date IN  VARCHAR2,     -- ����
    iv_ar_code1    IN  VARCHAR2,     -- ���|�R�[�h�P(������)
    iv_start_mode  IN  VARCHAR2,     -- �N���敪
    ov_errbuf      OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edi_date'; -- �v���O������
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
    cv_open_mode_w    CONSTANT VARCHAR2(10) := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
    cv_add_area_h     CONSTANT VARCHAR2(10) := 'H';     -- �t�^�敪�i�w�b�_�t�^�j
    cv_rec_type_d     CONSTANT VARCHAR2(1)  := 'D';     -- �t�^�敪�i���וt�^�j
    cv_add_area_f     CONSTANT VARCHAR2(10) := 'F';     -- �t�^�敪�i�t�b�^�t�^�j
    cv_row_number     CONSTANT VARCHAR2(2)  := '01';    -- ���񏈗��ԍ�
    cv_return_type    CONSTANT VARCHAR2(10) := '2';     -- �t�^�敪�i�t�b�^�t�^�j
--
    cv_nul_v_code     CONSTANT VARCHAR2(8)  := 'NUL_CODE';        -- NULL�l�⊮�����i�����R�[�h�j
    cv_nul_slip_num   CONSTANT VARCHAR2(12) := 'NUL_SLIP_NUM';    -- NULL�l�⊮�����i�`�[�ԍ��j
    cv_end_v_code     CONSTANT VARCHAR2(11) := '***END_C';        -- �I������i�����R�[�h�j
    cv_end_inv_id     CONSTANT VARCHAR2(13) := '***END_I';        -- �I������i������ID�j
    cv_end_slip_num   CONSTANT VARCHAR2(15) := '***END_S';        -- �I������i�`�[�ԍ��j
--
    -- �󔒕⊮�i���t�E���ԁj
    cv_trn_format_d   CONSTANT VARCHAR2(8)  := '00000000'; -- DATE�^
    cv_trn_format_t   CONSTANT VARCHAR2(6)  := '000000';   -- TIME�^
--
    -- ��������
    cv_num_format_t   CONSTANT VARCHAR2(10) := '9999.99';         -- ����ŗ�
    cv_num_format_u   CONSTANT VARCHAR2(25) := '99999999999999999999.99'; -- ���P��
--
    -- *** ���[�J���ϐ� ***
    -- �����J�E���g
    ln_target_cnt   NUMBER;         -- EDI�f�[�^�e�[�u���q�b�g����
    ln_data_cnt     NUMBER;         -- �W�v���ʊi�[�惌�R�[�h�J�E���^
    ln_loop_cnt     NUMBER;         -- �W�v���[�v�J�E���^
    ln_rec_cnt      NUMBER;         -- �o�̓��[�v�J�E���^
--
    ln_vend_cnt     NUMBER;         -- ���������R�[�h�J�E���^
    ln_slip_num     NUMBER;         -- �`�[�����i�����R�[�h�P�ʁj
--
    -- ���z���v�ϐ�
    ln_slip_amount  NUMBER;         -- �������z�i�`�[�P�ʁj
-- Modify 2009.06.08 Ver1.5 Start
    ln_slip_tax_amount  NUMBER;     -- ��������Ŋz�i�`�[�P�ʁj
-- Modify 2009.06.08 Ver1.5 END
    ln_vend_amount  NUMBER;         -- �������z���v�i�����R�[�h�P�ʁj
    ln_disc_amount  NUMBER;         -- �l�������v�i�����R�[�h�P�ʁj
    ln_retn_amount  NUMBER;         -- �ԕi���v�i�����R�[�h�P�ʁj
--
    -- �u���C�N�ϐ�
    lv_b_slip_num   VARCHAR2(300);   -- �`�[�ԍ�
    lv_b_inv_id     VARCHAR2(300);   -- �ꊇ������ID
    lv_b_vend_cd    VARCHAR2(300);    -- �����R�[�h
--
    -- �X�V�J�n�ʒu
    ln_slip_point   NUMBER;         -- �X�V�J�n�ʒu�i�`�[�j
    ln_inv_point    NUMBER;         -- �X�V�J�n�ʒu�i�ꊇ������ID�j
    ln_vend_point   NUMBER;         -- �X�V�J�n�ʒu�i�����R�[�h�j
--
    -- �t�@�C���o�͊֘A
    lf_file_hand    UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_edi_text     VARCHAR2(32767) ;       -- 1�s������̍ő啶����
    lv_output       VARCHAR2(32767);        -- EDI�w�b�_�E�t�b�^���ʊ֐��o�͒l
--
    -- 
    lv_output_str          VARCHAR2(5000);  -- EDI�o�͍��ڊi�[�ϐ�
    lv_overflow_msg        VARCHAR2(5000);  -- EDI�o�̓t�@�C�������I�[�o�[�t���[���b�Z�[�W
    lv_output_file_msg     VARCHAR2(5000);  -- EDI�o�̓t�@�C�������b�Z�[�W
    lv_output_rec_num_msg  VARCHAR2(5000);  -- EDI�o�̓t�@�C�����R�[�h�����b�Z�[�W
--
-- Modify 2009.06.15 Ver1.5 Start
    lv_tax_gap_out_flg     VARCHAR2(1);     -- �ō��z����o�̓t���O
-- Modify 2009.06.15 Ver1.5 End
-- Modify 2009.06.23 Ver1.6 Start
    -- �`�[�ԍ��`�F�b�N�p�ϐ�
    lv_chk_bef_slip        VARCHAR2(300);   -- �`�[�ԍ�
    ln_chk_slip_buf        NUMBER;
    lv_chk_err_flg         VARCHAR(1);
    lv_slip_warn_msg       VARCHAR2(5000) := NULL; -- �`�[�ԍ��s���x�����b�Z�[�W
--
    num_err_expt           EXCEPTION;     -- ���l�����G���[
--
    PRAGMA EXCEPTION_INIT(num_err_expt, -06502);
-- Modify 2009.06.23 Ver1.6 End
    -- *** ���[�J���E�J�[�\�� ***
--
    -- EDI�����f�[�^���o
    CURSOR get_edi_data_cur(
      iv_ar_code1    VARCHAR2)
    IS
      SELECT cv_rec_type_d                            file_rec_type          -- ���R�[�h�敪
            ,NULL                                     file_rec_num           -- ���R�[�h�ʔ�
-- Modify 2009.05.22 Ver1.4 Start
--            ,NULL                                     chain_st_code          -- �`�F�[���X�R�[�h
            ,gv_edi_chain_code                        chain_st_code          -- �`�F�[���X�R�[�h
-- Modify 2009.05.22 Ver1.4 End
            ,TO_CHAR(xih.inv_creation_date
                    ,cv_format_date_ymd)              inv_creation_day       -- �f�[�^�쐬��
            ,TO_CHAR(xih.inv_creation_date
                    ,cv_format_date_hms)              inv_creation_time      -- �f�[�^�쐬����
-- Modify 2009.06.05 Ver1.5 Start
-- Modify 2009.05.26 Ver1.4 Start                    
--            ,NVL(xih.vender_code,cv_nul_v_code)       vender_code            -- �d����R�[�h�^�����R�[�h
--            ,gv_comp_code                             vender_code            -- �d����R�[�h�^�����R�[�h
            ,NVL(xih.vender_code,gv_comp_code)        vender_code           -- �d����R�[�h�^�����R�[�h
-- Modify 2009.05.26 Ver1.4 End
-- Modify 2009.06.05 Ver1.5 End
            ,TO_CHAR(xih.invoice_id)                  invoice_id             -- �ꊇ������ID
            ,xih.tax_gap_amount                       tax_gap_amount         -- �ō��z
            ,SUBSTRB(xih.itoen_name,1,30)             itoen_name             -- �d���於�́^����於�́i�����j
            ,gv_comp_kana_name                        itoen_kana_name        -- �d���於�́^����於�́i�J�i�j
            ,NULL                                     co_code                -- �ЃR�[�h
            ,TO_CHAR(xih.object_date_from
                    ,cv_format_date_ymd)              object_date_from       -- �Ώۊ��ԁE��
            ,TO_CHAR(xih.object_date_to
                    ,cv_format_date_ymd)              object_date_to         -- �Ώۊ��ԁE��
            ,TO_CHAR(xih.cutoff_date
                    ,cv_format_date_ymd)              cutoff_date            -- �������N����
            ,TO_CHAR(xih.payment_date
                    ,cv_format_date_ymd)              payment_date           -- �x���N����
            ,xih.due_months_forword                   due_months_forword     -- �T�C�g����
            ,NULL                                     inv_slip_ttl           -- �`�[����
            ,NULL                                     cor_slip_ttl           -- �����`�[����
            ,NULL                                     n_ins_slip_ttl         -- �������`�[����
            ,NULL                                     vend_rec_num           -- ���������R�[�h�ʔ�
            ,NULL                                     inv_no                 -- ������No�^�����ԍ�
            ,xil.inv_type                             inv_type               -- �����敪
            ,NULL                                     pay_type               -- �x���敪
            ,NULL                                     pay_meth_type          -- �x�����@�敪
            ,NULL                                     iss_type               -- ���s�敪
            ,xil.ship_shop_code                       ship_shop_code         -- �X�R�[�h
            ,xil.ship_cust_name                       ship_cust_name         -- �X�ܖ��́i�����j
            ,xil.ship_cust_kana_name                  ship_cust_kana_name    -- �X�ܖ��́i�J�i�j
            ,NULL                                     inv_sign               -- �������z�����^��������Ŋz����
            ,xil.ship_amount + xil.tax_amount         inv_slip_amount        -- �������z�^�x�����z
            ,xih.tax_type                             tax_type               -- ����ŋ敪
            ,LTRIM(REPLACE(TO_CHAR(TRUNC(xil.tax_rate,2)
                                  ,cv_num_format_t)
                          ,cv_msg_cont))              tax_rate               -- ����ŗ�
            ,xil.tax_amount                           tax_amount             -- ��������Ŋz�^�x������Ŋz
            ,xih.tax_gap_trx_id                       tax_gap_trx_id         -- �ō��z���ID
            ,0                                        tax_gap_flg            -- ����ō��z�t���O
            ,NULL                                     mis_calc_type          -- ��Z�敪
            ,NULL                                     match_type             -- �}�b�`�敪
            ,NULL                                     unmatch_pay_amount     -- �A���}�b�`���|�v����z
            ,NULL                                     overlap_type           -- �_�u���敪
            ,TO_CHAR(xil.acceptance_date
                    ,cv_format_date_ymd)              acceptance_date        -- ������
            ,xih.month_remit                          month_remit            -- ����
            ,NVL(xil.slip_num,cv_nul_slip_num)        slip_num               -- �`�[�ԍ�
            ,xil.note_line_id                         note_line_id           -- �sNo
            ,xil.slip_type                            slip_type              -- �`�[�敪
            ,xil.classify_type                        classify_type          -- ���ރR�[�h
            ,xil.customer_dept_code                   customer_dept_code     -- ����敔��R�[�h
            ,xil.customer_division_code               customer_division_code -- �ۃR�[�h
            ,xil.sold_return_type                     sold_return_type       -- ����ԕi�敪
            ,xil.nichiriu_by_way_type                 nichiriu_by_way_type   -- �j�`���E�o�R�敪
            ,xil.sale_type                            sale_type              -- �����敪
            ,xil.direct_num                           direct_num             -- ��No
            ,TO_CHAR(xil.po_date
                    ,cv_format_date_ymd)              po_date                -- ������
            ,TO_CHAR(xil.delivery_date
                    ,cv_format_date_ymd)              delivery_date          -- �[�i���^�ԕi��
            ,xil.item_code                            item_code              -- ���i�R�[�h
            ,xil.item_name                            item_name              -- ���i���i�����j
            ,xil.item_kana_name                       item_kana_name         -- ���i��(�J�i)
            ,TRUNC(xil.quantity)                      quantity               -- �[�i����
            ,LTRIM(REPLACE(TO_CHAR(xil.unit_price,cv_num_format_u)
                  ,cv_msg_cont))                      unit_price             -- ���P��
            ,xil.sold_amount                          sold_amount            -- �������z
            ,xil.sold_location_code                   sold_location_code     -- ���l�R�[�h
            ,NULL                                     chain_st_area          -- �`�F�[���X�ŗL�G���A
            ,xil.ship_amount + xil.tax_amount         inv_amount             -- �������v���z�^�x�����v���z
            ,CASE
               WHEN (SELECT COUNT(*)
                     FROM fnd_lookup_values_vl  ffvv -- �N�C�b�N�R�[�h�r���[
                     WHERE ffvv.lookup_type = cv_discount_code -- 'XXCFR1_EDI_RETURN_CODE' -- EDI�l���R�[�h
                       AND ffvv.lookup_code IN xil.item_code
                       AND ffvv.enabled_flag = cv_flag_yes --'Y'--
                       AND gd_process_date BETWEEN NVL(ffvv.start_date_active ,cd_min_date) AND
                                                   NVL(ffvv.end_date_active ,cd_max_date)
                    ) > 0 THEN xil.ship_amount + xil.tax_amount
               ELSE 0
             END                                      discount_amount        -- �l�����v���z
            ,CASE xil.sold_return_type
               WHEN cv_sold_return_type_r THEN xil.ship_amount + xil.tax_amount
               ELSE 0
             END                                      return_amount          -- �ԕi���v���z
-- Modify 2009.10.15 Ver1.7 Start
           ,xil.jan_code                              jan_code               -- JAN�R�[�h
           ,xil.num_of_cases                          num_of_cases           -- �P�[�X����
           ,xil.medium_class                          medium_class           -- �󒍃\�[�X
-- Modify 2009.10.15 Ver1.7 End
      FROM xxcfr_invoice_headers          xih    -- �����w�b�_
          ,xxcfr_invoice_lines            xil    -- ��������
      WHERE xih.invoice_id = xil.invoice_id      -- �ꊇ������ID
        AND EXISTS (SELECT 'X'
                    FROM  xxcfr_bill_customers_v xbcv
                    WHERE xih.bill_cust_code = xbcv.bill_customer_code
                      AND xbcv.receiv_code1  = iv_ar_code1
                      AND xbcv.inv_prt_type  = cv_inv_prt_type -- '3'(EDI)
                   )
        AND ((gv_start_mode_flg = cv_start_mode_b
              AND EXISTS (SELECT 'x'
                          FROM xxcfr_inv_info_transfer xiit  -- ���������n�e�[�u��
                          WHERE xih.request_id = xiit.request_id
                            AND xiit.set_of_books_id = gn_set_of_bks_id
                            AND xiit.org_id = gn_org_id)) OR
             (gv_start_mode_flg = cv_start_mode_h
              AND xih.cutoff_date = gd_target_date ))        -- �p�����[�^�D����
        AND xih.set_of_books_id = gn_set_of_bks_id
        AND xih.org_id = gn_org_id
-- Modify 2009.06.05 Ver1.5 Start
--      ORDER BY xih.vender_code   -- �����R�[�h
--              ,xih.invoice_id    -- �ꊇ������ID
--              ,xil.slip_num      -- �`�[�ԍ�
--              ,xil.note_line_id  -- �sNo
-- Modify 2009.06.16 Ver1.5 Start
--      ORDER BY xih.vender_code                                -- �����R�[�h
      ORDER BY NVL(xih.vender_code, gv_comp_code)             -- �����R�[�h
-- Modify 2009.06.16 Ver1.5 End      
              ,xil.ship_shop_code                             -- �X�R�[�h
              ,NVL(xil.acceptance_date, xil.delivery_date)    -- ������(�[�i��)
              ,xil.slip_num                                   -- �`�[�ԍ�
              ,xil.note_line_id                               -- �sNo
-- Modify 2009.06.05 Ver1.5 End
      ;
--
    TYPE get_edi_data_tbl1 IS TABLE OF get_edi_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_get_edi_data_tbl1    get_edi_data_tbl1; -- �擾���ʊi�[�p
    lt_set_edi_data_tbl1    get_edi_data_tbl1; -- �W�v���ʊi�[�p
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --===============================================================
    -- 
    --===============================================================
    -- �J�[�\���I�[�v��
    OPEN get_edi_data_cur(iv_ar_code1);
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_edi_data_cur BULK COLLECT INTO lt_get_edi_data_tbl1;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_get_edi_data_tbl1.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE get_edi_data_cur;
--
-- Modify 2009.06.23 Ver1.6 Start
    -- �G���[�`�F�b�N�p�̃t���O��������
    lv_chk_err_flg := cv_flag_no;
--
    <<check_loop>>
    FOR i IN 1..(ln_target_cnt) LOOP
      -- �O�񃌃R�[�h�Ɠ`�[�ԍ����قȂ�ꍇ�ɃG���[�`�F�b�N�����s
      IF (i = 1) OR 
         (lt_get_edi_data_tbl1(i).slip_num != NVL(lv_chk_bef_slip,cv_end_slip_num)) OR
         (lt_get_edi_data_tbl1(i).slip_num != NULL)
      THEN
        -- �`�[�ԍ����ꌅ��"I"�̏ꍇ�A�G���[
        IF (lt_get_edi_data_tbl1(i).slip_num = cv_slip_no_chk_i) THEN
--
          --�G���[�`�[�ԍ����b�Z�[�W
          lv_slip_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                        cv_msg_kbn_cfr         -- 'XXCFR'
                                       ,cv_msg_003a04_025      -- �G���[�`�[�ԍ����b�Z�[�W
                                       ,cv_tkn_slip_num        -- �g�[�N��'SLIP_NUM'
                                       ,lt_get_edi_data_tbl1(i).slip_num)
                                     ,1
                                     ,5000);
          FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_slip_warn_msg
          );
--
          -- �G���[�`�F�b�N�p�̃t���O���Z�b�g
          lv_chk_err_flg := cv_flag_yes;
--        
        -- �`�[�ԍ��̈ꌅ�ڂ�"I"�̏ꍇ
        ELSIF (SUBSTRB(lt_get_edi_data_tbl1(i).slip_num, 1, 1) = cv_slip_no_chk_i) THEN
--
          BEGIN
            ln_chk_slip_buf := TO_NUMBER(SUBSTRB(lt_get_edi_data_tbl1(i).slip_num, 2));
          EXCEPTION
            -- *** ���l�ϊ��G���[ ***  
            WHEN num_err_expt THEN
              -- �G���[�`�[�ԍ����b�Z�[�W
              lv_slip_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                            cv_msg_kbn_cfr         -- 'XXCFR'
                                           ,cv_msg_003a04_025      -- �G���[�`�[�ԍ����b�Z�[�W
                                           ,cv_tkn_slip_num        -- �g�[�N��'SLIP_NUM'
                                           ,lt_get_edi_data_tbl1(i).slip_num)
                                         ,1
                                         ,5000);
              FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_slip_warn_msg
              );
--
              -- �G���[�`�F�b�N�p�̃t���O���Z�b�g
              lv_chk_err_flg := cv_flag_yes;
--
           END;
--
         -- �`�[�ԍ��̈ꌅ�ڂ�"I"�ȊO�̏ꍇ
         ELSE
--
           BEGIN
             ln_chk_slip_buf := TO_NUMBER(lt_get_edi_data_tbl1(i).slip_num);
           EXCEPTION
            -- *** ���l�ϊ��G���[ ***
            WHEN num_err_expt THEN
              -- �G���[�`�[�ԍ����b�Z�[�W
              lv_slip_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                            cv_msg_kbn_cfr         -- 'XXCFR'
                                           ,cv_msg_003a04_025      -- �G���[�`�[�ԍ����b�Z�[�W
                                           ,cv_tkn_slip_num        -- �g�[�N��'SLIP_NUM'
                                           ,lt_get_edi_data_tbl1(i).slip_num)
                                         ,1
                                         ,5000);
              FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_slip_warn_msg
              );
--
              -- �G���[�`�F�b�N�p�̃t���O���Z�b�g
              lv_chk_err_flg := cv_flag_yes;
--
          END;
--
        END IF;
      END IF;
--
      -- �`�[�ԍ���ۊ�
      lv_chk_bef_slip := lt_get_edi_data_tbl1(i).slip_num;
--
    END LOOP check_loop;
-- Modify 2009.06.23 Ver1.6 End     
    -- �ϐ��̏�����
    ln_vend_cnt := 1;
    ln_data_cnt := 1;
--
    ln_slip_num    := 0;
    ln_slip_amount := 0;
-- Modify 2009.06.08 Ver1.5 Start
    ln_slip_tax_amount := 0;
-- Modify 2009.06.08 Ver1.5 End
    ln_vend_amount := 0;
    ln_disc_amount := 0;
    ln_retn_amount := 0;
--
    ln_slip_point := 1;
    ln_inv_point  := 1;
    ln_vend_point := 1;
--
-- Modify 2009.06.23 Ver1.6 Start
--    IF (ln_target_cnt > 0) THEN
    -- �Ώی��������݂��邩�A�`�[�ԍ��`�F�b�N�ŃG���[�����݂��Ȃ������ꍇ
    IF (ln_target_cnt > 0)           AND
       (lv_chk_err_flg = cv_flag_no)
    THEN
-- Modify 2009.06.23 Ver1.6 End
--
      <<invoice_loop>>
      FOR i IN 1..(ln_target_cnt + 1) LOOP
        -- �ꌏ�ڂ̏����ł���ꍇ
        IF(i = 1) THEN
          lv_b_slip_num := lt_get_edi_data_tbl1(i).slip_num;
          lv_b_inv_id   := lt_get_edi_data_tbl1(i).invoice_id;
          lv_b_vend_cd  := lt_get_edi_data_tbl1(i).vender_code;
        -- �ŏI���R�[�h�̏����ł���ꍇ
        ELSIF (i = ln_target_cnt + 1) THEN
          -- �_�~�[�R�[�h���u���C�N�ϐ��ɐݒ�
          lt_get_edi_data_tbl1(i).vender_code := cv_end_v_code;
          lt_get_edi_data_tbl1(i).invoice_id  := cv_end_inv_id;
          lt_get_edi_data_tbl1(i).slip_num    := cv_end_slip_num;
        END IF;
--
        -- �u���C�N���ƂɏW�v�X�V
--
        -- �O�s�`�[�ԍ������ݍs�`�[�ԍ��łȂ��ꍇ�A
        -- �`�[�P�ʂ̏W�v������O�s�`�[�ԍ����R�[�h�ɑ΂��čs��
        IF (lv_b_slip_num <> lt_get_edi_data_tbl1(i).slip_num) THEN
          <<slip_loop>>
          FOR j IN ln_slip_point..(ln_data_cnt - 1) LOOP
            -- �������z�����̐ݒ�
            CASE
              -- �}�C�i�X�ł���ꍇ
              WHEN ln_slip_amount < 0 THEN
                lt_set_edi_data_tbl1(j).inv_sign := 1;
              -- �v���X�ł���ꍇ
              ELSE
                lt_set_edi_data_tbl1(j).inv_sign := 0;
            END CASE;
            -- �������z�i��Βl�j�̍X�V
            lt_set_edi_data_tbl1(j).inv_slip_amount := ABS(ln_slip_amount);
-- Modify 2009.06.08 Ver1.5 Start
            -- ����ŋ��z�i��Βl�j�̍X�V
            lt_set_edi_data_tbl1(j).tax_amount := ABS(ln_slip_tax_amount);
-- Modify 2009.06.08 Ver1.5 End
          END LOOP slip_loop;
          -- �������z�i�`�[�P�ʁj�ϐ��N���A
          ln_slip_amount := 0;
-- Modify 2009.06.08 Ver1.5 Start
          -- ����ŋ��z�i�`�[�P�ʁj�ϐ��N���A
          ln_slip_tax_amount := 0;
-- Modify 2009.06.08 Ver1.5 End
          -- �u���C�N�ϐ��X�V
          lv_b_slip_num := lt_get_edi_data_tbl1(i).slip_num;
          -- �`�[�����X�V
          ln_slip_num := ln_slip_num + 1;
          -- �X�V�J�n�ʒu�X�V
          ln_slip_point := ln_data_cnt;
          -- �������z�̏�����
          ln_slip_amount := 0;
        END IF;
--
        -- �O�s�ꊇ������ID�����ݍs�ꊇ������ID�łȂ��ꍇ
        IF (lv_b_inv_id <> lt_get_edi_data_tbl1(i).invoice_id) THEN
          -- �O�s����ŋ敪=�O�ł��O�s�ō��z���ID��NULL�łȂ��ꍇ�A�ō��z���R�[�h�}��
          IF (lt_get_edi_data_tbl1(i-1).tax_type = cv_syohizei_kbn_te) AND
             (lt_get_edi_data_tbl1(i-1).tax_gap_trx_id IS NOT NULL) THEN
--
-- Modify 2009.06.15 Ver1.5 Start
            lv_tax_gap_out_flg := cv_flag_yes;
            -- ����ꊇ������ID���㑱�̃��R�[�h�ɑ��݂��邩�m�F
            <<tax_gap_out_loop>>
            FOR l IN i..(ln_target_cnt) LOOP
              IF (lv_b_inv_id = lt_get_edi_data_tbl1(l).invoice_id) THEN
                -- �ō��z����o�̓t���O��N�ɐݒ�
                lv_tax_gap_out_flg := cv_flag_no;
              END IF;
            END LOOP tax_gap_out_loop;
--
            --�ō��z����o�̓t���O��Y�̏ꍇ�A�ō��z���R�[�h�}��
            IF (lv_tax_gap_out_flg = cv_flag_yes) THEN
--
-- Modify 2009.06.15 Ver1.5 End
            lt_set_edi_data_tbl1(ln_data_cnt).file_rec_type
              := lt_get_edi_data_tbl1(i-1).file_rec_type;                      -- ���R�[�h�敪
-- Modify 2009.05.22 Ver1.4 Start
--            lt_set_edi_data_tbl1(ln_data_cnt).chain_st_code := NULL ;          -- �`�F�[���X�R�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).chain_st_code  
              := lt_get_edi_data_tbl1(i-1).chain_st_code          ;            -- �`�F�[���X�R�[�h
-- Modify 2009.05.22 Ver1.4 End
            lt_set_edi_data_tbl1(ln_data_cnt). inv_creation_day      
              := lt_get_edi_data_tbl1(i-1). inv_creation_day      ;            -- �f�[�^�쐬��
            lt_set_edi_data_tbl1(ln_data_cnt).inv_creation_time      
              := lt_get_edi_data_tbl1(i-1).inv_creation_time      ;            -- �f�[�^�쐬����
            lt_set_edi_data_tbl1(ln_data_cnt).vender_code            
              := lt_get_edi_data_tbl1(i-1).vender_code            ;            -- �d����R�[�h�^�����R�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).itoen_name             
              := lt_get_edi_data_tbl1(i-1).itoen_name             ;            -- �d���於�́^����於�́i�����j
            lt_set_edi_data_tbl1(ln_data_cnt).itoen_kana_name        
              := lt_get_edi_data_tbl1(i-1).itoen_kana_name        ;            -- �d���於�́^����於�́i�J�i�j
            lt_set_edi_data_tbl1(ln_data_cnt).co_code := NULL ;                -- �ЃR�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).object_date_from       
              := lt_get_edi_data_tbl1(i-1).object_date_from       ;            -- �Ώۊ��ԁE��
            lt_set_edi_data_tbl1(ln_data_cnt).object_date_to         
              := lt_get_edi_data_tbl1(i-1).object_date_to         ;            -- �Ώۊ��ԁE��
            lt_set_edi_data_tbl1(ln_data_cnt).cutoff_date            
              := lt_get_edi_data_tbl1(i-1).cutoff_date            ;            -- �������N����
            lt_set_edi_data_tbl1(ln_data_cnt).payment_date           
              := lt_get_edi_data_tbl1(i-1).payment_date           ;            -- �x���N����
            lt_set_edi_data_tbl1(ln_data_cnt).due_months_forword     
              := lt_get_edi_data_tbl1(i-1).due_months_forword     ;            -- �T�C�g����
            lt_set_edi_data_tbl1(ln_data_cnt).cor_slip_ttl           := NULL ; -- �����`�[����
            lt_set_edi_data_tbl1(ln_data_cnt).n_ins_slip_ttl         := NULL ; -- �������`�[����
            lt_set_edi_data_tbl1(ln_data_cnt).vend_rec_num
              := ln_vend_cnt           ;                                       -- ���������R�[�h�ʔ�
            lt_set_edi_data_tbl1(ln_data_cnt).inv_no                 := NULL ; -- ������No�^�����ԍ�
            lt_set_edi_data_tbl1(ln_data_cnt).inv_type               := NULL ; -- �����敪
            lt_set_edi_data_tbl1(ln_data_cnt).pay_type               := NULL ; -- �x���敪
            lt_set_edi_data_tbl1(ln_data_cnt).pay_meth_type          := NULL ; -- �x�����@�敪
            lt_set_edi_data_tbl1(ln_data_cnt).iss_type               := NULL ; -- ���s�敪
            lt_set_edi_data_tbl1(ln_data_cnt).ship_shop_code         := NULL ; -- �X�R�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).ship_cust_name         := NULL ; -- �X�ܖ��́i�����j
            lt_set_edi_data_tbl1(ln_data_cnt).ship_cust_kana_name    := NULL ; -- �X�ܖ��́i�J�i�j
            -- �������z�����̐ݒ�
            CASE
              -- �}�C�i�X�ł���ꍇ
              WHEN lt_get_edi_data_tbl1(i-1).tax_gap_amount < 0 THEN
                lt_set_edi_data_tbl1(ln_data_cnt).inv_sign := 1;
              -- �v���X�ł���ꍇ
              ELSE
                lt_set_edi_data_tbl1(ln_data_cnt).inv_sign := 0;
            END CASE;
            lt_set_edi_data_tbl1(ln_data_cnt).inv_slip_amount        
              := ABS(lt_get_edi_data_tbl1(i-1).tax_gap_amount)       ;         -- �������z�^�x�����z�i��Βl�j
            lt_set_edi_data_tbl1(ln_data_cnt).tax_type               
              := lt_get_edi_data_tbl1(i-1).tax_type               ;            -- ����ŋ敪
            lt_set_edi_data_tbl1(ln_data_cnt).tax_rate               := NULL ; -- ����ŗ�
-- Modify 2009.05.22 Ver1.4 Start
--            lt_set_edi_data_tbl1(ln_data_cnt).tax_amount             
--              := lt_get_edi_data_tbl1(i-1).tax_gap_amount       ;              -- ��������Ŋz�^�x������Ŋz
            lt_set_edi_data_tbl1(ln_data_cnt).tax_amount         
              := ABS(lt_get_edi_data_tbl1(i-1).tax_gap_amount)       ;         -- ��������Ŋz�^�x������Ŋz
-- Modify 2009.05.22 Ver1.4 End
            lt_set_edi_data_tbl1(ln_data_cnt).tax_gap_flg            := 1 ; -- ����ō��z�t���O
            lt_set_edi_data_tbl1(ln_data_cnt).mis_calc_type          := NULL ; -- ��Z�敪
            lt_set_edi_data_tbl1(ln_data_cnt).match_type             := NULL ; -- �}�b�`�敪
            lt_set_edi_data_tbl1(ln_data_cnt).unmatch_pay_amount     := NULL ; -- �A���}�b�`���|�v����z
            lt_set_edi_data_tbl1(ln_data_cnt).overlap_type           := NULL ; -- �_�u���敪
            lt_set_edi_data_tbl1(ln_data_cnt).acceptance_date        := NULL ; -- ������
            lt_set_edi_data_tbl1(ln_data_cnt).month_remit            
              := lt_get_edi_data_tbl1(i-1).month_remit                       ; -- ����
            lt_set_edi_data_tbl1(ln_data_cnt).slip_num               := NULL ; -- �`�[�ԍ�
            lt_set_edi_data_tbl1(ln_data_cnt).note_line_id           := NULL ; -- �sNo
            lt_set_edi_data_tbl1(ln_data_cnt).slip_type              := NULL ; -- �`�[�敪
            lt_set_edi_data_tbl1(ln_data_cnt).classify_type          := NULL ; -- ���ރR�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).customer_dept_code     := NULL ; -- ����敔��R�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).customer_division_code := NULL ; -- �ۃR�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).sold_return_type       := NULL ; -- ����ԕi�敪
            lt_set_edi_data_tbl1(ln_data_cnt).nichiriu_by_way_type   := NULL ; -- �j�`���E�o�R�敪
            lt_set_edi_data_tbl1(ln_data_cnt).sale_type              := NULL ; -- �����敪
            lt_set_edi_data_tbl1(ln_data_cnt).direct_num             := NULL ; -- ��No
            lt_set_edi_data_tbl1(ln_data_cnt).po_date                := NULL ; -- ������
            lt_set_edi_data_tbl1(ln_data_cnt).delivery_date          := NULL ; -- �[�i���^�ԕi��
            lt_set_edi_data_tbl1(ln_data_cnt).item_code              := NULL ; -- ���i�R�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).item_name              := NULL ; -- ���i���i�����j
            lt_set_edi_data_tbl1(ln_data_cnt).item_kana_name         := NULL ; -- ���i��(�J�i)
            lt_set_edi_data_tbl1(ln_data_cnt).quantity               := NULL ; -- �[�i����
            lt_set_edi_data_tbl1(ln_data_cnt).unit_price             := NULL ; -- ���P��
            lt_set_edi_data_tbl1(ln_data_cnt).sold_amount            := NULL ; -- �������z
            lt_set_edi_data_tbl1(ln_data_cnt).sold_location_code     := NULL ; -- ���l�R�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).chain_st_area          := NULL ; -- �`�F�[���X�ŗL�G���A
-- Modify 2009.10.15 Ver1.7 Start
            lt_set_edi_data_tbl1(ln_data_cnt).jan_code               := NULL ; -- JAN�R�[�h
            lt_set_edi_data_tbl1(ln_data_cnt).num_of_cases           := NULL ; -- �P�[�X����
            lt_set_edi_data_tbl1(ln_data_cnt).medium_class           := NULL ; -- �󒍃\�[�X
-- Modify 2009.10.15 Ver1.7 End
            -- �����z���v�ɐō��z�����Z
            ln_vend_amount := ln_vend_amount + lt_get_edi_data_tbl1(i-1).tax_gap_amount;
            -- �ϐ����Z
            ln_data_cnt := ln_data_cnt + 1; -- �W�v���ʊi�[�惌�R�[�h�J�E���^
            ln_vend_cnt := ln_vend_cnt + 1; -- ���������R�[�h�J�E���^
            -- �������z�X�V�J�n�ʒu�X�V
            ln_slip_point := ln_data_cnt;
          END IF;
--
-- Modify 2009.06.15 Ver1.5 Start
          END IF;
-- Modify 2009.06.15 Ver1.5 End
          -- �u���C�N�ϐ��X�V
          lv_b_inv_id := lt_get_edi_data_tbl1(i).invoice_id;
        END IF;
--
        -- �O�s�����R�[�h�����ݍs�����R�[�h�łȂ��ꍇ�A
        IF (lv_b_vend_cd <> lt_get_edi_data_tbl1(i).vender_code) THEN
-- Modify 2009.06.05 Ver1.5 Start
          -- ���ݍs�����R�[�h���ŏI���R�[�h(�_�~�[�R�[�h)�̏ꍇ�A
          IF (lt_get_edi_data_tbl1(i).vender_code = cv_end_v_code) THEN
-- Modify 2009.06.05 Ver1.5 End
            -- ���z�X�V�������[�v
            <<vend_loop>>
            FOR k IN ln_vend_point..(ln_data_cnt - 1) LOOP
              -- �������v���z�^�x�����v���z�̍X�V
              lt_set_edi_data_tbl1(k).inv_amount := ln_vend_amount;
              -- �l�������v�̍X�V
              lt_set_edi_data_tbl1(k).discount_amount := ABS(ln_disc_amount);
              -- �ԕi���v�̍X�V
              lt_set_edi_data_tbl1(k).return_amount := ABS(ln_retn_amount);
              -- �`�[�����̍X�V
              lt_set_edi_data_tbl1(k).inv_slip_ttl := ln_slip_num;
            END LOOP vend_loop;
--
          -- �ϐ��̏�����
-- Modify 2009.06.05 Ver1.5 Start
--          ln_vend_cnt    := 1; -- ���������R�[�h�J�E���^
-- Modify 2009.06.05 Ver1.5 End
            ln_vend_amount := 0; -- �������z���v
            ln_disc_amount := 0; -- �l�������v
            ln_retn_amount := 0; -- �ԕi���v
            ln_slip_num    := 0; -- �`�[����
-- Modify 2009.06.10 Ver1.5 Start
--            -- �u���C�N�ϐ��X�V
--            lv_b_vend_cd := lt_get_edi_data_tbl1(i).vender_code;
-- Modify 2009.06.10 Ver1.5 End
            -- �X�V�J�n�ʒu�X�V
            ln_vend_point := ln_data_cnt;
-- Modify 2009.06.05 Ver1.5 Start
          END IF;
--
        -- �u���C�N�ϐ��X�V
        lv_b_vend_cd := lt_get_edi_data_tbl1(i).vender_code;
--
        -- �ϐ��̏�����
        ln_vend_cnt  := 1; -- ���������R�[�h�J�E���^
--
-- Modify 2009.06.05 Ver1.5 End
        END IF;
--
        -- �I������
        IF (i = ln_target_cnt + 1) THEN
          EXIT invoice_loop;
        END IF;
--
        -- ���v�l���Z
        ln_slip_amount := ln_slip_amount + lt_get_edi_data_tbl1(i).inv_slip_amount; -- �������z�^�x�����z
-- Modify 2009.06.05 Ver1.5 Start
        ln_slip_tax_amount := ln_slip_tax_amount + lt_get_edi_data_tbl1(i).tax_amount; -- ��������Ŋz�^�x������Ŋz
-- Modify 2009.06.05 Ver1.5 End        
        ln_vend_amount := ln_vend_amount + lt_get_edi_data_tbl1(i).inv_amount;      -- �������v���z�^�x�����v���z
        ln_disc_amount := ln_disc_amount + lt_get_edi_data_tbl1(i).discount_amount; -- �l�����v���z
        ln_retn_amount := ln_retn_amount + lt_get_edi_data_tbl1(i).return_amount;   -- �ԕi���v���z
--
        -- �o�͗p�ϐ��ɐݒ�
        lt_set_edi_data_tbl1(ln_data_cnt).file_rec_type
          := lt_get_edi_data_tbl1(i).file_rec_type          ; -- ���R�[�h�敪
        lt_set_edi_data_tbl1(ln_data_cnt).chain_st_code          
          := lt_get_edi_data_tbl1(i).chain_st_code          ; -- �`�F�[���X�R�[�h
        lt_set_edi_data_tbl1(ln_data_cnt). inv_creation_day      
          := lt_get_edi_data_tbl1(i). inv_creation_day      ;  -- �f�[�^�쐬��
        lt_set_edi_data_tbl1(ln_data_cnt).inv_creation_time      
          := lt_get_edi_data_tbl1(i).inv_creation_time      ; -- �f�[�^�쐬����
        lt_set_edi_data_tbl1(ln_data_cnt).vender_code            
          := lt_get_edi_data_tbl1(i).vender_code            ; -- �d����R�[�h�^�����R�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).itoen_name             
          := lt_get_edi_data_tbl1(i).itoen_name             ; -- �d���於�́^����於�́i�����j
        lt_set_edi_data_tbl1(ln_data_cnt).itoen_kana_name        
          := lt_get_edi_data_tbl1(i).itoen_kana_name        ; -- �d���於�́^����於�́i�J�i�j
        lt_set_edi_data_tbl1(ln_data_cnt).co_code                
          := lt_get_edi_data_tbl1(i).co_code                ; -- �ЃR�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).object_date_from       
          := lt_get_edi_data_tbl1(i).object_date_from       ; -- �Ώۊ��ԁE��
        lt_set_edi_data_tbl1(ln_data_cnt).object_date_to         
          := lt_get_edi_data_tbl1(i).object_date_to         ; -- �Ώۊ��ԁE��
        lt_set_edi_data_tbl1(ln_data_cnt).cutoff_date            
          := lt_get_edi_data_tbl1(i).cutoff_date            ; -- �������N����
        lt_set_edi_data_tbl1(ln_data_cnt).payment_date           
          := lt_get_edi_data_tbl1(i).payment_date           ; -- �x���N����
        lt_set_edi_data_tbl1(ln_data_cnt).due_months_forword     
          := lt_get_edi_data_tbl1(i).due_months_forword     ; -- �T�C�g����
        lt_set_edi_data_tbl1(ln_data_cnt).inv_slip_ttl           
          := ln_slip_num                                    ; -- �`�[����
        lt_set_edi_data_tbl1(ln_data_cnt).cor_slip_ttl           
          := lt_get_edi_data_tbl1(i).cor_slip_ttl           ; -- �����`�[����
        lt_set_edi_data_tbl1(ln_data_cnt).n_ins_slip_ttl         
          := lt_get_edi_data_tbl1(i).n_ins_slip_ttl         ; -- �������`�[����
        lt_set_edi_data_tbl1(ln_data_cnt).vend_rec_num           
          := ln_vend_cnt                                    ; -- ���������R�[�h�ʔ�
        lt_set_edi_data_tbl1(ln_data_cnt).inv_no                 
          := lt_get_edi_data_tbl1(i).inv_no                 ; -- ������No�^�����ԍ�
        lt_set_edi_data_tbl1(ln_data_cnt).inv_type               
          := lt_get_edi_data_tbl1(i).inv_type               ; -- �����敪
        lt_set_edi_data_tbl1(ln_data_cnt).pay_type               
          := lt_get_edi_data_tbl1(i).pay_type               ; -- �x���敪
        lt_set_edi_data_tbl1(ln_data_cnt).pay_meth_type          
          := lt_get_edi_data_tbl1(i).pay_meth_type          ; -- �x�����@�敪
        lt_set_edi_data_tbl1(ln_data_cnt).iss_type               
          := lt_get_edi_data_tbl1(i).iss_type               ; -- ���s�敪
        lt_set_edi_data_tbl1(ln_data_cnt).ship_shop_code         
          := lt_get_edi_data_tbl1(i).ship_shop_code         ; -- �X�R�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).ship_cust_name         
          := lt_get_edi_data_tbl1(i).ship_cust_name         ; -- �X�ܖ��́i�����j
        lt_set_edi_data_tbl1(ln_data_cnt).ship_cust_kana_name    
          := lt_get_edi_data_tbl1(i).ship_cust_kana_name    ; -- �X�ܖ��́i�J�i�j
        lt_set_edi_data_tbl1(ln_data_cnt).inv_sign               
          := lt_get_edi_data_tbl1(i).inv_sign               ; -- �������z�����^��������Ŋz����
        lt_set_edi_data_tbl1(ln_data_cnt).inv_slip_amount        
          := lt_get_edi_data_tbl1(i).inv_slip_amount        ; -- �������z�^�x�����z
        lt_set_edi_data_tbl1(ln_data_cnt).tax_type               
          := lt_get_edi_data_tbl1(i).tax_type               ; -- ����ŋ敪
        lt_set_edi_data_tbl1(ln_data_cnt).tax_rate               
          := lt_get_edi_data_tbl1(i).tax_rate               ; -- ����ŗ�
-- Modify 2009.05.22 Ver1.4 Start
--        lt_set_edi_data_tbl1(ln_data_cnt).tax_amount             
--          := lt_get_edi_data_tbl1(i).tax_amount             ; -- ��������Ŋz�^�x������Ŋz
        lt_set_edi_data_tbl1(ln_data_cnt).tax_amount
          := ABS(lt_get_edi_data_tbl1(i).tax_amount)        ; -- ��������Ŋz�^�x������Ŋz
-- Modify 2009.05.22 Ver1.4 End
        lt_set_edi_data_tbl1(ln_data_cnt).tax_gap_flg            
          := lt_get_edi_data_tbl1(i).tax_gap_flg            ; -- ����ō��z�t���O
        lt_set_edi_data_tbl1(ln_data_cnt).mis_calc_type          
          := lt_get_edi_data_tbl1(i).mis_calc_type          ; -- ��Z�敪
        lt_set_edi_data_tbl1(ln_data_cnt).match_type             
          := lt_get_edi_data_tbl1(i).match_type             ; -- �}�b�`�敪
        lt_set_edi_data_tbl1(ln_data_cnt).unmatch_pay_amount     
          := lt_get_edi_data_tbl1(i).unmatch_pay_amount     ; -- �A���}�b�`���|�v����z
        lt_set_edi_data_tbl1(ln_data_cnt).overlap_type           
          := lt_get_edi_data_tbl1(i).overlap_type           ; -- �_�u���敪
        lt_set_edi_data_tbl1(ln_data_cnt).acceptance_date        
          := lt_get_edi_data_tbl1(i).acceptance_date        ; -- ������
        lt_set_edi_data_tbl1(ln_data_cnt).month_remit            
          := lt_get_edi_data_tbl1(i).month_remit            ; -- ����
        lt_set_edi_data_tbl1(ln_data_cnt).slip_num               
          := lt_get_edi_data_tbl1(i).slip_num               ; -- �`�[�ԍ�
        lt_set_edi_data_tbl1(ln_data_cnt).note_line_id           
          := lt_get_edi_data_tbl1(i).note_line_id           ; -- �sNo
        lt_set_edi_data_tbl1(ln_data_cnt).slip_type              
          := lt_get_edi_data_tbl1(i).slip_type              ; -- �`�[�敪
        lt_set_edi_data_tbl1(ln_data_cnt).classify_type          
          := lt_get_edi_data_tbl1(i).classify_type          ; -- ���ރR�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).customer_dept_code     
          := lt_get_edi_data_tbl1(i).customer_dept_code     ; -- ����敔��R�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).customer_division_code 
          := lt_get_edi_data_tbl1(i).customer_division_code ; -- �ۃR�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).sold_return_type       
          := lt_get_edi_data_tbl1(i).sold_return_type       ; -- ����ԕi�敪
        lt_set_edi_data_tbl1(ln_data_cnt).nichiriu_by_way_type   
          := lt_get_edi_data_tbl1(i).nichiriu_by_way_type   ; -- �j�`���E�o�R�敪
        lt_set_edi_data_tbl1(ln_data_cnt).sale_type              
          := lt_get_edi_data_tbl1(i).sale_type              ; -- �����敪
        lt_set_edi_data_tbl1(ln_data_cnt).direct_num             
          := lt_get_edi_data_tbl1(i).direct_num             ; -- ��No
        lt_set_edi_data_tbl1(ln_data_cnt).po_date                
          := lt_get_edi_data_tbl1(i).po_date                ; -- ������
        lt_set_edi_data_tbl1(ln_data_cnt).delivery_date          
          := lt_get_edi_data_tbl1(i).delivery_date          ; -- �[�i���^�ԕi��
        lt_set_edi_data_tbl1(ln_data_cnt).item_code              
          := lt_get_edi_data_tbl1(i).item_code              ; -- ���i�R�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).item_name              
          := lt_get_edi_data_tbl1(i).item_name              ; -- ���i���i�����j
        lt_set_edi_data_tbl1(ln_data_cnt).item_kana_name         
          := lt_get_edi_data_tbl1(i).item_kana_name         ; -- ���i��(�J�i)
        lt_set_edi_data_tbl1(ln_data_cnt).quantity               
          := lt_get_edi_data_tbl1(i).quantity               ; -- �[�i����
        lt_set_edi_data_tbl1(ln_data_cnt).unit_price             
          := lt_get_edi_data_tbl1(i).unit_price             ; -- ���P��
        lt_set_edi_data_tbl1(ln_data_cnt).sold_amount            
          := lt_get_edi_data_tbl1(i).sold_amount            ; -- �������z
        lt_set_edi_data_tbl1(ln_data_cnt).sold_location_code     
          := lt_get_edi_data_tbl1(i).sold_location_code     ; -- ���l�R�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).chain_st_area          
          := lt_get_edi_data_tbl1(i).chain_st_area          ; -- �`�F�[���X�ŗL�G���A
-- Modify 2009.10.15 Ver1.7 Start
        lt_set_edi_data_tbl1(ln_data_cnt).jan_code               
          := lt_get_edi_data_tbl1(i).jan_code               ; -- JAN�R�[�h
        lt_set_edi_data_tbl1(ln_data_cnt).num_of_cases           
          := lt_get_edi_data_tbl1(i).num_of_cases           ; -- �P�[�X����
        lt_set_edi_data_tbl1(ln_data_cnt).medium_class           
          := lt_get_edi_data_tbl1(i).medium_class           ; -- �󒍃\�[�X
-- Modify 2009.10.15 Ver1.7 End
--
        -- �ϐ����Z
        ln_data_cnt := ln_data_cnt + 1; -- �W�v���ʊi�[�惌�R�[�h�J�E���^
        ln_vend_cnt := ln_vend_cnt + 1; -- ���������R�[�h�J�E���^
--
      END LOOP invoice_loop;
--
    -- ====================================================
    -- �w�b�_�o�͏���(A-6)
    -- ====================================================
      -- EDI�w�b�_�擾����
      xxccp_ifcommon_pkg.add_edi_header_footer( iv_add_area       => cv_add_area_h            -- �t�^�敪
                                               ,iv_from_series    => gv_edi_operation_code    -- �h�e���Ɩ��n��R�[�h
                                               ,iv_base_code      => gv_edi_output_dept       -- ���_�R�[�h
                                               ,iv_base_name      => gv_edi_output_dept_name  -- ���_����
                                               ,iv_chain_code     => gv_edi_chain_code        -- �`�F�[���X�R�[�h
                                               ,iv_chain_name     => gv_edi_chain_name        -- �`�F�[���X����
                                               ,iv_data_kind      => gv_edi_data_code         -- �f�[�^��R�[�h
                                               ,iv_row_number     => cv_row_number            -- ���񏈗��ԍ�
                                               ,in_num_of_records => NULL                     -- ���R�[�h����
                                               ,ov_retcode        => lv_retcode
                                               ,ov_output         => lv_output
                                               ,ov_errbuf         => lv_errbuf
                                               ,ov_errmsg         => lv_errmsg);
      IF (lv_retcode = cv_status_error) THEN
        -- ���[�J����`��O�����B
        RAISE edi_func_h_expt;
      END IF;
--
    -- ====================================================
    -- EDI�o�̓t�@�C��OPEN����(A-5)
    -- ====================================================
      lf_file_hand := UTL_FILE.FOPEN
                        ( gv_edi_data_filepath
                         ,gv_edi_data_filename
                         ,cv_open_mode_w
                        ) ;
--
      -- �w�b�_���R�[�h�̏�������
      UTL_FILE.PUT_LINE( lf_file_hand, lv_output ) ;
--
      -- ====================================================
      -- �擾�f�[�^�o�͏���(A-7)
      -- ====================================================
--
        ln_rec_cnt := 0;
        <<out_loop>>
        FOR ln_loop_cnt IN lt_set_edi_data_tbl1.FIRST..lt_set_edi_data_tbl1.LAST LOOP
--
          -- �����`�F�b�N
          -- ���R�[�h�敪
          set_edi_char(1                                                -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).file_rec_type  -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
          lt_set_edi_data_tbl1(ln_loop_cnt).file_rec_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �`�F�[���X�R�[�h
          set_edi_char(3                                                -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_code      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
          lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �d����R�[�h�^�����R�[�h
          set_edi_char(6                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).vender_code    -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
          lt_set_edi_data_tbl1(ln_loop_cnt).vender_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ����於�́i�����j
          set_edi_char(7                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).itoen_name    -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).itoen_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ����於�́i�J�i�j
          set_edi_char(8                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).itoen_kana_name      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).itoen_kana_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �ЃR�[�h
          set_edi_char(9                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).co_code      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).co_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
--
          -- �T�C�g����
          set_edi_char(14                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).due_months_forword      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).due_months_forword := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �`�[����
          set_edi_char(15                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_ttl      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_ttl := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �����`�[����
          set_edi_char(16                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).cor_slip_ttl      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).cor_slip_ttl := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �������`�[����
          set_edi_char(17                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).n_ins_slip_ttl      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).n_ins_slip_ttl := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ���������R�[�h�ʔ�
          set_edi_char(18                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).vend_rec_num      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).vend_rec_num := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ������No�^�����ԍ�
          set_edi_char(19                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_no      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_no := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �����敪
          set_edi_char(20                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �x���敪
          set_edi_char(21                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).pay_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).pay_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �x�����@�敪
          set_edi_char(22                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).pay_meth_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).pay_meth_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ���s�敪
          set_edi_char(23                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).iss_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).iss_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �X�R�[�h
          set_edi_char(24                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).ship_shop_code      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).ship_shop_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �X�ܖ��́i�����j
          set_edi_char(25                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_name      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �X�ܖ��́i�J�i�j
          set_edi_char(26                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_kana_name      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_kana_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �������z����
          set_edi_char(27                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_sign      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_sign := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �������z�^�x�����z
          set_edi_char(28                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_amount      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
         -- ����ŋ敪
          set_edi_char(29                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).tax_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).tax_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ����ŗ�
          set_edi_char(30                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).tax_rate      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).tax_rate := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ��������Ŋz
          set_edi_char(31                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).tax_amount      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).tax_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ����ō��z�t���O
          set_edi_char(32                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).tax_gap_flg      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).tax_gap_flg := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ��Z�敪
          set_edi_char(33                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).mis_calc_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).mis_calc_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �}�b�`�敪
          set_edi_char(34                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).match_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).match_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �A���}�b�`���|�v����z
          set_edi_char(35                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).unmatch_pay_amount      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).unmatch_pay_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �_�u���敪
          set_edi_char(36                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).overlap_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).overlap_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ����
          set_edi_char(38                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).month_remit      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).month_remit := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �`�[�ԍ�
          set_edi_char(39                                               -- ���ڏ�
                      ,CASE
                         WHEN lt_set_edi_data_tbl1(ln_loop_cnt).slip_num = cv_nul_slip_num THEN
                           NULL
                         ELSE
                           lt_set_edi_data_tbl1(ln_loop_cnt).slip_num
                         END                                            -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).slip_num := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �sNo
          set_edi_char(40                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �`�[�敪
          set_edi_char(41                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).slip_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ���ރR�[�h
          set_edi_char(42                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).classify_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).classify_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ����敔��R�[�h
          set_edi_char(43                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).customer_dept_code      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).customer_dept_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �ۃR�[�h
          set_edi_char(44                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).customer_division_code      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).customer_division_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ����ԕi�敪
          set_edi_char(45                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).sold_return_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).sold_return_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �j�`���E�o�R�敪
          set_edi_char(46                                              -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).nichiriu_by_way_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).nichiriu_by_way_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �����敪
          set_edi_char(47                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).sale_type      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).sale_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ��No
          set_edi_char(48                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).direct_num      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).direct_num := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ���i�R�[�h
          set_edi_char(51                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).item_code      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).item_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ���i���i�����j
          set_edi_char(52                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).item_name      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).item_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ���i��(�J�i)
          set_edi_char(53                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).item_kana_name      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).item_kana_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �[�i����
          set_edi_char(54                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).quantity      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).quantity := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ���P��
          set_edi_char(55                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).unit_price      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).unit_price := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �������z
          set_edi_char(56                                               -- ���ڏ�
                      ,TO_CHAR(lt_set_edi_data_tbl1(ln_loop_cnt).sold_amount)      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).sold_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ���l�R�[�h
          set_edi_char(57                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).sold_location_code      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).sold_location_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �`�F�[���X�ŗL�G���A
          set_edi_char(58                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_area      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_area := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �������v���z�^�x�����v���z
          set_edi_char(59                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_amount      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �l�����v���z
          set_edi_char(60                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).discount_amount      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).discount_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �ԕi���v���z
          set_edi_char(61                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).return_amount      -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).return_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
-- Modify 2009.10.15 Ver1.7 Start
          -- JAN�R�[�h
          set_edi_char(62                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).jan_code       -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).jan_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �P�[�X����
          set_edi_char(63                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).num_of_cases   -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).num_of_cases := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- �󒍃\�[�X
          set_edi_char(64                                               -- ���ڏ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).medium_class   -- �ϊ��Ώە�����
                      ,ln_loop_cnt                                      -- ���R�[�h�ʔ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- �`�[�ԍ�
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- �`�[�sNo
                      ,lv_output_str                                    -- �߂�l
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).medium_class := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
-- Modify 2009.10.15 Ver1.7 End
--
          -- �o�͕�����쐬
          lv_edi_text := pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).file_rec_type
                                     ,gt_edi_item_tab(1).data_type
                                     ,gt_edi_item_tab(1).edi_length)                                                       -- ���R�[�h�敪
                      || pad_edi_char(ln_loop_cnt
                                     ,gt_edi_item_tab(2).data_type
                                     ,gt_edi_item_tab(2).edi_length)                                                       -- ���R�[�h�ʔ�
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_code
                                     ,gt_edi_item_tab(3).data_type
                                     ,gt_edi_item_tab(3).edi_length)                                                       -- �`�F�[���X�R�[�h
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt). inv_creation_day
                                     ,cv_trn_format_d)                                         -- �f�[�^�쐬��
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).inv_creation_time
                                     ,cv_trn_format_t)                                         -- �f�[�^�쐬����
                      || pad_edi_char(CASE
                                        WHEN lt_set_edi_data_tbl1(ln_loop_cnt).vender_code = cv_nul_v_code THEN
                                          NULL
                                        ELSE
                                          lt_set_edi_data_tbl1(ln_loop_cnt).vender_code
                                        END
                                     ,gt_edi_item_tab(6).data_type
                                     ,gt_edi_item_tab(6).edi_length)                           -- �����R�[�h
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).itoen_name
                                     ,gt_edi_item_tab(7).data_type
                                     ,gt_edi_item_tab(7).edi_length)                           -- ����於�́i�����j
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).itoen_kana_name
                                     ,gt_edi_item_tab(8).data_type
                                     ,gt_edi_item_tab(8).edi_length)                           -- ����於�́i�J�i�j
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).co_code
                                     ,gt_edi_item_tab(9).data_type
                                     ,gt_edi_item_tab(9).edi_length)                           -- �ЃR�[�h
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).object_date_from
                                     ,cv_trn_format_d)                                         -- �Ώۊ��ԁE��
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).object_date_to
                                     ,cv_trn_format_d)                                         -- �Ώۊ��ԁE��
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).cutoff_date
                                     ,cv_trn_format_d)                                         -- �������N����
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).payment_date
                                     ,cv_trn_format_d)                                         -- �x���N����
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).due_months_forword
                                     ,gt_edi_item_tab(14).data_type
                                     ,gt_edi_item_tab(14).edi_length)                              -- �T�C�g����
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_ttl
                                     ,gt_edi_item_tab(15).data_type
                                     ,gt_edi_item_tab(15).edi_length)                              -- �`�[����
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).cor_slip_ttl
                                     ,gt_edi_item_tab(16).data_type
                                     ,gt_edi_item_tab(16).edi_length)                              -- �����`�[����
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).n_ins_slip_ttl
                                     ,gt_edi_item_tab(17).data_type
                                     ,gt_edi_item_tab(17).edi_length)                              -- �������`�[����
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).vend_rec_num
                                     ,gt_edi_item_tab(18).data_type
                                     ,gt_edi_item_tab(18).edi_length)                              -- ���������R�[�h�ʔ�
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_no
                                     ,gt_edi_item_tab(19).data_type
                                     ,gt_edi_item_tab(19).edi_length)                             -- ������No�^�����ԍ�
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_type
                                     ,gt_edi_item_tab(20).data_type
                                     ,gt_edi_item_tab(20).edi_length)                              -- �����敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).pay_type
                                     ,gt_edi_item_tab(21).data_type
                                     ,gt_edi_item_tab(21).edi_length)                              -- �x���敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).pay_meth_type
                                     ,gt_edi_item_tab(22).data_type
                                     ,gt_edi_item_tab(22).edi_length)                              -- �x�����@�敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).iss_type
                                     ,gt_edi_item_tab(23).data_type
                                     ,gt_edi_item_tab(23).edi_length)                              -- ���s�敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).ship_shop_code
                                     ,gt_edi_item_tab(24).data_type
                                     ,gt_edi_item_tab(24).edi_length)                             -- �X�R�[�h
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_name
                                     ,gt_edi_item_tab(25).data_type
                                     ,gt_edi_item_tab(25).edi_length)                            -- �X�ܖ��́i�����j
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_kana_name
                                     ,gt_edi_item_tab(26).data_type
                                     ,gt_edi_item_tab(26).edi_length)                             -- �X�ܖ��́i�J�i�j
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_sign
                                     ,gt_edi_item_tab(27).data_type
                                     ,gt_edi_item_tab(27).edi_length)                              -- �������z����
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_amount
                                     ,gt_edi_item_tab(28).data_type
                                     ,gt_edi_item_tab(28).edi_length)                             -- �������z�^�x�����z
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).tax_type
                                     ,gt_edi_item_tab(29).data_type
                                     ,gt_edi_item_tab(29).edi_length)                              -- ����ŋ敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).tax_rate
                                     ,gt_edi_item_tab(30).data_type
                                     ,gt_edi_item_tab(30).edi_length)                              -- ����ŗ�
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).tax_amount
                                     ,gt_edi_item_tab(31).data_type
                                     ,gt_edi_item_tab(31).edi_length)                             -- ��������Ŋz
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).tax_gap_flg
                                     ,gt_edi_item_tab(32).data_type
                                     ,gt_edi_item_tab(32).edi_length)                              -- ����ō��z�t���O
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).mis_calc_type
                                     ,gt_edi_item_tab(33).data_type
                                     ,gt_edi_item_tab(33).edi_length)                              -- ��Z�敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).match_type
                                     ,gt_edi_item_tab(34).data_type
                                     ,gt_edi_item_tab(34).edi_length)                              -- �}�b�`�敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).unmatch_pay_amount
                                     ,gt_edi_item_tab(35).data_type
                                     ,gt_edi_item_tab(35).edi_length)                             -- �A���}�b�`���|�v����z
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).overlap_type
                                     ,gt_edi_item_tab(36).data_type
                                     ,gt_edi_item_tab(36).edi_length)                              -- �_�u���敪
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).acceptance_date
                                     ,cv_trn_format_d)                                         -- ������
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).month_remit
                                     ,gt_edi_item_tab(38).data_type
                                     ,gt_edi_item_tab(38).edi_length)                                                       -- ����
                      || pad_edi_char(CASE
                                        WHEN lt_set_edi_data_tbl1(ln_loop_cnt).slip_num = cv_nul_slip_num THEN
                                          NULL
-- Modify 2009.06.23 Ver1.6 Start
                                        WHEN SUBSTRB(lt_set_edi_data_tbl1(ln_loop_cnt).slip_num, 1, 1) = cv_slip_no_chk_i THEN
                                          SUBSTRB(lt_set_edi_data_tbl1(ln_loop_cnt).slip_num, 2)
-- Modify 2009.06.23 Ver1.6 End
                                        ELSE
                                          lt_set_edi_data_tbl1(ln_loop_cnt).slip_num
                                        END
                                     ,gt_edi_item_tab(39).data_type
                                     ,gt_edi_item_tab(39).edi_length)                                                      -- �`�[�ԍ�
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id
                                     ,gt_edi_item_tab(40).data_type
                                     ,gt_edi_item_tab(40).edi_length)                                                       -- �sNo
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).slip_type
                                     ,gt_edi_item_tab(41).data_type
                                     ,gt_edi_item_tab(41).edi_length)                                                       -- �`�[�敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).classify_type
                                     ,gt_edi_item_tab(42).data_type
                                     ,gt_edi_item_tab(42).edi_length)                                                       -- ���ރR�[�h
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).customer_dept_code
                                     ,gt_edi_item_tab(43).data_type
                                     ,gt_edi_item_tab(43).edi_length)                                                       -- ����敔��R�[�h
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).customer_division_code
                                     ,gt_edi_item_tab(44).data_type
                                     ,gt_edi_item_tab(44).edi_length)                                                       -- �ۃR�[�h
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).sold_return_type
                                     ,gt_edi_item_tab(45).data_type
                                     ,gt_edi_item_tab(45).edi_length)                                                       -- ����ԕi�敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).nichiriu_by_way_type
                                     ,gt_edi_item_tab(46).data_type
                                     ,gt_edi_item_tab(46).edi_length)                                                       -- �j�`���E�o�R�敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).sale_type
                                     ,gt_edi_item_tab(47).data_type
                                     ,gt_edi_item_tab(47).edi_length)                                                       -- �����敪
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).direct_num
                                     ,gt_edi_item_tab(48).data_type
                                     ,gt_edi_item_tab(48).edi_length)                                                       -- ��No
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).po_date
                                     ,cv_trn_format_d)                                         -- ������
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).delivery_date
                                     ,cv_trn_format_d)                                         -- �[�i���^�ԕi��
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).item_code
                                     ,gt_edi_item_tab(51).data_type
                                     ,gt_edi_item_tab(51).edi_length)                                                       -- ���i�R�[�h
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).item_name
                                     ,gt_edi_item_tab(52).data_type
                                     ,gt_edi_item_tab(52).edi_length)                                                      -- ���i���i�����j
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).item_kana_name
                                     ,gt_edi_item_tab(53).data_type
                                     ,gt_edi_item_tab(53).edi_length)                                                      -- ���i��(�J�i)
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).quantity
                                     ,gt_edi_item_tab(54).data_type
                                     ,gt_edi_item_tab(54).edi_length)                                                      -- �[�i����
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).unit_price
                                     ,gt_edi_item_tab(55).data_type
                                     ,gt_edi_item_tab(55).edi_length)                                                      -- ���P��
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).sold_amount
                                     ,gt_edi_item_tab(56).data_type
                                     ,gt_edi_item_tab(56).edi_length)                                                      -- �������z
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).sold_location_code
                                     ,gt_edi_item_tab(57).data_type
                                     ,gt_edi_item_tab(57).edi_length)                                                       -- ���l�R�[�h
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_area
                                     ,gt_edi_item_tab(58).data_type
                                     ,gt_edi_item_tab(58).edi_length)                                                     -- �`�F�[���X�ŗL�G���A
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_amount
                                     ,gt_edi_item_tab(59).data_type
                                     ,gt_edi_item_tab(59).edi_length)                                                      -- �������v���z�^�x�����v���z
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).discount_amount
                                     ,gt_edi_item_tab(60).data_type
                                     ,gt_edi_item_tab(60).edi_length)                                                      -- �l�����v���z
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).return_amount
                                     ,gt_edi_item_tab(61).data_type
                                     ,gt_edi_item_tab(61).edi_length)                                                      -- �ԕi���v���z
-- Modify 2009.10.15 Ver1.7 Start
-- Modify 2009.05.08 Ver1.3 Start
--                      || pad_edi_char(null
--                                     ,gt_edi_item_tab(62).data_type
--                                     ,gt_edi_item_tab(62).edi_length)                                                      -- �\���G���A
-- Modify 2009.05.08 Ver1.3 End
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).jan_code
                                     ,gt_edi_item_tab(62).data_type
                                     ,gt_edi_item_tab(62).edi_length)                                                      -- JAN�R�[�h
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).num_of_cases
                                     ,gt_edi_item_tab(63).data_type
                                     ,gt_edi_item_tab(63).edi_length)                                                      -- �P�[�X����
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).medium_class
                                     ,gt_edi_item_tab(64).data_type
                                     ,gt_edi_item_tab(64).edi_length)                                                      -- �󒍃\�[�X
                      || pad_edi_char(null
                                     ,gt_edi_item_tab(65).data_type
                                     ,gt_edi_item_tab(65).edi_length)                                                      -- �\���G���A
-- Modify 2009.10.15 Ver1.7 End
                      ;
--
          -- ====================================================
          -- �t�@�C����������
          -- ====================================================
          UTL_FILE.PUT_LINE( lf_file_hand, lv_edi_text ) ;
--
          -- ====================================================
          -- ���������J�E���g�A�b�v
          -- ====================================================
          ln_rec_cnt := ln_rec_cnt + 1;
--
        END LOOP out_loop;
--
      -- ====================================================
      -- �g���C���o�͏���(A-8)
      -- ====================================================
      -- EDI�t�b�^�擾����
      xxccp_ifcommon_pkg.add_edi_header_footer( iv_add_area       => cv_add_area_f -- �t�^�敪
                                               ,iv_from_series    => NULL          -- �h�e���Ɩ��n��R�[�h
                                               ,iv_base_code      => NULL          -- ���_�R�[�h
                                               ,iv_base_name      => NULL          -- ���_����
                                               ,iv_chain_code     => NULL          -- �`�F�[���X�R�[�h
                                               ,iv_chain_name     => NULL          -- �`�F�[���X����
-- Modify 2009.05.08 Ver1.3 Start
--                                               ,iv_data_kind      => NULL          -- �f�[�^��R�[�h
                                               ,iv_data_kind      => gv_edi_data_code  -- �f�[�^��R�[�h
-- Modify 2009.05.08 Ver1.3 End
                                               ,iv_row_number     => NULL          -- ���񏈗��ԍ�
                                               ,in_num_of_records => ln_rec_cnt    -- ���R�[�h����
                                               ,ov_retcode        => lv_retcode    -- ���^�[���R�[�h
                                               ,ov_output         => lv_output     -- �o�͒l
                                               ,ov_errbuf         => lv_errbuf     -- �G���[���b�Z�[�W
                                               ,ov_errmsg         => lv_errmsg);   -- ���[�U�[�E�G���[���b�Z�[�W
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a04_003 -- ���ʊ֐��G���[
                                                      ,cv_tkn_func       -- �g�[�N��'FUNC_NAME'
                                                      ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                         ,cv_dict_f_func))
                                                      -- EDI�t�b�^�t�^�֐�
                            ,1
                            ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �t�b�^���R�[�h�̏�������
      UTL_FILE.PUT_LINE( lf_file_hand, lv_output ) ;
--
      -- ====================================================
      -- �t�s�k�t�@�C���N���[�Y
      -- ====================================================
      UTL_FILE.FCLOSE( lf_file_hand ) ;
-- 
      -- ���b�Z�[�W�o��
        lv_output_file_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr         -- 'XXCFR'
                                                               ,cv_msg_003a04_019      -- EDI�t�@�C���o��
                                                               ,cv_tkn_code            -- �g�[�N��'CODE'
                                                               ,iv_ar_code1            -- ���|�R�[�h�P�i�������j
                                                               ,cv_tkn_name            -- �g�[�N��'NAME'
                                                               ,gv_ar_code_name )      -- ���|�R�[�h�P�i�������j����
                            ,1
                            ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_file_msg
        ); 
        lv_output_file_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr         -- 'XXCFR'
                                                               ,cv_msg_003a04_011      -- �o�̓t�@�C����
                                                               ,cv_tkn_file            -- �g�[�N��'FILE_NAME'
                                                               ,gv_edi_data_filename ) -- �t�@�C����
                            ,1
                            ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_file_msg
        );
        lv_output_rec_num_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                                  ,cv_msg_003a04_020   -- EDI�o�̓��R�[�h��
                                                                  ,cv_tkn_rec          -- �g�[�N��'REC_COUNT'
                                                                  ,ln_rec_cnt         )-- �t�@�C�������R�[�h��
                            ,1
                            ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_rec_num_msg
        );
        -- �󔒍s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      -- �t�@�C���o�͌����̃J�E���g
      gn_output_cnt := gn_output_cnt + 1;
--
    END IF;
--
-- Modify 2009.06.23 Ver1.6 Start
    -- �`�[�ԍ��`�F�b�N�G���[�����݂����ꍇ
    IF (lv_chk_err_flg != cv_flag_no) THEN
      -- �t�@�C���o�͂Ȃ����b�Z�[�W���o��
      lv_slip_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                    cv_msg_kbn_cfr         -- 'XXCFR'
                                   ,cv_msg_003a04_026      -- �t�@�C���o�͂Ȃ����b�Z�[�W
                                   ,cv_tkn_code            -- �g�[�N��'CODE'
                                   ,iv_ar_code1            -- ���|�R�[�h�P�i�������j
                                   ,cv_tkn_name            -- �g�[�N��'NAME'
                                   ,gv_ar_code_name )      -- ���|�R�[�h�P�i�������j����)
                                 ,1
                                 ,5000);
      FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_slip_warn_msg
      );
--
      -- �߂�l�Ɍx���̃X�e�[�^�X���Z�b�g
      ov_retcode := cv_status_warn;
--
    END IF;
-- Modify 2009.06.23 Ver1.6 End
  EXCEPTION
    -- *** EDI�w�b�_�t�^�֐��G���[ ***
    WHEN edi_func_h_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_003 -- ���ʊ֐��G���[
                                                    ,cv_tkn_func       -- �g�[�N��'FUNC_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                       ,cv_dict_h_func))
                                                    -- EDI�w�b�_�t�^�֐�
                           ||cv_msg_part||lv_errmsg -- EDI�w�b�_�t�^�֐��ɂĔ��s���ꂽ�G���[���b�Z�[�W
                          ,1
                          ,5000);
      lv_errbuf  := lv_errmsg;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- �󔒍s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_output||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** �t�@�C���̏ꏊ�������ł� ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                    ,cv_msg_003a04_014 ) -- �t�@�C���̏ꏊ������
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂��� ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                    ,cv_msg_003a04_015 ) -- �t�@�C�����I�[�v���ł��Ȃ�
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �����ݑ��쒆�ɃI�y���[�e�B���O�E�V�X�e���̃G���[���������܂��� ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
--      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_016 -- �t�@�C���ɏ����݂ł��Ȃ�                                                 
                                                   )
                                                   ,1
                                                   ,5000);      
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_edi_date;
--
  /**********************************************************************************
   * Procedure Name   : get_edi_arcode
   * Description      : EDI�����Ώێ擾���[�v���� (A-3)
   ***********************************************************************************/
  PROCEDURE get_edi_arcode(
    iv_target_date IN  VARCHAR2,     -- ����
    iv_ar_code1    IN  VARCHAR2,     -- ���|�R�[�h�P(������)
    iv_start_mode  IN  VARCHAR2,     -- �N���敪
    ov_errbuf      OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edi_arcode'; -- �v���O������
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
    ln_ar1_cnt          NUMBER;                 -- ���|�R�[�h�P�i�������j����
    lv_ar_warn_msg      VARCHAR2(5000) := NULL; -- ���|�R�[�h�P�i�������j�x�����b�Z�[�W
-- Modify 2009.05.07 Ver1.3 Start
    ln_cust_cnt         NUMBER;                 -- �G���[���|�R�[�h1�i�������j�ݒ�ڋq��񌏐�
    iv_arcode1          VARCHAR2(5000);         -- ���|�R�[�h�P�i�������jin�p�����[�^
-- Modify 2009.05.07 Ver1.3 End    
    lv_msg              VARCHAR2(5000) := NULL; -- �Ώی������b�Z�[�W
    lb_fexists          BOOLEAN;                -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                 -- �t�@�C���̒���
    ln_block_size       NUMBER;                 -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���|�R�[�h�P�i�������j���o
    CURSOR get_edi_arcode1_cur
    IS
      SELECT flvv.lookup_code ar_code1              -- ���|�R�[�h�P�i�������j
            ,flvv.meaning     ar_code1_name         -- ���|�R�[�h�P�i�������j����
            ,flvv.attribute1  chain_code            -- �`�F�[���X�R�[�h
            ,flvv.attribute2  chain_name            -- �`�F�[���X����
            ,flvv.attribute3  edi_file_name         -- �t�@�C����
      FROM fnd_lookup_values_vl flvv                -- �N�C�b�N�R�[�h(���|�R�[�h1(������))
      WHERE flvv.lookup_type = cv_invoice_grp_code
        AND ((gv_start_mode_flg = cv_start_mode_b
              AND EXISTS (SELECT 'x'
                          FROM xxcfr_inv_info_transfer xiit  -- ���������n�e�[�u��
                              ,xxcfr_invoice_headers   xih
                              ,xxcfr_invoice_lines     xil
                              ,xxcfr_bill_customers_v  xbcv
                          WHERE flvv.lookup_code = xbcv.receiv_code1
                            AND xbcv.inv_prt_type = cv_inv_prt_type
                            AND xih.invoice_id = xil.invoice_id      -- �ꊇ������	ID
                            AND xbcv.bill_customer_code = xih.bill_cust_code
                            AND xih.request_id = xiit.request_id
                            AND xiit.set_of_books_id = gn_set_of_bks_id
                            AND xiit.org_id = gn_org_id
                            )) OR
             (gv_start_mode_flg = cv_start_mode_h))
        AND flvv.lookup_code = NVL(iv_ar_code1,flvv.lookup_code)
        AND flvv.enabled_flag = cv_flag_yes
        AND gd_process_date BETWEEN NVL(flvv.start_date_active ,cd_min_date) AND
                                    NVL(flvv.end_date_active ,cd_max_date)
      ORDER BY flvv.lookup_code;
--
-- Modify 2009.05.07 Ver1.3 Start
    -- �G���[���|�R�[�h1(������)�ݒ�ڋq�擾�J�[�\��
    CURSOR get_edi_cust_cur(iv_arcode1 IN VARCHAR2)
    IS
      SELECT xbcv.bill_customer_code  cust_code     -- ������ڋq�R�[�h
            ,xbcv.bill_customer_name  cust_name     -- ������ڋq��
      FROM   xxcfr_invoice_headers   xih            -- �����w�b�_���
            ,xxcfr_bill_customers_v  xbcv           -- ������ڋq�r���[
      WHERE  xbcv.receiv_code1 = iv_arcode1        -- ���|�R�[�h1(������)
      AND    xbcv.inv_prt_type = cv_inv_prt_type              -- �������o�͌`��(3:EDI����)
      AND    xbcv.bill_customer_code = xih.bill_cust_code 
      AND  ((gv_start_mode_flg = cv_start_mode_b     AND  -- ��ԃo�b�`�N����
             EXISTS (SELECT *
                     FROM   xxcfr_inv_info_transfer xiit  -- ���������n�e�[�u��
                     WHERE  xiit.target_request_id = xih.request_id
                     AND    xiit.set_of_books_id = gn_set_of_bks_id
                     AND    xiit.org_id = gn_org_id
                    ))
           OR
            (gv_start_mode_flg = cv_start_mode_h  AND  -- �蓮�N����
             xih.cutoff_date = gd_target_date))        -- ����
      ORDER BY xbcv.bill_customer_code;
--
-- Modify 2009.05.07 Ver1.3 End
    -- *** ���[�J���E���R�[�h ***
    TYPE g_edi_arcode1_ttype IS TABLE OF get_edi_arcode1_cur%ROWTYPE INDEX BY PLS_INTEGER;
-- Modify 2009.05.07 Ver1.3 Start
    TYPE g_edi_cust_ttype IS TABLE OF get_edi_cust_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_edi_cust              g_edi_cust_ttype;
-- Modify 2009.05.07 Ver1.3 End
    lt_arcode1_data          g_edi_arcode1_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�[�\���I�[�v��
    OPEN get_edi_arcode1_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_edi_arcode1_cur BULK COLLECT INTO lt_arcode1_data;
--
    -- ���������̃Z�b�g
    ln_ar1_cnt := lt_arcode1_data.COUNT;
    gn_target_cnt := ln_ar1_cnt;
--
    -- �J�[�\���N���[�Y
    CLOSE get_edi_arcode1_cur;
--
    -- EDI���ڏ����Q�ƃ^�C�v���擾
    OPEN get_edi_item_cur;
    -- �R���N�V�����ϐ��ɑ��
    FETCH get_edi_item_cur BULK COLLECT INTO gt_edi_item_tab;
    -- �J�[�\���N���[�Y
    CLOSE get_edi_item_cur;
--
    -- ���[�v����
    <<arcode1_loop>>
    FOR i IN 1..ln_ar1_cnt LOOP
--
      -- �K�{�`�F�b�N�F�`�F�[���X
      IF (lt_arcode1_data(i).chain_code IS NULL) THEN
        lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a04_018      -- EDI�ݒ�G���[���b�Z�[�W
                                                      ,cv_tkn_code            -- �g�[�N��'CODE'
                                                      ,lt_arcode1_data(i).ar_code1
                                                      ,cv_tkn_name            -- �g�[�N��'NAME'
                                                      ,lt_arcode1_data(i).ar_code1_name
                                                      ,cv_tkn_item       -- �g�[�N��'ITEM'
                                                      ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                          ,cv_dict_chain_code ))
                                                                                        -- �`�F�[���X�R�[�h
                                 ,1
                                 ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- �I���X�e�[�^�X���x���ɍX�V
        ov_retcode := cv_status_warn;
      END IF;
--
      -- �K�{�`�F�b�N�F�`�F�[���X����
      IF (lt_arcode1_data(i).chain_name IS NULL) THEN
        lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr -- 'XXCFR'
                                                      ,cv_msg_003a04_018   -- EDI�ݒ�G���[���b�Z�[�W
                                                      ,cv_tkn_code         -- �g�[�N��'CODE'
                                                      ,lt_arcode1_data(i).ar_code1
                                                      ,cv_tkn_name         -- �g�[�N��'NAME'
                                                      ,lt_arcode1_data(i).ar_code1_name
                                                      ,cv_tkn_item       -- �g�[�N��'ITEM'
                                                      ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                          ,cv_dict_chain_name ))
                                                                                        -- �`�F�[���X����
                                 ,1
                                 ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- �I���X�e�[�^�X���x���ɍX�V
        ov_retcode := cv_status_warn;
      END IF;
--
      -- �K�{�`�F�b�N�F�t�@�C����
      IF (lt_arcode1_data(i).edi_file_name IS NULL) THEN
        lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr -- 'XXCFR'
                                                      ,cv_msg_003a04_018   -- EDI�ݒ�G���[���b�Z�[�W
                                                      ,cv_tkn_code         -- �g�[�N��'CODE'
                                                      ,lt_arcode1_data(i).ar_code1
                                                      ,cv_tkn_name         -- �g�[�N��'NAME'
                                                      ,lt_arcode1_data(i).ar_code1_name
                                                      ,cv_tkn_item       -- �g�[�N��'ITEM'
                                                      ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                          ,cv_dict_file_name ))
                                                                                          -- �t�@�C����
                                  ,1
                                  ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- �I���X�e�[�^�X���x���ɍX�V
        ov_retcode := cv_status_warn;
      END IF;
--
-- Modify 2009.05.25 Ver1.4 Start
      IF (lv_ar_warn_msg IS NOT NULL) THEN
        -- �G���[���|�R�[�h1(������)�ݒ�ڋq�w�b�_���b�Z�[�W
         lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_003a04_023      -- �G���[���|�R�[�h1(������)�ݒ�ڋq�w�b�_���b�Z�[�W
                                                        ,cv_tkn_code            -- �g�[�N��'CODE'
                                                        ,lt_arcode1_data(i).ar_code1)                                                   
                                 ,1
                                 ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- �J�[�\���I�[�v��
        iv_arcode1 := lt_arcode1_data(i).ar_code1;
        OPEN get_edi_cust_cur(iv_arcode1);
--
        -- �f�[�^�̈ꊇ�擾
        FETCH get_edi_cust_cur BULK COLLECT INTO lt_edi_cust;
--
        -- ���������̃Z�b�g
        ln_cust_cnt := lt_edi_cust.COUNT;
--
        -- �J�[�\���N���[�Y
        CLOSE get_edi_cust_cur;
--
        -- ���[�v����
        <<cust_cur>>
        FOR i IN 1..ln_cust_cnt LOOP
-- 
        -- �G���[���|�R�[�h1(������)�ݒ�ڋq���׃��b�Z�[�W
          lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_003a04_024      -- �G���[���|�R�[�h1(������)�ݒ�ڋq���׃��b�Z�[�W
                                                        ,cv_tkn_code            -- �g�[�N��'CODE'
                                                        ,lt_edi_cust(i).cust_code
                                                        ,cv_tkn_name            -- �g�[�N��'NAME'
                                                        ,lt_edi_cust(i).cust_name)
                                 ,1
                                 ,5000);
          FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        END LOOP cust_cur;
      END IF;
-- Modify 2009.05.25 Ver1.4 End
      -- �x�����b�Z�[�W�ɒl���Z�b�g����Ă��Ȃ��ꍇ
      IF (lv_ar_warn_msg IS NULL) THEN
        -- �t�@�C���d���`�F�b�N
        UTL_FILE.FGETATTR(gv_edi_data_filepath,
                          lt_arcode1_data(i).edi_file_name,
                          lb_fexists,
                          ln_file_size,
                          ln_block_size);
        -- �O��t�@�C�������݂��Ă���ꍇ
        IF lb_fexists THEN
          lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                             ,cv_msg_003a04_017 -- �t�@�C�������݂��Ă���
                                                             ,cv_tkn_code       -- �g�[�N��'CODE'
                                                             ,lt_arcode1_data(i).ar_code1
                                                             ,cv_tkn_name       -- �g�[�N��'NAME'
                                                             ,lt_arcode1_data(i).ar_code1_name
                                                             ,cv_tkn_file       -- �g�[�N��'FILE_NAME'
                                                             ,lt_arcode1_data(i).edi_file_name )
                                   ,1
                                   ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- �I���X�e�[�^�X���x���ɍX�V
        ov_retcode := cv_status_warn;
--
        ELSE
          -- �O���[�o���ϐ���EDI�t�@�C������ݒ�
          gv_edi_chain_code := lt_arcode1_data(i).chain_code;
          gv_edi_chain_name := lt_arcode1_data(i).chain_name;
          gv_edi_data_filename := lt_arcode1_data(i).edi_file_name;
          gv_ar_code_name      := lt_arcode1_data(i).ar_code1_name;
--
          --===============================================================
          -- A-4�DEDI�f�[�^�擾���[�v����
          --===============================================================
          get_edi_date( iv_target_date => iv_target_date              -- ����
                       ,iv_ar_code1    => lt_arcode1_data(i).ar_code1 -- ���|�R�[�h�P(������)
                       ,iv_start_mode  => iv_start_mode               -- �N���敪
                       ,ov_errbuf      => lv_errbuf                   -- �G���[�E���b�Z�[�W
                       ,ov_retcode     => lv_retcode                  -- ���^�[���E�R�[�h
                       ,ov_errmsg      => lv_errmsg );                -- ���[�U�[�E�G���[�E���b�Z�[�W 
--
          -- �߂�l���G���[�ł���ꍇ
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          -- �߂�l���x���ł���ꍇ
          ELSIF (lv_retcode = cv_status_warn) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            -- �I���X�e�[�^�X���x���ɍX�V
            ov_retcode := cv_status_warn;
          ELSE
            NULL;
          END IF;
        END IF;
--
      END IF;
--
      IF (lv_ar_warn_msg IS NOT NULL) THEN
        gn_warn_cnt := gn_warn_cnt + 1;
-- Modify 2009.05.25 Ver1.4 Start
-- Modify 2009.05.07 Ver1.3 Start
--        -- �G���[���|�R�[�h1(������)�ݒ�ڋq�w�b�_���b�Z�[�W
--         lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                        ,cv_msg_003a04_023      -- �G���[���|�R�[�h1(������)�ݒ�ڋq�w�b�_���b�Z�[�W
--                                                        ,cv_tkn_code            -- �g�[�N��'CODE'
--                                                        ,lt_arcode1_data(i).ar_code1)                                                   
--                                 ,1
--                                 ,5000);
--        FND_FILE.PUT_LINE(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_ar_warn_msg
--        );
--        -- �J�[�\���I�[�v��
--        iv_arcode1 := lt_arcode1_data(i).ar_code1;
--        OPEN get_edi_cust_cur(iv_arcode1);
--
--        -- �f�[�^�̈ꊇ�擾
--        FETCH get_edi_cust_cur BULK COLLECT INTO lt_edi_cust;
--
--        -- ���������̃Z�b�g
--        ln_cust_cnt := lt_edi_cust.COUNT;
--
--        -- �J�[�\���N���[�Y
--        CLOSE get_edi_cust_cur;
--
--        -- ���[�v����
--        <<cust_cur>>
--        FOR i IN 1..ln_cust_cnt LOOP
-- 
--        -- �G���[���|�R�[�h1(������)�ݒ�ڋq���׃��b�Z�[�W
--          lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                        ,cv_msg_003a04_024      -- �G���[���|�R�[�h1(������)�ݒ�ڋq���׃��b�Z�[�W
--                                                        ,cv_tkn_code            -- �g�[�N��'CODE'
--                                                        ,lt_edi_cust(i).cust_code
--                                                        ,cv_tkn_name            -- �g�[�N��'NAME'
--                                                        ,lt_edi_cust(i).cust_name)
--                                 ,1
--                                 ,5000);
--          FND_FILE.PUT_LINE(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_ar_warn_msg
--        );
--        END LOOP cust_cur;*/
-- Modify 2009.05.07 Ver1.3 End
-- Modify 2009.05.25 Ver1.4 End
        -- �ŏI���R�[�h�łȂ��ꍇ�A�󔒍s��}��
        IF (i <> ln_ar1_cnt) THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => '');
        END IF;
      END IF;
--
      -- �ϐ��̏�����
      lv_ar_warn_msg       := NULL;
      gv_edi_chain_code    := NULL;
      gv_edi_chain_name    := NULL;
      gv_edi_data_filename := NULL;
      gv_ar_code_name      := NULL;
--
    END LOOP arcode1_loop;
--
    -- �蓮�N���̏ꍇ�������E�x��������0�ł���ꍇ
    IF (gv_start_mode_flg = cv_start_mode_h AND ov_retcode = cv_status_normal AND gn_output_cnt = 0) THEN
      gn_target_cnt := 0;
    END IF;
--
    -- �Ώی�����0�ł���ꍇ
    IF (ov_retcode = cv_status_normal) AND (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                    ,cv_msg_003a04_012 ) -- �Ώۃf�[�^0�����b�Z�[�W
                          ,1
                          ,5000);
      ov_errmsg  := lv_errmsg;
      -- �I���X�e�[�^�X���x���ɍX�V
      ov_retcode := cv_status_warn;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_edi_arcode;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date IN  VARCHAR2,     -- ����
    iv_ar_code1    IN  VARCHAR2,     -- ���|�R�[�h�P(������)
    iv_start_mode  IN  VARCHAR2,     -- �N���敪
    ov_errbuf      OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_retcode_out VARCHAR2(1);     -- ���^�[���E�R�[�h�iEDI�����Ώێ擾���[�v�����j
    lv_errmsg_out  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W�iEDI�����Ώێ擾���[�v�����j
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--

    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_target_date        -- ����
      ,iv_ar_code1           -- ���|�R�[�h�P(������)
      ,iv_start_mode         -- �N���敪
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_fixed_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  EDI�����Ώێ擾���[�v���� (A-3)
    -- =====================================================
    get_edi_arcode(
       iv_target_date        -- ����
      ,iv_ar_code1           -- ���|�R�[�h�P(������)
      ,iv_start_mode         -- �N���敪
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- �߂�l�̕���
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    errbuf         OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W #�Œ�#
    retcode        OUT     VARCHAR2,         -- �G���[�R�[�h       #�Œ�#
    iv_target_date IN      VARCHAR2,         -- ����
    iv_ar_code1    IN      VARCHAR2,         -- ���|�R�[�h�P(������)
    iv_start_mode  IN      VARCHAR2          -- �N���敪
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
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N���b�Z�[�W
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_target_date  -- ����
      ,iv_ar_code1     -- ���|�R�[�h�P(������)
      ,iv_start_mode   -- �N���敪
      ,lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
    --�G���[���b�Z�[�W���ݒ肳��Ă���ꍇ�A�G���[�o��
    IF (lv_errmsg IS NOT NULL) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
    --�G���[�̏ꍇ�A�V�X�e���G���[���b�Z�[�W�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    --�P�s���s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
    -- �t�@�C�����������o��
    gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr -- 'XXCFR'
                                                   ,cv_msg_003a04_022   -- �t�@�C���o�͌���
                                                   ,cv_cnt_token
                                                   ,gn_output_cnt)
                         ,1
                         ,5000);
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�P�s���s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt - gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
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
--###########################  �Œ蕔 END   #######################################################
--
END XXCFR003A04C;
/
