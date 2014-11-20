create or replace PACKAGE BODY xxwsh400003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh400003c(BODY)
 * Description            : �o�׈˗��m��֐�(BODY)
 * MD.050                 : T_MD050_BPO_401_�o�׈˗�
 * MD.070                 : T_MD070_EDO_BPO_40D_�o�׈˗��m��֐�
 * Version                : 1.26
 *
 * Program List
 *  ------------------------ ---- ---- --------------------------------------------------
 *   Name                    Type Ret  Description
 *  ------------------------ ---- ---- --------------------------------------------------
 *  iv_prod_class            P         ���i�敪
 *  iv_head_sales_branch     P         �Ǌ����_
 *  iv_input_sales_branch    P         ���͋��_
 *  in_deliver_to_id         P         �z����ID
 *  iv_request_no            P         �˗�No
 *  id_schedule_ship_date    P         �o�ɓ�
 *  id_schedule_arrival_date P         ����
 *  iv_callfrom_flg          P         �ďo���t���O
 *  iv_status_kbn            P         ���߃X�e�[�^�X�`�F�b�N�敪
 * ------------- ----------- --------- --------------------------------------------------
 *  Date         Ver.  Editor          Description
 * ------------- ----- --------------- --------------------------------------------------
 *  2008/03/13    1.0   R.Matusita      �V�K�쐬
 *  2008/04/23    1.1   R.Matusita      �����ύX�v��#65
 *  2008/06/03    1.2   M.Uehara        �����ύX�v��#80
 *  2008/06/05    1.3   N.Yoshida       ���[�h�^�C���Ó����`�F�b�N D-2�o�ɓ� > �ғ����ɏC��
 *  2008/06/05    1.4   M.Uehara        �ύڌ����`�F�b�N(�ύڌ����Z�o)�̎��{�������C��
 *  2008/06/05    1.5   N.Yoshida       �o�׉ۃ`�F�b�N�ɂĈ����ݒ�̏C��
 *                                     (���̓p�����[�^�F�Ǌ����_�ˎ󒍃w�b�_�̊Ǌ����_)
 *  2008/06/06    1.6   T.Ishiwata      �o�׉ۃ`�F�b�N�ɂăG���[���b�Z�[�W�̏C��
 *  2008/06/18    1.7   T.Ishiwata      ���߃X�e�[�^�X�`�F�b�N�敪���Q�̏ꍇ�AUpdate����悤�C��
 *                                      �S�̓I�Ƀl�X�g�C��
 *  2008/06/19    1.8   Y.Shindou       �����ύX�v��#143�Ή�
 *  2008/07/08    1.9   N.Fukuda        ST�s��Ή�#405
 *  2008/07/08    1.10  M.Uehara        ST�s��Ή�#424
 *  2008/07/09    1.11  N.Fukuda        ST�s��Ή�#430
 *  2008/07/29    1.12  D.Nihei         ST�s��Ή�#503
 *  2008/07/30    1.13  M.Uehara        ST�s��Ή�#501
 *  2008/08/06    1.14  D.Nihei         ST�s��Ή�#525
 *                                      �J�e�S�����VIEW�ύX
 *  2008/08/11    1.15  M.Hokkanji      �����ۑ�#32�Ή��A�����ύX�v��#173,178�Ή�
 *  2008/09/01    1.16  N.Yoshida       PT�Ή�(�N�[�Ȃ�)
 *  2008/09/24    1.17  M.Hokkanji       TE080_400�w�E66�Ή�
 *  2008/10/15    1.18  Marushita        I_S_387�Ή�
 *  2008/11/18    1.19  M.Hokkanji       �����w�E141�A632�A658�Ή�
 *  2008/11/26    1.20  M.Hokkanji       �{�ԏ�Q133�Ή�
 *  2008/12/02    1.21  M.Nomura         �{�ԏ�Q318�Ή�
 *  2008/12/07    1.22  M.Hokkanji       �{�ԏ�Q514�Ή�
 *  2008/12/13    1.23  M.Hokkanji       �{�ԏ�Q554�Ή�
 *  2008/12/24    1.24  M.Hokkanji       �{�ԏ�Q839�Ή�
 *  2009/01/09    1.25  H.Itou           �{�ԏ�Q894�Ή�
 *  2009/03/03    1.26  Y.Kazama         �{�ԏ�Q#1243�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  --*** ���������ʗ�O���[�j���O ***
  global_process_warn       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gn_status_normal CONSTANT NUMBER := 0;
  gn_status_error  CONSTANT NUMBER := 1;
  gn_status_warn   CONSTANT NUMBER := 2;
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh400003c'; -- �p�b�P�[�W��
--
  gv_cnst_msg_kbn  CONSTANT VARCHAR2(5)   := 'XXWSH';
  gv_cnst_msg_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
--
  gv_cnst_msg_001  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11162'; -- ۯ��װ
  gv_cnst_msg_002  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11163'; -- �Ώۃf�[�^�Ȃ�
  gv_cnst_msg_003  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11165'; -- ���������o��
  -- ���ڃ`�F�b�N
  gv_cnst_msg_null CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11161';  -- �K�{�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_prop CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11159';  -- �Ó����`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_155  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11155';  -- ���ʊ֐��G���[
  gv_cnst_msg_154  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11154';  -- �ғ����`�F�b�N�G���[
  gv_cnst_msg_153  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11153';  -- ���[�h�^�C���`�F�b�N�G���[
  gv_cnst_msg_160  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11160';  -- ���ߎ��{�`�F�b�N�G���[
  gv_cnst_msg_164  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11164';  -- �ڋq�G���[
  gv_cnst_msg_151  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11151';  -- �p���b�g�����`�F�b�N�G���[
  gv_cnst_msg_152  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11152';  -- �}�X�^�`�F�b�N�G���[
  gv_cnst_msg_166  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11166';  -- �i�ڋ��ʃG���[
  gv_cnst_msg_167  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11167';  -- �z���G���[
  gv_cnst_msg_168  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11168';  -- ���ʓ��̓G���[���b�Z�[�W
  gv_cnst_msg_169  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11169';  -- �o�׉ۃ`�F�b�N�i�o�א������j�G���[
  gv_cnst_msg_170  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11170';  -- �o�׉ۃ`�F�b�N�i�o�ג�~���j�G���[
  gv_cnst_msg_156  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11156';  -- �o�׉یx���i�R���J�����g�j
  gv_cnst_msg_157  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11157';  -- �o�׉یx���i��ʁj
  gv_cnst_msg_158  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11158';  -- �ύڌ����G���[
  gv_cnst_msg_171  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11171';  -- ���폈�������o��
  gv_cnst_msg_172  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11172';  -- �x�����������o��
  gv_cnst_msg_173  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11173';  -- �o�׉ۃ`�F�b�N�i�o�א������j�x��
  gv_cnst_msg_174  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11174';  -- �o�׉ۃ`�F�b�N�i�o�ג�~���j�x��
  gv_cnst_msg_175  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11175';  -- �o�׈����ΏۃG���[
-- Ver 1.17 M.Hokkanji START
  gv_cnst_msg_176  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11176';  -- �^���Ǝ҃G���[
-- Ver 1.17 M.Hokkanji END
-- Ver 1.19 M.Hokkanji Start
  gv_cnst_msg_177  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11177';  -- ���[�h�^�C���s���G���[
-- Ver 1.19 M.Hokkanji End
  gv_cnst_sep_msg  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00003';  -- sep_msg
  gv_cnst_cmn_008  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00008';  -- ��������
  gv_cnst_cmn_009  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00009';  -- ��������
  gv_cnst_cmn_010  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00010';  -- �G���[����
  gv_cnst_cmn_011  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00011';  -- �X�L�b�v����
  gv_cnst_cmn_cnt  CONSTANT VARCHAR2(15)  := 'CNT';              -- CNT
-- Ver 1.15 M.Hokkanji START
  gv_cnst_cmn_012  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10001';  -- �Ώۃf�[�^����
-- Ver 1.15 M.Hokkanji END
--
  gv_cnst_token_api_name CONSTANT VARCHAR2(15)  := 'API_NAME';  --
--
  gv_cnst_tkn_table       CONSTANT VARCHAR2(15)  := 'TABLE';
  gv_cnst_tkn_item        CONSTANT VARCHAR2(15)  := 'ITEM';
  gv_cnst_tkn_value       CONSTANT VARCHAR2(15)  := 'VALUE';
  gv_cnst_file_id_name    CONSTANT VARCHAR2(7)   := 'FILE_ID';
  gv_cnst_tkn_para        CONSTANT VARCHAR2(9)   := 'PARAMETER';
-- Ver 1.15 M.Hokkanji START
  gv_cnst_tkn_key         CONSTANT VARCHAR2(15)  := 'KEY';
-- Ver 1.15 M.Hokkanji END
-- Ver 1.17 M.Hokkanji START
  gv_cnst_tkn_request_no  CONSTANT VARCHAR2(15)  := 'REQUEST_NO';
-- Ver 1.17 M.Hokkanji END
-- Ver1.22 M.Hokkanji Start
  gv_cnst_tkn_deliver_from CONSTANT VARCHAR2(15) := 'DELIVER_FROM';
  gv_cnst_tkn_deliver_to   CONSTANT VARCHAR2(15) := 'DELIVER_TO';
  gv_cnst_tkn_head_saled   CONSTANT VARCHAR2(20) := 'HEAD_SALES_BRANCH';
  gv_cnst_tkn_ship_date    CONSTANT VARCHAR2(15) := 'SHIP_DATE';
  gv_cnst_tkn_item_code    CONSTANT VARCHAR2(15) := 'ITEM_CODE';
-- Ver1.22 M.Hokkanji End
--
-- ���̓p�����[�^����
  gv_cnst_item_name       CONSTANT VARCHAR2(15)  := '���ږ���';
  gv_cnst_item_value      CONSTANT VARCHAR2(15)  := '���ڂ̒l';
  gv_cnst_item_len        CONSTANT VARCHAR2(15)  := '���ڂ̒���';
  gv_cnst_item_decimal    CONSTANT VARCHAR2(50)  := '���ڂ̒����i�����_�ȉ��j';
--
  gv_cnst_file_type       CONSTANT VARCHAR2(30)  := '�t�H�[�}�b�g�p�^�[��';
  gv_cnst_target_date     CONSTANT VARCHAR2(30)  := '�Ώۓ��t';
  gv_cnst_p_days          CONSTANT VARCHAR2(30)  := '�p�[�W�Ώۊ���';
--
  gv_cnst_item_null       CONSTANT VARCHAR2(15)  := '�K�{�t���O';
  gv_cnst_item_attr       CONSTANT VARCHAR2(15)  := '���ڑ���';
--
  gv_cnst_period          CONSTANT VARCHAR2(1)   := '.';        -- �s���I�h
  gv_cnst_err_msg_space   CONSTANT VARCHAR2(6)   := '      ';   -- �X�y�[�X
--
  gv_status_01            CONSTANT VARCHAR2(2)   := '01';    -- ���͒�
  gv_status_02            CONSTANT VARCHAR2(2)   := '02';    -- ���_�m��
  gv_status_03            CONSTANT VARCHAR2(2)   := '03';    -- ���ߍς�
  gv_line_feed            CONSTANT VARCHAR2(1)   := CHR(10); -- ���s�R�[�h;
--
  gv_msg_null_01          CONSTANT VARCHAR2(30)  := '�Ǌ����_�R�[�h';
  gv_msg_null_02          CONSTANT VARCHAR2(30)  := '���͋��_�R�[�h';
  gv_msg_null_03          CONSTANT VARCHAR2(30)  := '�ďo���t���O';
  gv_msg_null_04          CONSTANT VARCHAR2(30)  := '���߃X�e�[�^�X�敪';
  gv_msg_null_05          CONSTANT VARCHAR2(30)  := '�ďo���t���O';
  gv_msg_null_06          CONSTANT VARCHAR2(30)  := '���߃X�e�[�^�X�`�F�b�N�敪';
  gv_msg_null_07          CONSTANT VARCHAR2(30)  := '���i�敪';
  gv_msg_null_08          CONSTANT VARCHAR2(30)  := '�o�ɓ�';
  gv_status_A             CONSTANT VARCHAR2(1)   := 'A'; -- �L��
--
  gv_transaction_type_name_ship CONSTANT VARCHAR2(100) := '����ύX'; -- �o�Ɍ`�� 2008/07/08 ST�s��Ή�#405
-- Ver1.19 M.Hokkanji Start
  gv_transaction_type_name_mat  CONSTANT VARCHAR2(100) := '���ޏo��';
-- Ver1.19 M.Hokkanji End
--
  gv_freight_charge_class_on  CONSTANT VARCHAR2(1) := '1'; -- �^���敪�u�Ώہv  2008/07/09 ST�s��Ή�#430
  gv_freight_charge_class_off CONSTANT VARCHAR2(1) := '0'; -- �^���敪�u�ΏۊO�v2008/07/09 ST�s��Ή�#430
-- 2008/07/29 D.Nihei ADD START
  gv_drink                    CONSTANT VARCHAR2(1) := '2'; -- ���i�敪�u�h�����N�v2008/07/29 ST�s��Ή�#503
-- 2008/07/29 D.Nihei ADD END
-- 2008/08/06 D.Nihei ADD START
  gv_prod                     CONSTANT VARCHAR2(1) := '5'; -- �i�ڋ敪�u���i�v2008/08/06 ST�s��Ή�#525
-- 2008/08/06 D.Nihei ADD END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �X�V�pPL/SQL�\�^
  TYPE order_header_id_ttype    IS TABLE OF 
  xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER; -- �󒍃w�b�_�A�h�I��ID
--
  -- �X�V�pPL/SQL�\
  gt_header_id_upd_tab    order_header_id_ttype;      -- �󒍃w�b�_�A�h�I��ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gv_callfrom_flg  VARCHAR2(1);               -- �ďo���t���O
  gv_transaction_type_id_ship VARCHAR2(4) ;   -- �o�Ɍ`�� 2008/07/08 ST�s��Ή�#405
--
   /**********************************************************************************
   * Procedure Name   : allow_pickup_flag_chk
   * Description      : �����Ώۃ`�F�b�N (D-3)
   ***********************************************************************************/
  FUNCTION allow_pickup_flag_chk(
    iv_deliver_from       IN  VARCHAR2,                   -- �o�׌��ۊǏꏊ�R�[�h
    ov_errbuf             OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'allow_pickup_flag_chk';       -- �v���O������
    cv_err                  CONSTANT xxcmn_item_locations2_v.allow_pickup_flag%TYPE := '0';
-- ##### 20081202 Ver.1.21 �{��#318�Ή� START #####
    cv_table_name_tran               VARCHAR2(30)   := 'OPM�ۊǏꏊ���VIEW2';
    cv_deliver_from                  VARCHAR2(30)   := '�z����R�[�h';
-- ##### 20081202 Ver.1.21 �{��#318�Ή� END   #####
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
    lv_allow_pickup_flag    VARCHAR2(150);
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- ##### 20081202 Ver.1.21 �{��#318�Ή� START #####
    BEGIN
-- ##### 20081202 Ver.1.21 �{��#318�Ή� END   #####
--
      SELECT allow_pickup_flag           -- �o�׈����Ώۃt���O
      INTO   lv_allow_pickup_flag
      FROM   xxcmn_item_locations2_v       -- OPM�ۊǏꏊ���VIEW2
      WHERE  segment1 = iv_deliver_from
      AND    disable_date IS NULL;
--
-- ##### 20081202 Ver.1.21 �{��#318�Ή� START #####
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                              gv_cnst_cmn_012,
                                              gv_cnst_tkn_table,
                                              cv_table_name_tran,
                                              gv_cnst_tkn_key,
                                              cv_deliver_from || ':' || iv_deliver_from);
        lv_errbuf := lv_errmsg;
      RETURN gn_status_error;
    END;
-- ##### 20081202 Ver.1.21 �{��#318�Ή� END   #####
--
    IF (lv_allow_pickup_flag = cv_err) THEN
      -- �����s��
      RETURN gn_status_error;
--
    ELSE
      RETURN gn_status_normal;
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END allow_pickup_flag_chk;
--
   /**********************************************************************************
   * Procedure Name   : get_plan_item_flag
   * Description      : �v�揤�i�t���O�擾���� (D-8)
   ***********************************************************************************/
  FUNCTION get_plan_item_flag(
    iv_shipping_item_code    IN  VARCHAR2,                -- �i�ڃR�[�h
    iv_head_sales_branch     IN  VARCHAR2,                -- ���_�R�[�h
    iv_deliver_from          IN  VARCHAR2,                -- �o�׌��ۊǏꏊ�R�[�h
    id_schedule_ship_date    IN  DATE,                    -- �o�ɓ�
    ov_errbuf             OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'get_plan_item_flag';       -- �v���O������
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
    ln_cnt    NUMBER;
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxcmn_sourcing_rules2_v -- �����\�����VIEW2
    WHERE  item_code            =  iv_shipping_item_code
    AND    base_code            =  iv_head_sales_branch
    AND    delivery_whse_code   =  iv_deliver_from
    AND    start_date_active    <= id_schedule_ship_date
    AND    end_date_active      >= id_schedule_ship_date
    AND    plan_item_flag       =  1;                  -- �v�揤�i�t���O ON
--
    IF (ln_cnt = 0) THEN
      -- ���݂��Ȃ�
      RETURN gn_status_error;
--
    ELSE
      -- ���݂���
      RETURN gn_status_normal;
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_plan_item_flag;
--
   /**********************************************************************************
   * Procedure Name   : master_check
   * Description      : �}�X�^�`�F�b�N (D-7)
   ***********************************************************************************/
  FUNCTION master_check(
    iv_shipping_item_code    IN  VARCHAR2,                   -- �i�ڃR�[�h
    iv_deliver_to            IN  VARCHAR2,                   -- �z����R�[�h
    iv_head_sales_branch     IN  VARCHAR2,                   -- ���_�R�[�h
    iv_deliver_from          IN  VARCHAR2,                   -- �o�׌��ۊǏꏊ�R�[�h
    id_schedule_ship_date    IN  DATE,                       -- �o�ɓ�
    ov_errbuf             OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'master_check';       -- �v���O������
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
    cv_ZZZZZZZ     VARCHAR2(7)    := 'ZZZZZZZ'; -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
    -- *** ���[�J���ϐ� ***
--
    ln_cnt    NUMBER;
    ln_cnt2   NUMBER;
    ln_cnt3   NUMBER;
    ln_cnt4   NUMBER;
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- 2009/01/09 H.Itou Mod Start �{�ԏ�Q#894
--    -- 1.�����\���A�h�I���}�X�^�̃`�F�b�N
--    SELECT COUNT(1)
--    INTO   ln_cnt
--    FROM   xxcmn_sourcing_rules2_v                            -- �����\�����VIEW2
--    WHERE  item_code            =  iv_shipping_item_code      -- �i�ڃR�[�h
--    AND    ship_to_code         =  iv_deliver_to              -- �z����R�[�h
--    AND    delivery_whse_code   =  iv_deliver_from            -- �o�׌��ۊǏꏊ�R�[�h
--    AND    start_date_active    <= id_schedule_ship_date      -- �o�ɓ�
--    AND    end_date_active      >= id_schedule_ship_date;     -- �o�ɓ�
----
--    IF (ln_cnt = 0) THEN
--      -- 2.�����\���A�h�I���}�X�^�̃`�F�b�N(1�ŊY���Ȃ��̏ꍇ)
--      SELECT COUNT(1)
--      INTO   ln_cnt2
--      FROM   xxcmn_sourcing_rules2_v                            -- �����\�����VIEW2
--      WHERE  item_code            =  iv_shipping_item_code      -- �i�ڃR�[�h
--      AND    base_code            =  iv_head_sales_branch       -- ���_�R�[�h
--      AND    delivery_whse_code   =  iv_deliver_from            -- �o�׌��ۊǏꏊ�R�[�h
--      AND    start_date_active    <= id_schedule_ship_date      -- �o�ɓ�
--      AND    end_date_active      >= id_schedule_ship_date;     -- �o�ɓ�
----
--      IF (ln_cnt2 = 0) THEN
--        -- 3.�����\���A�h�I���}�X�^�̃`�F�b�N(2�ŊY���Ȃ��̏ꍇ)
--        SELECT COUNT(1)
--        INTO   ln_cnt3
--        FROM   xxcmn_sourcing_rules2_v                           -- �����\�����VIEW2
--        WHERE  item_code            =  cv_ZZZZZZZ
--        AND    ship_to_code         =  iv_deliver_to             -- �z����R�[�h
--        AND    delivery_whse_code   =  iv_deliver_from           -- �o�׌��ۊǏꏊ�R�[�h
--        AND    start_date_active    <= id_schedule_ship_date     -- �o�ɓ�
--        AND    end_date_active      >= id_schedule_ship_date;    -- �o�ɓ�
----
--        IF (ln_cnt3 = 0) THEN
--          -- 4.�����\���A�h�I���}�X�^�̃`�F�b�N(3�ŊY���Ȃ��̏ꍇ)
--          SELECT COUNT(1)
--          INTO   ln_cnt4
--          FROM   xxcmn_sourcing_rules2_v                            -- �����\�����VIEW2
--          WHERE  item_code            =  cv_ZZZZZZZ
--          AND    base_code            =  iv_head_sales_branch       -- ���_�R�[�h
--          AND    delivery_whse_code   =  iv_deliver_from            -- �o�׌��ۊǏꏊ�R�[�h
--          AND    start_date_active    <= id_schedule_ship_date      -- �o�ɓ�
--          AND    end_date_active      >= id_schedule_ship_date;     -- �o�ɓ�
----
--          IF (ln_cnt4 = 0) THEN
--            -- 5.���݂��Ȃ��ꍇ�A�G���[
--            RETURN gn_status_error;
--          END IF;
----
--        END IF;
----
--      END IF;
----
--    END IF;
--
--    -- ���݂���
--    RETURN gn_status_normal;
----
    -- �����\�����݃`�F�b�N�֐�
    lv_retcode := xxwsh_common_pkg.chk_sourcing_rules(
                    it_item_code          => iv_shipping_item_code    -- 1.�i�ڃR�[�h
                   ,it_base_code          => iv_head_sales_branch     -- 2.�Ǌ����_
                   ,it_ship_to_code       => iv_deliver_to            -- 3.�z����
                   ,it_delivery_whse_code => iv_deliver_from          -- 4.�o�ɑq��
                   ,id_standard_date      => id_schedule_ship_date    -- 5.���(�K�p�����)
                  );
--
    -- �߂�l������łȂ��ꍇ�A�G���[
    IF (lv_retcode <> gv_status_normal) THEN
      RETURN gn_status_error;
--
     -- �߂�l������̏ꍇ�A����
    ELSE
      RETURN gn_status_normal;
    END IF;
-- 2009/01/09 H.Itou Mod End
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END master_check;
--
  /**********************************************************************************
   * Procedure Name   : upd_table_batch
   * Description      : �X�e�[�^�X�ꊇ�X�V����(D-12)
   ***********************************************************************************/
  PROCEDURE upd_table_batch(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_table_batch'; -- �v���O������
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
    ln_user_id          NUMBER;            -- ���O�C�����Ă��郆�[�U�[
    ln_login_id         NUMBER;            -- �ŏI�X�V���O�C��
    ln_conc_request_id  NUMBER;            -- �v��ID
    ln_prog_appl_id     NUMBER;            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id  NUMBER;            -- �R���J�����g�E�v���O����ID
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���ʍX�V���̎擾
    ln_user_id         := FND_GLOBAL.USER_ID;        -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id        := FND_GLOBAL.LOGIN_ID;       -- �ŏI�X�V���O�C��
    ln_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;-- �v��ID
    ln_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID;-- �R���J�����g�E�v���O����ID
--
    -- =====================================
    -- �ꊇ�X�V����
    -- =====================================
    FORALL ln_cnt IN 1 .. gt_header_id_upd_tab.COUNT
      -- �󒍃w�b�_�A�h�I���X�V(���_�m��)
      UPDATE xxwsh_order_headers_all
      SET req_status              = gv_status_02                   -- �X�e�[�^�X(02:���_�m��)
         ,last_updated_by         = ln_user_id                     -- �ŏI�X�V��
         ,last_update_date        = SYSDATE                        -- �ŏI�X�V��
         ,last_update_login       = ln_login_id                    -- �ŏI�X�V���O�C��
         ,request_id              = ln_conc_request_id             -- �v��ID
         ,program_application_id  = ln_prog_appl_id                -- �ݶ��āE��۸��сE���ع����ID
         ,program_id              = ln_conc_program_id             -- �R���J�����g�E�v���O����ID
         ,program_update_date     = SYSDATE                        -- �v���O�����X�V��
      WHERE order_header_id       = gt_header_id_upd_tab(ln_cnt); -- �󒍃w�b�_�A�h�I��ID
--
    EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : out_log
   * Description      : �����o�͏���
   ***********************************************************************************/
  PROCEDURE out_log(
    in_target_cnt   IN NUMBER,  --   ��������
    in_normal_cnt   IN NUMBER,  --   ��������
    in_error_cnt    IN NUMBER,  --   �G���[����
    in_warn_cnt     IN NUMBER)  --   �X�L�b�v����
  IS
--
  BEGIN
--
--
    IF (gv_callfrom_flg = '1') THEN
      -- ==================================
      -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
      -- ==================================
--
--    �Ăяo�����t���O���P�F�R���J�����g�̏ꍇ�̓��O�o�͂���
--
      gn_target_cnt := in_target_cnt;
      gn_normal_cnt := in_normal_cnt;
      gn_error_cnt  := in_error_cnt;
      gn_warn_cnt   := in_warn_cnt;
--
      --���������o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,gv_cnst_cmn_008,gv_cnst_cmn_cnt,TO_CHAR(gn_target_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --���팏���o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,gv_cnst_msg_171,gv_cnst_cmn_cnt,TO_CHAR(gn_normal_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --�G���[�����o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,gv_cnst_cmn_010,gv_cnst_cmn_cnt,TO_CHAR(gn_error_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --�x�������o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,gv_cnst_msg_172,gv_cnst_cmn_cnt,TO_CHAR(gn_warn_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --��؂蕶���o��
      gv_sep_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,gv_cnst_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
      gn_warn_cnt   := 0;
--
  END out_log;
--
  /**********************************************************************************
   * Procedure Name   : �o�׈˗��m��
   * Description      : ship_set
   ***********************************************************************************/
  PROCEDURE ship_set(
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- ���i�敪
    iv_head_sales_branch     IN  VARCHAR2  DEFAULT NULL, -- �Ǌ����_
    iv_input_sales_branch    IN  VARCHAR2  DEFAULT NULL, -- ���͋��_
    in_deliver_to_id         IN  NUMBER    DEFAULT NULL, -- �z����ID
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- �˗�No
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- �o�ɓ�
    id_schedule_arrival_date IN  DATE      DEFAULT NULL, -- ����
    iv_callfrom_flg          IN  VARCHAR2,               -- �ďo���t���O
    iv_status_kbn            IN  VARCHAR2,               -- ���߃X�e�[�^�X�`�F�b�N�敪
    ov_errbuf                OUT NOCOPY  VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY  VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY  VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT          VARCHAR2(100)  := 'ship_set'; -- �v���O������
    cv_order_category_code           VARCHAR2(5)    := 'ORDER'; -- 
    cv_shipping_shikyu_class         VARCHAR2(1)    := '1'; -- 
    cv_latest_external_flag          VARCHAR2(1)    := 'Y'; -- 
    cv_delete_flag                   VARCHAR2(1)    := 'Y'; -- 
    cv_whse_code                     VARCHAR2(1)    := '4'; -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
    cv_deliver_to                    VARCHAR2(1)    := '9'; -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�z����v
    cv_ship_disable                  xxcmn_item_mst2_v.ship_class%TYPE :=  '0';  -- �o�׋敪�u�ہv
-- Ver1.15 M.Hokkanji Start
-- �����ύX178,T_S_476�Ή�
--    cv_obsolete_class                xxcmn_item_mst2_v.obsolete_class%TYPE :=  'D';  -- 
    cv_obsolete_class                xxcmn_item_mst2_v.obsolete_class%TYPE :=  '1';  --
    cv_tran_type_name_ara            VARCHAR2(10)   := '�r���o��';
    cv_tran_type_name                VARCHAR2(15)   := '����^�C�v��';
    cv_table_name_tran               VARCHAR2(30)   := '�󒍃^�C�v���VIEW';
    cv_weight_capacity_class_1       VARCHAR2(1)    := '1'; -- �d��
    cv_small_amount_class_1          VARCHAR2(1)    := '1'; -- �����敪
-- Ver1.15 M.Hokkanji End
-- Ver1.19 M.Hokkanji Start
    cv_tran_type_name_mat            VARCHAR2(10)   := '���ޏo��';
-- Ver1.19 M.Hokkanji End
    cv_prod_class_leaf               VARCHAR2(1)    := '1'; -- ���[�t
    cv_rate_class                    xxcmn_item_mst2_v.rate_class%TYPE :=  '0';  -- 
    cv_item_kbn                      VARCHAR2(8)    := '�i�ڋ敪'; -- 
    cv_get_oprtn_day_api             VARCHAR2(50)   := '�ғ����Z�o�֐�'; -- 
    cv_get_oprtn_day_lt              VARCHAR2(50)   := '���Y����LT�^����ύXLT';
    cv_calc_lead_time_api            VARCHAR2(50)   := '���[�h�^�C���Z�o';
    cv_get_oprtn_day_lt2             VARCHAR2(50)   := '�z�����[�h�^�C��';
    cv_get_max_pallet_qty_api        VARCHAR2(50)   := '�ő�p���b�g�����`�F�b�N';
    cv_get_max_pallet_qty_msg        VARCHAR2(50)   := '�ő�p���b�g�������擾�ł��܂���ł����B';
    cv_master_check_msg              VARCHAR2(50)   := '�o�׉\�i�ڂł͂���܂���i�o�׋敪���u�ہv�j';
    cv_master_check_msg2             VARCHAR2(50)   := '����Ώۋ敪���u1�v�ł͂���܂���';
-- Ver1.15 M.Hokkanji START
--    cv_master_check_msg3             VARCHAR2(50)   := '�p�~�敪���uD�v�ł͂���܂���';
    cv_master_check_msg3             VARCHAR2(50)   := '�i�ڂ��p�~����Ă��邽�ߏ����ł��܂���B';
-- Ver1.15 M.Hokkanji END
    cv_master_check_msg4             VARCHAR2(50)   := '���敪���u0�v�ł͂���܂���';
    cv_master_check_attr             VARCHAR2(50)   := '�o�ד���';
    cv_master_check_attr2            VARCHAR2(50)   := '����';
    cv_c_s_j_chk   VARCHAR2(50)   := '�o�א������i���i���j';
    cv_c_s_j_api   VARCHAR2(50)   := '�o�׉ۃ`�F�b�N';
    cv_c_s_j_msg   VARCHAR2(50)   := '�o�׉ۃ`�F�b�N�ŃG���[���������܂����B';
    cv_c_s_j_msg3  VARCHAR2(50)   := '�o�Ɍ`�ԁi����ύX�j���擾�ł��܂���ł����B';   -- 2008/07/08 ST�s��Ή�#405
    cv_c_s_j_chk2  VARCHAR2(50)   := '�o�א������i�������j';
    cv_c_s_j_chk3  VARCHAR2(50)   := '����v��`�F�b�N';
    cv_c_s_j_msg2  VARCHAR2(50)   := '�o�׉ۃ`�F�b�N�Ōv�摍�ʂ𒴂��Ă��܂��B';
    cv_c_s_j_chk4  VARCHAR2(50)   := '�o�׉ۃ`�F�b�N�i����v��`�F�b�N�j';
    cv_c_s_j_chk5  VARCHAR2(50)   := '�v�揤�i����v��`�F�b�N';
    cv_calc_load_efficiency_api
                   VARCHAR2(50)   := '�ύڌ����`�F�b�N(�ύڌ����Z�o)';
    cv_sales_div   VARCHAR2(1)    := '1'; -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(32000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(32000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- *** ���[�J���ϐ� ***
--
    ln_retcode                       NUMBER;       -- ���^�[���R�[�h
    ln_d8retcode                     NUMBER;       -- D-8�������ʃ��^�[���R�[�h
--
    ld_oprtn_day                     DATE;         -- �ғ������t
    ld_sysdate                       DATE;         -- �V�X�e�����t
    ln_data_cnt                      NUMBER := 0;  -- �f�[�^����
    ln_warn_flg                      NUMBER := 0;  -- ���[�j���O�t���O
    ln_target_cnt                    NUMBER := 0;  -- ��������
    ln_normal_cnt                    NUMBER := 0;  -- ���팏��
    ln_warn_cnt                      NUMBER := 0;  -- ���[�j���O��������
    lv_err_message                   VARCHAR2(32000); -- �G���[���b�Z�[�W
    lv_warn_message                  VARCHAR2(32000); -- ���[�j���O���b�Z�[�W
--
    ln_lead_time                     NUMBER;       -- ���Y����LT�^����ύXLT
    ln_delivery_lt                   NUMBER;       -- �z��LT
    lv_status                        VARCHAR2(2);  -- ���߃X�e�[�^�X
--
    ln_drink_deadweight              NUMBER;       -- �h�����N�ύڏd��
    ln_leaf_deadweight               NUMBER;       -- ���[�t�ύڏd��
    ln_drink_loading_capacity        NUMBER;       -- �h�����N�ύڗe��
    ln_leaf_loading_capacity         NUMBER;       -- ���[�t�ύڗe��
    ln_palette_max_qty               NUMBER;       -- �p���b�g�ő喇��
--
    lv_bfr_request_no                VARCHAR2(12); -- �O�˗�No
    ln_bfr_sum_weight                NUMBER;       -- �O�ύڏd�ʍ��v
    ln_bfr_sum_capacity              NUMBER;       -- �O�ύڗe�ύ��v
    lv_bfr_deliver_from              VARCHAR2(4);  -- �O�o�׌��ۊǏꏊ
    lv_bfr_deliver_to                VARCHAR2(9);  -- �O�z����R�[�h
    lv_bfr_shipping_method_code      VARCHAR2(2);  -- �O�z���敪
    lv_bfr_prod_class                VARCHAR2(2);  -- �O���i�敪
    id_bfr_schedule_ship_date        DATE;         -- �O�o�ɓ�
    lv_bfr_freight_charge_class      VARCHAR2(1);  -- �O�^���敪 2008/07/09 ST�s��Ή�#430
--
    lv_loading_over_class            VARCHAR2(1);  -- �ύڃI�[�o�[�敪
    lv_ship_methods                  VARCHAR2(30); -- �o�ו��@
    ln_load_efficiency_weight        NUMBER;       -- �d�ʐύڌ���
    ln_load_efficiency_capacity      NUMBER;       -- �e�ϐύڌ���
    lv_mixed_ship_method             VARCHAR2(30); -- ���ڔz���敪
    ln_bfr_order_header_id           NUMBER;       -- �󒍃w�b�_�A�h�I��ID
--
    ln_head_sales_branch_nullflg     NUMBER;       -- �Ǌ����_�R�[�hNULL�`�F�b�N�t���O
    in_deliver_to_id_nullflg         NUMBER;       -- �z����IDNULL�`�F�b�N�t���O
    ln_request_no_nullflg            NUMBER;       -- �˗�NoNULL�`�F�b�N�t���O
    ln_schedule_ship_date_nullflg    NUMBER;       -- �o�ɓ�NULL�`�F�b�N�t���O
    ln_s_a_d_nullflg                 NUMBER;       -- ����NULL�`�F�b�N�t���O
-- 2008/08/06 D.Nihei ADD START
    ln_case_total                    NUMBER;       -- �P�[�X�����v
-- 2008/08/06 D.Nihei ADD END
-- Ver1.15 M.Hokkanji Start
    lt_weight_capacity_class         xxwsh_order_headers_all.weight_capacity_class%TYPE; -- �d�ʗe�ϋ敪
    lt_transaction_type_id           xxwsh_oe_transaction_types_v.transaction_type_id%TYPE; -- �r���o��ID�ۊ�
-- Ver1.15 M.Hokkanji End
-- Ver1.17 M.Hokkanji Start
    lv_bfr_freight_carrier_code      xxwsh_order_headers_all.freight_carrier_code%TYPE; --�^���Ǝ�
-- Ver1.17 M.Hokkanji End
-- Ver1.19 M.Hokkanji Start
    lt_transaction_type_id_mat       xxwsh_oe_transaction_types_v.transaction_type_id%TYPE; -- ���ޏo��ID�ۊ�
-- Ver1.19 M.Hokkanji End
-- 2008/09/01 N.Yoshida ADD START
    lv_select     VARCHAR2(32000) ;
    lv_select_other     VARCHAR2(32000) ;
    lv_select_c1     VARCHAR2(32000) ;
    lv_select_c2     VARCHAR2(32000) ;
    lv_select_c3     VARCHAR2(32000) ;
    lv_select_c4     VARCHAR2(32000) ;
    lv_select_c5     VARCHAR2(32000) ;
    lv_sql     VARCHAR2(32000) ;
    -- *** ���[�J���E�J�[�\�� ***    
    TYPE   ref_cursor IS REF CURSOR ;
    upd_status_cur ref_cursor ;
    TYPE ret_value  IS RECORD
      (
        shipping_item_code          xxwsh_order_lines_all.shipping_item_code%TYPE
       ,quantity                    xxwsh_order_lines_all.quantity%TYPE
       ,deliver_from_id             xxwsh_order_headers_all.deliver_from_id%TYPE
       ,schedule_ship_date          xxwsh_order_headers_all.shipped_date%TYPE
       ,head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE
       ,shipping_inventory_item_id  xxcmn_item_mst2_v.inventory_item_id %TYPE
       ,prod_class                  xxwsh_order_headers_all.prod_class%TYPE
       ,deliver_from                xxwsh_order_headers_all.deliver_from%TYPE
       ,deliver_to                  xxwsh_order_headers_all.deliver_to%TYPE
       ,request_no                  xxwsh_order_headers_all.request_no%TYPE
       ,schedule_arrival_date       xxwsh_order_headers_all.arrival_date%TYPE
       ,shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE
       ,sum_weight                  xxwsh_order_headers_all.sum_weight%TYPE
       ,sum_capacity                xxwsh_order_headers_all.sum_capacity%TYPE
       ,pallet_sum_quantity         xxwsh_order_headers_all.pallet_sum_quantity %TYPE
       ,order_type_id               xxwsh_order_headers_all.order_type_id%TYPE
       ,base_category               xxcmn_cust_accounts2_v.leaf_base_category%TYPE
       ,sum_pallet_weight           xxwsh_order_headers_all.sum_pallet_weight%TYPE
       ,weight_capacity_class       xxwsh_order_headers_all.weight_capacity_class %TYPE
       ,based_request_quantity      xxwsh_order_lines_all.based_request_quantity %TYPE
       ,request_item_code           xxwsh_order_lines_all.request_item_code  %TYPE
       ,request_item_id             xxwsh_order_lines_all.request_item_id%TYPE
       ,small_amount_class          xxwsh_ship_method2_v.small_amount_class %TYPE
       ,item_id                     xxcmn_item_mst2_v.item_id%TYPE
-- Ver1.24 M.Hokkanji Start
--       ,parent_item_id              xxcmn_item_mst2_v.parent_item_id %TYPE
-- Ver1.24 M.Hokkanji End
       ,num_of_deliver              xxcmn_item_mst2_v.num_of_deliver%TYPE
       ,num_of_cases                xxcmn_item_mst2_v.num_of_cases%TYPE
-- Ver1.24 M.Hokkanji Start
--       ,ship_class                  xxcmn_item_mst2_v.ship_class%TYPE
--       ,sales_div                   xxcmn_item_mst2_v.sales_div%TYPE
--       ,obsolete_class              xxcmn_item_mst2_v.obsolete_class%TYPE
--       ,rate_class                  xxcmn_item_mst2_v.rate_class%TYPE
-- Ver1.24 M.Hokkanji End
       ,delivery_qty                xxcmn_item_mst2_v.delivery_qty%TYPE
       ,item_class_code             xxcmn_item_categories5_v.item_class_code%TYPE
-- Ver1.24 M.Hokkanji Start
       ,opm_request_item_id         xxcmn_item_mst2_v.item_id%TYPE
       ,parent_item_id              xxcmn_item_mst2_v.parent_item_id %TYPE
       ,ship_class                  xxcmn_item_mst2_v.ship_class%TYPE
       ,sales_div                   xxcmn_item_mst2_v.sales_div%TYPE
       ,obsolete_class              xxcmn_item_mst2_v.obsolete_class%TYPE
       ,rate_class                  xxcmn_item_mst2_v.rate_class%TYPE
-- Ver1.24 M.Hokkanji End
       ,account_number              xxcmn_cust_accounts2_v.account_number%TYPE
       ,cust_enable_flag            xxcmn_cust_accounts2_v.cust_enable_flag%TYPE
       ,location_rel_code           xxcmn_cust_accounts2_v.location_rel_code %TYPE
       ,order_header_id             xxwsh_order_headers_all.order_header_id%TYPE
       ,conv_unit                   xxcmn_item_mst2_v.conv_unit%TYPE
       ,freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE
-- Ver 1.17 M.Hokkanji START
       ,freight_carrier_code        xxwsh_order_headers_all.freight_carrier_code%TYPE
-- Ver 1.17 M.Hokkanji END
      );
    loop_cnt    ret_value ;
    
    /*CURSOR upd_status_cur
    IS
      SELECT  xola.shipping_item_code shipping_item_code -- �i�ڃR�[�h - �󒍖��׃A�h�I��.�o�וi��
            , xola.quantity           quantity           -- ���� - �󒍖��׃A�h�I��.����
            , xoha.deliver_from_id    deliver_from_id    -- �o�׌�ID - �󒍃w�b�_�A�h�I��.�o�׌�ID
            , NVL(xoha.shipped_date,xoha.schedule_ship_date)
                                   schedule_ship_date    -- �o�ɓ� - �󒍃w�b�_�A�h�I��.�o�ח\���
            , xoha.head_sales_branch  head_sales_branch  -- ���_�R�[�h - �󒍃w�b�_�A�h�I��.�Ǌ����_
            , ximv.inventory_item_id 
                            shipping_inventory_item_id   -- �i��ID - inv�̕i��ID
            , xoha.prod_class         prod_class         -- ���i�敪 - �󒍃w�b�_�A�h�I��.���i�敪
            , xoha.deliver_from       deliver_from       -- �o�׌��ۊǏꏊ�R�[�h - �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
            , NVL(xoha.result_deliver_to,xoha.deliver_to)         deliver_to         -- �z����R�[�h - �󒍃w�b�_�A�h�I��.�o�א�
            , xoha.request_no         request_no         -- �˗�No - �󒍃w�b�_�A�h�I��.�˗�No
            , NVL(xoha.arrival_date,xoha.schedule_arrival_date) 
                                   schedule_arrival_date -- ���� - �󒍃w�b�_�A�h�I��.���ח\���
            , NVL(xoha.result_shipping_method_code,xoha.shipping_method_code) 
                                    shipping_method_code -- �z���敪 - �󒍃w�b�_�A�h�I��.�z���敪
            , xoha.sum_weight         sum_weight         -- �ύڏd�ʍ��v - �󒍃w�b�_�A�h�I��.�ύڏd�ʍ��v
            , xoha.sum_capacity       sum_capacity       -- �ύڗe�ύ��v - �󒍃w�b�_�A�h�I��.�ύڗe�ύ��v
            , xoha.pallet_sum_quantity
                                    pallet_sum_quantity  -- �p���b�g���v���� - �󒍃w�b�_�A�h�I��.�p���b�g���v����
            , xoha.order_type_id      order_type_id      -- �󒍃^�C�vID - �󒍃w�b�_�A�h�I��.�󒍃^�C�vID
            , DECODE(iv_prod_class
                ,'1', xcav.leaf_base_category            -- ���[�t���_�J�e�S�� �ڋq���VIEW2
                ,'2', xcav.drink_base_category           -- �h�����N���_�J�e�S�� �ڋq���VIEW2
                      ,'') base_category                 -- ���_�J�e�S��
-- Ver1.15 M.Hokkanji START
            , xoha.sum_pallet_weight  sum_pallet_weight  -- ���v�p���b�g�d�� �ύX#173
            , xoha.weight_capacity_class weight_capacity_class -- �d�ʗe�ϋ敪
            , xola.based_request_quantity based_request_quantity -- ���_�˗�����
            , xola.request_item_code request_item_code   -- �˗��i�ڃR�[�h
            , xola.request_item_id request_item_id       -- �˗��i��ID
            , xsmv.small_amount_class small_amount_class -- �����敪
            , ximv.item_id item_id                       -- �i��ID(OPM�̕i��ID)
            , ximv.parent_item_id parent_item_id         -- �e�i��ID
-- Ver1.15 M.Hokkanji END
            , ximv.num_of_deliver     num_of_deliver     -- �o�ד��� - OPM�i�ڃ}�X�^.�o�ד���
            , ximv.num_of_cases       num_of_cases       -- ���� OPM�i�ڃ}�X�^.����
            , ximv.ship_class         ship_class         -- �o�׋敪 - OPM�i�ڃ}�X�^.�o�׋敪
            , ximv.sales_div          sales_div          -- ����Ώۋ敪 - OPM�i�ڃ}�X�^. ����Ώۋ敪
            , ximv.obsolete_class     obsolete_class     -- �p�~�敪 - OPM�i�ڃ}�X�^. �p�~�敪
            , ximv.rate_class         rate_class         -- ���敪 - OPM�i�ڃ}�X�^. ���敪
            , ximv.delivery_qty       delivery_qty       -- �z�� - OPM�i�ڃ}�X�^.�z��
            , xicv.item_class_code    item_class_code    -- �i�ڋ敪 - �i�ڃJ�e�S��.�Z�O�����g1
            , xcav.account_number     account_number     -- �ڋq�R�[�h - �ڋq�}�X�^. �ڋq�R�[�h
            , xcav.cust_enable_flag   cust_enable_flag   -- ���~�q�\���t���O - �ڋq�}�X�^. ���~�q�\���t���O
            , xcav.location_rel_code  location_rel_code  -- ���_���їL���敪 - �ڋq�}�X�^.���_���їL���敪
            , xoha.order_header_id    order_header_id    -- �󒍃w�b�_�A�h�I��ID
            , ximv.conv_unit          conv_unit          -- ���o�Ɋ��Z�P�� OPM�i�ڃ}�X�^���o�Ɋ��Z�P��
            , xoha.freight_charge_class   freight_charge_class   -- �^���敪 2008/07/09 ST�s��Ή�#430
      FROM
         xxwsh_oe_transaction_types2_v xottv  --�@�󒍃^�C�v���VIEW2
        ,xxwsh_order_headers_all       xoha   --�A�󒍃w�b�_�A�h�I��
        ,xxwsh_order_lines_all         xola   --�B�󒍖��׃A�h�I��
        ,xxcmn_cust_accounts2_v        xcav   --�C�ڋq���VIEW2
        ,xxcmn_cust_acct_sites2_v      xcasv  --�D�ڋq�T�C�g���VIEW2
        ,xxcmn_item_mst2_v             ximv   --�EOPM�i�ڏ��VIEW2
        ,xxcmn_item_categories5_v      xicv   --OPM�i�ڃJ�e�S���������VIEW5
-- Ver1.15 M.Hokkanji START
        ,xxwsh_ship_method2_v          xsmv   --�z���敪���VIEW2
-- Ver1.15 M.Hokkanji END
      WHERE xottv.order_category_code   =  cv_order_category_code 
                                --�󒍃J�e�S���R�[�h
      AND   xottv.shipping_shikyu_class =  cv_shipping_shikyu_class
                                -- �o�׎x���敪���u�o�׈˗�
      AND   xoha.order_type_id          =  xottv.TRANSACTION_TYPE_ID
                                -- �󒍃w�b�_�A�h�I��.�󒍃^�C�vID���󒍃^�C�v.����^�C�vID����
      AND   xoha.latest_external_flag   =  cv_latest_external_flag
                                -- �ŐV�t���O���fY'
      AND   xoha.prod_class             =  iv_prod_class
                                -- �󒍃w�b�_�A�h�I��.���i�敪���p�����[�^.���i�敪 ����
      AND   xoha.req_status             =  gv_status_01
                                -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X���u01:���͒��v����
      AND   (1 = ln_request_no_nullflg -- �t���O��0�Ȃ�˗�No�������ɒǉ�����
             OR xoha.request_no = iv_request_no)
                                -- �󒍃w�b�_�A�h�I��.�˗�No���p�����[�^.�˗�No����
      AND   (1 = ln_head_sales_branch_nullflg -- �t���O��0�Ȃ�Ǌ����_�R�[�h�������ɒǉ�����
             OR xoha.head_sales_branch = iv_head_sales_branch)
                                -- �󒍃w�b�_�A�h�I��.�Ǌ����_���p�����[�^.�Ǌ����_�R�[�h����
      AND   xoha.input_sales_branch     =  iv_input_sales_branch
                                -- �󒍃w�b�_�A�h�I��.���͋��_���p�����[�^.���͋��_�R�[�h����
      AND   (1 = ln_schedule_ship_date_nullflg -- �t���O��0�Ȃ�o�ɓ��������ɒǉ�����
             OR NVL(xoha.shipped_date,xoha.schedule_ship_date) = id_schedule_ship_date)
                                -- �󒍃w�b�_�A�h�I��.�o�ח\������p�����[�^.�o�ɓ�����
      AND   (1 = ln_s_a_d_nullflg -- �t���O��0�Ȃ璅���������ɒǉ�����
             OR NVL(xoha.arrival_date,xoha.schedule_arrival_date) = id_schedule_arrival_date)
                                -- �󒍃w�b�_�A�h�I��.���ח\������p�����[�^.��������
      AND   (1 = in_deliver_to_id_nullflg -- �t���O��0�Ȃ�z����ID�������ɒǉ�����
             OR NVL(xoha.result_deliver_to_id,xoha.deliver_to_id) = in_deliver_to_id)
                                -- �󒍃w�b�_�A�h�I��.�o�א�ID���p�����[�^.�z����ID����
      AND   xoha.order_header_id        =  xola.order_header_id
        -- �󒍃w�b�_�A�h�I��.�󒍃w�b�_�A�h�I��ID���󒍖��׃A�h�I��.�󒍃w�b�_�A�h�I��ID����
      AND   NVL(xoha.result_deliver_to_id,xoha.deliver_to_id)          =  xcasv.party_site_id
        -- �󒍃w�b�_�A�h�I��.�o�א�ID �� �p�[�e�B�T�C�g�A�h�I���}�X�^.�p�[�e�B�T�C�gID����
      AND   xcav.party_id               =    xcasv.party_id 
        -- �p�[�e�B�A�h�I���}�X�^.�p�[�e�B�T�C�gID���p�[�e�B�T�C�g�A�h�I���}�X�^.�p�[�e�B�T�C�gID����
      AND   xcav.start_date_active   <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- �p�[�e�B�A�h�I���}�X�^.�K�p�J�n�����p�����[�^.�o�ɓ�����
      AND   xcav.end_date_active     >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- �p�[�e�B�A�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
      AND   xcasv.start_date_active  <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- �p�[�e�B�T�C�g�A�h�I���}�X�^.�K�p�J�n�����p�����[�^. �o�ɓ�����
      AND   xcasv.end_date_active    >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- �p�[�e�B�T�C�g�A�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
      AND   ximv.item_no             =  xola.shipping_item_code
                                -- OPM�i�ڃ}�X�^.�i�ځ��󒍖��׃A�h�I��.�o�וi�ڂ���
      AND   ximv.start_date_active   <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- OPM�i�ڃA�h�I���}�X�^.�K�p�J�n�����p�����[�^. �o�ɓ�����
      AND   ximv.end_date_active     >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- OPM�i�ڃA�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
      AND   xicv .item_id            =  ximv.item_id 
                                -- OPM�i�ڃJ�e�S������(�i�ڋ敪).�i��ID��OPM�i�ڃA�h�I���}�X�^.�i��ID
      AND   xola.delete_flag         <> cv_delete_flag
                                -- �󒍖��׃A�h�I��.�폜�t���O �� �fY�f
      AND   xcav.account_status      =  gv_status_A--�i�L���j
      AND   xottv.start_date_active  <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
      AND  (xottv.end_date_active    IS NULL
      OR    xottv.end_date_active    >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date)))
-- Ver 1.15 M.Hokkanji START
      AND   xsmv.ship_method_code(+) = NVL(xoha.result_shipping_method_code,xoha.shipping_method_code)
      AND   xsmv.start_date_active(+)  <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
      AND  (xsmv.end_date_active(+)    >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date)))
-- Ver 1.15 M.Hokkanji END
      ORDER BY xoha.request_no, xola.shipping_item_code
                                -- �˗�No,�i�ڃR�[�h
      FOR UPDATE OF xoha.req_status NOWAIT
      ;*/
-- 2008/09/01 N.Yoshida ADD END
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
-- 2008/09/01 N.Yoshida ADD START
      lv_select :=
      'SELECT  xola.shipping_item_code shipping_item_code' -- �i�ڃR�[�h - �󒍖��׃A�h�I��.�o�וi��
    ||      ', xola.quantity           quantity          ' -- ���� - �󒍖��׃A�h�I��.����
    ||      ', xoha.deliver_from_id    deliver_from_id   ' -- �o�׌�ID - �󒍃w�b�_�A�h�I��.�o�׌�ID
    ||      ', NVL(xoha.shipped_date,xoha.schedule_ship_date)'
    ||      '                        schedule_ship_date  ' -- �o�ɓ� - �󒍃w�b�_�A�h�I��.�o�ח\���
    ||      ' , xoha.head_sales_branch  head_sales_branch ' -- ���_�R�[�h - �󒍃w�b�_�A�h�I��.�Ǌ����_
    ||      ' , ximv.inventory_item_id '
    ||      '                 shipping_inventory_item_id ' -- �i��ID - inv�̕i��ID
    ||      ' , xoha.prod_class         prod_class       ' -- ���i�敪 - �󒍃w�b�_�A�h�I��.���i�敪
    ||      ' , xoha.deliver_from       deliver_from     ' -- �o�׌��ۊǏꏊ�R�[�h - �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
    ||      ' , NVL(xoha.result_deliver_to,xoha.deliver_to)         deliver_to  '       -- �z����R�[�h - �󒍃w�b�_�A�h�I��.�o�א�
    ||      ' , xoha.request_no         request_no       ' -- �˗�No - �󒍃w�b�_�A�h�I��.�˗�No
    ||      ' , NVL(xoha.arrival_date,xoha.schedule_arrival_date) '
    ||      '                        schedule_arrival_date ' -- ���� - �󒍃w�b�_�A�h�I��.���ח\���
    ||      ' , NVL(xoha.result_shipping_method_code,xoha.shipping_method_code) '
    ||      '                        shipping_method_code ' -- �z���敪 - �󒍃w�b�_�A�h�I��.�z���敪
    ||      ' , xoha.sum_weight         sum_weight        ' -- �ύڏd�ʍ��v - �󒍃w�b�_�A�h�I��.�ύڏd�ʍ��v
    ||      ' , xoha.sum_capacity       sum_capacity      ' -- �ύڗe�ύ��v - �󒍃w�b�_�A�h�I��.�ύڗe�ύ��v
    ||      ' , xoha.pallet_sum_quantity '
    ||      '                         pallet_sum_quantity ' -- �p���b�g���v���� - �󒍃w�b�_�A�h�I��.�p���b�g���v����
    ||      ' , xoha.order_type_id      order_type_id     ' -- �󒍃^�C�vID - �󒍃w�b�_�A�h�I��.�󒍃^�C�vID
    ||      ' , DECODE(''' || iv_prod_class || ''''
    ||      '     ,''' || 1 || ''', xcav.leaf_base_category          ' -- ���[�t���_�J�e�S�� �ڋq���VIEW2
    ||      '     ,''' || 2 || ''', xcav.drink_base_category         ' -- �h�����N���_�J�e�S�� �ڋq���VIEW2
    ||      '           ,'''')  base_category               ' -- ���_�J�e�S��
    ||      ', xoha.sum_pallet_weight  sum_pallet_weight ' -- ���v�p���b�g�d�� �ύX#173
    ||      ', xoha.weight_capacity_class weight_capacity_class ' -- �d�ʗe�ϋ敪
    ||      ', xola.based_request_quantity based_request_quantity ' -- ���_�˗�����
    ||      ', xola.request_item_code request_item_code  ' -- �˗��i�ڃR�[�h
    ||      ', xola.request_item_id request_item_id      ' -- �˗��i��ID
    ||      ', xsmv.small_amount_class small_amount_class ' -- �����敪
    ||      ', ximv.item_id item_id                      ' -- �i��ID(OPM�̕i��ID)
-- Ver1.24 M.Hokkanji Start
--    ||      ', ximv.parent_item_id parent_item_id        ' -- �e�i��ID
-- Ver1.24 M.Hokkanji End
    ||      ', ximv.num_of_deliver     num_of_deliver    ' -- �o�ד��� - OPM�i�ڃ}�X�^.�o�ד���
    ||      ', ximv.num_of_cases       num_of_cases      ' -- ���� OPM�i�ڃ}�X�^.����
-- Ver1.24 M.Hokkanji Start
--    ||      ', ximv.ship_class         ship_class        ' -- �o�׋敪 - OPM�i�ڃ}�X�^.�o�׋敪
--    ||      ', ximv.sales_div          sales_div         ' -- ����Ώۋ敪 - OPM�i�ڃ}�X�^. ����Ώۋ敪
--    ||      ', ximv.obsolete_class     obsolete_class    ' -- �p�~�敪 - OPM�i�ڃ}�X�^. �p�~�敪
--    ||      ', ximv.rate_class         rate_class        ' -- ���敪 - OPM�i�ڃ}�X�^. ���敪
-- Ver1.24 M.Hokkanji End
    ||      ', ximv.delivery_qty       delivery_qty      ' -- �z�� - OPM�i�ڃ}�X�^.�z��
    ||      ', xicv.item_class_code    item_class_code   ' -- �i�ڋ敪 - �i�ڃJ�e�S��.�Z�O�����g1
-- Ver1.24 M.Hokkanji Start
    ||      ', ximv2.item_id opm_request_item_id         ' -- �i��ID(OPM�̕i��ID)
    ||      ', ximv2.parent_item_id parent_item_id        ' -- �e�i��ID
    ||      ', ximv2.ship_class         ship_class        ' -- �o�׋敪 - OPM�i�ڃ}�X�^.�o�׋敪
    ||      ', ximv2.sales_div          sales_div         ' -- ����Ώۋ敪 - OPM�i�ڃ}�X�^. ����Ώۋ敪
    ||      ', ximv2.obsolete_class     obsolete_class    ' -- �p�~�敪 - OPM�i�ڃ}�X�^. �p�~�敪
    ||      ', ximv2.rate_class         rate_class        ' -- ���敪 - OPM�i�ڃ}�X�^. ���敪
-- Ver1.24 M.Hokkanji End
    ||      ', xcav.account_number     account_number    ' -- �ڋq�R�[�h - �ڋq�}�X�^. �ڋq�R�[�h
    ||      ', xcav.cust_enable_flag   cust_enable_flag  ' -- ���~�q�\���t���O - �ڋq�}�X�^. ���~�q�\���t���O
    ||      ', xcav.location_rel_code  location_rel_code ' -- ���_���їL���敪 - �ڋq�}�X�^.���_���їL���敪
    ||      ', xoha.order_header_id    order_header_id   ' -- �󒍃w�b�_�A�h�I��ID
    ||      ', ximv.conv_unit          conv_unit         ' -- ���o�Ɋ��Z�P�� OPM�i�ڃ}�X�^���o�Ɋ��Z�P��
    ||      ', xoha.freight_charge_class   freight_charge_class '  -- �^���敪 2008/07/09 ST�s��Ή�#430
    ||      ', NVL(xoha.result_freight_carrier_code,xoha.freight_carrier_code) '
    ||      '                          freight_carrier_code ' -- �^���Ǝ� - �󒍃w�b�_�A�h�I��.�^���Ǝ� 2008/09/24 TE080_400�w�E66�Ή�
    ||  ' FROM'
    ||  '   xxwsh_oe_transaction_types2_v xottv ' --�@�󒍃^�C�v���VIEW2
    ||  '  ,xxwsh_order_headers_all       xoha  ' --�A�󒍃w�b�_�A�h�I��
    ||  '  ,xxwsh_order_lines_all         xola  ' --�B�󒍖��׃A�h�I��
    ||  '  ,xxcmn_cust_accounts2_v        xcav  ' --�C�ڋq���VIEW2
    ||  '  ,xxcmn_cust_acct_sites2_v      xcasv ' --�D�ڋq�T�C�g���VIEW2
    ||  '  ,xxcmn_item_mst2_v             ximv  ' --�EOPM�i�ڏ��VIEW2
-- Ver1.24 M.Hokkanji Start
    ||  '  ,xxcmn_item_mst2_v             ximv2 ' --OPM�i�ڏ��VIEW2(�˗��i�ڗp)
-- Ver1.24 M.Hokkanji End
    ||  '  ,xxcmn_item_categories5_v      xicv  ' --OPM�i�ڃJ�e�S���������VIEW5
    ||  '  ,xxwsh_ship_method2_v          xsmv  ' --�z���敪���VIEW2
    ||  ' WHERE xottv.order_category_code   =  ''' || cv_order_category_code || ''''
                                --�󒍃J�e�S���R�[�h
    ||  ' AND   xottv.shipping_shikyu_class =  ''' || cv_shipping_shikyu_class || ''''
                                -- �o�׎x���敪���u�o�׈˗�
    ||  ' AND   xoha.order_type_id          =  xottv.TRANSACTION_TYPE_ID '
                                -- �󒍃w�b�_�A�h�I��.�󒍃^�C�vID���󒍃^�C�v.����^�C�vID����
    ||  ' AND   xoha.latest_external_flag   =  ''' || cv_latest_external_flag || ''''
                                -- �ŐV�t���O���fY'
    ||  ' AND   xoha.prod_class             =  ''' || iv_prod_class || ''''
                                -- �󒍃w�b�_�A�h�I��.���i�敪���p�����[�^.���i�敪 ����
    ||  ' AND   xoha.req_status             =  ''' || gv_status_01 || ''''
                                -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X���u01:���͒��v����
    ||  ' AND   xoha.input_sales_branch     =  ''' || iv_input_sales_branch || ''''
                                -- �󒍃w�b�_�A�h�I��.���͋��_���p�����[�^.���͋��_�R�[�h����
    ||  ' AND   xoha.order_header_id        =  xola.order_header_id '
        -- �󒍃w�b�_�A�h�I��.�󒍃w�b�_�A�h�I��ID���󒍖��׃A�h�I��.�󒍃w�b�_�A�h�I��ID����
    ||  ' AND   NVL(xoha.result_deliver_to_id,xoha.deliver_to_id)          =  xcasv.party_site_id '
        -- �󒍃w�b�_�A�h�I��.�o�א�ID �� �p�[�e�B�T�C�g�A�h�I���}�X�^.�p�[�e�B�T�C�gID����
    ||  ' AND   xcav.party_id               =    xcasv.party_id '
        -- �p�[�e�B�A�h�I���}�X�^.�p�[�e�B�T�C�gID���p�[�e�B�T�C�g�A�h�I���}�X�^.�p�[�e�B�T�C�gID����
    ||  ' AND   xcav.start_date_active   <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- �p�[�e�B�A�h�I���}�X�^.�K�p�J�n�����p�����[�^.�o�ɓ�����
    ||  ' AND   xcav.end_date_active     >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- �p�[�e�B�A�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
    ||  ' AND   xcasv.start_date_active  <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- �p�[�e�B�T�C�g�A�h�I���}�X�^.�K�p�J�n�����p�����[�^. �o�ɓ�����
    ||  ' AND   xcasv.end_date_active    >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- �p�[�e�B�T�C�g�A�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
    ||  ' AND   ximv.item_no             =  xola.shipping_item_code '
                                -- OPM�i�ڃ}�X�^.�i�ځ��󒍖��׃A�h�I��.�o�וi�ڂ���
    ||  ' AND   ximv.start_date_active   <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- OPM�i�ڃA�h�I���}�X�^.�K�p�J�n�����p�����[�^. �o�ɓ�����
    ||  ' AND   ximv.end_date_active     >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- OPM�i�ڃA�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
    ||  ' AND   xicv .item_id            =  ximv.item_id  '
                                -- OPM�i�ڃJ�e�S������(�i�ڋ敪).�i��ID��OPM�i�ڃA�h�I���}�X�^.�i��ID
    ||  ' AND   xola.delete_flag         <> ''' || cv_delete_flag || ''''
                                -- �󒍖��׃A�h�I��.�폜�t���O �� �fY�f
-- Ver1.24 M.Hokkanji Start
    ||  ' AND   ximv2.item_no            =  xola.request_item_code '
                                -- OPM�i�ڃA�h�I���}�X�^.�i�ځ��󒍖��׃A�h�I��.�˗��i�ڂ���
    ||  ' AND   ximv2.start_date_active   <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- OPM�i�ڃA�h�I���}�X�^.�K�p�J�n�����p�����[�^. �o�ɓ�����
    ||  ' AND   ximv2.end_date_active     >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- OPM�i�ڃA�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
-- Ver1.24 M.Hokkanji End
    ||  ' AND   xcav.account_status      =  ''' || gv_status_A || '''' --�i�L���j
    ||  ' AND   xottv.start_date_active  <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
    ||  ' AND  (xottv.end_date_active    IS NULL '
    ||  ' OR    xottv.end_date_active    >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date))) '
    ||  ' AND   xsmv.ship_method_code(+) = NVL(xoha.result_shipping_method_code,xoha.shipping_method_code) '
    ||  ' AND   xsmv.start_date_active(+)  <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
    ||  ' AND  (xsmv.end_date_active(+)    >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date))) ';

    lv_select_other :=
    '  ORDER BY xoha.request_no, xola.shipping_item_code '  -- �˗�No,�i�ڃR�[�h
    || '  FOR UPDATE OF xoha.req_status NOWAIT';
--
-- 2008/09/01 N.Yoshida ADD END
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--
    -- ������
    gv_callfrom_flg := iv_callfrom_flg;
    lv_err_message := NULL;
    lv_warn_message := NULL;
    lv_bfr_request_no := '';
    ln_bfr_order_header_id := 0;
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- **************************************************
    -- *** �p�����[�^�`�F�b�N(D-1)
    -- **************************************************
--
--  �K�{�`�F�b�N
--
    -- �u���͋��_�v�`�F�b�N
    IF (iv_input_sales_branch IS NULL) THEN
      -- ���͋��_��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_null,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_02) || gv_line_feed;
    END IF;
--
    -- �u�ďo���t���O�v�`�F�b�N
    IF (iv_callfrom_flg IS NULL) THEN
      -- �ďo���t���O��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_null,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_03) || gv_line_feed;
    END IF;
--
    -- �u���߃X�e�[�^�X�`�F�b�N�敪�v�`�F�b�N
    IF (iv_status_kbn IS NULL) THEN
      -- ���߃X�e�[�^�X�`�F�b�N�敪��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_null,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_04) || gv_line_feed;
    END IF;
--
    -- �u���i�敪�v�`�F�b�N
    IF (iv_prod_class IS NULL) THEN
      -- ���i�敪��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_null,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_07) || gv_line_feed;
    END IF;
--
--  �Ó����`�F�b�N
--
    -- �u�ďo���t���O�v�`�F�b�N
    IF ((iv_callfrom_flg <> '1') AND (iv_callfrom_flg <> '2')) THEN
      -- �ďo���t���O��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_prop,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_05) || gv_line_feed;
    END IF;
--
    -- �u���߃X�e�[�^�X�`�F�b�N�敪�v�`�F�b�N
    IF ((iv_status_kbn <> '1') AND (iv_status_kbn <> '2')) THEN
      -- ���߃X�e�[�^�X�`�F�b�N�敪��1�A2�ȊO�̃`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_prop,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_06) || gv_line_feed;
    END IF;
-- Ver1.15 M.Hokkanji START
    -- �o�Ɍ`��(�r���o��)���擾
    BEGIN
      SELECT xottv.transaction_type_id
        INTO lt_transaction_type_id
        FROM xxwsh_oe_transaction_types_v xottv
       WHERE xottv.transaction_type_name = cv_tran_type_name_ara;
    EXCEPTION
      WHEN OTHERS THEN
        lv_err_message := lv_err_message ||
                 xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                          gv_cnst_cmn_012,
                                          gv_cnst_tkn_table,
                                          cv_table_name_tran,
                                          gv_cnst_tkn_key,
                                          cv_tran_type_name || ':' || cv_tran_type_name_ara);
    END;
-- Ver1.15 M.Hokkanji END
-- Ver1.19 M.Hokkanji Start
    -- �o�Ɍ`��(�r���o��)���擾
    BEGIN
      SELECT xottv.transaction_type_id
        INTO lt_transaction_type_id_mat
        FROM xxwsh_oe_transaction_types_v xottv
       WHERE xottv.transaction_type_name = cv_tran_type_name_mat;
    EXCEPTION
      WHEN OTHERS THEN
        lv_err_message := lv_err_message ||
                 xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                          gv_cnst_cmn_012,
                                          gv_cnst_tkn_table,
                                          cv_table_name_tran,
                                          gv_cnst_tkn_key,
                                          cv_tran_type_name || ':' || cv_tran_type_name_mat);
    END;
-- Ver1.19 M.Hokkanji End
--
    -- **************************************************
    -- *** ���b�Z�[�W�̐��`
    -- **************************************************
    -- ���b�Z�[�W���o�^����Ă���ꍇ
    IF (lv_err_message IS NOT NULL) THEN
      -- �Ō�̉��s�R�[�h���폜��OUT�p�����[�^�ɐݒ�
      lv_errmsg := RTRIM(lv_err_message, gv_line_feed);
      -- �G���[�Ƃ��ďI��
      RAISE global_api_expt;
    END IF;
--
--
-- 2008/09/01 N.Yoshida ADD START
    /*
    -- �p�����[�^.�Ǌ����_�R�[�hNULL�`�F�b�N
    IF  (iv_head_sales_branch IS NULL) THEN
      -- �Ǌ����_�R�[�h��NULL�̏ꍇ
      ln_head_sales_branch_nullflg := 1;
    ELSE
      ln_head_sales_branch_nullflg := 0;
    END IF;
--
    -- �p�����[�^.�z����IDNULL�`�F�b�N
    IF  (in_deliver_to_id IS NULL) THEN
      -- �z����ID��NULL�̏ꍇ
      in_deliver_to_id_nullflg := 1;
    ELSE
      in_deliver_to_id_nullflg := 0;
    END IF;
--
    -- �p�����[�^.�˗�No NULL�`�F�b�N
    IF  (iv_request_no IS NULL) THEN
      -- �z����ID��NULL�̏ꍇ
      ln_request_no_nullflg := 1;
    ELSE
      ln_request_no_nullflg := 0;
    END IF;
--
    -- �p�����[�^.�o�ɓ� NULL�`�F�b�N
    IF  (id_schedule_ship_date IS NULL) THEN
      -- �o�ɓ���NULL�̏ꍇ
      ln_schedule_ship_date_nullflg := 1;
    ELSE
      ln_schedule_ship_date_nullflg := 0;
    END IF;
--
    -- �p�����[�^.���� NULL�`�F�b�N
    IF  (id_schedule_arrival_date IS NULL) THEN
      -- ������NULL�̏ꍇ
      ln_s_a_d_nullflg := 1;
    ELSE
      ln_s_a_d_nullflg := 0;
    END IF;
    */
    -- �p�����[�^.�Ǌ����_�R�[�hNULL�`�F�b�N
    IF  (iv_head_sales_branch IS NULL) THEN
      -- �Ǌ����_�R�[�h��NULL�̏ꍇ
      lv_select_c1 := '';
    ELSE
      lv_select_c1 := ' AND xoha.head_sales_branch = ''' || iv_head_sales_branch || '''';
    END IF;
--
    -- �p�����[�^.�z����IDNULL�`�F�b�N
    IF  (in_deliver_to_id IS NULL) THEN
      -- �z����ID��NULL�̏ꍇ
      lv_select_c2 := '';
    ELSE
      lv_select_c2 := ' AND NVL(xoha.result_deliver_to_id,xoha.deliver_to_id) = ''' || in_deliver_to_id ||  '''';
    END IF;
--
    -- �p�����[�^.�˗�No NULL�`�F�b�N
    IF  (iv_request_no IS NULL) THEN
      -- �z����ID��NULL�̏ꍇ
      lv_select_c3 := '';
    ELSE
      lv_select_c3 := ' AND xoha.request_no = ''' || iv_request_no || '''';
    END IF;
--
    -- �p�����[�^.�o�ɓ� NULL�`�F�b�N
    IF  (id_schedule_ship_date IS NULL) THEN
      -- �o�ɓ���NULL�̏ꍇ
      lv_select_c4 := '';
    ELSE
      lv_select_c4 := ' AND NVL(xoha.shipped_date,xoha.schedule_ship_date) = ''' || id_schedule_ship_date || '''';
    END IF;
--
    -- �p�����[�^.���� NULL�`�F�b�N
    IF  (id_schedule_arrival_date IS NULL) THEN
      -- ������NULL�̏ꍇ
      lv_select_c5 := '';
    ELSE
      lv_select_c5 := ' AND NVL(xoha.arrival_date,xoha.schedule_arrival_date) = ''' || id_schedule_arrival_date || '''';
    END IF;
-- 2008/09/01 N.Yoshida ADD END
--
    ld_sysdate := TRUNC(SYSDATE); -- �V�X�e�����t�̎擾
--
--  �X�V�pPL/SQL�\������
    gt_header_id_upd_tab.DELETE;                 -- �󒍃w�b�_�A�h�I��ID
--
    -- ========================================
    -- �f�[�^�̃`�F�b�N���s��
    -- ========================================
--
-- 2008/09/01 N.Yoshida ADD START
    --<<data_loop>>
    --FOR loop_cnt IN upd_status_cur LOOP
    OPEN upd_status_cur FOR lv_select || lv_select_c1 || lv_select_c2 || lv_select_c3 || lv_select_c4 ||
                            lv_select_c5 || lv_select_other;
    <<data_loop>>
    LOOP
      FETCH upd_status_cur INTO loop_cnt;
      EXIT WHEN upd_status_cur%NOTFOUND;
-- 2008/09/01 N.Yoshida ADD END
--
      -- �����������J�E���g
      IF (ln_bfr_order_header_id <> loop_cnt.order_header_id) THEN
        ln_target_cnt := ln_target_cnt + 1;
        ln_bfr_order_header_id := loop_cnt.order_header_id;
      END IF;
--
      ln_data_cnt := ln_data_cnt + 1;
--
      -- �ďo���t���O��1:�R���J�����g�̏ꍇ
      IF (iv_callfrom_flg = '1') THEN
        -- **************************************************
        -- *** �ғ����`�F�b�N(D-3)
        -- **************************************************
  --
-- Ver1.15 M.Hokkanji START
-- �ғ����`�F�b�N�͍r���o�ׂ̏ꍇ�̓`�F�b�N���s��Ȃ�
        IF ( loop_cnt.order_type_id <> lt_transaction_type_id) THEN
-- Ver1.15 M.Hokkanji END
          -- �o�ɓ��̉ғ����`�F�b�N
          ln_retcode := xxwsh_common_pkg.get_oprtn_day(loop_cnt.schedule_ship_date, -- D-2�o�ɓ�
                                                       loop_cnt.deliver_from,       -- D-2�o�׌��ۊǏꏊ
                                                       NULL,                        -- �z����R�[�h
                                                       0,                           -- ���[�h�^�C��
                                                       loop_cnt.prod_class,         -- D-2���i�敪
                                                       ld_oprtn_day);               -- �ғ������t
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          -- �o�ɓ����ғ����łȂ��ꍇ�̓G���[
-- Ver1.15 M.Hokkanji TE080_400�w�ENo75 START
          -- �ғ������t����v���Ȃ��ꍇ�̓G���[�ɕύX
--          ELSIF (ld_oprtn_day IS NULL) THEN
          ELSIF (ld_oprtn_day <> loop_cnt.schedule_ship_date) THEN
-- Ver1.15 M.Hokkanji TE080_400�w�ENo75 END
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_154,
                                                  'IN_DATE',
-- Ver1.15 M.Hokkanji TE080_400�w�ENo75 START
--                                                  loop_cnt.schedule_ship_date,
                                                  TO_CHAR(loop_cnt.schedule_ship_date,'YYYY/MM/DD'),
-- Ver1.15 M.Hokkanji TE080_400�w�ENo75 END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- �����̉ғ����`�F�b�N
          ln_retcode := xxwsh_common_pkg.get_oprtn_day(loop_cnt.schedule_arrival_date, -- D-2����
                                                       NULL,                  -- �o�׌��ۊǏꏊ
                                                       loop_cnt.deliver_to,   -- �z����R�[�h
                                                       0,                     -- ���[�h�^�C��
                                                       loop_cnt.prod_class,   -- D-2���i�敪
                                                       ld_oprtn_day);         -- �ғ������t
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          -- �������ғ����łȂ��ꍇ�͌x��
-- Ver1.15 M.Hokkanji TE080_400�w�ENo75 START
          -- �ғ������t����v���Ȃ��ꍇ�̓G���[�ɕύX
--          ELSIF (ld_oprtn_day IS NULL) THEN
          ELSIF (ld_oprtn_day <> loop_cnt.schedule_arrival_date) THEN
-- Ver1.15 M.Hokkanji TE080_400�w�ENo75 END
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_154,
                                                  'IN_DATE',
-- Ver1.15 M.Hokkanji TE080_400�w�ENo75 START
--                                                  loop_cnt.schedule_arrival_date,
                                                  TO_CHAR(loop_cnt.schedule_arrival_date,'YYYY/MM/DD'),
-- Ver1.15 M.Hokkanji TE080_400�w�ENo75 END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no) || gv_line_feed;
            -- �x�����Z�b�g
            ln_warn_cnt := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
          END IF;
-- Ver1.15 M.Hokkanji START
        END IF;
-- Ver1.15 M.Hokkanji END
  --
        -- �����Ώۃ`�F�b�N
        ln_retcode := allow_pickup_flag_chk(loop_cnt.deliver_from,   -- D-2�o�׌��ۊǏꏊ
                                            lv_retcode,              -- ���^�[���R�[�h
                                            lv_errbuf,               -- �G���[���b�Z�[�W�R�[�h
                                            lv_errmsg);              -- �G���[���b�Z�[�W
  --
        -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
        IF (ln_retcode = gn_status_error) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_175,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'SHIP_FROM',
                                                loop_cnt.deliver_from);
          RAISE global_api_expt;
        END IF;
  --
-- Ver1.15 M.Hokkanji START
-- ���[�h�^�C���`�F�b�N�͍r���o�ׂ̏ꍇ�̓`�F�b�N���s��Ȃ�
        IF ( loop_cnt.order_type_id <> lt_transaction_type_id) THEN
-- Ver1.15 M.Hokkanji END
          -- **************************************************
          -- *** ���[�h�^�C���`�F�b�N(D-4)
          -- **************************************************
--
          xxwsh_common910_pkg.calc_lead_time('4',                            -- �q��
                                             loop_cnt.deliver_from,          -- D-2�o�׌��ۊǏꏊ
                                             '9',                            -- �z����
                                             loop_cnt.deliver_to,            -- D-2�z����R�[�h
                                             loop_cnt.prod_class,            -- D-2���i�敪
                                             loop_cnt.order_type_id,         -- D-2�󒍃^�C�vID
                                             loop_cnt.schedule_ship_date,    -- D-2�o�ח\���
                                             lv_retcode,                     -- ���^�[���R�[�h
                                             lv_errbuf,                      -- �G���[���b�Z�[�W�R�[�h
                                             lv_errmsg,                      -- �G���[���b�Z�[�W
                                             ln_lead_time,                   -- ���Y����LT�^����ύXLT
                                             ln_delivery_lt);                -- �z��LT
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_calc_lead_time_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- ���[�h�^�C���Ó��`�F�b�N
-- Ver1.23 M.Hokkanji Start
--          ln_retcode :=
-- Ver1.23 M.Hokkanji End
-- Ver1.19 M.Hokkanji Start
-- �o�ɓ��̐��Y����LT�̉ғ������擾����悤�ɕύX
--          xxwsh_common_pkg.get_oprtn_day(loop_cnt.schedule_arrival_date, -- D-2����
--                                         NULL,                           -- �o�׌��ۊǏꏊ
--                                         loop_cnt.deliver_to,            -- D-2�z����R�[�h
--                                         ln_delivery_lt,                 -- ���[�h�^�C��
--                                         loop_cnt.prod_class,            -- D-2���i�敪
--                                         ld_oprtn_day);                  -- �ғ������t
-- Ver1.23 M.Hokkanji Start
--          xxwsh_common_pkg.get_oprtn_day(loop_cnt.schedule_ship_date,    -- D-2�o�ח\���
--                                         NULL,                           -- �o�׌��ۊǏꏊ
--                                         loop_cnt.deliver_to,            -- D-2�z����R�[�h
--                                         ln_lead_time,                   -- ���Y����LT
--                                         loop_cnt.prod_class,            -- D-2���i�敪
--                                         ld_oprtn_day);                  -- �ғ������t
-- Ver1.23 M.Hokkanji End
-- Ver1.19 M.Hokkanji End
--
-- Ver1.23 M.Hokkanji Start
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
--          IF (ln_retcode = gn_status_error) THEN
--            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
-- Ver1.15 M.Hokkanji START
 --                                                 gv_cnst_msg_155,
--                                                  gv_cnst_msg_154,
-- Ver1.15 M.Hokkanji END
--                                                  'API_NAME',
--                                                  cv_get_oprtn_day_api,
--                                                  'ERR_MSG',
--                                                  '',
--                                                  'REQUEST_NO',
--                                                  loop_cnt.request_no);
--            RAISE global_api_expt;
--          END IF;
-- Ver1.23 M.Hokkanji End
--
-- Ver1.19 M.Hokkanji Start
          IF (ln_delivery_lt IS NULL ) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_177,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
-- Ver1.19 M.Hokkanji End
          -- D-2�o�ɓ� > (���� - �z��LT)
          IF (loop_cnt.schedule_ship_date >
                 (loop_cnt.schedule_arrival_date - ln_delivery_lt)) THEN
 --          IF (loop_cnt.schedule_ship_date > ld_oprtn_day) THEN
            -- ���[�h�^�C���𖞂����Ă��Ȃ�
-- Ver1.19 M.Hokkanji End
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_153,
                                                  'LT_CLASS',
-- Ver1.19 M.Hokkanji Start
--                                                  cv_get_oprtn_day_lt,
                                                  cv_get_oprtn_day_lt2,
-- Ver1.19 M.Hokkanji End
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- �V�X�e�����t > �ғ���
-- Ver1.19 M.Hokkanji Start
--          IF (ld_sysdate > ld_oprtn_day) THEN
-- Ver1.23 M.Hokkanji Start
--          IF (ld_sysdate > ld_oprtn_day + 1) THEN
          IF (ld_sysdate > (loop_cnt.schedule_ship_date - ln_lead_time + 1)) THEN
-- Ver1.23 M.Hokkanji End
-- Ver1.19 M.Hokkanji End
            -- �z�����[�h�^�C�����Ó��łȂ�
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_153,
                                                  'LT_CLASS',
-- Ver1.19 M.Hokkanji Start
                                                  cv_get_oprtn_day_lt,
                                                  --cv_get_oprtn_day_lt2,
-- Ver1.19 M.Hokkanji End
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
-- Ver1.15 M.Hokkanji START
        END IF;
-- Ver1.15 M.Hokkanji END
      END IF;
--
      IF (iv_status_kbn = '1') THEN  -- 2008/07/30 ST�s��Ή�#501
        -- ���߃X�e�[�^�X�`�F�b�N�敪��1:�`�F�b�N�L��̏ꍇ
        -- D-2���~�q�\���t���O��'0'�ȊO�̏ꍇ�̓G���[
        IF (loop_cnt.cust_enable_flag <> '0') THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_164,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'CUST',
                                                loop_cnt.account_number);
          RAISE global_api_expt;
--
        END IF;
--
      -- **************************************************
      -- *** ���߃X�e�[�^�X�E�ڋq�`�F�b�N(D-5)
      -- **************************************************
--
--      IF (iv_status_kbn = '1') THEN  2008/07/30 ST�s��Ή�#501
        -- ���߃X�e�[�^�X�`�F�b�N�敪��1:�`�F�b�N�L��̏ꍇ
        lv_status :=
        xxwsh_common_pkg.check_tightening_status(loop_cnt.order_type_id,       -- D-2�󒍃^�C�vID
                                                 loop_cnt.deliver_from,        -- D-2�o�׌��ۊǏꏊ
                                                 loop_cnt.head_sales_branch,   -- D-2���_
                                                 NULL,                         -- ���_�J�e�S��
                                                 ln_lead_time,                 -- D-4���Y����LT
                                                 loop_cnt.schedule_ship_date,  -- D-2�o�ɓ�
                                                 loop_cnt.prod_class);         -- D-2���i�敪
--
        -- ���߃X�e�[�^�X��'2'�܂���'4'�̏ꍇ�̓G���[
        IF ((lv_status = '2') OR (lv_status = '4')) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_160,
                                                'REQUEST_NO',
                                                loop_cnt.request_no);
          RAISE global_api_expt;
--
        END IF;
--
        -- **************************************************
        -- *** �ő�p���b�g�����`�F�b�N(D-6)
        -- **************************************************
--
        -- �ő�p���b�g�����Z�o�֐�               �^���敪��ON�̏ꍇ�Ƀ`�F�b�N����(2008/07/09 ST�s��Ή�#430)
        --                                        ���i�敪���h�����N�̏ꍇ�Ƀ`�F�b�N����(2008/07/29 ST�s��Ή�#503)
-- 2008/07/29 D.Nihei MOD START
--        IF ( loop_cnt.freight_charge_class = gv_freight_charge_class_on ) THEN  -- 2008/07/09 ST�s��Ή�#430
        IF ( (loop_cnt.freight_charge_class = gv_freight_charge_class_on )
         AND (loop_cnt.prod_class           = gv_drink                   ) ) THEN  -- 2008/07/29 ST�s��Ή�#503
-- 2008/07/29 D.Nihei MOD START
--
          ln_retcode :=
          xxwsh_common_pkg.get_max_pallet_qty(cv_whse_code, -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
                                              loop_cnt.deliver_from,         -- D-2�o�׌��ۊǏꏊ
                                              cv_deliver_to,
                                                            -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�z����v
                                              loop_cnt.deliver_to,           -- D-2�z����R�[�h
                                              loop_cnt.schedule_ship_date,   -- D-2�o�ɓ�
                                              loop_cnt.shipping_method_code, -- D-2�z���敪
                                              ln_drink_deadweight,           -- �h�����N�ύڏd��
                                              ln_leaf_deadweight,            -- ���[�t�ύڏd��
                                              ln_drink_loading_capacity,     -- �h�����N�ύڗe��
                                              ln_leaf_loading_capacity,      -- ���[�t�ύڗe��
                                              ln_palette_max_qty);           -- �p���b�g�ő喇��
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_get_max_pallet_qty_api,
                                                  'ERR_MSG',
                                                  cv_get_max_pallet_qty_msg,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          -- D-2�p���b�g���v���� > D-6�p���b�g�ő喇���̏ꍇ�̓G���[
          ELSIF (loop_cnt.pallet_sum_quantity > ln_palette_max_qty) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_151,
                                              'REQUEST_NO',
                                              loop_cnt.request_no);
            RAISE global_api_expt;
--
          END IF;
        END IF;  -- 2008/07/09 ST�s��Ή�#430
--      END IF; -- 2008/07/30 ST�s��Ή�#501
--
        -- **************************************************
        -- *** �}�X�^�`�F�b�N(D-7)
        -- **************************************************
--
-- Ver1.15 M.Hokkanji START
-- �r���o�ׂ̏ꍇ�͕����\�����݃`�F�b�N�͍s��Ȃ� TE080400�w�E75
-- �����\�����݃`�F�b�N�͈˗��i�ڂōs���A����ɔ����˗��i�ڂ��ݒ肳��Ă���ꍇ�̂݃`�F�b�N���s��
-- 
        IF ( (loop_cnt.order_type_id <> lt_transaction_type_id) AND
             (loop_cnt.request_item_code IS NOT NULL)) THEN
--          ln_retcode := master_check(loop_cnt.shipping_item_code,    -- D-2�i�ڃR�[�h
          ln_retcode := master_check(loop_cnt.request_item_code,     -- D-2�˗��i�ڃR�[�h
-- Ver1.15 M.Hokkanji END
                                     loop_cnt.deliver_to,            -- D-2�z����R�[�h
                                     loop_cnt.head_sales_branch,     -- D-2���_�R�[�h
                                     loop_cnt.deliver_from,          -- D-2�o�׌��ۊǏꏊ
                                     loop_cnt.schedule_ship_date,    -- D-2�o�ɓ�
                                     lv_retcode,                     -- ���^�[���R�[�h
                                     lv_errbuf,                      -- �G���[���b�Z�[�W�R�[�h
                                     lv_errmsg);                     -- �G���[���b�Z�[�W
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
-- Ver1.22 M.Hokkanji Start
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_152,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no,
                                                  gv_cnst_tkn_item_code,
                                                  loop_cnt.request_item_code,
                                                  gv_cnst_tkn_deliver_to,
                                                  loop_cnt.deliver_to,
                                                  gv_cnst_tkn_head_saled,
                                                  loop_cnt.head_sales_branch,
                                                  gv_cnst_tkn_deliver_from,
                                                  loop_cnt.deliver_from,
                                                  gv_cnst_tkn_ship_date,
                                                  TO_CHAR(loop_cnt.schedule_ship_date,'YYYY/MM/DD')
                                                  );
--            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
--                                                  gv_cnst_msg_152,
--                                                  'REQUEST_NO',
--                                                  loop_cnt.request_no);
-- Ver1.22 M.Hokkanji End
            RAISE global_api_expt;
          END IF;
-- Ver1.15 M.Hokkanji START
        END IF;
--
        -- D-2�o�׋敪���u�ہv�̏ꍇ
        IF (loop_cnt.ship_class = cv_ship_disable) THEN
--        ELSIF (loop_cnt.ship_class = cv_ship_disable) THEN
-- Ver1.15 M.Hokkanji END
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_166,
                                                'ITEM_ERRMSG',
                                                cv_master_check_msg,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
-- Ver1.24 M.Hokkanji Start
                                                loop_cnt.request_item_code);
--                                                loop_cnt.shipping_item_code);
-- Ver1.24 M.Hokkanji End
          RAISE global_api_expt;
--
        -- D-2����Ώۋ敪���u1�v�ȊO�̏ꍇ
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E74�Ή�(�i�ڂ��e�̏ꍇ�̂݃`�F�b�N���s��)
--        ELSIF (loop_cnt.sales_div <> cv_sales_div) THEN
-- Ver1.19 M.Hokkanji Start
--        ELSIF ((loop_cnt.sales_div <> cv_sales_div) AND
--               (loop_cnt.item_id = loop_cnt.parent_item_id)) THEN
-- Ver1.19 M.Hokkanji END
-- Ver1.15 M.Hokkanji END]
-- Ver1.19 M.Hokkanji Start
-- ���ޏo�ׂ͔���Ώۋ敪�̃`�F�b�N���s��Ȃ��悤�ɏC��
        ELSIF (loop_cnt.order_type_id <> lt_transaction_type_id_mat) AND
              ((loop_cnt.sales_div <> cv_sales_div) AND
-- Ver1.24 M.Hokkanji Start
               (loop_cnt.opm_request_item_id = loop_cnt.parent_item_id)) THEN
--               (loop_cnt.item_id = loop_cnt.parent_item_id)) THEN
-- Ver1.24 M.Hokkanji End
-- Ver1.19 M.Hokkanji End
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_166,
                                                'ITEM_ERRMSG',
                                                cv_master_check_msg2,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
-- Ver1.24 M.Hokkanji Start
                                                loop_cnt.request_item_code);
--                                                loop_cnt.shipping_item_code);
-- Ver1.24 M.Hokkanji End
          RAISE global_api_expt;
--
        -- D-2�p�~�敪���u1�v�̏ꍇ
        ELSIF (loop_cnt.obsolete_class = cv_obsolete_class) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_166,
                                                'ITEM_ERRMSG',
                                                cv_master_check_msg3,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
-- Ver1.24 M.Hokkanji Start
                                                loop_cnt.request_item_code);
--                                                loop_cnt.shipping_item_code);
-- Ver1.24 M.Hokkanji End
          RAISE global_api_expt;
--
        -- D-2���敪���u0�v�̏ꍇ
        ELSIF (loop_cnt.rate_class <> cv_rate_class) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_166,
                                                'ITEM_ERRMSG',
                                                cv_master_check_msg4,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
-- Ver1.24 M.Hokkanji Start
                                                loop_cnt.request_item_code);
--                                                loop_cnt.shipping_item_code);
-- Ver1.24 M.Hokkanji End
          RAISE global_api_expt;
--
-- 2008/08/06 D.Nihei DEL START
--        -- D-2�Ŏ擾�������ʂ�D-2�Ŏ擾�����z���̐����{�łȂ��ꍇ
--        ELSIF (mod(loop_cnt.quantity, loop_cnt.delivery_qty) <> 0) THEN
--          -- ���ʂ�z���Ŋ������]�肪0�łȂ��ꍇ
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
--                                                gv_cnst_msg_167,
--                                                'REQUEST_NO',
--                                                loop_cnt.request_no,
--                                                'ITEM_CODE',
--                                                loop_cnt.shipping_item_code);
--          -- �x�����Z�b�g
--          lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
--          ln_warn_flg := 1;
--          IF (gv_callfrom_flg = '1') THEN
--            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
--          END IF;
-- 2008/08/06 D.Nihei DEL END
--
        -- D-2�Ŏ擾�������ʂ�D-2�Ŏ擾�����o�ד����̐����{�łȂ��ꍇ
        ELSIF ((loop_cnt.num_of_deliver IS NOT NULL)
        AND    (mod(loop_cnt.quantity, loop_cnt.num_of_deliver) <> 0)) THEN
          -- ���ʂ��o�ד����Ŋ������]�肪0�łȂ��ꍇ
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_168,
                                                'ATTR_TYPE',
                                                cv_master_check_attr,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
                                                loop_cnt.shipping_item_code);
          RAISE global_api_expt;
--
        -- D-2�Ŏ擾�������ʂ�D-2�Ŏ擾���������̐����{�łȂ��ꍇ
        ELSIF ((loop_cnt.num_of_cases IS NOT NULL)
        AND    (loop_cnt.conv_unit IS NOT NULL) --���o�Ɋ��Z�P��
        AND    (mod(loop_cnt.quantity,loop_cnt.num_of_cases) <> 0)) THEN
        -- ���ʂ�����Ŋ������]�肪0�łȂ��ꍇ
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_168,
                                            'ATTR_TYPE',
                                            cv_master_check_attr2,
                                            'REQUEST_NO',
                                            loop_cnt.request_no,
                                            'ITEM_CODE',
                                            loop_cnt.shipping_item_code);
          RAISE global_api_expt;
--
        END IF;
--
-- 2008/08/06 D.Nihei ADD START
        ln_case_total := 0; -- �P�[�X�����v
        -- ���i�敪���u�h�����N�v���i�ڋ敪���u���i�v�̏ꍇ
        IF ( ( loop_cnt.prod_class      = gv_drink )
         AND ( loop_cnt.item_class_code = gv_prod  ) ) THEN
--
          -- �u�P�[�X�����v�v���擾
          IF ( loop_cnt.num_of_deliver IS NOT NULL ) THEN
            ln_case_total := loop_cnt.quantity / loop_cnt.num_of_deliver;
--
          ELSIF ( loop_cnt.num_of_cases IS NOT NULL ) THEN
            ln_case_total := loop_cnt.quantity / loop_cnt.num_of_cases;
--
          ELSE
            ln_case_total := loop_cnt.quantity;
--
          END IF;
--
          -- �u�P�[�X�����v�v��D-2�Ŏ擾�����z���̐����{�łȂ��ꍇ
          IF (mod(ln_case_total, loop_cnt.delivery_qty) <> 0) THEN
            -- ���ʂ�z���Ŋ������]�肪0�łȂ��ꍇ
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_167,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no,
                                                  'ITEM_CODE',
                                                  loop_cnt.shipping_item_code);
            -- �x�����Z�b�g
            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          END IF;
--
        END IF;
-- 2008/08/06 D.Nihei ADD END
      -- �X�e�[�^�X�`�F�b�N�L��̏ꍇ�͏o�׉ۃ`�F�b�N���������{
--      IF ( iv_status_kbn = '1' ) THEN -- 2008/07/30 ST�s��Ή�#501
                                        -- �}�X�^�`�F�b�N�̎��{�����ɃX�e�[�^�X�`�F�b�N�敪��ǉ�
        -- **************************************************
        -- *** �v�揤�i�t���O�擾����(D-8)
        -- **************************************************
--
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
--        ln_d8retcode := get_plan_item_flag(loop_cnt.shipping_item_code,   -- D-2�i�ڃR�[�h
        ln_d8retcode := get_plan_item_flag(loop_cnt.request_item_code,   -- �˗��i�ڃR�[�h
-- Ver1.15 M.Hokkanji END
                                           loop_cnt.head_sales_branch,    -- D-2���_�R�[�h
                                           loop_cnt.deliver_from,         -- D-2�o�׌��ۊǏꏊ
                                           loop_cnt.schedule_ship_date,   -- D-2�o�ɓ�
                                           lv_retcode,                    -- ���^�[���R�[�h
                                           lv_errbuf,                     -- �G���[���b�Z�[�W�R�[�h
                                           lv_errmsg);                    -- �G���[���b�Z�[�W
--
--
        -- **************************************************
        -- *** �o�׉ۃ`�F�b�N(D-9)
        -- **************************************************
--
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή��ɔ����˗��i�ځA���_�˗����ʂ��ݒ肳��Ă���ꍇ�̂݃`�F�b�N���s��
-- �i�x���������ѓ��͂ł����֐����ĂԂ��߁j
        IF ((loop_cnt.request_item_id IS NOT NULL) AND
            (loop_cnt.based_request_quantity IS NOT NULL)) THEN
        -- �`�F�b�N�P
-- Ver1.15 M.Hokkanji END
          xxwsh_common910_pkg.check_shipping_judgment('2',                            -- �`�F�b�N���@
                                                      loop_cnt.head_sales_branch,     -- D-2���_�R�[�h
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                      loop_cnt.request_item_id,       -- D-2�˗��i��ID
                                                      loop_cnt.based_request_quantity, -- D-2���_�˗�����
--                                                    loop_cnt.shipping_inventory_item_id,-- D-2�i��ID
--                                                    loop_cnt.quantity,              -- D-2����
-- Ver1.15 M.Hokkanji END
                                                      loop_cnt.schedule_arrival_date, -- D-2����
                                                      loop_cnt.deliver_from_id,       -- D-2�o�Ɍ�ID
                                                      loop_cnt.request_no,            -- �˗�No   6/19�ǉ�
                                                      lv_retcode,                     -- ���^�[���R�[�h
                                                      lv_errbuf,                 -- �G���[���b�Z�[�W�R�[�h
                                                      lv_errmsg,                      -- �G���[���b�Z�[�W
                                                      ln_retcode);                    -- ��������
--
          IF (( lv_retcode = '0' )
          AND ( iv_status_kbn = '1' )              -- ���߃X�e�[�^�X�`�F�b�N�敪�L��
          AND ( loop_cnt.location_rel_code = '1' ) -- D-2���_���їL���敪��ON�i���㋒�_=1�j
          AND ( ln_retcode = 1)) THEN
--
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                       gv_cnst_msg_169,
                                                       'CHK_TYPE',
                                                       cv_c_s_j_chk,
                                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                       loop_cnt.request_item_code,
--                                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END

                                                       'REQUEST_NO',
                                                       loop_cnt.request_no);
            RAISE global_api_expt;
--
          ELSIF (( lv_retcode = '0' )
          AND    ( iv_status_kbn = '1' )              -- ���߃X�e�[�^�X�`�F�b�N�敪�L��
          AND    ( loop_cnt.location_rel_code = '2' ) -- D-2���_���їL���敪��ON�i����Ȃ����_=2�j
          AND    ( ln_retcode = 1)) THEN
--
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                       gv_cnst_msg_173,
                                                       'CHK_TYPE',
                                                       cv_c_s_j_chk,
                                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                       loop_cnt.request_item_code,
--                                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                       'REQUEST_NO',
                                                       loop_cnt.request_no);
            -- �x�����Z�b�g
            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          ELSIF (( lv_retcode = '0' )
          AND    ( iv_status_kbn = '2' ) -- ���߃X�e�[�^�X�`�F�b�N�敪����
          AND    ( loop_cnt.location_rel_code = '2' ) -- D-2���_���їL���敪��ON�i����Ȃ����_=2�j
          AND    ( ln_retcode = 1 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                       gv_cnst_msg_173,
                                                       'CHK_TYPE',
                                                       cv_c_s_j_chk,
                                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                       loop_cnt.request_item_code,
--                                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                       'REQUEST_NO',
                                                       loop_cnt.request_no);
            -- �x�����Z�b�g
            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          ELSIF ( lv_retcode = gn_status_error ) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_c_s_j_api,
                                                    'ERR_MSG',
                                                    lv_errmsg, --cv_c_s_j_msg,
                                                    'REQUEST_NO',
                                                    loop_cnt.request_no);
              RAISE global_api_expt;
          END IF;
--
          -- �`�F�b�N�Q
          xxwsh_common910_pkg.check_shipping_judgment('3',                           -- �`�F�b�N���@
                                                      loop_cnt.head_sales_branch,    -- ���_�R�[�h
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                      loop_cnt.request_item_id,       -- D-2�˗��i��ID
                                                      loop_cnt.based_request_quantity, -- D-2���_�˗�����
--                                                    loop_cnt.shipping_inventory_item_id,-- D-2�i��ID
--                                                    loop_cnt.quantity,              -- D-2����
-- Ver1.15 M.Hokkanji END
                                                      loop_cnt.schedule_ship_date,   -- D-2�o�ɓ�
                                                      loop_cnt.deliver_from_id,      -- D-2�o�Ɍ�ID
                                                      loop_cnt.request_no,            -- �˗�No   6/19�ǉ�
                                                      lv_retcode,                    -- ���^�[���R�[�h
                                                      lv_errbuf,              -- �G���[���b�Z�[�W�R�[�h
                                                      lv_errmsg,                     -- �G���[���b�Z�[�W
                                                      ln_retcode);                   -- ��������
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (( lv_retcode = '0' )
          AND ( iv_status_kbn = '1' ) -- ���߃X�e�[�^�X�`�F�b�N�敪 �L��
          AND ( ln_retcode = 1 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_169,
                                                  'CHK_TYPE',
                                                  cv_c_s_j_chk2,
                                                  'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                  loop_cnt.request_item_code,
--                                                loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
              RAISE global_api_expt;
--
          ELSIF (( lv_retcode = '0' )
          AND ( iv_status_kbn = '2' ) -- ���߃X�e�[�^�X�`�F�b�N�敪 ����
          AND ( ln_retcode = 1 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_173,
                                                  'CHK_TYPE',
                                                  cv_c_s_j_chk2,
                                                  'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                  loop_cnt.request_item_code,
--                                                loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            -- �x�����Z�b�g

            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          ELSIF (( lv_retcode = '0' )
          AND ( iv_status_kbn = '1' ) -- ���߃X�e�[�^�X�`�F�b�N�敪 �L��
          AND ( ln_retcode = 2 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_170,
                                                  'CHK_TYPE',
                                                  cv_c_s_j_chk2,
                                                  'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                  loop_cnt.request_item_code,
--                                                loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          ELSIF (( lv_retcode = '0' )
          AND    ( iv_status_kbn = '2' ) -- ���߃X�e�[�^�X�`�F�b�N�敪 ����
          AND    ( ln_retcode = 2 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_174,
                                                  'CHK_TYPE',
                                                  cv_c_s_j_chk2,
                                                  'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                  loop_cnt.request_item_code,
--                                                loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            -- �x�����Z�b�g
            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          ELSIF ( lv_retcode = gn_status_error ) THEN-- 
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_c_s_j_api,
                                                  'ERR_MSG',
                                                  lv_errmsg, --cv_c_s_j_msg,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          END IF;
--
          IF ( iv_prod_class = cv_prod_class_leaf ) THEN -- ���[�t�̂�
--
-- ##### 20081202 Ver.1.21 �{��#318�Ή� START #####
            BEGIN
-- ##### 20081202 Ver.1.21 �{��#318�Ή� END   #####
--
              -- 2008/07/08 ST�s��Ή�#405 START
              -- �o�Ɍ`��(����ύX)�擾
              SELECT transaction_type_id
                INTO gv_transaction_type_id_ship
                FROM XXWSH_OE_TRANSACTION_TYPES2_V
                WHERE transaction_type_name = gv_transaction_type_name_ship;
--
-- ##### 20081202 Ver.1.21 �{��#318�Ή� START #####
            EXCEPTION
              -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
              WHEN OTHERS THEN
                lv_errmsg :=xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                                  gv_cnst_cmn_012,
                                                  gv_cnst_tkn_table,
                                                  cv_table_name_tran,
                                                  gv_cnst_tkn_key,
                                                  cv_tran_type_name || ':' || gv_transaction_type_name_ship);
                RAISE global_api_expt;
            END;
-- ##### 20081202 Ver.1.21 �{��#318�Ή� END   #####
--
            IF gv_transaction_type_id_ship IS NULL THEN  -- �擾�ł��Ȃ��ꍇ�̓G���[
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_c_s_j_api,
                                                    'ERR_MSG',
                                                    cv_c_s_j_msg3,
                                                    'REQUEST_NO',
                                                    loop_cnt.request_no);
              RAISE global_api_expt;
            END IF;
            -- 2008/07/08 ST�s��Ή�#405 END
--
            -- ���[�t�ŏo�Ɍ`�Ԃ�����ύX�ȊO�Ȃ�`�F�b�N�͍s��Ȃ� 2008/07/08 ST�s��Ή�#405
            IF ( loop_cnt.order_type_id = gv_transaction_type_id_ship ) THEN
--
              -- �`�F�b�N�R
              xxwsh_common910_pkg.check_shipping_judgment('1',                           -- �`�F�b�N���@
                                                          loop_cnt.head_sales_branch,    -- ���_�R�[�h
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                          loop_cnt.request_item_id,       -- D-2�˗��i��ID
                                                          loop_cnt.based_request_quantity, -- D-2���_�˗�����
--                                                          loop_cnt.shipping_inventory_item_id,-- D-2�i��ID
--                                                          loop_cnt.quantity,              -- D-2����
-- Ver1.15 M.Hokkanji END
                                                          loop_cnt.schedule_arrival_date, -- D-2����
                                                          loop_cnt.deliver_from_id,     -- D-2�o�Ɍ�ID
                                                          loop_cnt.request_no,           -- �˗�No   6/19�ǉ�
                                                          lv_retcode,                   -- ���^�[���R�[�h
                                                          lv_errbuf,            -- �G���[���b�Z�[�W�R�[�h
                                                          lv_errmsg,                    -- �G���[���b�Z�[�W
                                                          ln_retcode);                  -- ��������
              -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
              IF (( lv_retcode = '0' )
              AND ( iv_callfrom_flg = '1' ) -- �p�����[�^�E�ďo���t���O
              AND ( ln_retcode = 1 )) THEN
                lv_errmsg :=
                xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                         gv_cnst_msg_156,
                                         'API_NAME',
                                         cv_c_s_j_api,
                                         'CHK_TYPE',
                                         cv_c_s_j_chk3,
                                         'ERR_MSG',
                                         cv_c_s_j_msg2,
                                         'REQUEST_NO',
                                         loop_cnt.request_no,
                                         'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                         loop_cnt.request_item_code);
--                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                -- �x�����Z�b�g
                ln_warn_flg := 1;
                lv_retcode := gv_status_warn;
                IF (gv_callfrom_flg = '1') THEN
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
                -- Ver1.18 MARUSHITA START
                ELSE
                  lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
                -- Ver1.18 MARUSHITA END
                END IF;
--
              ELSIF (( lv_retcode = '0' )
              AND    ( iv_callfrom_flg = '2' ) -- �p�����[�^�E�ďo���t���O
              AND    ( ln_retcode = 1 )) THEN
                lv_errmsg :=
                xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                         gv_cnst_msg_157,
                                         'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                         loop_cnt.request_item_code,
--                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                         'CHK_TYPE',
                                         cv_c_s_j_chk4);
                -- �x�����Z�b�g
                ln_warn_cnt := 1;
                lv_retcode := gv_status_warn;
                IF (gv_callfrom_flg = '1') THEN
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
                -- Ver1.18 MARUSHITA START
                ELSE
                  lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
                -- Ver1.18 MARUSHITA END
                END IF;
--
              -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
              ELSIF ( lv_retcode = gn_status_error ) THEN-- 
                lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                      gv_cnst_msg_155,
                                                      'API_NAME',
                                                      cv_c_s_j_api,
                                                      'ERR_MSG',
                                                      lv_errmsg, --cv_c_s_j_msg,
                                                      'REQUEST_NO',
                                                      loop_cnt.request_no);
                RAISE global_api_expt;
              END IF;
--
            END IF;
--
          END IF;
-- Ver1.20 �{�Ԏw�E133�b��Ή�
-- Ver1.26 Y.Kazama �{�ԏ�Q#1243 �{�Ԏw�E133�̃R�����g������
--
          IF ( ln_d8retcode = 0 ) THEN
            -- D-8�Ōv�揤�i�t���O���擾�ł��Ȃ������ꍇ�́A�{�`�F�b�N�͍s���܂���B
--
            -- �`�F�b�N�S
            xxwsh_common910_pkg.check_shipping_judgment('4',                           -- �`�F�b�N���@
                                                        loop_cnt.head_sales_branch,    -- ���_�R�[�h
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                                        loop_cnt.request_item_id,       -- D-2�˗��i��ID
                                                        loop_cnt.based_request_quantity, -- D-2���_�˗�����
--                                                      loop_cnt.shipping_inventory_item_id,-- D-2�i��ID
--                                                      loop_cnt.quantity,              -- D-2����
-- Ver1.15 M.Hokkanji END
                                                        loop_cnt.schedule_ship_date,   -- D-2�o�ɓ�
                                                        loop_cnt.deliver_from_id,      -- D-2�o�Ɍ�ID
                                                        loop_cnt.request_no,           -- �˗�No   6/19�ǉ�
                                                        lv_retcode,                  -- ���^�[���R�[�h
                                                        lv_errbuf,           -- �G���[���b�Z�[�W�R�[�h
                                                        lv_errmsg,                -- �G���[���b�Z�[�W
                                                        ln_retcode);              -- ��������
--
            -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
            IF (( lv_retcode = '0' )
            AND ( ln_retcode = 1) 
            AND (  iv_callfrom_flg = '1' )) THEN-- �p�����[�^�E�ďo���t���O
              lv_errmsg :=
              xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                       gv_cnst_msg_156,
                                       'API_NAME',
                                       cv_c_s_j_api,
                                       'CHK_TYPE',
                                       cv_c_s_j_chk5,
                                       'ERR_MSG',
                                       cv_c_s_j_msg2,
                                       'REQUEST_NO',
                                       loop_cnt.request_no,
                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                       loop_cnt.request_item_code);
--                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
              -- �x�����Z�b�g
              ln_warn_flg := 1;
              IF (gv_callfrom_flg = '1') THEN
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
              -- Ver1.18 MARUSHITA START
              ELSE
                lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
              -- Ver1.18 MARUSHITA END
              END IF;
--
            ELSIF (( lv_retcode = '0' )
            AND    ( ln_retcode = 1) 
            AND    ( iv_callfrom_flg = '2' )) THEN-- �p�����[�^�E�ďo���t���O
              lv_errmsg :=
              xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                       gv_cnst_msg_157,
                                       'CHK_TYPE',
                                       cv_c_s_j_chk5,
                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400�w�E78�Ή�
                                       loop_cnt.request_item_code);
--                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
              -- �x�����Z�b�g
              ln_warn_flg := 1;
              IF (gv_callfrom_flg = '1') THEN
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
              -- Ver1.18 MARUSHITA START
              ELSE
                lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
              -- Ver1.18 MARUSHITA END
              END IF;
--
            -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
            ELSIF ( lv_retcode = gn_status_error ) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_c_s_j_api,
                                                    'ERR_MSG',
                                                    lv_errmsg, --cv_c_s_j_msg,
                                                    'REQUEST_NO',
                                                    loop_cnt.request_no);
              RAISE global_api_expt;
--
            END IF;
--
          END IF;
--Ver1.30 M.Hokkanji End �{�ԏ�Q133�b��Ή�
-- Ver1.15 M.Hokkanji START
        END IF;
-- Ver1.15 M.Hokkanji END
--
--
        -- **************************************************
        -- *** �ύڌ����`�F�b�N(�ύڌ����Z�o)(D-10)
        -- **************************************************
--
        IF ((lv_bfr_request_no <> loop_cnt.request_no)
        AND ( lv_bfr_freight_charge_class = gv_freight_charge_class_on ) -- �^���敪��ON�̏ꍇ�Ƀ`�F�b�N����(2008/07/09 ST�s��Ή�#430)
        AND ( ln_data_cnt > 1 )) THEN
--
-- Ver 1.17 M.Hokkanji START
        -- �^���Ǝ҂�NULL�̏ꍇ
        IF (lv_bfr_freight_carrier_code IS NULL ) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_176,
                                                gv_cnst_tkn_request_no,
                                                lv_bfr_request_no);
          RAISE global_api_expt;
        END IF;
-- Ver 1.17 M.Hokkanji END
-- Ver1.15 M.Hokkanji START
          -- �d�ʗe�ϋ敪�̒l�ɂ�肢���ꂩ�̂݃`�F�b�N���s���悤�ɏC���i��������̂̓w�b�_�ɒl�Z�b�g���̂݁j
          IF (lt_weight_capacity_class = cv_weight_capacity_class_1) THEN
-- Ver1.15 M.Hokkanji END
            -- �O�˗�No <> D-2�˗�No �̏ꍇ
            xxwsh_common910_pkg.calc_load_efficiency(ln_bfr_sum_weight,        -- �O�ύڏd�ʍ��v
                                                     NULL,                     -- �O�ύڗe�ύ��v
                                                     cv_whse_code,
                                                              -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
                                                     lv_bfr_deliver_from,      -- �O�o�׌��ۊǏꏊ
                                                     cv_deliver_to,
                                                              -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�z����v
                                                     lv_bfr_deliver_to,        -- �O�z����R�[�h
                                                     lv_bfr_shipping_method_code,
                                                                               -- �O�z���敪
                                                     lv_bfr_prod_class,        -- �O���i�敪
                                                     '0',                      -- �ΏۊO 
                                                     id_bfr_schedule_ship_date,-- �O�o�ɓ�
                                                     lv_retcode,               -- ���^�[���R�[�h
                                                     lv_errbuf,              -- �G���[���b�Z�[�W�R�[�h
                                                     lv_errmsg,                -- �G���[���b�Z�[�W
                                                     lv_loading_over_class,    -- �ύڃI�[�o�[�敪
                                                     lv_ship_methods,          -- �o�ו��@
                                                     ln_load_efficiency_weight,
                                                                               -- �d�ʐύڌ���
                                                     ln_load_efficiency_capacity,
                                                                               -- �e�ϐύڌ���
                                                     lv_mixed_ship_method);    -- ���ڔz���敪
  --
            -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
            IF ( lv_retcode = gn_status_error ) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_calc_load_efficiency_api,
                                                    'ERR_MSG',
                                                    lv_errmsg,
                                                    'REQUEST_NO',
                                                    lv_bfr_request_no,'POS',27);
              RAISE global_api_expt;
  --
            ELSIF ( lv_loading_over_class = 1 ) THEN-- �ύڃI�[�o�[�̏ꍇ
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_158,
                                                    'API_NAME',
                                                    cv_calc_load_efficiency_api,                                                                    
                                                    'ERR_MSG',
                                                    lv_errmsg,
                                                    'REQUEST_NO',
                                                    lv_bfr_request_no,'POS',28);
              RAISE global_api_expt;
  --
            END IF;
-- Ver1.15 M.Hokkanji START
          ELSE
-- Ver1.15 M.Hokkanji EMD
--
            -- �O�˗�No <> D-2�˗�No �̏ꍇ(�e�σ`�F�b�N)
            xxwsh_common910_pkg.calc_load_efficiency(NULL,                     -- �O�ύڏd�ʍ��v
                                                     ln_bfr_sum_capacity,      -- �O�ύڗe�ύ��v
                                                     cv_whse_code,
                                                              -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
                                                     lv_bfr_deliver_from,      -- �O�o�׌��ۊǏꏊ
                                                     cv_deliver_to,
                                                              -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�z����v
                                                     lv_bfr_deliver_to,        -- �O�z����R�[�h
                                                     lv_bfr_shipping_method_code,
                                                                               -- �O�z���敪
                                                     lv_bfr_prod_class,        -- �O���i�敪
                                                     '0',                      -- �ΏۊO 
                                                     id_bfr_schedule_ship_date,-- �O�o�ɓ�
                                                     lv_retcode,               -- ���^�[���R�[�h
                                                     lv_errbuf,              -- �G���[���b�Z�[�W�R�[�h
                                                     lv_errmsg,                -- �G���[���b�Z�[�W
                                                     lv_loading_over_class,    -- �ύڃI�[�o�[�敪
                                                     lv_ship_methods,          -- �o�ו��@
                                                     ln_load_efficiency_weight,
                                                                               -- �d�ʐύڌ���
                                                     ln_load_efficiency_capacity,
                                                                               -- �e�ϐύڌ���
                                                     lv_mixed_ship_method);    -- ���ڔz���敪
  --
            -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
            IF ( lv_retcode = gn_status_error ) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_calc_load_efficiency_api,
                                                    'ERR_MSG',
                                                    lv_errmsg,
                                                    'REQUEST_NO',
                                                    lv_bfr_request_no);
              RAISE global_api_expt;
  --
            ELSIF ( lv_loading_over_class = 1 ) THEN-- �ύڃI�[�o�[�̏ꍇ
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_158,
                                                    'API_NAME',
                                                    cv_calc_load_efficiency_api,                                                                    
                                                    'ERR_MSG',
                                                    lv_errmsg,
                                                    'REQUEST_NO',
                                                    lv_bfr_request_no);
              RAISE global_api_expt;
  --
            END IF;
-- Ver1.15 M.Hokkanji START
          END IF;
-- Ver1.15 M.Hokkanji EMD
--
        END IF;
--
      END IF;
--
      -- �O�f�[�^���Z�b�g
      lv_bfr_request_no            := loop_cnt.request_no;           -- �O�˗�No
-- Ver1.15 M.Hokkanji START
      -- �����̏ꍇ
      IF ( loop_cnt.small_amount_class = cv_small_amount_class_1) THEN
        ln_bfr_sum_weight          := NVL(loop_cnt.sum_weight,0);  -- �O�ύڏd�ʍ��v
      ELSE
        ln_bfr_sum_weight          := NVL(loop_cnt.sum_weight,0) +
                                      NVL(loop_cnt.sum_pallet_weight,0); -- �O�ύڏd�ʍ��v
      END IF;
      ln_bfr_sum_capacity          := NVL(loop_cnt.sum_capacity,0);  -- �O�ύڗe�ύ��v
      lt_weight_capacity_class     := loop_cnt.weight_capacity_class; -- �d�ʗe�ϋ敪
-- Ver1.15 M.Hokkanji END
      lv_bfr_deliver_from          := loop_cnt.deliver_from;         -- �O�o�׌��ۊǏꏊ
      lv_bfr_deliver_to            := loop_cnt.deliver_to;           -- �O�z����R�[�h
      lv_bfr_shipping_method_code  := loop_cnt.shipping_method_code; -- �O�z���敪
      lv_bfr_prod_class            := loop_cnt.prod_class;           -- �O���i�敪
      id_bfr_schedule_ship_date    := loop_cnt.schedule_ship_date;   -- �O�o�ɓ�
      lv_bfr_freight_charge_class  := loop_cnt.freight_charge_class; -- �O�^���敪 2008/07/09 ST�s��Ή�#430
-- Ver1.17 M.Hokkanji Start
      lv_bfr_freight_carrier_code  := loop_cnt.freight_carrier_code; -- �^���Ǝ�
-- Ver1.17 M.Hokkanji End
--
--
      -- **************************************************
      -- *** PL/SQL�\�ւ̑}��(D-11)
      -- **************************************************
--
      gt_header_id_upd_tab(ln_data_cnt) := loop_cnt.order_header_id; -- �󒍃w�b�_�A�h�I��ID
--
      ln_normal_cnt := ln_target_cnt;
      ln_warn_cnt   := ln_warn_cnt + ln_warn_flg;
      ln_warn_flg   := 0;
--
-- 2008/09/01 N.Yoshida ADD START
    --END LOOP upd_data_loop;
    END LOOP data_loop;
    CLOSE upd_status_cur;
-- 2008/09/01 N.Yoshida ADD END

-- Ver 1.17 M.Hokkanji START
    IF (( ln_data_cnt <> 0)
    AND ( lv_bfr_freight_charge_class = gv_freight_charge_class_on )
    AND ( lv_bfr_freight_carrier_code IS NULL)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_176,
                                            gv_cnst_tkn_request_no,
                                            lv_bfr_request_no);
      RAISE global_api_expt;
    END IF;
-- Ver 1.17 M.Hokkanji END
--
    IF ( ln_data_cnt = 0 ) THEN
      -- �o�׈˗����Ώۃf�[�^�Ȃ�
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_002);
      -- �x�����Z�b�g
      lv_warn_message := lv_errmsg;
      ln_warn_cnt := 1 ;
      RAISE global_process_warn;
--
    -- �o�׈˗����Ώۃf�[�^����
    -- �`�F�b�N�����̏ꍇ�̓`�F�b�N���������{���Ȃ�
    ELSIF (( ln_data_cnt > 0 ) AND ( iv_status_kbn = '2' )) THEN
      NULL;
    ELSE
--
      -- �Ō�ɐύڌ����`�F�b�N���s��
      -- **************************************************
      -- *** �ύڌ����`�F�b�N(�ύڌ����Z�o)(D-10)
      -- **************************************************
--
      -- �^���敪��ON�̏ꍇ�Ƀ`�F�b�N����   2008/07/09 ST�s��Ή�#430
      IF ( lv_bfr_freight_charge_class = gv_freight_charge_class_on ) THEN
--
-- Ver1.15 M.Hokkanji START
        -- �d�ʗe�ϋ敪�̒l�ɂ�肢���ꂩ�̂݃`�F�b�N���s���悤�ɏC���i��������̂̓w�b�_�ɒl�Z�b�g���̂݁j
        IF (lt_weight_capacity_class = cv_weight_capacity_class_1) THEN
-- Ver1.15 M.Hokkanji END
          -- �O�˗�No <> D-2�˗�No �̏ꍇ�i�d�ʃ`�F�b�N�j
          xxwsh_common910_pkg.calc_load_efficiency(ln_bfr_sum_weight,        -- �O�ύڏd�ʍ��v
                                                   NULL,                     -- �O�ύڗe�ύ��v
                                                   cv_whse_code,
                                                            -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
                                                   lv_bfr_deliver_from,      -- �O�o�׌��ۊǏꏊ
                                                   cv_deliver_to,
                                                            -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�z����v
                                                   lv_bfr_deliver_to,        -- �O�z����R�[�h
                                                   lv_bfr_shipping_method_code,
                                                                                 -- �O�z���敪
                                                   lv_bfr_prod_class,            -- �O���i�敪
                                                   '0',                          -- �ΏۊO 
                                                   id_bfr_schedule_ship_date,    -- �O�o�ɓ�
                                                   lv_retcode,                   -- ���^�[���R�[�h
                                                   lv_errbuf,                    -- �G���[���b�Z�[�W�R�[�h
                                                   lv_errmsg,                    -- �G���[���b�Z�[�W
                                                   lv_loading_over_class,        -- �ύڃI�[�o�[�敪
                                                   lv_ship_methods,              -- �o�ו��@
                                                   ln_load_efficiency_weight,    -- �d�ʐύڌ���
                                                   ln_load_efficiency_capacity,  -- �e�ϐύڌ���
                                                   lv_mixed_ship_method);        -- ���ڔz���敪
  --
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF ( lv_retcode = gn_status_error ) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_calc_load_efficiency_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lv_bfr_request_no,'POS',29);
            RAISE global_api_expt;
  --
          ELSIF ( lv_loading_over_class = 1 ) THEN-- �ύڃI�[�o�[�̏ꍇ
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_158,
                                                  'API_NAME',
                                                  cv_calc_load_efficiency_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lv_bfr_request_no,'POS',30);
            RAISE global_api_expt;
  --
          END IF;
-- Ver1.15 M.Hokkanji START
        ELSE
-- Ver1.15 M.Hokkanji END
  --
          -- �O�˗�No <> D-2�˗�No �̏ꍇ(�e�σ`�F�b�N)
          xxwsh_common910_pkg.calc_load_efficiency(NULL,                     -- �O�ύڏd�ʍ��v
                                                   ln_bfr_sum_capacity,      -- �O�ύڗe�ύ��v
                                                   cv_whse_code,
                                                            -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
                                                   lv_bfr_deliver_from,      -- �O�o�׌��ۊǏꏊ
                                                   cv_deliver_to,
                                                            -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�z����v
                                                   lv_bfr_deliver_to,        -- �O�z����R�[�h
                                                   lv_bfr_shipping_method_code,
                                                                                 -- �O�z���敪
                                                   lv_bfr_prod_class,            -- �O���i�敪
                                                   '0',                          -- �ΏۊO 
                                                   id_bfr_schedule_ship_date,    -- �O�o�ɓ�
                                                   lv_retcode,                   -- ���^�[���R�[�h
                                                   lv_errbuf,                    -- �G���[���b�Z�[�W�R�[�h
                                                   lv_errmsg,                    -- �G���[���b�Z�[�W
                                                   lv_loading_over_class,        -- �ύڃI�[�o�[�敪
                                                   lv_ship_methods,              -- �o�ו��@
                                                   ln_load_efficiency_weight,    -- �d�ʐύڌ���
                                                   ln_load_efficiency_capacity,  -- �e�ϐύڌ���
                                                   lv_mixed_ship_method);        -- ���ڔz���敪
  --
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF ( lv_retcode = gn_status_error ) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_calc_load_efficiency_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lv_bfr_request_no);
            RAISE global_api_expt;
  --
          ELSIF ( lv_loading_over_class = 1 ) THEN-- �ύڃI�[�o�[�̏ꍇ
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_158,
                                                  'API_NAME',
                                                  cv_calc_load_efficiency_api,                                                                    
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lv_bfr_request_no);
            RAISE global_api_expt;
  --
          END IF;
-- Ver1.15 M.Hokkanji START
        END IF;
-- Ver1.15 M.Hokkanji END
--
      END IF;  -- 2008/07/09 ST�s��Ή�#430
--
    END IF;
--
    -- **************************************************
    -- *** �X�e�[�^�X�ꊇ�X�V(D-12)
    -- **************************************************
--
    upd_table_batch(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �X�e�[�^�X�ꊇ�X�V�������G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** OUT�p�����[�^�Z�b�g(D-13)
    -- **************************************************
--
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      IF (gv_callfrom_flg = '1') THEN
        lv_errmsg := NULL;
      ELSE
        lv_errmsg := lv_warn_message;
      END IF;
      RAISE global_process_warn;
    ELSE
      ov_retcode := lv_retcode;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    out_log(ln_target_cnt,ln_normal_cnt,0,ln_warn_cnt);
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
--
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_001);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      out_log(0,0,1,0);
--
    WHEN global_process_warn THEN                           --*** ���[�j���O ***
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
      out_log(ln_target_cnt,ln_normal_cnt,0,ln_warn_cnt);
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ship_set;
  --
END xxwsh400003c;
/
