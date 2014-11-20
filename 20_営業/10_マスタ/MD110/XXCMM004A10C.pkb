CREATE OR REPLACE PACKAGE BODY XXCMM004A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A10C(body)
 * Description      : �i�ڈꗗ�쐬
 * MD.050           : �i�ڈꗗ�쐬 MD050_CMM_004_A10
 * Version          : Issue3.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              ��������
 *  get_cmp_cost           �W�������擾
 *  get_item_mst           �i�ڏ��擾
 *  get_item_header        ���ڃ^�C�g���擾
 *  output_csv             CSV�`���f�[�^�o��
 *  submain                �����̎��s��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   N.Nishimura      main�V�K�쐬
 *  2009/01/20    1.1   N.Nishimura      �P�̃e�X�g�o�O�C��
 *  2009/01/23    1.2   N.Nishimura      �萔���ʉ�
 *  2009/02/03    1.3   N.Nishimura      �Ώۊ��� ���ݐݒ�l�F�����Ώۓ����ɕύX
 *                                                �\��ݒ�l�F�K�p���ɕύX
 *                                       �i�ڃX�e�[�^�X��NULL�̏ꍇ���o�͂���
 *  2009/02/12    1.4   H.Yoshikawa      �P�̃e�X�g�o�O�C��
 *                                        1.�o���e��Q��LOOKUP_TYPE�����C��
 *                                        2.�\��l�擾�J�[�\���̃\�[�g���C��
 *                                        3.�Ώۊ���(�J�n�A�I��)�̖��w�莞�̃`�F�b�N���C��
 *                                          (�ǂ�����w�肳��Ă���ꍇ�̂݊��Ԃ̃`�F�b�N�����{����)
 *                                        4.���ݒl�A�\��l�Ƃ����Ԗ��w�莞�͑S���擾����悤�C��
 *                                        5.�W�������v�̎擾���C��
 *                                           �@�Ώۊ���(�J�n) �A�Ɩ����t�i�Ώۊ���(�J�n)���w�莞�j
 *                                        6.�e�i�ڃR�[�h�擾���@���C��
 *                                        7.Disc�i�ڃA�h�I���̐��l���ځu���e�ʁv�u��������v�����ύX�ɔ����C��
 *  2009/02/17    1.5   R.Takigawa       �P�̃e�X�g�o�O�C��
 *                                        1.�{�Џ��i�敪�Ə��i���i�敪�̓���ւ�
 *  2009/04/14    1.6   H.Yoshikawa      ��QT1_0214�Ή�  Disc�i�ڃA�h�I���u���e�ʁv�u��������v�����ύX
 *  2009/05/26    1.7   H.Yoshikawa      ��QT1_0317�Ή�  �i�ڃR�[�h�̕s�v�Ȕ͈͐ݒ���폜
 *  2009/07/13    1.8   H.Yoshikawa      ��Q0000366�Ή�  �R���|�[�l���g����(01:01GEN�`07:07KEI)��ǉ�
 *  2009/08/12    1.9   Y.Kuboshima      ��Q0000894�Ή�  ���t���ڂ̏C��(SYSDATE -> �Ɩ����t)
 *
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  --�p�b�P�[�W��
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCMM004A10C';
  --�A�v���P�[�V�����Z�k��
  cv_app_name_xxcmm       CONSTANT VARCHAR2(5)   := 'XXCMM';
  --���b�Z�[�W
  cv_msg_xxcmm_00001      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001'; -- �Ώۃf�[�^����
  cv_msg_xxcmm_00019      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019'; -- �Ώۊ��Ԏw��G���[
  cv_msg_xxcmm_00473      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00473'; -- ���̓p�����[�^
  cv_msg_xxcmm_00475      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00475'; -- �i���R�[�h�w��G���[
  cv_msg_xxcmm_00485      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00485'; -- �f�[�^���o�G���[
  --�g�[�N��
  cv_tkn_count            CONSTANT VARCHAR2(10)  := 'COUNT';
  cv_tkn_date_name        CONSTANT VARCHAR2(10)  := 'DATE_NAME';
  cv_tkn_item_code        CONSTANT VARCHAR2(10)  := 'ITEM_CODE';
  cv_tkn_name             CONSTANT VARCHAR2(10)  := 'NAME';
  cv_tkn_value            CONSTANT VARCHAR2(10)  := 'VALUE';
  --���͍���
  cv_inp_output_div       CONSTANT VARCHAR2(30)  := '�o�͑Ώېݒ�l';     -- �o�͑Ώېݒ�l
  cv_inp_item_status      CONSTANT VARCHAR2(30)  := '�o�͑ΏۃX�e�[�^�X'; -- �o�͑ΏۃX�e�[�^�X
  cv_inp_date_from        CONSTANT VARCHAR2(30)  := '�Ώۊ��ԊJ�n';       -- �Ώۊ��ԊJ�n
  cv_inp_date_to          CONSTANT VARCHAR2(30)  := '�Ώۊ��ԏI��';       -- �Ώۊ��ԏI��
  cv_inp_item_code_from   CONSTANT VARCHAR2(30)  := '�i���R�[�h�J�n';     -- �i���R�[�h�J�n
  cv_inp_item_code_to     CONSTANT VARCHAR2(30)  := '�i���R�[�h�I��';     -- �i���R�[�h�I��
  --���b�N�A�b�v
  cv_lookup_cost_cmpt     CONSTANT VARCHAR2(30)  := 'XXCMM1_COST_CMPT';          -- �W������
  cv_lookup_itm_status    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_STATUS';          -- �i�ڃX�e�[�^�X
  cv_lookup_sales_class   CONSTANT VARCHAR2(30)  := 'XXCMN_SALES_TARGET_CLASS';  -- ����Ώۋ敪
  cv_lookup_rate_class    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_RATE_CLASS';      -- ���敪
  cv_lookup_nets_uom      CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_NET_UOM_CODE';    -- ���e��
  cv_lookup_baracha       CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_BARACHAKUBUN';    -- �o�����敪
  cv_lookup_procuct_class CONSTANT VARCHAR2(30)  := 'XXCMN_D02';                 -- ���i����
  cv_lookup_obso_class    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_HAISHI_KUBUN';    -- �p�~�敪
  cv_lookup_vessel        CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_YOKIGUN';         -- �e��Q
  cv_lookup_new_item      CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_SHINSYOHINKUBUN'; -- �V���i�敪
  cv_lookup_acnt_grp      CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_KERIGUN';         -- �o���Q
-- Ver1.4 2009/02/12  �o���e��Q��LOOKUP_TYPE���C��
--  cv_lookup_acnt_vessel   CONSTANT VARCHAR2(30)  := 'XXCMN_BOTTLE_CLASS';        -- �o���e��Q
  cv_lookup_acnt_vessel   CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_KERIYOKIGUN';     -- �o���e��Q
-- End
  cv_lookup_brand         CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_BRANDGUN';        -- �u�����h�Q
  cv_lookup_supplier      CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_SENMONTEN_SHIIRESAKI'; -- ���X�d����
  cv_lookup_item_head     CONSTANT VARCHAR2(30)  := 'XXCMM1_004A10_ITEMLIST';       -- �{�Џ��i�敪
  -- �i�ڃJ�e�S���Z�b�g��
  cv_categ_set_seisakugun CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_seisakugun;
                                                                                -- ����Q
  cv_categ_set_hon_prod   CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_hon_prod;
                                                                                -- �{�Џ��i�敪
  cv_categ_set_item_prod  CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_prod;
                                                                                -- ���i���i�敪
  --���ʉ��̂��߃R�����g�A�E�g 2009/01/23
  --cv_seisakugun           CONSTANT VARCHAR2(20) := '����Q�R�[�h';              -- ����Q
  --cv_product_class        CONSTANT VARCHAR2(20) := '���i���i�敪';              -- ���i���i�敪
  --cv_hon_product_class    CONSTANT VARCHAR2(20) := '�{�Џ��i�敪';              -- �{�Џ��i�敪
  --
  -- �萔
  cv_get_item             CONSTANT VARCHAR2(20)  := '�i�ڏ��';   -- �i�ڏ��
  cv_cmpt_cost            CONSTANT VARCHAR2(20)  := '�W������';   -- �W������
  cv_sep_com              CONSTANT VARCHAR2(1)   := ',';          -- CSV�`���f�[�^��؂蕶��
  cv_csv_file             CONSTANT VARCHAR2(1)   := '0';          -- CSV�t�@�C��
  cv_sep                  CONSTANT VARCHAR2(1)   := ':';          -- �Z�p���[�^
  cv_output_div           CONSTANT VARCHAR2(1)   := '1';          -- �o�͑Ώېݒ�l(���ݐݒ�l)
  cv_output_log           CONSTANT VARCHAR2(3)   := 'LOG';
  cv_date_fmt_std         CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                  -- ���t����
-- Ver1.8  2009/07/13  Add  0000364�Ή�
  cv_cost_cmpnt_01gen     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_01gen;   -- ����
  cv_cost_cmpnt_02sai     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_02sai;   -- �Đ���
  cv_cost_cmpnt_03szi     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_03szi;   -- ���ޔ�
  cv_cost_cmpnt_04hou     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_04hou;   -- ���
  cv_cost_cmpnt_05gai     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_05gai;   -- �O�����H��
  cv_cost_cmpnt_06hkn     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_06hkn;   -- �ۊǔ�
  cv_cost_cmpnt_07kei     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_07kei;   -- ���̑��o��
  --
  cv_yes                  CONSTANT VARCHAR2(1)   := 'Y';          -- 'Y'
-- End1.8
  cv_no                   CONSTANT VARCHAR2(1)   := 'N';          -- 'N'
-- Ver1.6 2009/04/14  ��Q�FT1_0214 ���e�ʁA������� �����ύX�ɔ����C��
---- Ver1.4 2009/02/13  7.Disc�i�ڃA�h�I���̐��l���ځu���e�ʁv�����ύX�ɔ����C��
--  cv_number_fmt           CONSTANT VARCHAR2(5)   := '999D9';      -- NUMBER(4,1)
---- End1.4
  cv_number_fmt           CONSTANT VARCHAR2(6)   := '9999D9';     -- NUMBER(5,1)
-- End1.6
  --���ʉ��̂��߃R�����g�A�E�g 2009/01/23
  --cv_date_format          CONSTANT VARCHAR2(10) := 'YYYY/MM/DD'; -- ���t����
  --
-- Ver1.7 2009/05/27  Del  �s�v�Ȃ��ߍ폜
--  --�f�t�H���g�l
--  cv_item_code_from       CONSTANT VARCHAR2(20)  := '0000001';    -- �i���R�[�h�J�n
--  cv_item_code_to         CONSTANT VARCHAR2(20)  := '3999999';    -- �i���R�[�h�I��
-- End1.7
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date    DATE;          -- �Ɩ����t
  gv_output_div      VARCHAR2(1);   -- �o�͑Ώېݒ�l
  gn_item_status     NUMBER;        -- �i�ڃX�e�[�^�X
  gd_date_from       DATE;          -- �Ώۊ��ԊJ�n
  gd_date_to         DATE;          -- �Ώۊ��ԏI��
  gv_item_code_from  ic_item_mst_b.item_no%TYPE;  -- �i���R�[�h�J�n
  gv_item_code_to    ic_item_mst_b.item_no%TYPE;  -- �i���R�[�h�I��
--
-- Ver1.8  2009/07/13  Add  0000364�Ή�
  -- �W�������擾�p���R�[�h�^�ϐ�
  TYPE g_opmcost_rtype IS RECORD(
    cmpnt_cost1           NUMBER        -- ����
   ,cmpnt_cost2           NUMBER        -- �Đ���
   ,cmpnt_cost3           NUMBER        -- ���ޔ�
   ,cmpnt_cost4           NUMBER        -- ���
   ,cmpnt_cost5           NUMBER        -- �O�����H��
   ,cmpnt_cost6           NUMBER        -- �ۊǔ�
   ,cmpnt_cost7           NUMBER        -- ���̑��o��
   ,cmpnt_cost            NUMBER        -- �W�������v
   ,start_date            DATE          -- �K�p�J�n��
  );
-- End1.8
  --
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_output_div        IN  VARCHAR2,     -- �o�͑Ώېݒ�l
    iv_item_status       IN  VARCHAR2,     -- �i�ڃX�e�[�^�X
    iv_date_from         IN  VARCHAR2,     -- �Ώۊ��ԊJ�n
    iv_date_to           IN  VARCHAR2,     -- �Ώۊ��ԏI��
    iv_item_code_from    IN  VARCHAR2,     -- �i���R�[�h�J�n
    iv_item_code_to      IN  VARCHAR2,     -- �i���R�[�h�I��
    ov_errbuf            OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
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
    lv_step       VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token  VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    init_err_expt  EXCEPTION;
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
    -- ===============================
    -- ��������(A-1.1) �Ɩ����t�擾
    -- ===============================
    lv_step      := 'A-1.1';
    lv_msg_token := '�Ɩ����t�擾';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => ''
    );
    -----------------------------------------
    -- ���̓p�����[�^���O���[�o���ϐ��Ɋi�[
    -----------------------------------------
    gv_output_div     := iv_output_div;
    gn_item_status    := TO_NUMBER( iv_item_status );
    gd_date_from      := FND_DATE.CANONICAL_TO_DATE( iv_date_from );
    gd_date_to        := FND_DATE.CANONICAL_TO_DATE( iv_date_to );
    gv_item_code_from := iv_item_code_from;
    gv_item_code_to   := iv_item_code_to;
    --
    ------------------------------------------
    -- ���̓p�����[�^���b�Z�[�W�o�́A���O�o��
    ------------------------------------------
    lv_step      := 'A-1.1';
    lv_msg_token := '���̓p�����[�^���b�Z�[�W�o��';
    -- �o�͑Ώېݒ�l
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_output_div,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => gv_output_div
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- �o�͑ΏۃX�e�[�^�X
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_item_status,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => gn_item_status
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- �Ώۊ��ԊJ�n
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_date_from,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => TO_CHAR( gd_date_from, cv_date_fmt_std )
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- �Ώۊ��ԏI��
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_date_to,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => TO_CHAR( gd_date_to, cv_date_fmt_std )
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- �i���R�[�h�J�n
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_item_code_from,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => gv_item_code_from
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- �i���R�[�h�I��
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_item_code_to,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => gv_item_code_to
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => ''
    );
    -- ========================================
    -- ��������(A-1.2) ���͍��ڂ̑Ó����`�F�b�N
    -- ========================================
    -- �Ώۊ���
    lv_step      := 'A-1.2';
    lv_msg_token := '�Ώۊ��ԃ`�F�b�N';
-- Ver1.4 2009/02/12  �Ώۊ���(�J�n�A�I��)�̖��w�莞�̃`�F�b�N���C��
--    -- �Ώۊ��ԁi�J�n�j��NULL�Ȃ�Ɩ����t���Z�b�g 2009/01/20�ǉ�
--    IF ( gd_date_from IS NULL ) THEN
--      gd_date_from := gd_process_date;
--    END IF;
--    -- �Ώۊ��ԁi�I���j��NULL�Ȃ�Ɩ����t���Z�b�g 2009/01/20�ǉ�
--    IF ( gd_date_to IS NULL ) THEN
--      gd_date_to := gd_process_date;
--    END IF;
--    -- �Ώۊ��ԁi�J�n�j�ƑΏۊ��ԁi�I���j�̔�r
--    IF ( gd_date_from > gd_date_to ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--          iv_application  => cv_app_name_xxcmm,
--          iv_name         => cv_msg_xxcmm_00019
--      );
--      RAISE init_err_expt;
--    END IF;
    -- �J�n�A�I���Ƃ��w�莞�Ƀ`�F�b�N����
    IF  ( gd_date_from IS NOT NULL )
    AND ( gd_date_to   IS NOT NULL ) THEN
      -- �Ώۊ��ԁi�J�n�j�ƑΏۊ��ԁi�I���j�̔�r
      IF ( gd_date_from > gd_date_to ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application  => cv_app_name_xxcmm,
            iv_name         => cv_msg_xxcmm_00019
        );
        RAISE init_err_expt;
      END IF;
    END IF;
-- End
    -- �i���R�[�h
    lv_step      := 'A-1.2';
    lv_msg_token := '�i���R�[�h�`�F�b�N';
-- Ver1.7 2009/05/27  Del  �s�v�Ȃ��ߍ폜
--    -- �i���R�[�h�i�J�n�j��NULL�Ȃ�'0000001'���Z�b�g 2009/01/20�ǉ�
--    IF ( gv_item_code_from IS NULL ) THEN
--      gv_item_code_from := cv_item_code_from;
--    END IF;
--    -- �i���R�[�h�i�I���j��NULL�Ȃ�'3999999'���Z�b�g 2009/01/20�ǉ�
--    IF ( gv_item_code_to IS NULL ) THEN
--      gv_item_code_to := cv_item_code_to;
--    END IF;
-- End1.7
--
-- Ver1.7 2009/05/27  Mod  �s�v�ȕi�ڃR�[�h�͈͐ݒ���폜�ɔ����C��
    -- �i���R�[�h�i�J�n�j�ƕi���R�[�h�i�I���j�̔�r
    -- �J�n�A�I���Ƃ��w�莞�Ƀ`�F�b�N����
--    IF ( gv_item_code_from > gv_item_code_to ) THEN
    IF  ( gv_item_code_from IS NOT NULL )
    AND ( gv_item_code_to   IS NOT NULL )
    AND ( gv_item_code_from > gv_item_code_to ) THEN
-- End1.7
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_app_name_xxcmm,
          iv_name         => cv_msg_xxcmm_00475
      );
      RAISE init_err_expt;
    END IF;
--
  EXCEPTION
    WHEN init_err_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_init;
--
--
  /**********************************************************************************
   * Procedure Name   : get_cmp_cost
   * Description      : �W�������擾(A-2.3, A-3.2)
   ***********************************************************************************/
  PROCEDURE get_cmp_cost(
    in_item_id     IN  NUMBER,           -- �i��ID
-- Ver1.8  2009/07/13  Mod  0000364�Ή�
--    on_cmp_cost    OUT NUMBER,           -- �W�������v
--    od_apply_date  OUT DATE,             -- �W�������K�p�J�n��
    o_opmcost_rec  OUT g_opmcost_rtype,  -- �W���������R�[�h
-- End1.8
    ov_errbuf      OUT VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'get_cmp_cost'; -- �v���O������
-- Ver1.4 2009/02/12  �W�������v�̎擾���C��
    -- �W������
    cv_whse_code               CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                               -- �q��
    cv_cost_mthd_code          CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                               -- �������@
    cv_cost_analysis_code      CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                               -- ���̓R�[�h
-- End
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- Ver1.8  2009/07/13  Add  0000364�Ή�
    l_opmcost_rec     g_opmcost_rtype;  -- �W���������R�[�h
-- End1.8
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step           VARCHAR2(100);    -- �X�e�b�v
    lv_msg_token      VARCHAR2(100);    -- �f�o�b�O�p�g�[�N��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
-- Ver1.8 2009/07/13  Mod  0000366�Ή�
---- Ver1.4 2009/02/12  �W�������v�̎擾���C��
----  �Ώۊ���(�J�n)�w�莞�́A�Ώۊ���(�J�n)�����ԂɊ܂܂��J�����_�A���Ԃ̕W���������擾
----  �Ώۊ���(�J�n)���w�莞�́A�Ɩ����t�����ԂɊ܂܂��J�����_�A���Ԃ̕W���������擾
----    -- �W�������ƓK�p�J�n�����擾����
----    CURSOR      cnp_cost_cur
----    IS
----      SELECT    ccmd.cmpnt_cost,
----                ccld.start_date
----      FROM      cm_cmpt_dtl          ccmd,
----                cm_cldr_dtl          ccld,
----                cm_cmpt_mst_vl       ccmv,
----                fnd_lookup_values_vl flv
----      WHERE     ccmd.calendar_code       = ccld.calendar_code
----      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id
----      AND       ccmv.cost_cmpntcls_code  = flv.meaning
----      AND       ccmd.item_id             = in_item_id
----      AND       flv.lookup_type          = cv_lookup_cost_cmpt
----      ORDER BY  ccmv.cost_cmpntcls_code;
----  �w������J�����_���ԂɊ܂܂�錴�����v�A�J�n�����擾
--    CURSOR      cnp_cost_cur
--    IS
--      SELECT    SUM( NVL( ccmd.cmpnt_cost, 0 ) )    -- �W������
--               ,cclr.start_date
--      FROM      cm_cmpt_dtl          ccmd           -- OPM�W������
--               ,cm_cldr_dtl          cclr           -- OPM�����J�����_
--               ,cm_cmpt_mst_vl       ccmv           -- �����R���|�[�l���g
--               ,fnd_lookup_values_vl flv            -- �Q�ƃR�[�h�l
--      WHERE     ccmd.item_id             = in_item_id                 -- �i��ID
--      AND       cclr.start_date         <= NVL( gd_date_from, gd_process_date )
--                                                                      -- �J�n��
--      AND       cclr.end_date           >= NVL( gd_date_from, gd_process_date )
--                                                                      -- �I����
--      AND       flv.lookup_type          = cv_lookup_cost_cmpt        -- �Q�ƃ^�C�v
--      AND       flv.enabled_flag         = cv_yes                     -- �g�p�\
--      AND       ccmv.cost_cmpntcls_code  = flv.meaning                -- �����R���|�[�l���g�R�[�h
--      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id      -- �����R���|�[�l���gID
--      AND       ccmd.calendar_code       = cclr.calendar_code         -- �J�����_�R�[�h
--      AND       ccmd.period_code         = cclr.period_code           -- ���ԃR�[�h
--      AND       ccmd.whse_code           = cv_whse_code               -- �q��
--      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code          -- �������@
--      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code      -- ���̓R�[�h
--      GROUP BY  cclr.start_date;
---- End
    --
    CURSOR      cnp_cost_cur
    IS
      SELECT    DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_01gen, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_01gen, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                     cmpnt_cost1      -- 01GEN:����
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_02sai, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_02sai, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                     cmpnt_cost2      -- 02SAI:�Đ���
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_03szi, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_03szi, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost3     -- 03SZI:���ޔ�
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_04hou, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_04hou, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost4     -- 04HOU:���
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_05gai, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_05gai, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost5     -- 05GAI:�O�����H��
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_06hkn, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_06hkn, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost6     -- 06HKN:�ۊǔ�
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_07kei, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_07kei, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost7     -- 07KEI:���̑��o��
               ,SUM( ccmd.cmpnt_cost )                                      opm_cost_total  -- �W�������v
               ,cclr.start_date
      FROM      cm_cmpt_dtl          ccmd           -- OPM�W������
               ,cm_cldr_dtl          cclr           -- OPM�����J�����_
               ,cm_cmpt_mst_vl       ccmv           -- �����R���|�[�l���g
               ,fnd_lookup_values_vl flv            -- �Q�ƃR�[�h�l
      WHERE     ccmd.item_id             = in_item_id                 -- �i��ID
      AND       cclr.start_date         <= NVL( gd_date_from, gd_process_date )
                                                                      -- �J�n��
      AND       cclr.end_date           >= NVL( gd_date_from, gd_process_date )
                                                                      -- �I����
      AND       flv.lookup_type          = cv_lookup_cost_cmpt        -- �Q�ƃ^�C�v
      AND       flv.enabled_flag         = cv_yes                     -- �g�p�\
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                -- �����R���|�[�l���g�R�[�h
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id      -- �����R���|�[�l���gID
      AND       ccmd.calendar_code       = cclr.calendar_code         -- �J�����_�R�[�h
      AND       ccmd.period_code         = cclr.period_code           -- ���ԃR�[�h
      AND       ccmd.whse_code           = cv_whse_code               -- �q��
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code          -- �������@
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code      -- ���̓R�[�h
      GROUP BY  cclr.start_date;
-- End1.8
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �W�������擾(A-2.4, A-3.2)
    -- ===============================
    -- �W�������v�i�[�ϐ�������
    lv_step      := 'A-2.3, A-3.2';
    lv_msg_token := '�W�������擾';
-- Ver1.4 2009/02/12  �W�������v�̎擾���C��
--    on_cmp_cost := 0;
--    <<cnp_cost_loop>>
--    FOR lt_cost_rec IN cnp_cost_cur LOOP
--      on_cmp_cost   := on_cmp_cost + lt_cost_rec.cmpnt_cost;
--      od_apply_date := lt_cost_rec.start_date;
--    END LOOP cnp_cost_loop;
    --
    OPEN  cnp_cost_cur;
-- Ver1.8 2009/07/13  Mod  0000366�Ή�
--    FETCH cnp_cost_cur INTO on_cmp_cost, od_apply_date;
    FETCH cnp_cost_cur INTO l_opmcost_rec;
-- End1.8
    CLOSE cnp_cost_cur;
-- End1.4
--
-- Ver1.8 2009/07/13  Add  0000366�Ή�
    o_opmcost_rec := l_opmcost_rec;
-- End1.8
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cmp_cost;
--
--
  /**********************************************************************************
   * Procedure Name   : get_item_mst
   * Description      : �i�ڈꗗ���擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_item_mst(
    ov_errbuf            OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_mst'; -- �v���O������
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
    ln_cmp_cost      NUMBER;          -- �W�������v
    ld_apply_date    DATE;            -- �W�������K�p�J�n��
    ln_cnt           NUMBER;          -- �����p�ϐ�
    lv_step          VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token     VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �o�͑Ώېݒ�l�F���ݐݒ�l
    CURSOR      item_csv_cur1
    IS
      SELECT    xoiv.item_id,                     --�i��ID
                xoiv.item_code,                   --�i���R�[�h
                xoiv.item_name,                   --������
                xoiv.item_short_name,             --����
                xoiv.item_name_alt,               --�J�i��
                xoiv.item_status,                 --�i�ڃX�e�[�^�X
                isn.item_status_name,             --�i�ڃX�e�[�^�X��
                xoiv.sales_div,                   --����Ώۋ敪
                sdn.sales_div_name,               --����Ώۋ敪��
-- Ver1.4 2009/02/12  �e�i�ڃR�[�h�擾���@���C��
--                p_itm.parent_item_code,           --�e�i�ڃR�[�h
                p_itm.item_no        AS parent_item_code,
                                                  --�e�i�ڃR�[�h
-- End
                xoiv.num_of_cases,                --�P�[�X����
                xoiv.item_um,                     --�P��
                ipc.item_product_class,           --���i���i�敪
                ipc.item_product_class_name,      --���i���i�敪��
                xoiv.rate_class,                  --���敪
                rcn.rate_class_name,              --���敪��
                xoiv.net,                         --NET
                xoiv.unit,                        --�d��
                xoiv.jan_code,                    --JAN�R�[�h
                xoiv.nets,                        --���e��
                nuc.nets_uom_code_name,           --���e�ʒP��
                xoiv.inc_num,                     --�������
                xoiv.case_jan_code,               --�P�[�XJAN�R�[�h
                hpc.hon_product_class,            --�{�Џ��i�敪
                hpc.hon_product_class_name,       --�{�Џ��i�敪��
                xoiv.baracha_div,                 --�o�����敪
                bdn.baracha_div_name,             --�o�����敪��
                xoiv.itf_code,                    --ITF�R�[�h
                xoiv.product_class,               --���i����
                pcn.product_class_name,           --���i���ޖ�
                xoiv.palette_max_cs_qty,          --�z��
                xoiv.palette_max_step_qty,        --�p���b�g����ő�i��
                xoiv.bowl_inc_num,                --�{�[������
                xoiv.sell_start_date,             --�����i�����j�J�n��
                xoiv.obsolete_date,               --�p�~���i�������~���j
                xoiv.obsolete_class,              --�p�~�敪
                ocn.obsolete_class_name,          --�p�~�敪��
                xoiv.vessel_group,                --�e��Q
                vgn.vessel_group_name,            --�e��Q��
                xoiv.new_item_div,                --�V���i�敪
                nid.new_item_div_name,            --�V���i�敪��
                xoiv.acnt_group,                  --�o���Q
                agn.acnt_group_name,              --�o���Q��
                xoiv.acnt_vessel_group,           --�o���e��Q
                avg.acnt_vessel_group_name,       --�o���e��Q��
                xoiv.brand_group,                 --�u�����h�Q
                bgn.brand_group_name,             --�u�����h�Q��
                se.seisakugun,                    --����Q
                se.seisakugun_name,               --����Q��
                xoiv.price_old,                   --�艿�i���j
                xoiv.price_new,                   --�艿�i�V�j
                xoiv.price_apply_date,            --�艿�K�p�J�n��
                xoiv.opt_cost_old,                --�c�ƌ����i���j
                xoiv.opt_cost_new,                --�c�ƌ����i�V�j
                xoiv.opt_cost_apply_date,         --�c�ƌ����K�p�J�n��
                xoiv.renewal_item_code,           --���j���[�A�������i�R�[�h
                xoiv.sp_supplier_code,            --���X�d����R�[�h
                scn.ss_code_name                  --���X�d����
      FROM      xxcmm_opmmtl_items_v  xoiv,
-- Ver1.4 2009/02/12  �e�i�ڃR�[�h�擾���@���C��
--              ( SELECT    chi_itm.item_id,
--                          o_itm.item_no          AS parent_item_code
--                FROM      ic_item_mst_b          chi_itm,
--                          xxcmn_item_mst_b       ximb,
--                          ic_item_mst_b          o_itm
--                WHERE     chi_itm.item_id = ximb.item_id
--                AND       ximb.parent_item_id    = o_itm.item_id
--                AND       ximb.start_date_active <= TRUNC( SYSDATE )
--                AND       ximb.end_date_active   >= TRUNC( SYSDATE )
--              ) p_itm,  --�e�i�ڃR�[�h
                ic_item_mst_b          p_itm,  --�e�i�ڃR�[�h
-- End
-- Ver1.4 2009/02/13  8.�Öٌ^�ϊ������{����Ȃ��悤�C��
--              ( SELECT    flvv_isn.lookup_code  AS item_status,
              ( SELECT    TO_NUMBER( flvv_isn.lookup_code ) AS item_status,
                          flvv_isn.meaning      AS item_status_name
                FROM      fnd_lookup_values_vl  flvv_isn
                WHERE     flvv_isn.lookup_type  = cv_lookup_itm_status
              ) isn,    --�i�ڃX�e�[�^�X
              ( SELECT    flvv_sdn.lookup_code  AS sales_div,
                          flvv_sdn.meaning      AS sales_div_name
                FROM      fnd_lookup_values_vl  flvv_sdn
                WHERE     flvv_sdn.lookup_type  = cv_lookup_sales_class
              ) sdn,    --����Ώۋ敪
              ( SELECT    flvv_rcn.lookup_code  AS rate_class,
                          flvv_rcn.meaning      AS rate_class_name
                FROM      fnd_lookup_values_vl  flvv_rcn
                WHERE     flvv_rcn.lookup_type  = cv_lookup_rate_class
              ) rcn,    --���敪
              ( SELECT    flvv_nuc.lookup_code  AS nets_uom_code,
                          flvv_nuc.meaning      AS nets_uom_code_name
                FROM      fnd_lookup_values_vl  flvv_nuc
                WHERE     flvv_nuc.lookup_type  = cv_lookup_nets_uom
              ) nuc,    --���e�ʒP��
--              ( SELECT    flvv_bdn.lookup_code  AS baracha_div,
              ( SELECT    TO_NUMBER( flvv_bdn.lookup_code ) AS baracha_div,
                          flvv_bdn.meaning      AS baracha_div_name
                FROM      fnd_lookup_values_vl  flvv_bdn
                WHERE     flvv_bdn.lookup_type  = cv_lookup_baracha
              ) bdn,    --�o�����敪
--              ( SELECT    flvv_pcn.lookup_code  AS product_class,
              ( SELECT    TO_NUMBER( flvv_pcn.lookup_code ) AS product_class,
                          flvv_pcn.meaning      AS product_class_name
                FROM      fnd_lookup_values_vl  flvv_pcn
                WHERE     flvv_pcn.lookup_type  = cv_lookup_procuct_class
              ) pcn,    --���i����
              ( SELECT    flvv_ocn.lookup_code  AS obsolete_class,
                          flvv_ocn.meaning      AS obsolete_class_name
                FROM      fnd_lookup_values_vl  flvv_ocn
                WHERE     flvv_ocn.lookup_type  = cv_lookup_obso_class
              ) ocn,    --�p�~�敪
              ( SELECT    flvv_vgn.lookup_code  AS vessel_group,
                          flvv_vgn.meaning      AS vessel_group_name
                FROM      fnd_lookup_values_vl  flvv_vgn
                WHERE     flvv_vgn.lookup_type  = cv_lookup_vessel
              ) vgn,    --�e��Q
              ( SELECT    flvv_nid.lookup_code  AS new_item_div,
                          flvv_nid.meaning      AS new_item_div_name
                FROM      fnd_lookup_values_vl  flvv_nid
                WHERE     flvv_nid.lookup_type  = cv_lookup_new_item
              ) nid,    --�V���i�敪
              ( SELECT    flvv_agn.lookup_code  AS acnt_group,
                          flvv_agn.meaning      AS acnt_group_name
                FROM      fnd_lookup_values_vl  flvv_agn
                WHERE     flvv_agn.lookup_type  = cv_lookup_acnt_grp
              ) agn,    --�o���Q
              ( SELECT    flvv_avg.lookup_code  AS acnt_vessel_group,
                          flvv_avg.meaning      AS acnt_vessel_group_name
                FROM      fnd_lookup_values_vl  flvv_avg
                WHERE     flvv_avg.lookup_type  = cv_lookup_acnt_vessel
              ) avg,    --�o���e��Q
              ( SELECT    flvv_bgn.lookup_code  AS brand_group,
                          flvv_bgn.meaning      AS brand_group_name
                FROM      fnd_lookup_values_vl  flvv_bgn
                WHERE     flvv_bgn.lookup_type  = cv_lookup_brand
              ) bgn,    --�u�����h�Q
              ( SELECT    flvv_scn.lookup_code  AS sp_supplier_code,
                          flvv_scn.description  AS ss_code_name
                          --meaning����description�ɕύX 2009/01/20
                FROM      fnd_lookup_values_vl  flvv_scn
                WHERE     flvv_scn.lookup_type  = cv_lookup_supplier
              ) scn,    --���X�d����
              ( SELECT    gic_se.item_id             AS item_id,
                          mcv_se.segment1            AS seisakugun,
                          mcv_se.description         AS seisakugun_name
                FROM      gmi_item_categories        gic_se,
                          mtl_category_sets_vl       mcsv_se,
                          mtl_categories_vl          mcv_se
                WHERE     gic_se.category_set_id     = mcsv_se.category_set_id
                AND       gic_se.category_id         = mcv_se.category_id
                AND       mcsv_se.category_set_name  = cv_categ_set_seisakugun
              ) se,     --����Q
              ( SELECT    gic_ipc.item_id            AS item_id,
                          mcv_ipc.segment1           AS item_product_class,
                          mcv_ipc.description        AS item_product_class_name
                FROM      gmi_item_categories        gic_ipc,
                          mtl_category_sets_vl       mcsv_ipc,
                          mtl_categories_vl          mcv_ipc
                WHERE     gic_ipc.category_set_id    = mcsv_ipc.category_set_id
                AND       gic_ipc.category_id        = mcv_ipc.category_id
-- Ver1.5 2009/02/17  1.�{�Џ��i�敪�Ə��i���i�敪�̓���ւ�
--                AND       mcsv_ipc.category_set_name = cv_categ_set_hon_prod
                AND       mcsv_ipc.category_set_name = cv_categ_set_item_prod
              ) ipc,  --���i���i�敪
              ( SELECT    gic_hpc.item_id            AS item_id,
                          mcv_hpc.segment1           AS hon_product_class,
                          mcv_hpc.description        AS hon_product_class_name
                FROM      gmi_item_categories        gic_hpc,
                          mtl_category_sets_vl       mcsv_hpc,
                          mtl_categories_vl          mcv_hpc
                WHERE     gic_hpc.category_set_id    = mcsv_hpc.category_set_id
                AND       gic_hpc.category_id        = mcv_hpc.category_id
--                AND       mcsv_hpc.category_set_name = cv_categ_set_item_prod
                AND       mcsv_hpc.category_set_name = cv_categ_set_hon_prod
-- End1.5
              ) hpc    --�{�Џ��i�敪
      WHERE     xoiv.parent_item_id     =  p_itm.item_id(+)             --�e�i�ڃR�[�h
      AND       xoiv.item_status        =  isn.item_status(+)           --�i�ڃX�e�[�^�X
      AND       xoiv.sales_div          =  sdn.sales_div(+)             --����Ώۋ敪
      AND       xoiv.rate_class         =  rcn.rate_class(+)            --���敪
      AND       xoiv.nets_uom_code      =  nuc.nets_uom_code(+)         --���e�ʒP��
      AND       xoiv.baracha_div        =  bdn.baracha_div(+)           --�o�����敪
      AND       xoiv.product_class      =  pcn.product_class(+)         --���i����
      AND       xoiv.obsolete_class     =  ocn.obsolete_class(+)        --�p�~�敪
      AND       xoiv.vessel_group       =  vgn.vessel_group(+)          --�e��Q
      AND       xoiv.new_item_div       =  nid.new_item_div(+)          --�V���i�敪
      AND       xoiv.acnt_group         =  agn.acnt_group(+)            --�o���Q
      AND       xoiv.acnt_vessel_group  =  avg.acnt_vessel_group(+)     --�o���e��Q
      AND       xoiv.brand_group        =  bgn.brand_group(+)           --�u�����h�Q
      AND       xoiv.sp_supplier_code   =  scn.sp_supplier_code(+)      --���X�d����
      AND       xoiv.item_id            =  se.item_id(+)                --����Q
      AND       xoiv.item_id            =  ipc.item_id(+)               --���i���i�敪
      AND       xoiv.item_id            =  hpc.item_id(+)               --�{�Џ��i�敪
-- 2009/08/12 Ver1.9 modify start by Y.Kuboshima
--      AND       xoiv.start_date_active  <= TRUNC( SYSDATE )
--      AND       xoiv.end_date_active    >= TRUNC( SYSDATE )
      AND       xoiv.start_date_active  <= gd_process_date
      AND       xoiv.end_date_active    >= gd_process_date
-- 2009/08/12 Ver1.9 modify end by Y.Kuboshima
-- Ver1.4 2009/02/12  ���Ԗ��w�莞�͑S���擾����悤�C��
--      AND     ( TRUNC( xoiv.search_update_date ) >= gd_date_from        --�����Ώۓ����ɕύX 2009/02/03
--      AND       TRUNC( xoiv.search_update_date ) <= gd_date_to )        --�Ώۊ���
      AND     ( (   gd_date_from IS NULL )
             OR (   gd_date_from IS NOT NULL
                AND TRUNC( xoiv.search_update_date ) >= gd_date_from ))
      AND     ( (   gd_date_to   IS NULL )
             OR (   gd_date_to   IS NOT NULL
                AND TRUNC( xoiv.search_update_date ) <= gd_date_to   ))
-- End
-- Ver1.7 2009/05/27  Mod  �s�v�ȕi�ڃR�[�h�͈͐ݒ���폜�ɔ����C��
--      AND     ( xoiv.item_code   >= gv_item_code_from
--      AND       xoiv.item_code   <= gv_item_code_to )                   --�i���R�[�h
      AND     ( (   gv_item_code_from IS NULL )
             OR (   gv_item_code_from IS NOT NULL
                AND xoiv.item_code   >= gv_item_code_from ))
      AND     ( (   gv_item_code_to   IS NULL )
             OR (   gv_item_code_to   IS NOT NULL
                AND xoiv.item_code   <= gv_item_code_to   ))
-- End1.7
      AND   ( ( gn_item_status IS NULL )
      OR      ( gn_item_status IS NOT NULL AND xoiv.item_status = gn_item_status ) ) -- �i�ڃX�e�[�^�X
      ORDER BY  se.seisakugun,
                xoiv.item_code;
      --BETWEEN����߂� 2009/01/20
--
    -- �o�͑Ώېݒ�l�F�\��ݒ�l
    -- ���o�����̕i�ڃX�e�[�^�X��Disc�i�ڕύX�����A�h�I�������� 2009/01/20�C��
    CURSOR      item_csv_cur2
    IS
      SELECT    xsibh.item_hst_id,                                      --�i�ڕύX����ID
                xsibh.item_id,                                          --�i��ID
                xsibh.item_code,                                        --�i�ڃR�[�h
                xoiv.item_name,                                         --������
                xsibh.apply_date,                                       --�K�p���i�K�p�J�n���j
                xsibh.item_status,                                      --�i�ڃX�e�[�^�X
                isn.item_status_name,                                   --�i�ڃX�e�[�^�X��
                xsibh.fixed_price,                                      --�艿
                xsibh.discrete_cost,                                    --�c�ƌ���
                xsibh.policy_group,                                     --����Q�R�[�h
                se.policy_grp_name                                      --����Q��
      FROM      xxcmm_system_items_b_hst  xsibh,
                xxcmm_opmmtl_items_v      xoiv,
-- Ver1.4 2009/02/13  8.�Öٌ^�ϊ������{����Ȃ��悤�C��
--              ( SELECT    flvv_isn.lookup_code  AS item_status,
              ( SELECT    TO_NUMBER( flvv_isn.lookup_code ) AS item_status,
                          flvv_isn.meaning      AS item_status_name
                FROM      fnd_lookup_values_vl  flvv_isn
                WHERE     flvv_isn.lookup_type  = cv_lookup_itm_status
              ) isn,  --�i�ڃX�e�[�^�X
              ( SELECT    xsibh.item_hst_id,
                          xsibh.policy_group,
                          mcv.description      policy_grp_name
                FROM      xxcmm_system_items_b_hst   xsibh,
                          mtl_categories_vl          mcv,
                          mtl_category_sets_vl       mcsv
                WHERE     xsibh.policy_group         = mcv.segment1
                AND       mcv.structure_id           = mcsv.structure_id
                AND       mcsv.category_set_name     = cv_categ_set_seisakugun
              ) se  --����Q�R�[�h
      WHERE     xsibh.item_code         = xoiv.item_code                        -- �i���R�[�h
      AND       xsibh.item_status       = isn.item_status(+)                    -- �i�ڃX�e�[�^�X
      AND       xsibh.item_hst_id       = se.item_hst_id(+)                     -- ����Q
      AND       xsibh.apply_flag        = cv_no                                 -- �K�p�t���O
-- 2009/08/12 Ver1.9 modify start by Y.Kuboshima
--      AND       xoiv.start_date_active  <= TRUNC( SYSDATE )
--      AND       xoiv.end_date_active    >= TRUNC( SYSDATE )
      AND       xoiv.start_date_active  <= gd_process_date
      AND       xoiv.end_date_active    >= gd_process_date
-- 2009/08/12 Ver1.9 modify end by Y.Kuboshima
-- Ver1.4 2009/02/12  ���Ԗ��w�莞�͑S���擾����悤�C��
--      AND     ( TRUNC( xsibh.apply_date ) >= gd_date_from                       -- �K�p���ɕύX 2009/02/03
--      AND       TRUNC( xsibh.apply_date ) <= gd_date_to )                       -- �Ώۊ���
      AND     ( (   gd_date_from IS NULL )
             OR (   gd_date_from IS NOT NULL
                AND xsibh.apply_date >= gd_date_from ))
      AND     ( (   gd_date_to   IS NULL )
             OR (   gd_date_to   IS NOT NULL
                AND xsibh.apply_date <= gd_date_to   ))
-- End
-- Ver1.7 2009/05/27  Mod  �s�v�ȕi�ڃR�[�h�͈͐ݒ���폜�ɔ����C��
--      AND     ( xoiv.item_code    >= gv_item_code_from
--      AND       xoiv.item_code    <= gv_item_code_to )                          -- �i���R�[�h
      AND     ( (   gv_item_code_from IS NULL )
             OR (   gv_item_code_from IS NOT NULL
                AND xoiv.item_code   >= gv_item_code_from ))
      AND     ( (   gv_item_code_to   IS NULL )
             OR (   gv_item_code_to   IS NOT NULL
                AND xoiv.item_code   <= gv_item_code_to   ))
-- End1.7
      AND   ( ( gn_item_status IS NULL )
      OR      ( gn_item_status IS NOT NULL AND xsibh.item_status = gn_item_status ) ) -- �i�ڃX�e�[�^�X
-- Ver1.4 2009/02/12  �\�[�g���C��
--   �E ����i�ڂœK�p�����΂�΂�ɏo�͂����̂ŏC��
--   �E �i�ڏ��ɕ��΂Ȃ��Ȃ�̂͂��肦��̂ŁA����Q���Ƀ\�[�g����̂͂Ƃ肠�����폜
--      ������Q���\�[�g�ɉ�����̂ł���΁A�ݒ肳��Ă���l�Ń\�[�g���邱�ƁB
--      ORDER BY  xsibh.policy_group,
--                xoiv.item_code;
      ORDER BY  xoiv.item_code,
                xsibh.apply_date;
-- End
      --BETWEEN����߂� 2009/01/20
--
-- Ver1.8  2009/07/13  Add  0000364�Ή�
    l_opmcost_rec    g_opmcost_rtype;  -- �W���������R�[�h
-- End1.8
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_data_expt     EXCEPTION;
    select_err_expt  EXCEPTION;
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�E���g�p�ϐ�������
    lv_step := 'A-2.1';
    ln_cnt := 0;
    IF ( gv_output_div = cv_output_div ) THEN
      <<item_csv_cur1_loop>>
      -- ===============================
      -- �i�ڈꗗ���擾(A-2.1)
      -- ===============================
      FOR lt_item01_rec IN item_csv_cur1 LOOP
        -- =======================
        -- �W�������擾(A-2.4)
        -- =======================
        lv_step      := 'A-2.4';
        lv_msg_token := '�W�������擾';
        get_cmp_cost(
          in_item_id     => lt_item01_rec.item_id,    -- IN  �i��ID
-- Ver1.8  2009/07/13  Mod  0000364�Ή�
--          on_cmp_cost    => ln_cmp_cost,              -- OUT �W�������v
--          od_apply_date  => ld_apply_date,            -- OUT �W�������K�p�J�n��
          o_opmcost_rec  => l_opmcost_rec,            -- OUT �W���������R�[�h
-- End1.8
          ov_errbuf      => lv_errbuf,                -- OUT �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode     => lv_retcode,               -- OUT ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg      => lv_errmsg                 -- OUT ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm,
                          iv_name         => cv_msg_xxcmm_00485,
                          iv_token_name1  => cv_tkn_date_name,
                          iv_token_value1 => cv_cmpt_cost,
                          iv_token_name2  => cv_tkn_item_code,
                          iv_token_value2 => lt_item01_rec.item_code
                        );
          RAISE select_err_expt;
        END IF;
        --
        ln_cnt := ln_cnt + 1;    -- ����
        --
        -- ���[�N�e�[�u���Ƀf�[�^��insert
        INSERT INTO xxcmm_wk_item_csv(
          item_id,                      -- �i��ID
          item_code,                    -- �i���R�[�h
          item_name,                    -- ������
          item_short_name,              -- ����
          item_name_alt,                -- �J�i��
          item_status,                  -- �i�ڃX�e�[�^�X
          item_status_name,             -- �i�ڃX�e�[�^�X��
          sales_div,                    -- ����Ώۋ敪
          sales_div_name,               -- ����Ώۋ敪��
          parent_item_code,             -- �e�i�ڃR�[�h
          num_of_cases,                 -- �P�[�X����
          item_um,                      -- �P��
          item_product_class,           -- ���i���i�敪
          item_product_class_name,      -- ���i���i�敪��
          rate_class,                   -- ���敪
          rate_class_name,              -- ���敪��
          net,                          -- NET
          unit,                         -- �d��
          jan_code,                     -- JAN�R�[�h
          nets,                         -- ���e��
          nets_uom_code_name,           -- ���e�ʒP��
          inc_num,                      -- �������
          case_jan_code,                -- �P�[�XJAN�R�[�h
          hon_product_class,            -- �{�Џ��i�敪
          hon_product_class_name,       -- �{�Џ��i�敪��
          baracha_div,                  -- �o�����敪
          baracha_div_name,             -- �o�����敪��
          itf_code,                     -- ITF�R�[�h
          product_class,                -- ���i����
          product_class_name,           -- ���i���ޖ�
          palette_max_cs_qty,           -- �z��
          palette_max_step_qty,         -- �p���b�g����ő�i��
          bowl_inc_num,                 -- �{�[������
          sell_start_date,              -- ����(����)�J�n��
          obsolete_date,                -- �p�~��(�������~��)
          obsolete_class,               -- �p�~�敪
          obsolete_class_name,          -- �p�~�敪��
          vessel_group,                 -- �e��Q
          vessel_group_name,            -- �e��Q��
          new_item_div,                 -- �V���i�敪
          new_item_div_name,            -- �V���i�敪��
          acnt_group,                   -- �o���Q
          acnt_group_name,              -- �o���Q��
          acnt_vessel_group,            -- �o���e��Q
          acnt_vessel_group_name,       -- �o���e��Q��
          brand_group,                  -- �u�����h�Q
          brand_group_name,             -- �u�����h�Q��
          seisakugun,                   -- ����Q
          seisakugun_name,              -- ����Q��
          price_old,                    -- �艿(��)
          price_new,                    -- �艿(�V)
          price_apply_date,             -- �艿�K�p�J�n��
          opt_cost_old,                 -- �c�ƌ���(��)
          opt_cost_new,                 -- �c�ƌ���(�V)
          opt_cost_apply_date,          -- �c�ƌ����K�p�J�n��
          cmpnt_cost,                   -- �W�������v
-- Ver1.8  2009/07/13  Add  0000366�Ή�
          cmpnt_01gen,                  -- �W�������i�����j
          cmpnt_02sai,                  -- �W�������i�Đ���j
          cmpnt_03szi,                  -- �W�������i���ޔ�j
          cmpnt_04hou,                  -- �W�������i���j
          cmpnt_05gai,                  -- �W�������i�O�����H��j
          cmpnt_06hkn,                  -- �W�������i�ۊǔ�j
          cmpnt_07kei,                  -- �W�������i���̑��o��j
-- End1.8
          cmp_cost_apply_date,          -- �W�������K�p�J�n��
          renewal_item_code,            -- ���j���[�A�����i���R�[�h
          sp_supplier_code,             -- ���X�d����R�[�h
          ss_code_name,                 -- ���X�d����
          created_by,                   -- CREATED_BY
          creation_date,                -- CREATION_DATE
          last_updated_by,              -- LAST_UPDATED_BY
          last_update_date,             -- LAST_UPDATE_DATE
          last_update_login,            -- LAST_UPDATE_LOGIN
          request_id,                   -- REQUEST_ID
          program_application_id,       -- PROGRAM_APPLICATION_ID
          program_id,                   -- PROGRAM_ID
          program_update_date           -- PROGRAM_UPDATE_DATE
        ) VALUES (
          lt_item01_rec.item_id,                  -- �i��ID
          lt_item01_rec.item_code,                -- �i���R�[�h
          lt_item01_rec.item_name,                -- ������
          lt_item01_rec.item_short_name,          -- ����
          lt_item01_rec.item_name_alt,            -- �J�i��
          lt_item01_rec.item_status,              -- �i�ڃX�e�[�^�X
          lt_item01_rec.item_status_name,         -- �i�ڃX�e�[�^�X��
          lt_item01_rec.sales_div,                -- ����Ώۋ敪
          lt_item01_rec.sales_div_name,           -- ����Ώۋ敪��
          lt_item01_rec.parent_item_code,         -- �e�i��ID
          lt_item01_rec.num_of_cases,             -- �P�[�X����
          lt_item01_rec.item_um,                  -- �P��
          lt_item01_rec.item_product_class,       -- ���i���i�敪
          lt_item01_rec.item_product_class_name,  -- ���i���i�敪��
          lt_item01_rec.rate_class,               -- ���敪
          lt_item01_rec.rate_class_name,          -- ���敪��
          lt_item01_rec.net,                      -- NET
          lt_item01_rec.unit,                     -- �d��
          lt_item01_rec.jan_code,                 -- JAN�R�[�h
          lt_item01_rec.nets,                     -- ���e��
          lt_item01_rec.nets_uom_code_name,       -- ���e�ʒP��
          lt_item01_rec.inc_num,                  -- �������
          lt_item01_rec.case_jan_code,            -- �P�[�XJAN�R�[�h
          lt_item01_rec.hon_product_class,        -- �{�Џ��i�敪
          lt_item01_rec.hon_product_class_name,   -- �{�Џ��i�敪��
          lt_item01_rec.baracha_div,              -- �o�����敪
          lt_item01_rec.baracha_div_name,         -- �o�����敪��
          lt_item01_rec.itf_code,                 -- ITF�R�[�h
          lt_item01_rec.product_class,            -- ���i����
          lt_item01_rec.product_class_name,       -- ���i���ޖ�
          lt_item01_rec.palette_max_cs_qty,       -- �z��
          lt_item01_rec.palette_max_step_qty,     -- �p���b�g����ő�i��
          lt_item01_rec.bowl_inc_num,             -- �{�[������
          lt_item01_rec.sell_start_date,          -- ����(����)�J�n��
          lt_item01_rec.obsolete_date,            -- �p�~��(�������~��)
          lt_item01_rec.obsolete_class,           -- �p�~�敪
          lt_item01_rec.obsolete_class_name,      -- �p�~�敪��
          lt_item01_rec.vessel_group,             -- �e��Q
          lt_item01_rec.vessel_group_name,        -- �e��Q��
          lt_item01_rec.new_item_div,             -- �V���i�敪
          lt_item01_rec.new_item_div_name,        -- �V���i�敪��
          lt_item01_rec.acnt_group,               -- �o���Q
          lt_item01_rec.acnt_group_name,          -- �o���Q��
          lt_item01_rec.acnt_vessel_group,        -- �o���e��Q
          lt_item01_rec.acnt_vessel_group_name,   -- �o���e��Q��
          lt_item01_rec.brand_group,              -- �u�����h�Q
          lt_item01_rec.brand_group_name,         -- �u�����h�Q��
          lt_item01_rec.seisakugun,               -- ����Q
          lt_item01_rec.seisakugun_name,          -- ����Q��
          lt_item01_rec.price_old,                -- �艿(��)
          lt_item01_rec.price_new,                -- �艿(�V)
          lt_item01_rec.price_apply_date,         -- �艿�K�p�J�n��
          lt_item01_rec.opt_cost_old,             -- �c�ƌ���(��)
          lt_item01_rec.opt_cost_new,             -- �c�ƌ���(�V)
          lt_item01_rec.opt_cost_apply_date,      -- �c�ƌ����K�p�J�n��
-- Ver1.8  2009/07/13  Mod  0000364�Ή�
--          ln_cmp_cost,                            -- �W�������v
--          ld_apply_date,                          -- �W�������K�p�J�n��
          l_opmcost_rec.cmpnt_cost,               -- �W�������v
          l_opmcost_rec.cmpnt_cost1,              -- ����
          l_opmcost_rec.cmpnt_cost2,              -- �Đ���
          l_opmcost_rec.cmpnt_cost3,              -- ���ޔ�
          l_opmcost_rec.cmpnt_cost4,              -- ���
          l_opmcost_rec.cmpnt_cost5,              -- �O�����H��
          l_opmcost_rec.cmpnt_cost6,              -- �ۊǔ�
          l_opmcost_rec.cmpnt_cost7,              -- ���̑��o��
          l_opmcost_rec.start_date,               -- �W�������K�p�J�n��
-- End1.8
          lt_item01_rec.renewal_item_code,        -- ���j���[�A�����i���R�[�h
          lt_item01_rec.sp_supplier_code,         -- ���X�d����R�[�h
          lt_item01_rec.ss_code_name,             -- ���X�d����
          cn_created_by,                          -- CREATED_BY
          cd_creation_date,                       -- CREATION_DATE
          cn_last_updated_by,                     -- LAST_UPDATED_BY
          cd_last_update_date,                    -- LAST_UPDATE_DATE
          cn_last_update_login,                   -- LAST_UPDATE_LOGIN
          cn_request_id,                          -- REQUEST_ID
          cn_program_application_id,              -- PROGRAM_APPLICATION_ID
          cn_program_id,                          -- PROGRAM_ID
          cd_program_update_date                  -- PROGRAM_UPDATE_DATE
        );
        -- �G���[�������܂ł̌�����\�����邽�߃��[�v���Ɍ������Z�b�g���� 2009/01/20�C��
        -- �����̃J�E���g�������b�Z�[�W�p�̕ϐ��ɑ��
        gn_target_cnt := ln_cnt;
      END LOOP item_csv_cur1_loop;
    ELSE
      -- ===============================
      -- �i�ڈꗗ���擾(A-3.1)
      -- ===============================
      <<item_csv_cur2_loop>>
      FOR lt_item01_rec IN item_csv_cur2 LOOP
        -- =======================
        -- �W�������擾(A-3.2)
        -- =======================
        lv_step      := 'A-3.2';
        lv_msg_token := '�W�������擾';
        get_cmp_cost(
          in_item_id     => lt_item01_rec.item_id,    -- IN  �i��ID
-- Ver1.8  2009/07/13  Mod  0000364�Ή�
--          on_cmp_cost    => ln_cmp_cost,              -- OUT �W�������v
--          od_apply_date  => ld_apply_date,            -- OUT �W�������K�p�J�n��
          o_opmcost_rec  => l_opmcost_rec,            -- OUT �W���������R�[�h
-- End1.8
          ov_errbuf      => lv_errbuf,                -- OUT �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode     => lv_retcode,               -- OUT ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg      => lv_errmsg                 -- OUT ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm,
                          iv_name         => cv_msg_xxcmm_00485,
                          iv_token_name1  => cv_tkn_date_name,
                          iv_token_value1 => cv_cmpt_cost,
                          iv_token_name2  => cv_tkn_item_code,
                          iv_token_value2 => lt_item01_rec.item_code
                        );
          RAISE select_err_expt;
        END IF;
        --
        ln_cnt := ln_cnt + 1;    -- ����
        --
        -- ���[�N�e�[�u���Ƀf�[�^��insert
        INSERT INTO xxcmm_wk_itemrsv_csv(
          item_id,                 -- �i��ID
          item_code,               -- �i���R�[�h
          item_name,               -- ������
          apply_date,              -- �K�p�J�n��
          item_status,             -- �i�ڃX�e�[�^�X
          item_status_name,        -- �i�ڃX�e�[�^�X��
          fixed_price,             -- �艿
          cmpnt_cost,              -- �W�������v
-- Ver1.8  2009/07/13  Add  0000366�Ή�
          cmpnt_01gen,             -- �W�������i�����j
          cmpnt_02sai,             -- �W�������i�Đ���j
          cmpnt_03szi,             -- �W�������i���ޔ�j
          cmpnt_04hou,             -- �W�������i���j
          cmpnt_05gai,             -- �W�������i�O�����H��j
          cmpnt_06hkn,             -- �W�������i�ۊǔ�j
          cmpnt_07kei,             -- �W�������i���̑��o��j
-- End1.8
          cmp_cost_apply_date,     -- �W�������K�p�J�n��
          discrete_cost,           -- �c�ƌ���
          policy_group,            -- ����Q
          policy_grp_name,         -- ����Q��
          created_by,              -- CREATED_BY
          creation_date,           -- CREATION_DATE
          last_updated_by,         -- LAST_UPDATED_BY
          last_update_date,        -- LAST_UPDATE_DATE
          last_update_login,       -- LAST_UPDATE_LOGIN
          request_id,              -- REQUEST_ID
          program_application_id,  -- PROGRAM_APPLICATION_ID
          program_id,              -- PROGRAM_ID
          program_update_date      -- PROGRAM_UPDATE_DATE
        ) VALUES (
          lt_item01_rec.item_id,           -- �i��ID
          lt_item01_rec.item_code,         -- �i���R�[�h
          lt_item01_rec.item_name,         -- ������
          lt_item01_rec.apply_date,        -- �K�p�J�n��
          lt_item01_rec.item_status,       -- �i�ڃX�e�[�^�X
          lt_item01_rec.item_status_name,  -- �i�ڃX�e�[�^�X��
          lt_item01_rec.fixed_price,       -- �艿
-- Ver1.8  2009/07/13  Mod  0000364�Ή�
--          ln_cmp_cost,                     -- �W�������v
--          ld_apply_date,                   -- �W�������K�p�J�n��
          l_opmcost_rec.cmpnt_cost,        -- �W�������v
          l_opmcost_rec.cmpnt_cost1,       -- ����
          l_opmcost_rec.cmpnt_cost2,       -- �Đ���
          l_opmcost_rec.cmpnt_cost3,       -- ���ޔ�
          l_opmcost_rec.cmpnt_cost4,       -- ���
          l_opmcost_rec.cmpnt_cost5,       -- �O�����H��
          l_opmcost_rec.cmpnt_cost6,       -- �ۊǔ�
          l_opmcost_rec.cmpnt_cost7,       -- ���̑��o��
          l_opmcost_rec.start_date,        -- �W�������K�p�J�n��
-- End1.8
          lt_item01_rec.discrete_cost,     -- �c�ƌ���
          lt_item01_rec.policy_group,      -- ����Q
          lt_item01_rec.policy_grp_name,   -- ����Q��
          cn_created_by,                   -- CREATED_BY
          cd_creation_date,                -- CREATION_DATE
          cn_last_updated_by,              -- LAST_UPDATED_BY
          cd_last_update_date,             -- LAST_UPDATE_DATE
          cn_last_update_login,            -- LAST_UPDATE_LOGIN
          cn_request_id,                   -- REQUEST_ID
          cn_program_application_id,       -- PROGRAM_APPLICATION_ID
          cn_program_id,                   -- PROGRAM_ID
          cd_program_update_date           -- PROGRAM_UPDATE_DATE
        );
        -- �G���[�������܂ł̌�����\�����邽�߃��[�v���Ɍ������Z�b�g���� 2009/01/20�C��
        -- �����̃J�E���g�������b�Z�[�W�p�̕ϐ��ɑ��
        gn_target_cnt := ln_cnt;
      END LOOP item_csv_cur2_loop;
    END IF;
    -- �J�E���g�p�ϐ���'0'�̎��A�f�[�^�Ȃ�
    IF ( ln_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
    --
--
  EXCEPTION
    -- ���^�[���R�[�h�F�G���[���O���Đ���I������悤�ɏC�� 2009/01/20
    WHEN no_data_expt THEN  --�Ώۃf�[�^����
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm,
                      iv_name         => cv_msg_xxcmm_00001
                    );
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
    WHEN select_err_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_item_mst;
--
--
  /**********************************************************************************
   * Procedure Name   : get_item_header
   * Description      : ���ڃ^�C�g���擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_header(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_header'; -- �v���O������
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
    lv_csv_file     VARCHAR2(5000);  -- �o�͏��
    ln_cnt          NUMBER;
    lv_step         VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token    VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR      lookup_itemlist_cur
    IS
      SELECT    flv.lookup_code,
                flv.description
      FROM      fnd_lookup_values_vl flv
      WHERE     flv.lookup_type = cv_lookup_item_head
      AND       flv.attribute1  = gv_output_div
      ORDER BY  flv.lookup_code;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_data_expt  EXCEPTION;
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ���ڃ^�C�g���擾(A-4)
    -- ===============================
    lv_step      := 'A-4';
    lv_msg_token := '���ڃ^�C�g���擾';
    -- �ϐ�������
    lv_csv_file := NULL;
    ln_cnt      := 0;
    -- ���b�N�A�b�v���獀�ڃ^�C�g�����擾��CSV�`���ɂ���
    <<head_info_loop>>
    FOR lt_head_info_rec IN lookup_itemlist_cur LOOP
      ln_cnt := ln_cnt + 1;
      lv_csv_file := lv_csv_file || lt_head_info_rec.description || cv_sep_com;
    END LOOP head_info_loop;
    --
    -- �J�E���g�ϐ���'0'�̎��A�f�[�^�Ȃ�
    IF ( ln_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
    --
    lv_csv_file := SUBSTRB(lv_csv_file, 1, LENGTHB(lv_csv_file) - 1);
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_file
    );
--
  EXCEPTION
    -- ���^�[���R�[�h�F�G���[���O���Đ���I������悤�ɏC�� 2009/01/20
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm,
                      iv_name         => cv_msg_xxcmm_00001
                    );
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_item_header;
--
--
  /**********************************************************************************
   * Procedure Name   : output_csv�i���[�v���j
   * Description      : CSV�t�@�C���o��(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_file_type  IN  VARCHAR2,            -- �t�@�C�����
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    lv_csv_file     VARCHAR2(5000);  -- �o�͏��
    ln_c            NUMBER;
    lv_step         VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token    VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �f�[�^�擾(���ݐݒ�l)
    CURSOR      csv_data_cur1
    IS
      SELECT    xicw.item_code,                -- �i���R�[�h
                xicw.item_name,                -- ������
                xicw.item_short_name,          -- ����
                xicw.item_name_alt,            -- �J�i��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.item_status,
                TO_CHAR( xicw.item_status )    AS item_status,
                                               -- �i�ڃX�e�[�^�X
-- End
                xicw.item_status_name,         -- �i�ڃX�e�[�^�X��
                xicw.sales_div,                -- ����Ώۋ敪
                xicw.sales_div_name,           -- ����Ώۋ敪��
                xicw.parent_item_code,         -- �e�i�ڃR�[�h
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.num_of_cases,
                TO_CHAR( xicw.num_of_cases )   AS num_of_cases,
                                               -- �P�[�X����
-- End
                xicw.item_um,                  -- �P��
                xicw.item_product_class,       -- ���i���i�敪
                xicw.item_product_class_name,  -- ���i���i�敪��
                xicw.rate_class,               -- ���敪
                xicw.rate_class_name,          -- ���敪��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.net,
--                xicw.unit,
                TO_CHAR( xicw.net )            AS net,
                                               -- NET
                TO_CHAR( xicw.unit )           AS unit,
                                               -- �d��
-- End
                xicw.jan_code,                 -- JAN�R�[�h
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.nets,
-- Ver1.4 2009/02/13  7.Disc�i�ڃA�h�I���̐��l���ځu���e�ʁv�����ύX�ɔ����C��
--                TO_CHAR( xicw.nets )           AS nets,
                TRIM ( TO_CHAR( xicw.nets , cv_number_fmt) )           AS nets,
                                               -- ���e��
-- End1.4
                xicw.nets_uom_code_name,       -- ���e�ʒP��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.inc_num,
-- Ver1.4 2009/02/13  7.Disc�i�ڃA�h�I���̐��l���ځu��������v�����ύX�ɔ����C��
--                TO_CHAR( xicw.inc_num )        AS inc_num,
                TRIM ( TO_CHAR( xicw.inc_num , cv_number_fmt ) )        AS inc_num,
                                               -- �������
-- End1.4
                xicw.case_jan_code,            -- �P�[�XJAN�R�[�h
                xicw.hon_product_class,        -- �{�Џ��i�敪
                xicw.hon_product_class_name,   -- �{�Џ��i�敪��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.baracha_div,
                TO_CHAR( xicw.baracha_div )    AS baracha_div,
                                               -- �o�����敪
-- End
                xicw.baracha_div_name,         -- �o�����敪��
                xicw.itf_code,                 -- ITF�R�[�h
                xicw.product_class,            -- ���i����
                xicw.product_class_name,       -- ���i���ޖ�
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.palette_max_cs_qty,
--                xicw.palette_max_step_qty,
--                xicw.bowl_inc_num,
                TO_CHAR( xicw.palette_max_cs_qty )    AS palette_max_cs_qty,
                                               -- �z��
                TO_CHAR( xicw.palette_max_step_qty )  AS palette_max_step_qty,
                                               -- �p���b�g����ő�i��
                TO_CHAR( xicw.bowl_inc_num )   AS bowl_inc_num,
                                               -- �{�[������
-- End
                xicw.sell_start_date,          -- ����(����)�J�n��
                xicw.obsolete_date,            -- �p�~��(�������~��)
                xicw.obsolete_class,           -- �p�~�敪
                xicw.obsolete_class_name,      -- �p�~�敪��
                xicw.vessel_group,             -- �e��Q
                xicw.vessel_group_name,        -- �e��Q��
                xicw.new_item_div,             -- �V���i�敪
                xicw.new_item_div_name,        -- �V���i�敪��
                xicw.acnt_group,               -- �o���Q
                xicw.acnt_group_name,          -- �o���Q��
                xicw.acnt_vessel_group,        -- �o���e��Q
                xicw.acnt_vessel_group_name,   -- �o���e��Q��
                xicw.brand_group,              -- �u�����h�Q
                xicw.brand_group_name,         -- �u�����h�Q��
                xicw.renewal_item_code,        -- ���j���[�A�����i���R�[�h
                xicw.sp_supplier_code,         -- ���X�d����R�[�h
                xicw.ss_code_name,             -- ���X�d����
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
                TO_CHAR( xicw.price_old )      AS price_old,
                                               -- �艿(��)
                TO_CHAR( xicw.price_new )      AS price_new,
                                               -- �艿(�V)
-- End
                xicw.price_apply_date,         -- �艿�K�p�J�n��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
                TO_CHAR( xicw.opt_cost_old )   AS opt_cost_old,
                                               -- �c�ƌ���(��)
                TO_CHAR( xicw.opt_cost_new )   AS opt_cost_new,
                                               -- �c�ƌ���(�V)
-- End
                xicw.opt_cost_apply_date,      -- �c�ƌ����K�p�J�n��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
                TO_CHAR( xicw.cmpnt_cost )     AS cmpnt_cost,
                                               -- �W�������v
-- End
-- Ver1.8  2009/07/13  Add  0000366�Ή�
                TO_CHAR( xicw.cmpnt_01gen )    AS cmpnt_01gen,
                                               -- �W�������i�����j
                TO_CHAR( xicw.cmpnt_02sai )    AS cmpnt_02sai,
                                               -- �W�������i�Đ���j
                TO_CHAR( xicw.cmpnt_03szi )    AS cmpnt_03szi,
                                               -- �W�������i���ޔ�j
                TO_CHAR( xicw.cmpnt_04hou )    AS cmpnt_04hou,
                                               -- �W�������i���j
                TO_CHAR( xicw.cmpnt_05gai )    AS cmpnt_05gai,
                                               -- �W�������i�O�����H��j
                TO_CHAR( xicw.cmpnt_06hkn )    AS cmpnt_06hkn,
                                               -- �W�������i�ۊǔ�j
                TO_CHAR( xicw.cmpnt_07kei )    AS cmpnt_07kei,
                                               -- �W�������i���̑��o��j
-- End1.8
                xicw.cmp_cost_apply_date,      -- �W�������K�p�J�n��
                xicw.seisakugun,               -- ����Q
                xicw.seisakugun_name           -- ����Q��
      FROM      xxcmm_wk_item_csv xicw
      WHERE     xicw.request_id = cn_request_id
      ORDER BY  xicw.seisakugun,
                xicw.item_code;
--
    -- �f�[�^�擾(�\��ݒ�l)
    CURSOR      csv_data_cur2
    IS
      SELECT    xicw.item_code,                -- �i���R�[�h
                xicw.item_name,                -- ������
                xicw.apply_date,               -- �K�p�J�n��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.item_status,
                TO_CHAR( xicw.item_status )    AS item_status,
                                               -- �i�ڃX�e�[�^�X
-- End
                xicw.item_status_name,         -- �i�ڃX�e�[�^�X��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
--                xicw.fixed_price,
--                xicw.cmpnt_cost,
                TO_CHAR( xicw.fixed_price )    AS fixed_price,
                                               -- �艿
                TO_CHAR( xicw.cmpnt_cost )     AS cmpnt_cost,
                                               -- �W�������v
-- End
-- Ver1.8  2009/07/13  Add  0000366�Ή�
                TO_CHAR( xicw.cmpnt_01gen )    AS cmpnt_01gen,
                                               -- �W�������i�����j
                TO_CHAR( xicw.cmpnt_02sai )    AS cmpnt_02sai,
                                               -- �W�������i�Đ���j
                TO_CHAR( xicw.cmpnt_03szi )    AS cmpnt_03szi,
                                               -- �W�������i���ޔ�j
                TO_CHAR( xicw.cmpnt_04hou )    AS cmpnt_04hou,
                                               -- �W�������i���j
                TO_CHAR( xicw.cmpnt_05gai )    AS cmpnt_05gai,
                                               -- �W�������i�O�����H��j
                TO_CHAR( xicw.cmpnt_06hkn )    AS cmpnt_06hkn,
                                               -- �W�������i�ۊǔ�j
                TO_CHAR( xicw.cmpnt_07kei )    AS cmpnt_07kei,
                                               -- �W�������i���̑��o��j
-- End1.8
                xicw.cmp_cost_apply_date,      -- �W�������K�p�J�n��
-- Ver1.4 2009/02/12  �Öٌ^�ϊ������{����Ȃ��悤�C��
                TO_CHAR( xicw.discrete_cost )  AS discrete_cost,
                                               -- �c�ƌ���
-- End
                xicw.policy_group,             -- ����Q
                xicw.policy_grp_name           -- ����Q��
      FROM      xxcmm_wk_itemrsv_csv xicw
      WHERE     xicw.request_id = cn_request_id
-- Ver1.8  209/07/13  Mod  �i�ڃR�[�h�A�K�p�����ɕύX
--      ORDER BY  xicw.policy_group,
--                xicw.item_code;
      ORDER BY  xicw.item_code,
                xicw.apply_date;
-- End1.8
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_data_expt  EXCEPTION;
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�E���g�p�ϐ�������
    lv_step      := 'A-5';
    lv_msg_token := 'CSV�`���̃f�[�^�o��';
    ln_c := 0;
    -- ===============================
    -- CSV�`���̃f�[�^�o��(A-5)
    -- ===============================
    -- �o�͑Ώېݒ�l�����ݐݒ�l�̏ꍇ
    IF ( gv_output_div = cv_output_div ) THEN
      lv_step      := 'A-5';
      lv_msg_token := 'CSV�`���̃f�[�^�o��:���ݐݒ�l';
      <<item_info1_loop>>
      FOR lt_item01_rec IN csv_data_cur1 LOOP
        ln_c := ln_c + 1;
        lv_csv_file :=
          lt_item01_rec.item_code
          || cv_sep_com       -- �i���R�[�h
          || lt_item01_rec.item_name
          || cv_sep_com       -- ������
          || lt_item01_rec.item_short_name
          || cv_sep_com       -- ����
          || lt_item01_rec.item_name_alt
          || cv_sep_com ||    -- �J�i��
          ( CASE
              WHEN ( lt_item01_rec.item_status IS NOT NULL ) THEN
                lt_item01_rec.item_status || cv_sep || lt_item01_rec.item_status_name
              ELSE
                NULL
            END    -- �i�ڃX�e�[�^�X�F�i�ڃX�e�[�^�X��
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.sales_div IS NOT NULL ) THEN
                lt_item01_rec.sales_div || cv_sep || lt_item01_rec.sales_div_name
              ELSE
                NULL
            END    -- ����Ώۋ敪�F����Ώۋ敪��
          )
          || cv_sep_com
          || lt_item01_rec.parent_item_code
          || cv_sep_com      -- �e�i��ID
          || lt_item01_rec.num_of_cases
          || cv_sep_com      -- �P�[�X����
          || lt_item01_rec.item_um
          || cv_sep_com ||   -- �P��
          ( CASE
              WHEN ( lt_item01_rec.item_product_class IS NOT NULL ) THEN
                lt_item01_rec.item_product_class || cv_sep || lt_item01_rec.item_product_class_name
              ELSE
                NULL
            END    -- ���i���i�敪�F���i���i�敪��
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.rate_class IS NOT NULL ) THEN
                lt_item01_rec.rate_class || cv_sep || lt_item01_rec.rate_class_name
              ELSE
                NULL
            END    -- ���敪�F���敪��
          )
          || cv_sep_com
          || lt_item01_rec.net
          || cv_sep_com      -- NET
          || lt_item01_rec.unit
          || cv_sep_com      -- �d��
          || lt_item01_rec.jan_code
          || cv_sep_com ||   -- JAN�R�[�h
          ( CASE
              WHEN ( lt_item01_rec.nets IS NOT NULL ) THEN
                lt_item01_rec.nets || cv_sep || lt_item01_rec.nets_uom_code_name
              ELSE
                NULL
            END    -- ���e��
          )
          || cv_sep_com
          || lt_item01_rec.inc_num
          || cv_sep_com    -- �������
          || lt_item01_rec.case_jan_code
          || cv_sep_com ||  -- �P�[�XJAN�R�[�h
          ( CASE
              WHEN ( lt_item01_rec.hon_product_class IS NOT NULL ) THEN
                lt_item01_rec.hon_product_class || cv_sep || lt_item01_rec.hon_product_class_name
              ELSE
                NULL
            END    -- �{�Џ��i�敪�F�{�Џ��i�敪��
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.baracha_div IS NOT NULL ) THEN
                lt_item01_rec.baracha_div || cv_sep || lt_item01_rec.baracha_div_name
              ELSE
                NULL
            END    -- �o�����敪�F�o�����敪��
          )
          || cv_sep_com
          || lt_item01_rec.itf_code
          || cv_sep_com ||  -- ITF�R�[�h
          ( CASE
              WHEN ( lt_item01_rec.product_class IS NOT NULL ) THEN
                lt_item01_rec.product_class || cv_sep || lt_item01_rec.product_class_name
              ELSE
                NULL
            END    -- ���i���ށF���i���ޖ�
          )
          || cv_sep_com
          || lt_item01_rec.palette_max_cs_qty
          || cv_sep_com    -- �z��
          || lt_item01_rec.palette_max_step_qty
          || cv_sep_com    -- �p���b�g����ő�i��
          || lt_item01_rec.bowl_inc_num
          || cv_sep_com    -- �{�[������
          || TO_CHAR( lt_item01_rec.sell_start_date, cv_date_fmt_std )
          || cv_sep_com    -- ����(����)�J�n��
          || TO_CHAR( lt_item01_rec.obsolete_date, cv_date_fmt_std )
          || cv_sep_com ||  -- �p�~��(����)���~��
          ( CASE
              WHEN ( lt_item01_rec.obsolete_class IS NOT NULL ) THEN
                lt_item01_rec.obsolete_class || cv_sep || lt_item01_rec.obsolete_class_name
              ELSE
                NULL
            END    -- �p�~�敪�F�p�~�敪��
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.vessel_group IS NOT NULL ) THEN
                lt_item01_rec.vessel_group || cv_sep || lt_item01_rec.vessel_group_name
              ELSE
                NULL
            END    -- �e��Q�F�e��Q��
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.new_item_div IS NOT NULL ) THEN
                lt_item01_rec.new_item_div || cv_sep || lt_item01_rec.new_item_div_name
              ELSE
                NULL
            END    -- �V���i�敪�F�V���i�敪��
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.acnt_group IS NOT NULL ) THEN
                lt_item01_rec.acnt_group || cv_sep || lt_item01_rec.acnt_group_name
              ELSE
                NULL
            END    -- �o���Q�F�o���Q��
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.acnt_vessel_group IS NOT NULL ) THEN
                lt_item01_rec.acnt_vessel_group || cv_sep || lt_item01_rec.acnt_vessel_group_name
              ELSE
                NULL
            END    -- �o���e��Q�F�o���e��Q��
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.brand_group IS NOT NULL ) THEN
                lt_item01_rec.brand_group || cv_sep || lt_item01_rec.brand_group_name
              ELSE
                NULL
            END    -- �u�����h�Q�F�u�����h�Q��
          )
          || cv_sep_com
          || lt_item01_rec.renewal_item_code
          || cv_sep_com ||  -- ���j���[�A�����i���R�[�h
          ( CASE
              WHEN ( lt_item01_rec.sp_supplier_code IS NOT NULL ) THEN
                lt_item01_rec.sp_supplier_code || cv_sep || lt_item01_rec.ss_code_name
              ELSE
                NULL
            END    -- ���X�d����R�[�h�F���X�d����
          )
          || cv_sep_com
          || lt_item01_rec.price_old
          || cv_sep_com    -- �艿(��)
          || lt_item01_rec.price_new
          || cv_sep_com    -- �艿(�V)
          || TO_CHAR( lt_item01_rec.price_apply_date, cv_date_fmt_std )
          || cv_sep_com    -- �艿�K�p�J�n��
          || lt_item01_rec.cmpnt_cost
          || cv_sep_com    -- �W�������v
-- Ver1.8  2009/07/13  Add  0000366�Ή�
          || lt_item01_rec.cmpnt_01gen
          || cv_sep_com    -- �W�������i�����j
          || lt_item01_rec.cmpnt_02sai
          || cv_sep_com    -- �W�������i�Đ���j
          || lt_item01_rec.cmpnt_03szi
          || cv_sep_com    -- �W�������i���ޔ�j
          || lt_item01_rec.cmpnt_04hou
          || cv_sep_com    -- �W�������i���j
          || lt_item01_rec.cmpnt_05gai
          || cv_sep_com    -- �W�������i�O�����H��j
          || lt_item01_rec.cmpnt_06hkn
          || cv_sep_com    -- �W�������i�ۊǔ�j
          || lt_item01_rec.cmpnt_07kei
          || cv_sep_com    -- �W�������i���̑��o��j
-- End1.8
          || TO_CHAR( lt_item01_rec.cmp_cost_apply_date, cv_date_fmt_std )
          || cv_sep_com    -- �W�������K�p�J�n��
          || lt_item01_rec.opt_cost_old
          || cv_sep_com    -- �c�ƌ���(��)
          || lt_item01_rec.opt_cost_new
          || cv_sep_com    -- �c�ƌ���(�V)
          || TO_CHAR( lt_item01_rec.opt_cost_apply_date, cv_date_fmt_std )
          || cv_sep_com ||  -- �c�ƌ����K�p�J�n��
          ( CASE
              WHEN ( lt_item01_rec.seisakugun IS NOT NULL ) THEN
                lt_item01_rec.seisakugun || cv_sep || lt_item01_rec.seisakugun_name
              ELSE
                NULL
            END    -- ����Q�F����Q��
          );
        -- �쐬����CSV�f�[�^���o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_csv_file
        );
        -- ��������
        gn_normal_cnt := ln_c;
      END LOOP item_info1_loop;
    -- �o�͑Ώېݒ�l���\��ݒ�l�̏ꍇ
    ELSE
      lv_step      := 'A-5';
      lv_msg_token := 'CSV�`���̃f�[�^�o��:�\��ݒ�l';
      <<item_info2_loop>>
      FOR lt_item01_rec IN csv_data_cur2 LOOP
        ln_c := ln_c + 1;
        lv_csv_file :=
          lt_item01_rec.item_code
          || cv_sep_com    -- �i���R�[�h
          || lt_item01_rec.item_name
          || cv_sep_com    -- ������
          || TO_CHAR( lt_item01_rec.apply_date, cv_date_fmt_std )
          || cv_sep_com ||  -- �K�p�J�n��
          ( CASE
              WHEN ( lt_item01_rec.item_status IS NOT NULL ) THEN
                lt_item01_rec.item_status || cv_sep || lt_item01_rec.item_status_name
              ELSE
                NULL
            END    -- �i�ڃX�e�[�^�X�F�i�ڃX�e�[�^�X��
          )
          || cv_sep_com
          || lt_item01_rec.fixed_price
          || cv_sep_com    -- �艿
          || lt_item01_rec.cmpnt_cost
          || cv_sep_com    -- �W�������v
-- Ver1.8  2009/07/13  Add  0000366�Ή�
          || lt_item01_rec.cmpnt_01gen
          || cv_sep_com    -- �W�������i�����j
          || lt_item01_rec.cmpnt_02sai
          || cv_sep_com    -- �W�������i�Đ���j
          || lt_item01_rec.cmpnt_03szi
          || cv_sep_com    -- �W�������i���ޔ�j
          || lt_item01_rec.cmpnt_04hou
          || cv_sep_com    -- �W�������i���j
          || lt_item01_rec.cmpnt_05gai
          || cv_sep_com    -- �W�������i�O�����H��j
          || lt_item01_rec.cmpnt_06hkn
          || cv_sep_com    -- �W�������i�ۊǔ�j
          || lt_item01_rec.cmpnt_07kei
          || cv_sep_com    -- �W�������i���̑��o��j
-- End1.8
          || TO_CHAR( lt_item01_rec.cmp_cost_apply_date, cv_date_fmt_std )
          || cv_sep_com    -- �W�������K�p�J�n��
          || lt_item01_rec.discrete_cost
          || cv_sep_com ||  -- �c�ƌ���
          ( CASE
              WHEN ( lt_item01_rec.policy_group IS NOT NULL ) THEN
                lt_item01_rec.policy_group || cv_sep || lt_item01_rec.policy_grp_name
              ELSE
                NULL
            END    -- ����Q�F����Q��
          );
        -- �쐬����CSV�f�[�^���o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_csv_file
        );
        -- ��������
        gn_normal_cnt := ln_c;
      END LOOP item_info1_loop;
    END IF;
    --
    -- �J�E���g�p�ϐ���'0'�̎��A�f�[�^�Ȃ�
    IF ( ln_c = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
    -- ���^�[���R�[�h�F�G���[���O���Đ���I������悤�ɏC�� 2009/01/20
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm,
                      iv_name         => cv_msg_xxcmm_00001
                    );
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      gn_error_cnt := ln_c;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_output_div        IN  VARCHAR2,     -- �o�͑Ώېݒ�l
    iv_item_status       IN  VARCHAR2,     -- �i�ڃX�e�[�^�X
    iv_date_from         IN  VARCHAR2,     -- �Ώۊ��ԊJ�n
    iv_date_to           IN  VARCHAR2,     -- �Ώۊ��ԏI��
    iv_item_code_from    IN  VARCHAR2,     -- �i���R�[�h�J�n
    iv_item_code_to      IN  VARCHAR2,     -- �i���R�[�h�I��
    ov_errbuf            OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_step           VARCHAR2(100);   -- �X�e�b�v
    lv_msg_token      VARCHAR2(100);   -- �f�o�b�O�p�g�[�N��
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    subprog_err_expt  EXCEPTION;
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
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    lv_step      := 'A-1';
    lv_msg_token := '��������';
    proc_init(
      iv_output_div      => iv_output_div,     -- �o�͑Ώېݒ�l
      iv_item_status     => iv_item_status,    -- �i�ڃX�e�[�^�X
      iv_date_from       => iv_date_from,      -- �Ώۊ��ԊJ�n
      iv_date_to         => iv_date_to,        -- �Ώۊ��ԏI��
      iv_item_code_from  => iv_item_code_from, -- �i���R�[�h�J�n
      iv_item_code_to    => iv_item_code_to,   -- �i���R�[�h�I��
      ov_errbuf          => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode         => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    --
    -- =====================================================
    -- �i�ڈꗗ���擾(A-2,A-3)�A�W�������擾(A-2.4,A-3.2)
    -- =====================================================
    lv_step      := 'A-2,A-3';
    lv_msg_token := '�i�ڈꗗ���擾�A�W�������擾';
    get_item_mst(
      ov_errbuf   => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode  => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    --
    -- ===============================
    -- ���ڃ^�C�g���擾(A-4)
    -- ===============================
    lv_step      := 'A-4';
    lv_msg_token := '���ڃ^�C�g���擾';
    get_item_header(
      ov_errbuf   => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode  => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    --
    -- ===============================
    -- CSV�`���̃f�[�^�o��(A-5)
    -- ===============================
    lv_step      := 'A-5';
    lv_msg_token := 'CSV�`���̃f�[�^�o��';
    output_csv(
      iv_file_type  => cv_csv_file,       -- CSV�t�@�C��
      ov_errbuf     => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    --
    --���b�Z�[�W�o��(�Ώۃf�[�^������)
    IF ( lv_retcode = cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
  EXCEPTION
    WHEN subprog_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h    --# �Œ� #
    iv_output_div        IN  VARCHAR2,    -- �o�͑Ώېݒ�l
    iv_item_status       IN  VARCHAR2,    -- �i�ڃX�e�[�^�X
    iv_date_from         IN  VARCHAR2,    -- �Ώۊ��ԊJ�n
    iv_date_to           IN  VARCHAR2,    -- �Ώۊ��ԏI��
    iv_item_code_from    IN  VARCHAR2,    -- �i���R�[�h�J�n
    iv_item_code_to      IN  VARCHAR2     -- �i���R�[�h�I��
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
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
       iv_which   => cv_output_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_output_div     => iv_output_div,     -- �o�͑Ώېݒ�l
      iv_item_status    => iv_item_status,    -- �i�ڃX�e�[�^�X
      iv_date_from      => iv_date_from,      -- �Ώۊ��ԊJ�n
      iv_date_to        => iv_date_to,        -- �Ώۊ��ԏI��
      iv_item_code_from => iv_item_code_from, -- �i���R�[�h�J�n
      iv_item_code_to   => iv_item_code_to,   -- �i���R�[�h�I��
      ov_errbuf         => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode        => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ======================
    -- �I������(A-6)
    -- ======================
    -- ���[�N�e�[�u���̃f�[�^���폜����
    IF ( gv_output_div = cv_output_div) THEN
      DELETE FROM xxcmm_wk_item_csv xicw
      WHERE       xicw.request_id = cn_request_id;
    ELSE
      DELETE FROM xxcmm_wk_itemrsv_csv xicw
      WHERE       xicw.request_id = cn_request_id;
    END IF;
    COMMIT;
    --
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
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
END XXCMM004A10C;
/
