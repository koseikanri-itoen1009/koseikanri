CREATE OR REPLACE PACKAGE BODY XXINV550002C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550002C(body)
 * Description      : �󕥑䒠�쐬
 * MD.050/070       : �݌�(���[)Draft2A (T_MD050_BPO_550)
 *                    �󕥑䒠Draft1A   (T_MD070_BPO_55B)
 * Version          : 1.25
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  convert_into_xml       XML�f�[�^�ϊ�
 *  check_parameter        �p�����[�^�`�F�b�N
 *  insert_xml_plsql_table XML�f�[�^�i�[
 *  create_xml             XML�f�[�^�쐬
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0   Kazuo Kumamoto   �V�K�쐬
 *  2008/05/07    1.1   Kazuo Kumamoto   �����ύX�v��#33�Ή�
 *  2008/05/15    1.2   Kazuo Kumamoto   �����ύX�v��#93�Ή�
 *  2008/05/15    1.3   Kazuo Kumamoto   SQL�`���[�j���O
 *  2008/06/04    1.4   Takao Ohashi     �����e�X�g�s��C��
 *  2008/06/05    1.5   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�א����Βl�ɕύX)
 *  2008/06/05    1.6   Kazuo Kumamoto   SQL�`���[�j���O
 *  2008/06/05    1.7   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�ׂ̑����擾���@��ύX)
 *  2008/06/05    1.8   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�ׂ̎󕥋敪�A�h�I���}�X�^���o�����ύX)
 *  2008/06/09    1.9   Kazuo Kumamoto   �����e�X�g��Q�Ή�(���Y�̓��t�����ύX)
 *  2008/06/09    1.10  Kazuo Kumamoto   �����e�X�g��Q�Ή�(�o�ׂ̎󕥋敪�A�h�I���}�X�^���o�����ǉ�)
 *  2008/06/23    1.11  Kazuo Kumamoto   �����e�X�g��Q�Ή�(�P�ʂ̏o�͓��e�ύX)
 *  2008/07/01    1.12  Kazuo Kumamoto   �����e�X�g��Q�Ή�(�p�����[�^.�i�ځE���i�敪�E�i�ڋ敪�g�ݍ��킹�`�F�b�N)
 *  2008/07/01    1.13  Kazuo Kumamoto   �����e�X�g��Q�Ή�(�p�����[�^.�����u���b�N�E�q��/�ۊǑq�ɂ�OR�����Ƃ���)
 *  2008/07/02    1.14  Satoshi Yunba    �֑������Ή�
 *  2008/07/07    1.15 Yasuhisa Yamamoto �����e�X�g��Q�Ή�(�������т̎擾���ʂ𔭒����ׂ���擾����悤�ɕύX)
 *  2008/09/16    1.16  Hitomi Itou      T_TE080_BPO_550 �w�E31(�ϑ�����̏ꍇ������q�ɓ��ړ��̏ꍇ�A���o���Ȃ��B)
 *                                       T_TE080_BPO_550 �w�E28(�݌ɒ������я��̎���ԕi���擾(�����݌�)��ǉ�)
 *                                       T_TE080_BPO_540 �w�E44(����)
 *                                       �ύX�v��#171(����)
 *  2008/09/22    1.17  Hitomi Itou      T_TE080_BPO_550 �w�E28(�݌ɒ������я��̊O���o�������E����ԕi���擾(�����݌�)�̑����������ɕύX)
 *  2008/10/20    1.18  Takao Ohashi     T_S_492(�o�͂���Ȃ������敪�Ǝ��R�R�[�g�̑g�ݍ��킹���o�͂�����)
 *  2008/10/23    1.19  Takao Ohashi     �w�E442(�i�ڐU�֏��̎擾�����C��)
 *  2008/11/07    1.20  Hitomi Itou      �����e�X�g�w�E548�Ή�
 *  2008/11/17    1.21  Takao Ohashi     �w�E356�Ή�
 *  2008/11/20    1.22  Naoki Fukuda     �����e�X�g��Q696�Ή�
 *  2008/11/21    1.23  Natsuki Yoshida  �����e�X�g��Q687�Ή� (�啝�ȏC���ׁ̈A�������c���Ă���܂���)
 *  2008/11/28    1.24  Hitomi Itou      �{�ԏ�Q#227�Ή�
 *  2008/12/02    1.25  Natsuki Yoshida  �{�ԏ�Q#327�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -------------------------------------------------------
  --�v���O������
  -------------------------------------------------------
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXINV550002C'; -- �p�b�P�[�W��
  gv_report_id         CONSTANT VARCHAR2(12)  := 'XXINV550002T' ; -- �v���O���������[�o�͗p
--
  -------------------------------------------------------
  --�G���[���b�Z�[�W�֘A
  -------------------------------------------------------
  gc_application_inv   CONSTANT VARCHAR2(5)  := 'XXINV'; -- �A�v���P�[�V�����iXXINV�j
  gc_application_cmn   CONSTANT VARCHAR2(5)  := 'XXCMN'; -- �A�v���P�[�V�����iXXCMN�j
  gv_xxinv_10096       CONSTANT VARCHAR2(15) := 'APP-XXINV-10096'; --���t�召��r�G���[
  gv_xxinv_10111       CONSTANT VARCHAR2(15) := 'APP-XXINV-10111'; --�i�ڃ`�F�b�N�G���[
  gv_xxinv_10112       CONSTANT VARCHAR2(15) := 'APP-XXINV-10112'; --�q�Ƀ`�F�b�N�G���[
  gv_xxinv_10153       CONSTANT VARCHAR2(15) := 'APP-XXINV-10153'; --�ۊǑq�Ƀ`�F�b�N�G���[
  gv_xxinv_10113       CONSTANT VARCHAR2(15) := 'APP-XXINV-10113'; --�u���b�N�`�F�b�N�G���[
  gc_xxcmn_10122       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122'; -- ����0���p���b�Z�[�W
--
  -------------------------------------------------------
  --�ʏ�萔
  -------------------------------------------------------
  --�̈於
  gv_trtry_po          CONSTANT VARCHAR2(4) := '����'; --�������я��
  gv_trtry_mv          CONSTANT VARCHAR2(4) := '�ړ�'; --�ړ����я��
  gv_trtry_sh          CONSTANT VARCHAR2(4) := '�o��'; --�o��/�L���o�׎��я��
  gv_trtry_rt          CONSTANT VARCHAR2(8) := '�q�֕ԕi'; --�q�֕ԕi���я��
  gv_trtry_mf          CONSTANT VARCHAR2(4) := '���Y'; --���Y���я��
  gv_trtry_ad          CONSTANT VARCHAR2(8) := '�݌ɒ���'; --�݌ɒ������я��
--
  --�q�ɕۊǑq�ɑI���敪
  gv_wh_loc_ctl_wh     CONSTANT VARCHAR2(1) := '1';--�q�ɕۊǑq�ɑI���敪(�q��)
  gv_wh_loc_ctl_loc    CONSTANT VARCHAR2(1) := '2';--�q�ɕۊǑq�ɑI���敪(�ۊǑq��)
--
  --����
  gv_lang              CONSTANT VARCHAR2(2) := 'JA'; --language
  gv_source_lang       CONSTANT VARCHAR2(2) := 'JA'; --source_lang
--
  --XML�o�̓��[�h
  gv_output_normal     CONSTANT VARCHAR2(1) := '0'; --XML�o��(�ʏ�)
  gv_output_notfound   CONSTANT VARCHAR2(1) := '1'; --XML�o��(�O��)
--
  --����
  gv_fmt_ymd           CONSTANT VARCHAR2(10) := 'YYYY/MM/DD'; --�N�����̏���
  gv_fmt_ymd_out       CONSTANT VARCHAR2(20) := 'YYYY"�N"MM"��"DD"��"'; --���[�o�͎��̔N��������(�N����FROM,TO)
  gv_fmt_ymd_out2      CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS'; --���[�o�͎��̔N��������(�o�͓��t)
--
  --�����w�b�_�X�e�[�^�X
  gv_po_sts_rcv        CONSTANT VARCHAR2(2) := '25'; --�������
  gv_po_sts_qty_deci   CONSTANT VARCHAR2(2) := '30'; --���ʊm��ς�
  gv_po_sts_price_deci CONSTANT VARCHAR2(2) := '35'; --���z�m��ς�
--
  --�������א��ʊm��t���O
  gv_po_flg_qty        CONSTANT VARCHAR2(2) := 'Y'; --���ʊm��ς�
--
  --���ы敪
  gv_txns_type_rcv     CONSTANT VARCHAR2(1) := '1'; --���
--
  --�v���t�@�C��
  gv_prf_mst_org       CONSTANT VARCHAR2(19) := 'XXCMN_MASTER_ORG_ID'; --�g�DID
  gv_prf_prod_div      CONSTANT VARCHAR2(14) := 'XXCMN_ITEM_DIV'; --���i�敪
  gv_prf_item_div      CONSTANT VARCHAR2(17) := 'XXCMN_ARTICLE_DIV'; --�i�ڋ敪
--
  --OPM�ۗ��݌Ƀg�����U�N�V���������t���O
  gv_tran_cmp          CONSTANT VARCHAR2(1) := '1'; --����
--
  --OPM�ۗ��݌Ƀg�����U�N�V�����폜�}�[�N
  gn_delete_mark_no    CONSTANT NUMBER := 0; --���폜
--
  --�N�C�b�N�R�[�h�Q�ƃ^�C�v
  gv_lookup_newdiv     CONSTANT VARCHAR2(18) := 'XXCMN_NEW_DIVISION'; --�V�敪
  gv_lookup_basedate   CONSTANT VARCHAR2(15) := 'XXINV_BASE_DATE'; --���
--
  --����/�����
  gv_base_date_arrival CONSTANT VARCHAR2(1) := '1'; --����
  gv_base_date_ship    CONSTANT VARCHAR2(1) := '2'; --����
--
  --���R�[�h�^�C�v
  gv_rectype_in        CONSTANT VARCHAR2(2) := '30'; --���Ɏ���
  gv_rectype_out       CONSTANT VARCHAR2(2) := '20'; --�o�Ɏ���
--
  --���b�g�Ǘ��敪
  gn_lotctl_yes        CONSTANT NUMBER := 1; --���b�g�Ǘ��i
  gn_lotctl_no         CONSTANT NUMBER := 0; --�񃍃b�g�Ǘ��i
--
  --�ړ��^�C�v
  gv_movetype_yes      CONSTANT VARCHAR2(1) := '1'; --�ϑ�����
  gv_movetype_no       CONSTANT VARCHAR2(1) := '2'; --�ϑ��Ȃ�
--
  --���ьv��ς݃t���O
  gv_cmp_actl_yes      CONSTANT VARCHAR2(1) := 'Y'; --���ьv��ς�
--
  --����t���O
  gv_delete_no         CONSTANT VARCHAR2(1) := 'N'; --�����
--
  --�����^�C�v
--add start 1.22
  gv_dctype_shipped    CONSTANT VARCHAR2(2) := '10'; --�o��
--add end 1.22
  gv_dctype_move       CONSTANT VARCHAR2(2) := '20'; --�ړ�
--
  --�󕥋敪
  gv_rcvdiv_rcv        CONSTANT VARCHAR2(1) := '1'; --���
  gv_rcvdiv_pay        CONSTANT VARCHAR2(2) := '-1'; --���o
--
  --�o�׈˗�/�x���˗��X�e�[�^�X
  gv_recsts_shipped    CONSTANT VARCHAR2(2) := '04'; --�o�׎��ьv��ς�(�o�׈˗��X�e�[�^�X)
  gv_recsts_shipped2   CONSTANT VARCHAR2(2) := '08'; --�o�׎��ьv��ς�(�x���˗��X�e�[�^�X)
--
  --���ьv��ς݋敪
  gv_confirm_yes       CONSTANT VARCHAR2(1) := 'Y'; --EBS�v��ς�
--
  --�ŐV�t���O
  gv_latest_yes        CONSTANT VARCHAR2(1) := 'Y'; --�ŐV
--
  --�݌Ɏg�p�敪
  gv_inventory         CONSTANT VARCHAR2(1) := 'Y'; --�݌�
--
  --�ڋq�敪
  gv_custclass         CONSTANT VARCHAR2(1) := '1'; --���_
--
  --�o�׎x���敪
  gv_shipclass         CONSTANT VARCHAR2(1) := '3'; --�q�֕ԕi
--
  --���C���^�C�v
  gn_linetype_mtrl     CONSTANT NUMBER := -1; --����
  gn_linetype_prod     CONSTANT NUMBER := 1; --���i
--
  gv_dummy             CONSTANT VARCHAR2(5) := 'DUMMY';
--
--mod start 1.9
--  gv_item_transfer     CONSTANT VARCHAR2(8) := '�i�ڐU��';
  gv_item_transfer     CONSTANT VARCHAR2(100) := FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING');           --�i�ڐU��
  gv_item_return       CONSTANT VARCHAR2(100) := FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET');       --�ԕi����
  gv_item_dissolve     CONSTANT VARCHAR2(100) := FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE');  --��̔����i
--mod end 1.9
  cn_prod_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
  cn_item_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
--
  --���R�R�[�h
  gv_reason_other      CONSTANT VARCHAR2(4) := 'X977'; --�����݌�
--
  --���o�ɋ敪
  gv_inout_ctl_all     CONSTANT VARCHAR2(1) := '0'; --���o��
  gv_inout_ctl_in      CONSTANT VARCHAR2(1) := '1'; --����
  gv_inout_ctl_out     CONSTANT VARCHAR2(1) := '2'; --�o��
--
  --�P�ʋ敪
  gv_unitctl_qty       CONSTANT VARCHAR2(1) := '0'; --�{��
  gv_unitctl_case      CONSTANT VARCHAR2(1) := '1'; --�P�[�X
--
  --�����t���O
  gv_inactive          CONSTANT VARCHAR2(1) := '1'; --����
--
  --�J�e�S���}�X�^�g�p�\�t���O
  gv_enabled_flag      CONSTANT VARCHAR2(1) := 'Y'; --�L��
--
  --�i�ڋ敪
  gv_item_class_prod   CONSTANT VARCHAR2(1) := '5'; --���i
--
  --�݌ɒ����敪
  gv_stock_adjm        CONSTANT VARCHAR2(1) := '2'; --�݌ɒ���
--
  --�݌Ƀ^�C�v
  gv_adji_xrart        CONSTANT VARCHAR2(1) := '1'; --����ԕi����
  gv_adji_xnpt         CONSTANT VARCHAR2(1) := '2'; --���t����
  gv_adji_xvst         CONSTANT VARCHAR2(1) := '3'; --�O���o��������
  gv_adji_xmrih        CONSTANT VARCHAR2(1) := '4'; --�ړ�����
  gv_adji_ijm          CONSTANT VARCHAR2(1) := '5'; --EBS�W���݌Ɏ���
--
  --�o�׎x���敪
  gv_spdiv_ship        CONSTANT VARCHAR2(1) := '1'; --�o�׈˗�
  gv_spdiv_prov        CONSTANT VARCHAR2(1) := '2'; --�x���˗�
--add start 1.2
  --�V�敪
  gv_newdiv_pay        CONSTANT VARCHAR2(3) := '402'; --�q�Ɉړ�_�o��
  gv_newdiv_rcv        CONSTANT VARCHAR2(3) := '401'; --�q�Ɉړ�_����
--add end 1.2
--add start 1.3
  gv_nullvalue         CONSTANT VARCHAR2(2) := CHR(09);
--add end 1.3
--add start 1.16
  --�����敪
  po_type_inv          CONSTANT VARCHAR2(1) := '3'; --�����݌�
--add end 1.16
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�J�e�S���Z�b�g��
  gv_category_prod              VARCHAR2(100); --�J�e�S���Z�b�g��
  gv_category_item              VARCHAR2(100); --�J�e�S���Z�b�g��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���̓p�����[�^�i�[�p���R�[�h�^�C�v
  TYPE rec_param_data  IS RECORD (
    ymd_from           VARCHAR2(4000)
   ,ymd_to             VARCHAR2(4000)
   ,base_date          VARCHAR2(4000)
   ,inout_ctl          VARCHAR2(4000)
   ,prod_div           VARCHAR2(4000)
   ,unit_ctl           VARCHAR2(4000)
   ,wh_loc_ctl         VARCHAR2(4000)
   ,wh_code_01         VARCHAR2(4000)
   ,wh_code_02         VARCHAR2(4000)
   ,wh_code_03         VARCHAR2(4000)
   ,block_01           VARCHAR2(4000)
   ,block_02           VARCHAR2(4000)
   ,block_03           VARCHAR2(4000)
   ,item_div           VARCHAR2(4000)
   ,item_code_01       VARCHAR2(4000)
   ,item_code_02       VARCHAR2(4000)
   ,item_code_03       VARCHAR2(4000)
   ,lot_no_01          VARCHAR2(4000)
   ,lot_no_02          VARCHAR2(4000)
   ,lot_no_03          VARCHAR2(4000)
   ,mnfctr_date_01     VARCHAR2(4000)
   ,mnfctr_date_02     VARCHAR2(4000)
   ,mnfctr_date_03     VARCHAR2(4000)
   ,reason_code_01     VARCHAR2(4000)
   ,reason_code_02     VARCHAR2(4000)
   ,reason_code_03     VARCHAR2(4000)
   ,symbol             VARCHAR2(4000)
  );
--
  --���o�f�[�^�i�[�p���R�[�h�^�C�v
  TYPE rec_main_data IS RECORD(
    wh_code        VARCHAR2(4000)                                               --�q�ɃR�[�h
   ,wh_name        VARCHAR2(4000)                                               --�q�ɖ�
   ,strg_wh_code   VARCHAR2(4000)                                               --�ۊǑq�ɃR�[�h
   ,strg_wh_name   VARCHAR2(4000)                                               --�ۊǑq�ɖ�
   ,item_code      VARCHAR2(4000)                                               --�i�ڃR�[�h
   ,item_name      VARCHAR2(4000)                                               --�i�ږ�
   ,standard_date  VARCHAR2(4000)                                               --���t
   ,reason_code    VARCHAR2(4000)                                               --���R�R�[�h
   ,reason_name    VARCHAR2(4000)                                               --���R
   ,slip_no        VARCHAR2(4000)                                               --�`�[�ԍ�
   ,out_date       VARCHAR2(4000)                                               --�o�ɓ�
   ,in_date        VARCHAR2(4000)                                               --����
   ,jrsd_code      VARCHAR2(4000)                                               --�Ǌ����_�R�[�h
   ,jrsd_name      VARCHAR2(4000)                                               --�Ǌ����_��
   ,other_code     VARCHAR2(4000)                                               --�����R�[�h
   ,other_name     VARCHAR2(4000)                                               --����於
   ,lot_no         VARCHAR2(4000)                                               --���b�gNo
   ,mnfctr_date    VARCHAR2(4000)                                               --�����N����
   ,limit_date     VARCHAR2(4000)                                               --�ܖ�����
   ,symbol         VARCHAR2(4000)                                               --�ŗL�L��
   ,unit           VARCHAR2(4000)                                               --�P��
   ,num_of_cases   VARCHAR2(4000)                                               --�P�[�X���萔
   ,in_qty         NUMBER                                                       --���ɐ�
   ,out_qty        NUMBER                                                       --�o�ɐ�
   ,item_div_name  VARCHAR2(4000)                                               --�i�ڋ敪����
  );
--
  --���o�f�[�^�i�[�p�e�[�u��
  TYPE tab_main_data IS TABLE OF rec_main_data INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : put_line
   * Description      : FND_FILE.PUT_LINE���s
   ***********************************************************************************/
  PROCEDURE put_line(
    in_which IN NUMBER
   ,iv_msg   IN VARCHAR2
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_line'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
    FND_FILE.PUT_LINE(in_which,iv_msg);
--    DBMS_OUTPUT.PUT_LINE(iv_msg);
--
  END put_line;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION convert_into_xml(
    iv_name  IN VARCHAR2,
    iv_value IN VARCHAR2,
    ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_into_xml'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_convert_data VARCHAR2(2000);
--
  BEGIN
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : output_xml
   * Description      : XML�f�[�^�o�͏����v���V�[�W��
   ***********************************************************************************/
  PROCEDURE output_xml(
    iox_xml_data         IN OUT    NOCOPY XML_DATA -- XML�f�[�^
   ,iv_output_mode       IN        VARCHAR2        -- �o�̓��[�h
   ,ov_errbuf            OUT       VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT       VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT       VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_xml' ;  --  �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_xml_string  VARCHAR2(32000) ;
--
  BEGIN
    -- XML�w�b�_�o��
    put_line(FND_FILE.OUTPUT,'<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    IF (iv_output_mode = gv_output_normal) THEN
      --�Ώۃf�[�^������ꍇ
      <<xml_loop>>
      FOR i IN 1 .. iox_xml_data.COUNT LOOP
        lv_xml_string := convert_into_xml(
                           iox_xml_data(i).tag_name
                          ,iox_xml_data(i).tag_value
                          ,iox_xml_data(i).tag_type) ;
        put_line(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_loop ;
--
      -- XML�f�[�^(Temp)�폜
      iox_xml_data.DELETE ;
--
    ELSE
      --�Ώۃf�[�^0���̏ꍇ
      put_line( FND_FILE.OUTPUT, '<root>');
      put_line( FND_FILE.OUTPUT, '  <data_info>');
      put_line( FND_FILE.OUTPUT, '    <lg_strg_wh>');
      put_line( FND_FILE.OUTPUT, '      <g_strg_wh>');
      put_line( FND_FILE.OUTPUT, '        <lg_item>');
      put_line( FND_FILE.OUTPUT, '          <g_item>');
      put_line( FND_FILE.OUTPUT, '            <lg_date>');
      put_line( FND_FILE.OUTPUT, '              <g_date>');
      put_line( FND_FILE.OUTPUT, '                <msg>***�@�f�[�^�͂���܂���@***</msg>');
      put_line( FND_FILE.OUTPUT, '              </g_date>');
      put_line( FND_FILE.OUTPUT, '            </lg_date>');
      put_line( FND_FILE.OUTPUT, '          </g_item>');
      put_line( FND_FILE.OUTPUT, '        </lg_item>');
      put_line( FND_FILE.OUTPUT, '      </g_strg_wh>');
      put_line( FND_FILE.OUTPUT, '    </lg_strg_wh>');
      put_line( FND_FILE.OUTPUT, '  </data_info>');
      put_line( FND_FILE.OUTPUT, '</root>');
--
      --�X�e�[�^�X���x���ɃZ�b�g
      ov_retcode := gv_status_warn;
      --0�����b�Z�[�W���Z�b�g
      ov_errmsg  := xxcmn_common_pkg.get_msg(gc_application_cmn,gc_xxcmn_10122) ;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
--
  END output_xml ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml
   * Description      : XML�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE create_xml (
    iox_xml_data IN OUT NOCOPY XML_DATA
   ,ir_prm       IN            rec_param_data    --���̓p�����[�^
   ,it_main_data IN            tab_main_data     --���o�f�[�^�Z�b�g
   ,ov_errbuf    OUT           VARCHAR2          --�G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode   OUT           VARCHAR2          --���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg    OUT           VARCHAR2          --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml'; -- �v���O������
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
    --�O�񏈗��f�[�^�i�[�p���R�[�h�^�C�v
    TYPE prev_main_data IS RECORD(
      strg_wh_code           VARCHAR2(4000)
     ,item_code              VARCHAR2(4000)
     ,standard_date          VARCHAR2(4000)
    );
--
    -- *** ���[�J���ϐ� ***
    ln_idx                   NUMBER := 0;      --XML�f�[�^INDEX
    lv_user_dept             VARCHAR2(10);     --�S��������
    lv_user_name             VARCHAR2(14);     --�S���Җ�
    lv_param_01_rmks         VARCHAR2(14);     --�N����_FROM
    lv_param_02_rmks         VARCHAR2(14);     --�N����_TO
    lv_param_03_rmks         VARCHAR2(16);     --����/���������
    lv_param_14_rmks         VARCHAR2(6);      --�i�ڋ敪����
    lr_prev                  prev_main_data;   --�O�񏈗��f�[�^
    ln_in_qty                NUMBER;           --���ɐ�
    ln_out_qty               NUMBER;           --�o�ɐ�
    ln_num_of_cases          NUMBER;           --�P�[�X���萔
--
  BEGIN
--
    -- ====================================================
    -- �w�b�_�o�͏��̐ݒ�
    -- ====================================================
    --�S���������擾
    BEGIN
      SELECT SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10)
      INTO   lv_user_dept
      FROM   DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --�S���Җ��擾
    BEGIN
      SELECT SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14)
      INTO   lv_user_name
      FROM   DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --�N����_FROM�����ݒ�
    BEGIN
      SELECT TO_CHAR(TO_DATE(ir_prm.ymd_from,gv_fmt_ymd),gv_fmt_ymd_out)
      INTO   lv_param_01_rmks
      FROM DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --�N����_TO�����ݒ�
    BEGIN
      SELECT TO_CHAR(TO_DATE(ir_prm.ymd_to,gv_fmt_ymd),gv_fmt_ymd_out)
      INTO   lv_param_02_rmks
      FROM DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --�����/��������̎擾
    BEGIN
      SELECT SUBSTRB(xlv.description, 1, 16)
      INTO   lv_param_03_rmks
      FROM xxcmn_lookup_values_v xlv
      WHERE xlv.lookup_type = gv_lookup_basedate
      AND xlv.lookup_code = ir_prm.base_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --�i�ڋ敪���̎擾
    BEGIN
      SELECT xcv.description
      INTO lv_param_14_rmks
      FROM xxcmn_categories_v xcv
      WHERE xcv.segment1 = ir_prm.item_div
      AND xcv.category_set_name = gv_category_item
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    -- ====================================================
    -- USER_INFO�쐬
    -- ====================================================
    --root�J�n�^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'root' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --user_info�J�n�^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'user_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --report_id�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'report_id' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := gv_report_id ;
--
    --exec_date�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_date' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := TO_CHAR(SYSDATE, gv_fmt_ymd_out2);
--
    --exec_user_dept�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_user_dept' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_user_dept;
--
    --exec_user_name�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_user_name' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_user_name;
--
    --user_info�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/user_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- PARAM_INFO�쐬
    -- ====================================================
    --param_info�J�n�^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --param_01�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_01' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.ymd_from;
--
    --param_01_remarks�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_01_remarks' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_param_01_rmks;
--
    --param_02�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_02' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.ymd_to;
--
    --param_02_remarks�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_02_remarks' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_param_02_rmks;
--
    --param_03�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_03' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.base_date;
--
    --param_03_remarks�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_03_remarks' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_param_03_rmks;
--
    --param_04�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_04' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.inout_ctl;
--
    --param_05�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_05' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.prod_div;
--
    --param_06�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_06' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.unit_ctl;
--
    --param_07�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_07' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.wh_loc_ctl;
--
    --param_08�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_08' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.wh_code_01;
--
    --param_09�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_09' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.wh_code_02;
--
    --param_10�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_10' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.wh_code_03;
--
    --param_11�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_11' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.block_01;
--
    --param_12�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_12' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.block_02;
--
    --param_13�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_13' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.block_03;
--
    --param_14�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_14' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.item_div;
--
    --param_14_remarks�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_14_remarks' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_param_14_rmks;
--
    --param_15�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_15' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.item_code_01;
--
    --param_16�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_16' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.item_code_02;
--
    --param_17�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_17' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.item_code_03;
--
    --param_18�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_18' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.lot_no_01;
--
    --param_19�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_19' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.lot_no_02;
--
    --param_20�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_20' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.lot_no_03;
--
    --param_21�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_21' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.mnfctr_date_01;
--
    --param_22�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_22' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.mnfctr_date_02;
--
    --param_23�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_23' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.mnfctr_date_03;
--
    --param_24�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_24' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.reason_code_01;
--
    --param_25�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_25' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.reason_code_02;
--
    --param_26�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_26' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.reason_code_03;
--
    --param_27�f�[�^�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_27' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.symbol;
--
    --param_info�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/param_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- DATA_INFO�쐬
    -- ====================================================
    --data_info�J�n�^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'data_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --lg_strg_wh�J�n�^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'lg_strg_wh' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --g_strg_wh�J�n�^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'g_strg_wh' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    FOR i IN 1..it_main_data.COUNT LOOP
--
      --����̂ݍs���^�O�Z�b�g
      IF (i = 1) THEN
        --wh_code�f�[�^�Z�b�g
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'wh_code' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := it_main_data(i).wh_code;
--
        --wh_name�f�[�^�Z�b�g
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'wh_name' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := it_main_data(i).wh_name;
--
        --strg_wh_code�f�[�^�Z�b�g
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'strg_wh_code' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := it_main_data(i).strg_wh_code;
--
        --strg_wh_name�f�[�^�Z�b�g
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'strg_wh_name' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := it_main_data(i).strg_wh_name;
--
        --lg_item�J�n�^�O�Z�b�g
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_item' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        --g_item�J�n�^�O�Z�b�g
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_item' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        --lg_date�J�n�^�O�Z�b�g
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_date' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        --g_date�J�n�^�O�Z�b�g
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_date' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      --2���ڈȍ~�ɍs���^�O�Z�b�g
      ELSE
--
        --�ۊǑq�ɃR�[�h�A�i�ڃR�[�h�A���t�̂����ꂩ���u���C�N�����ꍇ
        IF ( (lr_prev.strg_wh_code != it_main_data(i).strg_wh_code)
          OR (lr_prev.item_code != it_main_data(i).item_code)
          OR (lr_prev.standard_date != it_main_data(i).standard_date)
        ) THEN
--
          --g_date�I���^�O�Z�b�g
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := '/g_date' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          --�ۊǑq�ɃR�[�h�A�i�ڃR�[�h�̂����ꂩ���u���C�N�����ꍇ
          IF ( (lr_prev.strg_wh_code != it_main_data(i).strg_wh_code)
            OR (lr_prev.item_code != it_main_data(i).item_code)
          ) THEN
            --lg_date�I���^�O�Z�b�g
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := '/lg_date' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            --g_item�I���^�O�Z�b�g
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := '/g_item' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            --�ۊǑq�ɃR�[�h���u���C�N�����ꍇ
            IF (lr_prev.strg_wh_code != it_main_data(i).strg_wh_code) THEN
              --lg_item�I���^�O�Z�b�g
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := '/lg_item' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              --g_strg_wh�I���^�O�Z�b�g
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := '/g_strg_wh' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              --g_strg_wh�J�n�^�O�Z�b�g
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'g_strg_wh' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              --wh_code�f�[�^�Z�b�g
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'wh_code' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := it_main_data(i).wh_code;
--
              --wh_name�f�[�^�Z�b�g
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'wh_name' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := it_main_data(i).wh_name;
--
              --strg_wh_code�f�[�^�Z�b�g
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'strg_wh_code' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := it_main_data(i).strg_wh_code;
--
              --strg_wh_name�f�[�^�Z�b�g
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'strg_wh_name' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := it_main_data(i).strg_wh_name;
--
              --lg_item�J�n�^�O�Z�b�g
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'lg_item' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            END IF;
--
            --g_item�J�n�^�O�Z�b�g
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'g_item' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            --lg_date�J�n�^�O�Z�b�g
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'lg_date' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          END IF;
--
          --g_date�J�n�^�O�Z�b�g
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := 'g_date' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        END IF;
--
      END IF;
--
      --g_slip�J�n�^�O�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'g_slip' ;
      iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      --item_code�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'item_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).item_code;
--
      --item_name�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'item_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).item_name;
--
      --standard_date�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'standard_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).standard_date;
--
      --reason_code�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'reason_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).reason_code;
--
      --reason_name�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'reason_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).reason_name;
--
      --slip_no�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'slip_no' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).slip_no;
--
      --out_date�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'out_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).out_date;
--
      --in_date�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'in_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).in_date;
--
      --jrsd_code�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'jrsd_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).jrsd_code;
--
      --jrsd_name�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'jrsd_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).jrsd_name;
--
      --other_code�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'other_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).other_code;
--
      --other_name�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'other_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).other_name;
--
      --lot_no�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'lot_no' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).lot_no;
--
      --mnfctr_date�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'mnfctr_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).mnfctr_date;
--
      --limit_date�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'limit_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).limit_date;
--
      --symbol�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'symbol' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).symbol;
--
      --�{��(�P�[�X��)�Z�o
      IF (ir_prm.unit_ctl = gv_unitctl_case) THEN
        IF (NVL(it_main_data(i).num_of_cases,'0') = '0') THEN
          ln_num_of_cases := 1;
        ELSE
          ln_num_of_cases := TO_NUMBER(it_main_data(i).num_of_cases);
        END IF;
--
        ln_in_qty := ROUND(it_main_data(i).in_qty / ln_num_of_cases, 3);
        ln_out_qty := ROUND(it_main_data(i).out_qty / ln_num_of_cases, 3);
      ELSE
        ln_in_qty := it_main_data(i).in_qty;
        ln_out_qty := it_main_data(i).out_qty;
      END IF;
--
      --in_qty�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'in_qty' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := ln_in_qty;
--
      --out_qty�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'out_qty' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := ln_out_qty;
--
      --unit�f�[�^�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'unit' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).unit;
--
      --g_slip�I���^�O�Z�b�g
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := '/g_slip' ;
      iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      --�O�񏈗��f�[�^�̋L��
      lr_prev.strg_wh_code := it_main_data(i).strg_wh_code;   --�ۊǑq�ɃR�[�h
      lr_prev.item_code := it_main_data(i).item_code;         --�i�ڃR�[�h
      lr_prev.standard_date := it_main_data(i).standard_date; --���t
--
    END LOOP main_data_loop;
--
    --g_date�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_date' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --lg_date�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_date' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --g_item�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_item' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --lg_item�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_item' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --g_strg_wh�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_strg_wh' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --lg_strg_wh�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_strg_wh' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --data_info�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/data_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --root�I���^�O�Z�b�g
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/root' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
  END create_xml;
--
  /**********************************************************************************
   * Procedure Name   : get_record
   * Description      : �f�[�^���o����
   ***********************************************************************************/
  PROCEDURE get_record(
    ir_prm        IN  rec_param_data
   ,ot_main_data  OUT tab_main_data
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_record'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_main_data_cnt     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    /*CURSOR cur_main_data(
      civ_ymd_from VARCHAR2        --�N����_FROM
     ,civ_ymd_to VARCHAR2          --�N����_TO
     ,civ_base_date VARCHAR2       --������^�����
     ,civ_inout_ctl VARCHAR2       --���o�ɋ敪
     ,civ_prod_div VARCHAR2        --���i�敪
     ,civ_unit_ctl VARCHAR2        --�P�ʋ敪
     ,civ_wh_loc_ctl VARCHAR2      --�q��/�ۊǑq�ɑI���敪
     ,civ_wh_code_01 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h1
     ,civ_wh_code_02 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h2
     ,civ_wh_code_03 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h3
     ,civ_block_01 VARCHAR2        --�u���b�N1
     ,civ_block_02 VARCHAR2        --�u���b�N2
     ,civ_block_03 VARCHAR2        --�u���b�N3
     ,civ_item_div VARCHAR2        --�i�ڋ敪
     ,civ_item_code_01 VARCHAR2    --�i�ڃR�[�h1
     ,civ_item_code_02 VARCHAR2    --�i�ڃR�[�h2
     ,civ_item_code_03 VARCHAR2    --�i�ڃR�[�h3
     ,civ_lot_no_01 VARCHAR2       --���b�gNo1
     ,civ_lot_no_02 VARCHAR2       --���b�gNo2
     ,civ_lot_no_03 VARCHAR2       --���b�gNo3
     ,civ_mnfctr_date_01 VARCHAR2  --�����N����1
     ,civ_mnfctr_date_02 VARCHAR2  --�����N����2
     ,civ_mnfctr_date_03 VARCHAR2  --�����N����3
     ,civ_reason_code_01 VARCHAR2  --���R�R�[�h1
     ,civ_reason_code_02 VARCHAR2  --���R�R�[�h2
     ,civ_reason_code_03 VARCHAR2  --���R�R�[�h3
     ,civ_symbol VARCHAR2          --�ŗL�L��
    )
    IS 
      --======================================================================================================
      SELECT
        slip.whse_code                                        whse_code           --�q�ɃR�[�h
       ,slip.whse_name                                        whse_name           --�q�ɖ���
       ,slip.location                                         strg_wh_code        --�ۊǑq�ɃR�[�h
       ,slip.description                                      strg_wh_name        --�ۊǑq�ɖ���
       ,ximv.item_no                                          item_code           --�i�ڃR�[�h
       ,ximv.item_short_name                                  item_name           --�i�ږ���
       ,slip.standard_date                                    standard_date       --���t
       ,slip.reason_code                                      reason_code         --���R�R�[�h
       ,xlvv.meaning                                          reason_name         --���R�R�[�h����
       ,slip.slip_no                                          slip_no             --�`�[�ԍ�
       ,slip.out_date                                         out_date            --�o�ɓ�
       ,slip.in_date                                          in_date             --����
       ,slip.jrsd_code                                        jrsd_code           --�Ǌ����_�R�[�h
       ,slip.jrsd_name                                        jrsd_name           --�Ǌ����_����
       ,slip.other_code                                       other_code          --�����R�[�h
       ,CASE slip.territory
          WHEN gv_trtry_ad THEN
            NVL(slip.other_name,xlvv.meaning)
          ELSE slip.other_name
        END                                                   other_name          --����於
       ,DECODE(ximv.lot_ctl
              ,gn_lotctl_yes,ilm.lot_no
              ,NULL)                                          lot_no              --���b�gNo
       ,DECODE(ximv.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute1,1,10)
              ,NULL)                                          mnfctr_date         --�����N����
       ,DECODE(ximv.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute3,1,10)
              ,NULL)                                          limit_date          --�ܖ�����
       ,DECODE(ximv.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute2,1,6)
              ,NULL)                                          symbol              --�ŗL�L��
--mod start 2.1
--       ,CASE slip.territory
--          WHEN gv_trtry_po THEN ximv.item_um                                        --�����F�P��
--          WHEN gv_trtry_mv THEN ximv.item_um                                        --�ړ��F�P��
--          WHEN gv_trtry_sh THEN ximv.conv_unit                                      --�o�ׁF���o�Ɋ��Z�P��
--          WHEN gv_trtry_rt THEN ximv.conv_unit                                      --�q�֕ԕi�F���o�Ɋ��Z�P��
--          WHEN gv_trtry_mf THEN ximv.item_um                                        --���Y�F�P��
--          WHEN gv_trtry_ad THEN ximv.item_um                                        --�݌ɒ����F�P��
--          ELSE NULL
--        END                                                   unit                --�P��
       ,DECODE(civ_unit_ctl
              ,gv_unitctl_qty ,ximv.item_um
              ,gv_unitctl_case,ximv.conv_unit
              ,NULL)                                          unit                --�P��
--mod end 2.1
       ,ximv.num_of_cases                                     num_of_cases        --�P�[�X���萔
       ,NVL(slip.in_qty,0)                                    in_qty              --���ɐ�
-- mod start 1.18
--mod start 1.5
       ,NVL(slip.out_qty,0)                                   out_qty             --�o�ɐ�
--       ,ABS(NVL(slip.out_qty,0))                                   out_qty             --�o�ɐ�
--mod end 1.5
-- mod end 1.18
       ,xicv2.description                                     item_div_name       --�i�ڋ敪����
      FROM (
      --======================================================================================================
        ------------------------------
        -- 1.�������я��
        ------------------------------
        SELECT
          gv_trtry_po                                         territory           --�̈�(����)
         ,ximv.item_id                                        item_id             --�i��ID
         ,itp.lot_id                                          lot_id              --���b�gID
         ,pha.attribute4                                      standard_date       --���t
         ,xrpm.new_div_invent                                 reason_code         --�V�敪
         ,pha.segment1                                        slip_no             --�`�[No
         ,pha.attribute4                                      out_date            --�o�ɓ�
         ,pha.attribute4                                      in_date             --����
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,xvv.segment1                                        other_code          --�����R�[�h
         ,xvv.vendor_name                                     other_name          --����於��
--mod start 1.15
--         ,SUM(TO_NUMBER(NVL(pla.attribute7,'0')))             in_qty              --���ɐ�
         ,SUM(NVL(pla.quantity,0))                            in_qty              --���ɐ�
--mod end 1.15
         ,0                                                   out_qty             --�o�ɐ�
         ,itp.whse_code                                       whse_code           --�q�ɃR�[�h
         ,xilv.whse_name                                      whse_name           --�q�ɖ�
         ,itp.location                                        location            --�ۊǑq�ɃR�[�h
         ,xilv.description                                    description         --�ۊǑq�ɖ�
         ,xilv.distribution_block                             distribution_block  --�u���b�N
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --�󕥋敪
        FROM
        ----------------------------------------------------------------------------------------
          po_headers_all                                      pha                 --�����w�b�_
         ,po_lines_all                                        pla                 --��������
         ,rcv_shipment_lines                                  rsl                 --�������
         ,rcv_transactions                                    rt                  --������
         ,ic_lots_mst                                         ilm                 --OPM���b�g�}�X�^(�����p)
         ,xxpo_rcv_and_rtn_txns                               xrart               --����ԕi����
         ,xxcmn_vendors2_v                                    xvv                 --�d������VIEW2
         ,xxcmn_item_locations2_v                             xilv                --�ۊǏꏊ���VIEW2
         ,mtl_system_items_b                                  msib                --�i�ڃ}�X�^
         ,xxcmn_item_mst_v                                    ximv                --OPM�i�ڏ��VIEW1(�����p)
         ,ic_tran_pnd                                         itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
         ,xxcmn_rcv_pay_mst                                   xrpm                --����敪�A�h�I���}�X�^
        ----------------------------------------------------------------------------------------
        --�����w�b�_���o����
        WHERE pha.attribute1 IN (gv_po_sts_rcv, gv_po_sts_qty_deci, gv_po_sts_price_deci)--�X�e�[�^�X
        AND pha.attribute4 BETWEEN civ_ymd_from AND civ_ymd_to                    --�[����
        --�������ג��o����
        AND pha.po_header_id = pla.po_header_id                                   --�����w�b�_ID
        AND pla.attribute13 = gv_po_flg_qty                                       --���ʊm��t���O
        --������ג��o����
        AND rsl.po_header_id = pha.po_header_id                                   --�����w�b�_ID
        AND rsl.po_line_id = pla.po_line_id                                       --��������ID
        --���������o����
        AND rsl.shipment_line_id = rt.shipment_line_id                            --�������ID
        --�i�ڃ}�X�^���o����
        AND msib.organization_id = FND_PROFILE.VALUE(gv_prf_mst_org)              --�g�DID
        AND pla.item_id = msib.inventory_item_id                                  --�i��ID
        --OPM�i�ڏ��VIEW���o����
        AND msib.segment1 = ximv.item_no                                          --�i�ڃR�[�h
        --OPM���b�g�}�X�^���o����
        AND ilm.item_id = ximv.item_id                                            --�i��ID
        AND ( 
                pla.attribute1 = ilm.lot_no                                       --���b�gNo
          OR (
                pla.attribute1 IS NULL
          )
        )
        --����ԕi���ђ��o����
        AND pha.segment1 = xrart.source_document_number                           --�������ԍ�
        AND pla.line_num = xrart.source_document_line_num                         --���������הԍ�
        AND xrart.txns_type = gv_txns_type_rcv                                    --���ы敪
        --�ۊǏꏊ�}�X�^VIEW���o����
        AND pha.attribute5 = xilv.segment1                                        --�[���ꏊ
        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
--mod start 1.3
--          BETWEEN TRUNC(xilv.date_from) AND NVL(TRUNC(xilv.date_to),TO_DATE(civ_ymd_from,gv_fmt_ymd))
          BETWEEN xilv.date_from AND NVL(xilv.date_to,TO_DATE(civ_ymd_from,gv_fmt_ymd))
--mod end 1.3
        --�d������VIEW���o����
        AND pha.vendor_id = xvv.vendor_id                                         --�d����ID
        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
--mod start 1.3
--          BETWEEN TRUNC(xvv.start_date_active) AND TRUNC(xvv.end_date_active)     --�K�p�J�n���E�I����
          BETWEEN xvv.start_date_active AND xvv.end_date_active                   --�K�p�J�n���E�I����
--mod end 1.3
        --OPM�ۗ��݌Ƀg�����U�N�V�������o����
        AND itp.doc_type = 'PORC'                                                 --�����^�C�v
        AND rsl.shipment_header_id = itp.doc_id                                   --����ID
        AND rsl.line_num = itp.doc_line                                           --������הԍ�
        AND rt.transaction_id = itp.line_id                                       --���C��ID
        AND ximv.item_id = itp.item_id                                            --�i��ID
        AND ilm.lot_id = itp.lot_id                                               --���b�gID
        AND xilv.segment1 = itp.location                                          --�ۊǑq�ɃR�[�h
        AND itp.completed_ind = gv_tran_cmp                                       --�����t���O
        --�󕥋敪�}�X�^�A�h�I�����o����
        AND xrpm.doc_type = 'PORC'                                                --�����^�C�v
        AND xrpm.source_document_code = 'PO'                                      --�\�[�X����
        AND xrpm.transaction_type = rt.transaction_type                           --PO����^�C�v
        AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪
        ----------------------------------------------------------------------------------------
        GROUP BY
          ximv.item_id                                                            --�i��ID
         ,itp.lot_id                                                              --���b�gID
         ,pha.attribute4                                                          --���t
         ,xrpm.new_div_invent                                                     --�V�敪
         ,pha.segment1                                                            --�`�[No
         ,pha.attribute4                                                          --�o�ɓ�/����
         ,xvv.segment1                                                            --�����R�[�h
         ,xvv.vendor_name                                                         --����於��
         ,itp.whse_code                                                           --�q�ɃR�[�h
         ,xilv.whse_name                                                          --�q�ɖ�
         ,itp.location                                                            --�ۊǑq�ɃR�[�h
         ,xilv.description                                                        --�ۊǑq�ɖ�
         ,xilv.distribution_block                                                 --�u���b�N
         ,xrpm.rcv_pay_div                                                        --�󕥋敪
         ,xrpm.transaction_type                                                   --PO����^�C�v
        UNION ALL
        ------------------------------
        -- 2.�ړ����я��
        ------------------------------
        SELECT
          gv_trtry_mv                                         territory           --�̈�(�ړ�)
         ,ximv.item_id                                        item_id             --�i��ID
         ,xm.lot_id                                           lot_id              --���b�gID
         ,CASE civ_base_date --�p�����[�^.�
            WHEN gv_base_date_arrival THEN TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd) --�����:���Ɏ��ѓ�
            WHEN gv_base_date_ship THEN TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)       --�����:�o�Ɏ��ѓ�
            ELSE NULL
          END                                                 standard_date       --���t
--mod start 1.2
--         ,xrpm.new_div_invent                                 reason_code         --�V�敪
         ,xm.new_div_invent                                   reason_code         --�V�敪
--mod end 1.2
         ,xm.mov_num                                          slip_no             --�`�[No
         ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)             out_date            --�o�ɓ�
         ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)          in_date             --���ɓ�
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,xm.other_code                                       other_code          --�����R�[�h
         ,xilv2.description                                   other_name          --����於��
         ,CASE xm.record_type
            WHEN gv_rectype_in THEN
--mod start 1.2
--              SUM(CASE ximv.lot_ctl --���b�g�Ǘ��敪
--                WHEN gn_lotctl_yes THEN xm.actual_quantity --���b�g�Ǘ��i
--                WHEN gn_lotctl_no THEN xm.ship_to_quantity --�񃍃b�g�Ǘ��i
--                ELSE 0
--              END)
              SUM(NVL(xm.trans_qty,0))
--mod end 1.2
            ELSE 0 END                                        in_qty              --���ɐ�
         ,CASE xm.record_type
            WHEN gv_rectype_out THEN
--mod start 1.2
--              SUM(CASE ximv.lot_ctl --���b�g�Ǘ��敪
--                WHEN gn_lotctl_yes THEN xm.actual_quantity --���b�g�Ǘ��i
--                WHEN gn_lotctl_no THEN xm.shipped_quantity --�񃍃b�g�Ǘ��i
--                ELSE 0
--              END)
-- mod start 1.18
--              SUM(NVL(xm.trans_qty,0)) * -1
              ABS(SUM(NVL(xm.trans_qty,0)) * -1)
-- mod end 1.18
--mod end 1.2
            ELSE 0 END                                                out_qty             --�o�ɐ�
         ,CASE xm.mov_type --�ړ��^�C�v
            WHEN gv_movetype_yes THEN xm.whse_code --�ϑ�����
            WHEN gv_movetype_no THEN xm.whse_code --�ϑ��Ȃ�
            ELSE NULL
          END                                                 whse_code           --�q�ɃR�[�h
         ,xilv.whse_name                                      whse_name           --�q�ɖ�
         ,CASE xm.mov_type --�ړ��^�C�v
            WHEN gv_movetype_yes THEN xm.location --�ϑ�����
            WHEN gv_movetype_no THEN xm.location --�ϑ��Ȃ�
            ELSE NULL
          END                                                 location            --�ۊǑq�ɃR�[�h
         ,xilv.description                                    description         --�ۊǑq�ɖ�
         ,xilv.distribution_block                             distribution_block  --�u���b�N
--mod start 1.2
--         ,xrpm.rcv_pay_div                                    rcv_pay_div         --�󕥋敪
         ,xm.rcv_pay_div                                      rcv_pay_div         --�󕥋敪
--mod end 1.2
       FROM
        (
-------------------------------------------------------------------------------------------------------------------
          --�ϑ�����
          SELECT
          xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
         ,xmrih.record_type                               record_type             --���R�[�h�^�C�v
         ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
         ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
         ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
         ,xmrih.arvl_ship_date                            arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
         ,xmrih.locat_id                                  locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
         ,xmrih.locat_code                                locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
         ,xmrih.arvl_ship_date2                           arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
         ,xmrih.other_id                                  other_id                --�����ID(���ɐ�ID)
         ,xmrih.other_code                                other_code              --�����(���ɐ�ۊǏꏊ)
         ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
         ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
         ,xmril.item_id                                   item_id                 --�i��ID
         ,xmril.delete_flg                                delete_flg              --����t���O
         ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
         ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
         ,xmld.document_type_code                         document_type_code      --�����^�C�v
         ,xmld.actual_date                                actual_date             --���ѓ�
         ,xmld.lot_id                                     lot_id                  --���b�gID
         ,xmld.actual_quantity                            actual_quantity         --���ѐ���
         ,xilv.segment1                                   segment1                --�ۊǏꏊ�R�[�h
         ,itp.doc_type                                    doc_type                --�����^�C�v
         ,itp.trans_qty                                   trans_qty               --����
         ,itp.whse_code                                   whse_code               --�q�ɃR�[�h
         ,itp.location                                    location                --�ۊǑq�ɃR�[�h
--add start 1.2
         ,xmrih.new_div_invent                            new_div_invent          --�V�敪
         ,xmrih.rcv_pay_div                               rcv_pay_div             --�󕥋敪
--add end 1.2
          FROM
          (
            --�o�Ɏ��я��
            SELECT
              xmrih.mov_hdr_id                                mov_hdr_id          --�ړ��w�b�_ID
             ,xmrih.comp_actual_flg                           comp_actual_flg     --���ьv��σt���O
             ,xmrih.mov_type                                  mov_type            --�ړ��^�C�v
             ,xmrih.mov_num                                   mov_num             --�ړ��ԍ�
             ,xmrih.actual_ship_date                          arvl_ship_date      --���ѓ�(�o�Ɏ��ѓ�)
             ,xmrih.shipped_locat_id                          locat_id            --�ۊǑq��ID(�o�Ɍ�ID)
             ,xmrih.shipped_locat_code                        locat_code          --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
             ,xmrih.actual_arrival_date                       arvl_ship_date2     --���ѓ�(���Ɏ��ѓ�)
             ,xmrih.ship_to_locat_id                          other_id            --�����ID(���ɐ�ID)
             ,xmrih.ship_to_locat_code                        other_code          --�����(���ɐ�ۊǏꏊ)
             ,xmrih.actual_arrival_date                       actual_arrival_date --���Ɏ��ѓ�
             ,xmrih.actual_ship_date                          actual_ship_date    --�o�Ɏ��ѓ�
             ,gv_rectype_out                                  record_type         --���R�[�h�^�C�v(�o�Ɏ���)
--add start 1.2
             ,gv_newdiv_pay                                   new_div_invent      --�V�敪
             ,gv_rcvdiv_pay                                   rcv_pay_div         --�󕥋敪
--add end 1.2
            FROM
              xxinv_mov_req_instr_headers                     xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
            --�ړ��˗�/�w���w�b�_(�A�h�I��)���o����
            WHERE xmrih.mov_type = gv_movetype_yes                                --�ړ��^�C�v(�ϑ�����)
            UNION ALL
            --���Ɏ��я��
            SELECT
              xmrih.mov_hdr_id                                mov_hdr_id          --�ړ��w�b�_ID
             ,xmrih.comp_actual_flg                           comp_actual_flg     --���ьv��σt���O
             ,xmrih.mov_type                                  mov_type            --�ړ��^�C�v
             ,xmrih.mov_num                                   mov_num             --�ړ��ԍ�
             ,xmrih.actual_arrival_date                       arvl_ship_date      --���ѓ�(���Ɏ��ѓ�)
             ,xmrih.ship_to_locat_id                          locat_id            --�ۊǑq��ID(���ɐ�ID)
             ,xmrih.ship_to_locat_code                        locat_code          --�ۊǑq�ɃR�[�h(���ɐ�ۊǏꏊ)
             ,xmrih.actual_ship_date                          arvl_ship_date2     --���ѓ�(�o�Ɏ��ѓ�)
             ,xmrih.shipped_locat_id                          other_id            --�����ID(�o�Ɍ�ID)
             ,xmrih.shipped_locat_code                        other_code          --�����(�o�Ɍ��ۊǏꏊ)
             ,xmrih.actual_arrival_date                       actual_arrival_date --���Ɏ��ѓ�
             ,xmrih.actual_ship_date                          actual_ship_date    --�o�Ɏ��ѓ�
             ,gv_rectype_in                                   record_type         --���R�[�h�^�C�v(���Ɏ���)
--add start 1.2
             ,gv_newdiv_rcv                                   new_div_invent      --�V�敪
             ,gv_rcvdiv_rcv                                   rcv_pay_div         --�󕥋敪
--add end 1.2
            FROM
              xxinv_mov_req_instr_headers                     xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
            --�ړ��˗�/�w���w�b�_(�A�h�I��)���o����
            WHERE xmrih.mov_type = gv_movetype_yes                                --�ړ��^�C�v(�ϑ�����)
          ) xmrih
         ,xxinv_mov_req_instr_lines                           xmril               --�ړ��˗�/�w������(�A�h�I��)
         ,xxinv_mov_lot_details                               xmld                --�ړ����b�g�ڍ�(�A�h�I��)
         ,xxcmn_item_locations2_v                             xilv                --OPM�ۊǏꏊ���VIEW2
         ,ic_xfer_mst                                         ixm                 --OPM�݌ɓ]���}�X�^
         ,ic_tran_pnd                                         itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
         --�ړ��˗�/�w������(�A�h�I��)���o����
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         --�ړ����b�g�ڍ�(�A�h�I��)���o����
--mod start 1.2
--         AND xmld.mov_line_id(+) = xmril.mov_line_id                              --�ړ�����ID
--         AND ( xmld.mov_line_id IS NOT NULL
--           AND xmld.document_type_code = gv_dctype_move                           --�����^�C�v
--         OR    xmld.mov_line_id IS NULL
--         )
--         AND  (xmld.mov_line_id IS NOT NULL
--           AND xmrih.record_type = xmld.record_type_code                          --���R�[�h�^�C�v
--         OR    xmld.mov_line_id IS NULL
--         )
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = xmrih.record_type                            --���R�[�h�^�C�v
--mod end 1.2
         --OPM�ۊǏꏊ���VIEW2���o����
         AND xmrih.locat_id = xilv.inventory_location_id                          --�ۊǑq��ID
         AND xmrih.arvl_ship_date
           BETWEEN xilv.date_from AND NVL(xilv.date_to,xmrih.arvl_ship_date)      --�K�p�J�n���E�I����
         --OPM�݌ɓ]���}�X�^���o����
         AND xmril.mov_line_id = ixm.attribute1                                   --�����\�[�XID
         --OPM�ۗ��݌Ƀg�����U�N�V�������o����
         AND itp.doc_type = 'XFER'                                                --�����^�C�v
         AND ixm.transfer_id = itp.doc_id                                         --����ID
         AND xmril.item_id = itp.item_id                                          --�i��ID
         AND ( xmld.lot_id IS NOT NULL 
           AND xmld.lot_id = itp.lot_id                                           --���b�gID
         OR    xmld.lot_id IS NULL
         )
         AND xilv.segment1 = itp.location                                         --�ۊǑq�ɃR�[�h
         AND itp.completed_ind = gv_tran_cmp                                      --�����t���O�@
--add start 1.2
--add start 1.16
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT COUNT(*)
             FROM ic_tran_pnd itp2                                                --OPM�ۗ��݌Ƀg�����U�N�V����
             WHERE itp.doc_id = itp2.doc_id                                       --����ID
             AND   itp.whse_code = itp2.whse_code                                 --�q�ɃR�[�h
             GROUP BY itp2.doc_id
                     ,itp2.whse_code
             HAVING COUNT(*) > 1
             )
--add end 1.16
        UNION ALL
          --�ϑ�����(ADJI)
          SELECT
          xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
         ,xmrih.record_type                               record_type             --���R�[�h�^�C�v
         ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
         ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
         ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
         ,xmrih.arvl_ship_date                            arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
         ,xmrih.locat_id                                  locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
         ,xmrih.locat_code                                locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
         ,xmrih.arvl_ship_date2                           arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
         ,xmrih.other_id                                  other_id                --�����ID(���ɐ�ID)
         ,xmrih.other_code                                other_code              --�����(���ɐ�ۊǏꏊ)
         ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
         ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
         ,xmril.item_id                                   item_id                 --�i��ID
         ,xmril.delete_flg                                delete_flg              --����t���O
         ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
         ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
         ,xmld.document_type_code                         document_type_code      --�����^�C�v
         ,xmld.actual_date                                actual_date             --���ѓ�
         ,xmld.lot_id                                     lot_id                  --���b�gID
         ,xmld.actual_quantity                            actual_quantity         --���ѐ���
         ,xilv.segment1                                   segment1                --�ۊǏꏊ�R�[�h
         ,itc.doc_type                                    doc_type                --�����^�C�v
         ,itc.trans_qty                                   trans_qty               --����
         ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
         ,itc.location                                    location                --�ۊǑq�ɃR�[�h
         ,xmrih.new_div_invent                            new_div_invent          --�V�敪
         ,xmrih.rcv_pay_div                               rcv_pay_div             --�󕥋敪
          FROM
          (
            --�o�Ɏ��я��
            SELECT
              xmrih.mov_hdr_id                                mov_hdr_id          --�ړ��w�b�_ID
             ,xmrih.comp_actual_flg                           comp_actual_flg     --���ьv��σt���O
             ,xmrih.mov_type                                  mov_type            --�ړ��^�C�v
             ,xmrih.mov_num                                   mov_num             --�ړ��ԍ�
             ,xmrih.actual_ship_date                          arvl_ship_date      --���ѓ�(�o�Ɏ��ѓ�)
             ,xmrih.shipped_locat_id                          locat_id            --�ۊǑq��ID(�o�Ɍ�ID)
             ,xmrih.shipped_locat_code                        locat_code          --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
             ,xmrih.actual_arrival_date                       arvl_ship_date2     --���ѓ�(���Ɏ��ѓ�)
             ,xmrih.ship_to_locat_id                          other_id            --�����ID(���ɐ�ID)
             ,xmrih.ship_to_locat_code                        other_code          --�����(���ɐ�ۊǏꏊ)
             ,xmrih.actual_arrival_date                       actual_arrival_date --���Ɏ��ѓ�
             ,xmrih.actual_ship_date                          actual_ship_date    --�o�Ɏ��ѓ�
             ,gv_rectype_out                                  record_type         --���R�[�h�^�C�v(�o�Ɏ���)
             ,gv_newdiv_pay                                   new_div_invent      --�V�敪
             ,gv_rcvdiv_pay                                   rcv_pay_div         --�󕥋敪
            FROM
              xxinv_mov_req_instr_headers                     xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
--add start 1.16
             ,xxcmn_item_locations2_v                         xilv_locat          --OPM�ۊǏꏊ���VIEW2(�ۊǑq�ɂ̑q�ɃR�[�h�擾�p)
             ,xxcmn_item_locations2_v                         xilv_other          --OPM�ۊǏꏊ���VIEW2(�����̑q�ɃR�[�h�擾�p)
--add end 1.16
            --�ړ��˗�/�w���w�b�_(�A�h�I��)���o����
            WHERE xmrih.mov_type = gv_movetype_yes                                --�ړ��^�C�v(�ϑ�����)
--add start 1.16
            --OPM�ۊǏꏊ���VIEW2(�ۊǑq��)���o����
            AND xmrih.shipped_locat_id = xilv_locat.inventory_location_id                        --�ۊǑq��ID
            AND xmrih.actual_ship_date
              BETWEEN xilv_locat.date_from AND NVL(xilv_locat.date_to,xmrih.actual_ship_date)    --�K�p�J�n���E�I����
            --OPM�ۊǏꏊ���VIEW2(�����)���o����
            AND xmrih.ship_to_locat_id = xilv_other.inventory_location_id                        --�ۊǑq��ID
            AND xmrih.actual_arrival_date
              BETWEEN xilv_other.date_from AND NVL(xilv_other.date_to,xmrih.actual_arrival_date) --�K�p�J�n���E�I����
            AND xilv_locat.whse_code <> xilv_other.whse_code                      --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
--add end 1.16
            UNION ALL
            --���Ɏ��я��
            SELECT
              xmrih.mov_hdr_id                                mov_hdr_id          --�ړ��w�b�_ID
             ,xmrih.comp_actual_flg                           comp_actual_flg     --���ьv��σt���O
             ,xmrih.mov_type                                  mov_type            --�ړ��^�C�v
             ,xmrih.mov_num                                   mov_num             --�ړ��ԍ�
             ,xmrih.actual_arrival_date                       arvl_ship_date      --���ѓ�(���Ɏ��ѓ�)
             ,xmrih.ship_to_locat_id                          locat_id            --�ۊǑq��ID(���ɐ�ID)
             ,xmrih.ship_to_locat_code                        locat_code          --�ۊǑq�ɃR�[�h(���ɐ�ۊǏꏊ)
             ,xmrih.actual_ship_date                          arvl_ship_date2     --���ѓ�(�o�Ɏ��ѓ�)
             ,xmrih.shipped_locat_id                          other_id            --�����ID(�o�Ɍ�ID)
             ,xmrih.shipped_locat_code                        other_code          --�����(�o�Ɍ��ۊǏꏊ)
             ,xmrih.actual_arrival_date                       actual_arrival_date --���Ɏ��ѓ�
             ,xmrih.actual_ship_date                          actual_ship_date    --�o�Ɏ��ѓ�
             ,gv_rectype_in                                   record_type         --���R�[�h�^�C�v(���Ɏ���)
             ,gv_newdiv_rcv                                   new_div_invent      --�V�敪
             ,gv_rcvdiv_rcv                                   rcv_pay_div         --�󕥋敪
            FROM
              xxinv_mov_req_instr_headers                     xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
--add start 1.16
             ,xxcmn_item_locations2_v                         xilv_locat          --OPM�ۊǏꏊ���VIEW2(�ۊǑq�ɂ̑q�ɃR�[�h�擾�p)
             ,xxcmn_item_locations2_v                         xilv_other          --OPM�ۊǏꏊ���VIEW2(�����̑q�ɃR�[�h�擾�p)
--add end 1.16
            --�ړ��˗�/�w���w�b�_(�A�h�I��)���o����
            WHERE xmrih.mov_type = gv_movetype_yes                                --�ړ��^�C�v(�ϑ�����)
--add start 1.16
            --OPM�ۊǏꏊ���VIEW2(�ۊǑq��)���o����
            AND xmrih.ship_to_locat_id = xilv_locat.inventory_location_id                        --�ۊǑq��ID
            AND xmrih.actual_arrival_date
              BETWEEN xilv_locat.date_from AND NVL(xilv_locat.date_to,xmrih.actual_arrival_date) --�K�p�J�n���E�I����
            --OPM�ۊǏꏊ���VIEW2(�����)���o����
            AND xmrih.shipped_locat_id = xilv_other.inventory_location_id                        --�ۊǑq��ID
            AND xmrih.actual_ship_date
              BETWEEN xilv_other.date_from AND NVL(xilv_other.date_to,xmrih.actual_ship_date)    --�K�p�J�n���E�I����
            AND xilv_locat.whse_code <> xilv_other.whse_code                      --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
--add end 1.16
          ) xmrih
         ,xxinv_mov_req_instr_lines                           xmril               --�ړ��˗�/�w������(�A�h�I��)
         ,xxinv_mov_lot_details                               xmld                --�ړ����b�g�ڍ�(�A�h�I��)
         ,xxcmn_item_locations2_v                             xilv                --OPM�ۊǏꏊ���VIEW2
         ,ic_jrnl_mst                                         ijm                 --OPM�W���[�i���}�X�^
         ,ic_adjs_jnl                                         iaj                 --OPM�݌ɒ����W���[�i��
         ,ic_tran_cmp                                         itc                 --OPM�����݌Ƀg�����U�N�V����
         --�ړ��˗�/�w������(�A�h�I��)���o����
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         --�ړ����b�g�ڍ�(�A�h�I��)���o����
--mod start 1.2
--         AND xmld.mov_line_id(+) = xmril.mov_line_id                              --�ړ�����ID
--         AND ( xmld.mov_line_id IS NOT NULL
--           AND xmld.document_type_code = gv_dctype_move                           --�����^�C�v
--         OR    xmld.mov_line_id IS NULL
--         )
--         AND  (xmld.mov_line_id IS NOT NULL
--           AND xmrih.record_type = xmld.record_type_code                          --���R�[�h�^�C�v
--         OR    xmld.mov_line_id IS NULL
--         )
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = xmrih.record_type                            --���R�[�h�^�C�v
--mod end 1.2
         --OPM�ۊǏꏊ���VIEW2���o����
         AND xmrih.locat_id = xilv.inventory_location_id                          --�ۊǑq��ID
         AND xmrih.arvl_ship_date
           BETWEEN xilv.date_from AND NVL(xilv.date_to,xmrih.arvl_ship_date)      --�K�p�J�n���E�I����
         --OPM�W���[�i���}�X�^���o����
         AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         --OPM�݌ɒ����W���[�i��
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND xilv.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         --OPM�����݌Ƀg�����U�N�V�������o����
         AND itc.doc_type = 'ADJI'                                                --�����^�C�v
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND ( xmld.lot_id IS NOT NULL 
           AND xmld.lot_id = itc.lot_id                                           --���b�gID
         OR    xmld.lot_id IS NULL
         )
--add end 1.2
-------------------------------------------------------------------------------------------------------------------
         UNION ALL
          --�ϑ��Ȃ�
         SELECT
          xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
         ,xmrih.record_type                               record_type             --���R�[�h�^�C�v
         ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
         ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
         ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
         ,xmrih.arvl_ship_date                            arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
         ,xmrih.locat_id                                  locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
         ,xmrih.locat_code                                locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
         ,xmrih.arvl_ship_date2                           arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
         ,xmrih.other_id                                  other_id                --�����ID(���ɐ�ID)
         ,xmrih.other_code                                other_code              --�����(���ɐ�ۊǏꏊ)
         ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
         ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
         ,xmril.item_id                                   item_id                 --�i��ID
         ,xmril.delete_flg                                delete_flg              --����t���O
         ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
         ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
         ,xmld.document_type_code                         document_type_code      --�����^�C�v
         ,xmld.actual_date                                actual_date             --���ѓ�
         ,xmld.lot_id                                     lot_id                  --���b�gID
         ,xmld.actual_quantity                            actual_quantity         --���ѐ���
         ,xilv.segment1                                   segment1                --�ۊǏꏊ�R�[�h
         ,itc.doc_type                                    doc_type                --�����^�C�v
         ,itc.trans_qty                                   trans_qty               --����
         ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
         ,itc.location                                    location                --�ۊǑq�ɃR�[�h
--add start 1.2
         ,xmrih.new_div_invent                            new_div_invent          --�V�敪
         ,xmrih.rcv_pay_div                               rcv_pay_div             --�󕥋敪
--add end 1.2
         FROM
          (
            --�o�Ɏ��я��
            SELECT
              xmrih.mov_hdr_id                            mov_hdr_id              --�ړ��w�b�_ID
             ,xmrih.comp_actual_flg                       comp_actual_flg         --���ьv��σt���O
             ,xmrih.mov_type                              mov_type                --�ړ��^�C�v
             ,xmrih.mov_num                               mov_num                 --�ړ��ԍ�
             ,xmrih.actual_ship_date                      arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
             ,xmrih.shipped_locat_id                      locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
             ,xmrih.shipped_locat_code                    locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
             ,xmrih.actual_arrival_date                   arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
             ,xmrih.ship_to_locat_id                      other_id                --�����ID(���ɐ�ID)
             ,xmrih.ship_to_locat_code                    other_code              --�����(���ɐ�ۊǏꏊ)
             ,xmrih.actual_arrival_date                   actual_arrival_date     --���Ɏ��ѓ�
             ,xmrih.actual_ship_date                      actual_ship_date        --�o�Ɏ��ѓ�
             ,gv_rectype_out                              record_type             --���R�[�h�^�C�v(�o�Ɏ���)
--add start 1.2
             ,gv_newdiv_pay                               new_div_invent          --�V�敪
             ,gv_rcvdiv_pay                               rcv_pay_div             --�󕥋敪
--add end 1.2
            FROM
              xxinv_mov_req_instr_headers                 xmrih                   --�ړ��˗�/�w���w�b�_(�A�h�I��)
            --�ړ��˗�/�w���w�b�_(�A�h�I��)���o����
            WHERE xmrih.mov_type = gv_movetype_no                                 --�ړ��^�C�v(�ϑ��Ȃ�)
            UNION ALL
            --���Ɏ��я��
            SELECT
              xmrih.mov_hdr_id                            mov_hdr_id              --�ړ��w�b�_ID
             ,xmrih.comp_actual_flg                       comp_actual_flg         --���ьv��σt���O
             ,xmrih.mov_type                              mov_type                --�ړ��^�C�v
             ,xmrih.mov_num                               mov_num                 --�ړ��ԍ�
             ,xmrih.actual_arrival_date                   arvl_ship_date          --���ѓ�(���Ɏ��ѓ�)
             ,xmrih.ship_to_locat_id                      locat_id                --�ۊǑq��ID(���ɐ�ID)
             ,xmrih.ship_to_locat_code                    locat_code              --�ۊǑq�ɃR�[�h(���ɐ�ۊǏꏊ)
             ,xmrih.actual_ship_date                      arvl_ship_date2         --���ѓ�(�o�Ɏ��ѓ�)
             ,xmrih.shipped_locat_id                      other_id                --�����ID(�o�Ɍ�ID)
             ,xmrih.shipped_locat_code                    other_code              --�����(�o�Ɍ��ۊǏꏊ)
             ,xmrih.actual_arrival_date                   actual_arrival_date     --���Ɏ��ѓ�
             ,xmrih.actual_ship_date                      actual_ship_date        --�o�Ɏ��ѓ�
             ,gv_rectype_in                               record_type             --���R�[�h�^�C�v(���Ɏ���)
--add start 1.2
             ,gv_newdiv_rcv                               new_div_invent          --�V�敪
             ,gv_rcvdiv_rcv                               rcv_pay_div             --�󕥋敪
--add end 1.2
            FROM
              xxinv_mov_req_instr_headers                 xmrih                   --�ړ��˗�/�w���w�b�_(�A�h�I��)
            --�ړ��˗�/�w���w�b�_(�A�h�I��)���o����
            WHERE xmrih.mov_type = gv_movetype_no                                 --�ړ��^�C�v(�ϑ��Ȃ�)
          ) xmrih
         ,xxinv_mov_req_instr_lines                       xmril                   --�ړ��˗�/�w������(�A�h�I��)
         ,xxinv_mov_lot_details                           xmld                    --�ړ����b�g�ڍ�(�A�h�I��)
         ,xxcmn_item_locations2_v                         xilv                    --OPM�ۊǏꏊ���VIEW2
         ,ic_jrnl_mst                                     ijm                     --OPM�W���[�i���}�X�^
         ,ic_adjs_jnl                                     iaj                     --OPM�݌ɒ����W���[�i��
         ,ic_tran_cmp                                     itc                     --OPM�����݌Ƀg�����U�N�V����
         --�ړ��˗�/�w���w�b�_(�A�h�I��)���o����
--mod start 1.3
--         WHERE TRUNC(xmrih.actual_ship_date) = TRUNC(xmrih.actual_arrival_date)   --�o�׎��ѓ������Ɏ��ѓ�
         WHERE xmrih.actual_ship_date = xmrih.actual_arrival_date                 --�o�׎��ѓ������Ɏ��ѓ�
--mod end 1.3
         --�ړ��˗�/�w������(�A�h�I��)���o����
         AND xmrih.mov_hdr_id = xmril.mov_hdr_id                                  --�ړ��w�b�_ID
         --�ړ����b�g�ڍ�(�A�h�I��)���o����
--mod start 1.2
--         AND xmld.mov_line_id(+) = xmril.mov_line_id                              --�ړ�����ID
--         AND ( xmld.mov_line_id IS NOT NULL
--           AND xmld.document_type_code = gv_dctype_move                           --�����^�C�v
--         OR    xmld.mov_line_id IS NULL
--         )
--         AND  (xmld.mov_line_id IS NOT NULL
--           AND xmrih.record_type = xmld.record_type_code                          --���R�[�h�^�C�v
--         OR    xmld.mov_line_id IS NULL
--         )
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = xmrih.record_type                            --���R�[�h�^�C�v
--mod end 1.2
         --OPM�ۊǏꏊ���VIEW2���o����
         AND xmrih.locat_id = xilv.inventory_location_id                          --�ۊǑq��ID
         AND xmrih.arvl_ship_date
           BETWEEN xilv.date_from AND NVL(xilv.date_to,xmrih.arvl_ship_date)      --�K�p�J�n���E�I����
         --OPM�W���[�i���}�X�^���o����
         AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         --OPM�݌ɒ����W���[�i��
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND xilv.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         --OPM�����݌Ƀg�����U�N�V�������o����
--mod start 1.2
--         AND itc.doc_type = 'TRNI'                                                --�����^�C�v
         AND itc.doc_type IN ('TRNI','ADJI')                                      --�����^�C�v
--mod end 1.2
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND ( xmld.lot_id IS NOT NULL 
           AND xmld.lot_id = itc.lot_id                                           --���b�gID
         OR    xmld.lot_id IS NULL
         )
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT COUNT(*)
             FROM ic_tran_cmp itc2                                                --OPM�����݌Ƀg�����U�N�V����
             WHERE itc.doc_id = itc2.doc_id                                       --����ID
             AND   itc.whse_code = itc2.whse_code                                 --�q�ɃR�[�h
             GROUP BY itc2.doc_id
                     ,itc2.whse_code
             HAVING COUNT(*) > 1
             )
         )                                                    xm                  --�ړ����
         ,xxcmn_item_mst2_v                                   ximv                --OPM�i�ڏ��VIEW2(�����p)
         ,xxcmn_item_locations2_v                             xilv                --OPM�ۊǏꏊ���VIEW2
         ,xxcmn_item_locations2_v                             xilv2               --OPM�ۊǏꏊ���VIEW2(�����)
         ,xxcmn_rcv_pay_mst                                   xrpm                --����敪�A�h�I���}�X�^
        --�ړ���񒊏o����
        WHERE xm.comp_actual_flg = gv_cmp_actl_yes                                --���ьv��t���O
        AND xm.delete_flg = gv_delete_no                                          --�폜�t���O
        --OPM�ۊǏꏊ���VIEW2���o����
        AND xm.item_id = ximv.item_id                                             --�i��ID
        AND xm.arvl_ship_date 
          BETWEEN ximv.start_date_active AND ximv.end_date_active                 --���ѓ�
        --OPM�ۊǏꏊ���VIEW2���o����
        AND xm.locat_id = xilv.inventory_location_id                              --�ۊǑq��ID
        AND xm.arvl_ship_date
          BETWEEN xilv.date_from AND NVL(xilv.date_to,xm.arvl_ship_date)          --�K�p�J�n���E�I����
        --OPM�ۊǏꏊ���VIEW2(�����)���o����
        AND xm.other_id = xilv2.inventory_location_id                             --�ۊǑq��ID(�����)
        AND xm.arvl_ship_date
          BETWEEN xilv2.date_from AND NVL(xilv2.date_to,xm.arvl_ship_date)        --�K�p�J�n���E�I����
        --�󕥋敪�A�h�I���}�X�^���o����
        AND xrpm.doc_type =xm.doc_type                                            --�����^�C�v
        AND TO_CHAR(SIGN(xm.trans_qty)) = xrpm.rcv_pay_div                        --�󕥋敪
        AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪
        AND xrpm.new_div_invent IN (gv_newdiv_pay,gv_newdiv_rcv)
        ------------------�����-------------------------
        AND ( civ_base_date = gv_base_date_arrival                                --������̏ꍇ
--mod start 1.3
--          AND TRUNC(xm.actual_arrival_date)                                       --���Ɏ��ѓ�
          AND xm.actual_arrival_date                                              --���Ɏ��ѓ�
--mod end 1.3
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
        ------------------�����-------------------------
        OR    civ_base_date = gv_base_date_ship                                   --������̏ꍇ
--mod start 1.3
--          AND TRUNC(xm.actual_ship_date)                                          --�o�׎��ѓ�
          AND xm.actual_ship_date                                                 --�o�׎��ѓ�
--mod end 1.3
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
        )
        ----------------------------------------------------------------------------------------
        GROUP BY 
          ximv.item_id                                                            --�i��ID
         ,xm.lot_id                                                               --���b�gID
--mod start 1.2
--         ,xrpm.new_div_invent                                                     --�V�敪
         ,xm.new_div_invent                                                       --�V�敪
--mod end 1.2
         ,xm.mov_num                                                              --�`�[No
         ,xilv.description                                                        --�ۊǑq�ɖ�
         ,xm.mov_type                                                             --�ړ��^�C�v
         ,xm.whse_code                                                            --�ۗ�.�q�ɃR�[�h
         ,xm.location                                                             --�ۗ�.�ۊǑq�ɃR�[�h
         ,xm.whse_code                                                            --����.�q�ɃR�[�h
         ,xm.location                                                             --����.�ۊǑq�ɃR�[�h
         ,xilv.whse_name                                                          --�q�ɖ�
         ,xilv.distribution_block                                                 --�u���b�N
--mod start 1.2
--         ,xrpm.rcv_pay_div                                                        --�󕥋敪
         ,xm.rcv_pay_div                                                          --�󕥋敪
--mod end 1.2
        ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)
        ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)
        ,TO_CHAR(xm.arvl_ship_date,gv_fmt_ymd)
        ,xm.other_code
        ,xilv2.description
        ,ximv.lot_ctl
        ,xm.record_type
        UNION ALL
        ------------------------------
        -- 3.�o��/�L���o�׎��я��
        ------------------------------
        SELECT
          gv_trtry_sh                                         territory           --�̈�(�o��)
         ,sh_info.item_id                                     item_id             --�i��ID
         ,sh_info.lot_id                                      lot_id              --���b�gID
         ,CASE civ_base_date --�p�����[�^.�
--mod start 1.6
--            WHEN gv_base_date_arrival THEN TO_CHAR(xoha.arrival_date,gv_fmt_ymd) 
--            WHEN gv_base_date_ship THEN TO_CHAR(xoha.shipped_date,gv_fmt_ymd) 
            WHEN gv_base_date_arrival THEN TO_CHAR(sh_info.arrival_date,gv_fmt_ymd) 
            WHEN gv_base_date_ship THEN TO_CHAR(sh_info.shipped_date,gv_fmt_ymd) 
--mod end 1.6
            ELSE NULL
          END                                                 standard_date       --���t
         ,sh_info.new_div_invent                              reason_code         --�V�敪
--mod start 1.6
--         ,xoha.request_no                                     slip_no             --�`�[No
--         ,TO_CHAR(xoha.shipped_date,gv_fmt_ymd)               out_date            --�o�ɓ�
--         ,TO_CHAR(xoha.arrival_date,gv_fmt_ymd)               in_date             --����
--         ,xoha.head_sales_branch                              jrsd_code           --�Ǌ����_�R�[�h
         ,sh_info.request_no                                     slip_no             --�`�[No
         ,TO_CHAR(sh_info.shipped_date,gv_fmt_ymd)               out_date            --�o�ɓ�
         ,TO_CHAR(sh_info.arrival_date,gv_fmt_ymd)               in_date             --����
         ,sh_info.head_sales_branch                              jrsd_code           --�Ǌ����_�R�[�h
--mod end 1.6
         ,xcav.party_short_name                               jrsd_name           --�Ǌ����_��
--mod start 1.6
--         ,xoha.deliver_to                                     other_code          --�����R�[�h
         ,sh_info.deliver_to                                     other_code          --�����R�[�h
--mod end 1.6
--mod start 1.7
--         ,xpsv.party_site_full_name                           other_name          --����於��
         ,sh_info.party_site_full_name                           other_name          --����於��
--mod end 1.7
         ,CASE sh_info.rcv_pay_div--�󕥋敪
            WHEN gv_rcvdiv_rcv THEN sh_info.trans_qty_sum
            ELSE 0
          END                                                 in_qty              --���ɐ�
         ,CASE sh_info.rcv_pay_div--�󕥋敪
-- mod start ver1.21
-- mod start 1.18
--            WHEN gv_rcvdiv_pay THEN sh_info.trans_qty_sum
--            WHEN gv_rcvdiv_pay THEN ABS(sh_info.trans_qty_sum)
            WHEN gv_rcvdiv_pay THEN 
              CASE
                WHEN (sh_info.new_div_invent = '104' AND sh_info.order_category_code = 'RETURN') THEN
                  ABS(sh_info.trans_qty_sum) * -1
                ELSE
                  ABS(sh_info.trans_qty_sum)
              END
-- mod end 1.18
-- mod end ver1.21
            ELSE 0
          END                                                 out_qty             --�o�ɐ�
         ,sh_info.whse_code                                   whse_code           --�q�ɃR�[�h
         ,sh_info.whse_name                                   whse_name           --�q�ɖ�
         ,sh_info.location                                    location            --�ۊǑq�ɃR�[�h
         ,sh_info.description                                 description         --�ۊǑq�ɖ�
         ,sh_info.distribution_block                          distribution_block  --�u���b�N
         ,sh_info.rcv_pay_div                                 rcv_pay_div         --�󕥋敪
        ----------------------------------------------------------------------------------------
        FROM (
          SELECT
            oe_info.doc_type                                  doc_type            --�����^�C�v
           ,oe_info.item_id                                   item_id             --�i��ID
           ,oe_info.whse_code                                 whse_code           --�q�ɃR�[�h
           ,xilv.whse_name                                    whse_name           --�q�ɖ�
           ,oe_info.location                                  location            --�ۊǑq�ɃR�[�h
           ,xilv.description                                  description         --�ۊǑq�ɖ�
           ,xilv.inventory_location_id                        inventory_location_id   --�ۊǑq��ID
           ,oe_info.lot_id                                    lot_id              --���b�gID
           ,oe_info.doc_id                                    doc_id              --����ID
           ,oe_info.doc_line                                  doc_line            --������הԍ�
           ,oe_info.header_id                                 header_id           --�󒍃w�b�_ID
           ,oe_info.order_type_id                             order_type_id       --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                                  rcv_pay_div         --�󕥋敪
           ,xrpm.new_div_invent                               new_div_invent      --�V�敪
           ,SUM(oe_info.trans_qty)                            trans_qty_sum       --���ʍ��v
           ,xilv.distribution_block                           distribution_block  --�u���b�N
--add start 1.6
           ,xoha.head_sales_branch                            head_sales_branch
           ,xoha.deliver_to_id                                deliver_to_id
           ,DECODE(xoha.req_status,gv_recsts_shipped,xoha.result_deliver_to
                                  ,gv_recsts_shipped2,xoha.vendor_site_code
            ) deliver_to
           ,xoha.arrival_date                                 arrival_date
           ,xoha.shipped_date                                 shipped_date
           ,xoha.request_no                                   request_no
           ,DECODE(xoha.req_status,gv_recsts_shipped,xpsv.party_site_full_name
                                  ,gv_recsts_shipped2,xvsv.vendor_site_name
            ) party_site_full_name
-- add start ver1.21
           ,otta.order_category_code                          order_category_code
-- add end ver1.21
--add end 1.6
          FROM
            ( --OMSO�֘A���
              SELECT
                itp.doc_type                                  doc_type            --�����^�C�v
               ,itp.item_id                                   item_id             --�i��ID
               ,itp.whse_code                                 whse_code           --�q�ɃR�[�h
               ,itp.location                                  location            --�ۊǑq�ɃR�[�h
               ,itp.lot_id                                    lot_id              --���b�gID
               ,itp.doc_id                                    doc_id              --����ID
               ,itp.doc_line                                  doc_line            --������הԍ�
               ,itp.trans_qty                                 trans_qty           --���ʍ��v
               ,itp.trans_date                                trans_date          --�g�����U�N�V�������t
               ,ooha.header_id                                header_id           --�󒍃w�b�_ID
               ,ooha.order_type_id                            order_type_id       --�󒍃^�C�vID
              FROM
                ic_tran_pnd                                   itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
               ,wsh_delivery_details                          wdd                 --�o�ה�������
               ,oe_order_headers_all                          ooha                --�󒍃w�b�_
              WHERE itp.doc_type = 'OMSO'
              AND itp.completed_ind = gv_tran_cmp                                 --�����t���O
              AND itp.line_id = wdd.source_line_id                                --�\�[�X����ID
              AND wdd.org_id = ooha.org_id                                        --�g�DID
              AND wdd.source_header_id = ooha.header_id                           --�󒍃w�b�_ID
              UNION ALL
              --PORC�֘A���
              SELECT
                itp.doc_type                                      doc_type        --�����^�C�v
               ,itp.item_id                                       item_id         --�i��ID
               ,itp.whse_code                                     whse_code       --�q�ɃR�[�h
               ,itp.location                                      location        --�ۊǑq�ɃR�[�h
               ,itp.lot_id                                        lot_id          --���b�gID
               ,itp.doc_id                                        doc_id          --����ID
               ,itp.doc_line                                      doc_line        --������הԍ�
               ,itp.trans_qty                                     trans_qty       --���ʍ��v
               ,itp.trans_date                                trans_date          --�g�����U�N�V�������t
               ,ooha.header_id                                    header_id       --�󒍃w�b�_ID
               ,ooha.order_type_id                                order_type_id   --�󒍃^�C�vID
              FROM
                ic_tran_pnd                                       itp             --OPM�ۗ��݌Ƀg�����U�N�V����
               ,rcv_shipment_lines                                rsl             --�������
               ,oe_order_headers_all                              ooha            --�󒍃w�b�_
              WHERE itp.doc_type = 'PORC'                                         --�����^�C�v
              AND itp.completed_ind = gv_tran_cmp                                 --�����t���O
              AND rsl.source_document_code = 'RMA'                                --�\�[�X����
              AND itp.doc_id = rsl.shipment_header_id                             --����w�b�_ID
              AND itp.doc_line = rsl.line_num                                     --���הԍ�
              AND rsl.oe_order_header_id = ooha.header_id                         --�󒍃w�b�_ID
           ) oe_info
           ,xxwsh_order_headers_all                           xoha                --�󒍃w�b�_(�A�h�I��)
--add start 1.7
           ,xxcmn_party_sites2_v                              xpsv                --�p�[�e�B�T�C�g���VIEW2
           ,xxcmn_vendor_sites2_v                             xvsv                --�d����T�C�g���VIEW2
--add end 1.7
           ,xxwsh_order_lines_all                             xola                --�󒍖���(�A�h�I��)
           ,oe_transaction_types_all                          otta                --�󒍃^�C�v
           ,xxcmn_rcv_pay_mst                                 xrpm                --����敪�A�h�I���}�X�^
           ,xxcmn_item_mst2_v                                 ximv_s              --OPM�i�ڏ��VIEW2(�o�וi�ڗp)
           ,xxcmn_item_mst2_v                                 ximv_r              --OPM�i�ڏ��VIEW2(�˗��i�ڗp)
           ,xxcmn_item_categories5_v                          xicv_s              --OPM�i�ڃJ�e�S���������VIEW5(�o�וi�ڗp)
           ,xxcmn_item_categories5_v                          xicv_r              --OPM�i�ڃJ�e�S���������VIEW5(�˗��i�ڗp)
           ,xxcmn_item_locations2_v                           xilv                --OPM�ۊǏꏊ���VIEW2
--add start 1.22
           ,xxinv_mov_lot_details                             xmld                 -- �ړ����b�g�ڍ׃A�h�I��
--add end 1.22
          --�󒍃w�b�_(�A�h�I��)���o����
          WHERE oe_info.header_id = xoha.header_id                                --�󒍃w�b�_ID
--add start 1.6
          AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --�X�e�[�^�X
          AND xoha.actual_confirm_class = gv_confirm_yes                            --���ьv��敪
          AND xoha.latest_external_flag = gv_latest_yes                             --�ŐV�t���O
--add end 1.6
          --�󒍖���(�A�h�I��)���o����
          AND xoha.order_header_id = xola.order_header_id                         --�󒍃A�h�I���w�b�_ID
          --�󒍃^�C�v���o����
          AND oe_info.order_type_id = otta.transaction_type_id                    --�󒍃^�C�vID
          --OPM�i�ڏ��VIEW2(�o�וi�ڗp)���o����
          AND xola.shipping_item_code = ximv_s.item_no                            --�i�ڃR�[�h
--add start 1.20
          AND oe_info.item_id         = ximv_s.item_id                            --�i��ID
--add end 1.20
--add start 1.22
          AND xmld.lot_id             = oe_info.lot_id
          AND xmld.mov_line_id        = xola.order_line_id
          AND xmld.document_type_code = gv_dctype_shipped                         -- �o��
          AND xmld.record_type_code   = gv_rectype_out                            -- �o�Ɏ���
--add end 1.22
          AND oe_info.trans_date
            BETWEEN ximv_s.start_date_active
            AND NVL(ximv_s.end_date_active,oe_info.trans_date)                    --�K�p�J�n���E�I����
          --OPM�i�ڃJ�e�S���������VIEW5(�o�וi�ڗp)���o����
          AND ximv_s.item_id = xicv_s.item_id                                     --�i��ID
          --OPM�i�ڏ��VIEW2(�˗��i�ڗp)���o����
          AND xola.request_item_code = ximv_r.item_no                             --�i�ڃR�[�h
          AND oe_info.trans_date
            BETWEEN ximv_r.start_date_active
            AND NVL(ximv_r.end_date_active,oe_info.trans_date)                    --�K�p�J�n���E�I����
          --OPM�i�ڃJ�e�S���������VIEW5(�˗��i�ڗp)���o����
          AND ximv_r.item_id = xicv_r.item_id                                     --�i��ID
--add start 1.7
          --�p�[�e�B�T�C�g���VIEW2���o����
          AND xoha.result_deliver_to_id = xpsv.party_site_id(+)
          AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
            BETWEEN xpsv.start_date_active(+)
            AND NVL(xpsv.end_date_active(+),TO_DATE(civ_ymd_from,gv_fmt_ymd))     --�K�p�J�n���E�I����
          --�d����T�C�g���VIEW���o����
          AND xoha.vendor_site_id = xvsv.vendor_site_id(+)
          AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
            BETWEEN xvsv.start_date_active(+)
            AND NVL(xvsv.end_date_active(+),TO_DATE(civ_ymd_from,gv_fmt_ymd))     --�K�p�J�n���E�I����
--add end 1.7
          --�󕥋敪�A�h�I���}�X�^���o����
          AND oe_info.doc_type = xrpm.doc_type                                    --�����^�C�v
          AND ((oe_info.doc_type = 'PORC'
             AND xrpm.source_document_code = 'RMA')                               --�\�[�X����
          OR 
            (oe_info.doc_type = 'OMSO')
          )
          AND ( otta.attribute1 = xrpm.shipment_provision_div                      --�o�׎x���敪
            AND xrpm.shipment_provision_div IN (gv_spdiv_ship,gv_spdiv_prov)
          OR    xrpm.shipment_provision_div IS NULL
          )
          AND (otta.attribute11 = xrpm.ship_prov_rcv_pay_category                 --�o�׎x���󕥃J�e�S��
          OR   xrpm.ship_prov_rcv_pay_category IS NULL
          )
--mod start 1.8
--          AND NVL(DECODE(xicv_s.item_class_code
--                        ,gv_item_class_prod
--                        ,gv_item_class_prod
--                        ,NULL),gv_dummy
----mod start 1.4
----              ) = NVL(xrpm.item_div_ahead,gv_dummy)                               --�o�וi�ڂ̕i�ڋ敪���U�֐�i�ڋ敪
--              ) = NVL(xrpm.item_div_origin,gv_dummy)                              --�o�וi�ڂ̕i�ڋ敪���U�֌��i�ڋ敪
----mod end 1.4
--          AND NVL(DECODE(xicv_r.item_class_code
--                        ,gv_item_class_prod
--                        ,gv_item_class_prod
--                        ,NULL),gv_dummy
----mod start 1.4
----              ) = NVL(xrpm.item_div_origin,gv_dummy)                              --�˗��i�ڂ̕i�ڋ敪���U�֌��i�ڋ敪
--              ) = NVL(xrpm.item_div_ahead,gv_dummy)                               --�˗��i�ڂ̕i�ڋ敪���U�֐�i�ڋ敪
----mod end 1.4
          --�o�וi�ڋ敪=�U�֌��i�ڋ敪
          AND (
                --�o�׈˗��E�x���˗�
                xrpm.shipment_provision_div in (gv_spdiv_ship,gv_spdiv_prov)
            AND NVL(DECODE(xicv_s.item_class_code
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_origin,gv_dummy)
                --�o�׈˗��E�x���˗��ȊO
          OR
                NVL(xrpm.shipment_provision_div,gv_dummy) NOT IN (gv_spdiv_ship,gv_spdiv_prov)
          )
          --�˗��i�ڋ敪=�U�֐�i�ڋ敪
          AND (
                --�o�׈˗��E�x���˗�
                xrpm.shipment_provision_div in (gv_spdiv_ship,gv_spdiv_prov)
            AND NVL(DECODE(xicv_r.item_class_code
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_ahead,gv_dummy)
                --�o�׈˗��E�x���˗��ȊO
          OR
                NVL(xrpm.shipment_provision_div,gv_dummy) NOT IN (gv_spdiv_ship,gv_spdiv_prov)
          )
--mod end 1.8
          AND NVL(DECODE(otta.attribute4
                        ,gv_stock_adjm
                        ,gv_stock_adjm
                        ,NULL),gv_dummy
              ) = NVL(DECODE(xrpm.stock_adjustment_div                            --�݌ɒ����敪
                            ,gv_stock_adjm
                            ,gv_stock_adjm
                            ,NULL),gv_dummy
              )
          AND xrpm.use_div_invent = gv_inventory                                  --�݌Ɏg�p�敪
--add start 2.0
          AND (xicv_s.item_class_code = gv_item_class_prod AND xicv_r.item_class_code = gv_item_class_prod
            AND ( ximv_s.item_id = ximv_r.item_id
              AND xrpm.prod_div_origin IS NULL
              AND xrpm.prod_div_ahead IS NULL
            OR    ximv_s.item_id != ximv_r.item_id
              AND xrpm.prod_div_origin IS NOT NULL
              AND xrpm.prod_div_ahead IS NOT NULL
            )
          OR NOT( xicv_s.item_class_code = gv_item_class_prod AND xicv_r.item_class_code = gv_item_class_prod)
          )
--add end 2.0
          --OPM�ۊǏꏊ���VIEW���o����
          AND oe_info.location = xilv.segment1                                    --�ۊǏꏊ�R�[�h
          AND oe_info.trans_date
            BETWEEN xilv.date_from
            AND NVL(xilv.date_to,oe_info.trans_date)                              --�K�p�J�n���E�I����
          GROUP BY 
            oe_info.doc_type                                                      --�����^�C�v
           ,oe_info.item_id                                                       --�i��ID
           ,oe_info.whse_code                                                     --�q�ɃR�[�h
           ,xilv.whse_name                                                        --�q�ɖ�
           ,oe_info.location                                                      --�ۊǑq�ɃR�[�h
           ,xilv.description                                                      --�ۊǑq�ɖ�
           ,xilv.inventory_location_id                                            --�ۊǑq��ID
           ,oe_info.lot_id                                                        --���b�gID
           ,oe_info.doc_id                                                        --����ID
           ,oe_info.doc_line                                                      --������הԍ�
           ,oe_info.header_id                                                     --�󒍃w�b�_ID
           ,oe_info.order_type_id                                                 --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                                                      --�󕥋敪
           ,xrpm.new_div_invent                                                   --�V�敪
           ,xilv.distribution_block                                               --�u���b�N
--add start 1.6
           ,xoha.head_sales_branch
           ,xoha.deliver_to_id
           ,xoha.result_deliver_to
           ,xoha.vendor_site_code
           ,xoha.arrival_date
           ,xoha.shipped_date
           ,xoha.request_no
           ,xoha.req_status
           ,xpsv.party_site_full_name
           ,xvsv.vendor_site_name
-- add start ver1.21
           ,otta.order_category_code
-- add end ver1.21
--add end 1.6
        )                                                     sh_info             --�o�׊֘A���
--del start 1.6
--         ,xxwsh_order_headers_all                             xoha                --�󒍃w�b�_(�A�h�I��)
--del end 1.6
         ,xxcmn_cust_accounts2_v                              xcav                --�ڋq���VIEW2
--del start 1.7
--         ,xxcmn_party_sites2_v                                xpsv                --�p�[�e�B�T�C�g���VIEW2
--del end 1.7
        ----------------------------------------------------------------------------------------
        --�󒍃w�b�_(�A�h�I��)���o����
--del start 1.6
--        WHERE sh_info.header_id = xoha.header_id                                  --�󒍃w�b�_ID
--        AND sh_info.inventory_location_id = xoha.deliver_from_id                  --�o�׌�ID
--        AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --�X�e�[�^�X
--        AND xoha.actual_confirm_class = gv_confirm_yes                            --���ьv��敪
--        AND xoha.latest_external_flag = gv_latest_yes                             --�ŐV�t���O
--del end 1.6
        --�ڋq���VIEW���o����
--mod start 1.6
--        AND xoha.head_sales_branch = xcav.account_number                          --�ڋq�ԍ�
        WHERE sh_info.head_sales_branch = xcav.account_number(+)                          --�ڋq�ԍ�
--mod end 1.6
        AND xcav.customer_class_code(+) = gv_custclass                               --�ڋq�敪(���_)
        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
--mod start 1.3
--          BETWEEN TRUNC(xcav.start_date_active) AND TRUNC(xcav.end_date_active)   --�K�p�J�n���E�I����
          BETWEEN xcav.start_date_active(+)
          AND NVL(xcav.end_date_active(+),TO_DATE(civ_ymd_from,gv_fmt_ymd))         --�K�p�J�n���E�I����
--mod end 1.3
        --�p�[�e�B�T�C�g���VIEW���o����
--del start 1.6
--        AND xoha.deliver_to_id = xpsv.party_site_id                               --�p�[�e�B�T�C�gID
--del end 1.6
--del start 1.7
--        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
----mod start 1.3
----          BETWEEN TRUNC(xpsv.start_date_active) AND TRUNC(xpsv.end_date_active)   --�K�p�J�n���E�I����
--          BETWEEN xpsv.start_date_active AND xpsv.end_date_active                 --�K�p�J�n���E�I����
----mod end 1.3
--del end 1.7
        --������̏ꍇ�̏���
        AND (
          (civ_base_date = gv_base_date_arrival --������̏ꍇ
--mod start 1.6
----mod start 1.3
----            AND TRUNC(xoha.arrival_date)                                          --���ד�
--            AND xoha.arrival_date                                                 --���ד�
----mod end 1.3
            AND sh_info.arrival_date                                                 --���ד�
--mod end 1.6
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          )
        --������̏ꍇ�̏���
        OR  (
          (civ_base_date = gv_base_date_ship --������̏ꍇ
--mod start 1.6
----mod start 1.3
----            AND TRUNC(xoha.shipped_date)                                          --�o�ד�
--            AND xoha.shipped_date                                          --�o�ד�
----mod end 1.3
            AND sh_info.shipped_date                                          --�o�ד�
--mod end 1.6
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            )
          )
        )
        UNION ALL
        ------------------------------
        -- 4.�q�֕ԕi���я��
        ------------------------------
        SELECT
          gv_trtry_rt                                         territory           --�̈�(�q�֕ԕi)
         ,rt_info.item_id                                     item_id             --�i��ID
         ,rt_info.lot_id                                      lot_id              --���b�gID
         ,CASE civ_base_date --�p�����[�^.�
            WHEN gv_base_date_arrival THEN TO_CHAR(xoha.arrival_date,gv_fmt_ymd)
            WHEN gv_base_date_ship THEN TO_CHAR(xoha.shipped_date,gv_fmt_ymd)
            ELSE NULL
          END                                                 standard_date       --���t
         ,rt_info.reason_code                                 reason_code         --�V�敪
         ,xoha.request_no                                     slip_no             --�`�[No
         ,TO_CHAR(xoha.shipped_date,gv_fmt_ymd)               out_date            --�o�ɓ�
         ,TO_CHAR(xoha.arrival_date,gv_fmt_ymd)               in_date             --����
         ,xoha.head_sales_branch                              jrsd_code           --�Ǌ����_�R�[�h
         ,xcav.party_short_name                               jrsd_name           --�Ǌ����_��
         ,xoha.head_sales_branch                              other_code          --�����R�[�h
         ,xcav.party_name                                     other_name          --����於��
         ,rt_info.in_qty_sum                                  in_qty              --���ɐ�
         ,0                                                   out_qty             --�o�ɐ�
         ,rt_info.whse_code                                   whse_code           --�q�ɃR�[�h
         ,rt_info.whse_name                                   whse_name           --�q�ɖ�
         ,rt_info.location                                    location            --�ۊǑq�ɃR�[�h
         ,rt_info.description                                 description         --�ۊǑq�ɖ�
         ,rt_info.distribution_block                          distribution_block  --�u���b�N
         ,rt_info.rcv_pay_div                                 rcv_pay_div         --�󕥋敪
        ----------------------------------------------------------------------------------------
        FROM (
          SELECT
            xoha.header_id                                    header_id           --�󒍃w�b�_ID
           ,itp.whse_code                                     whse_code           --�q�ɃR�[�h
           ,xilv.whse_name                                    whse_name           --�q�ɖ�
           ,itp.item_id                                       item_id             --�i��ID
           ,itp.lot_id                                        lot_id              --���b�gID
           ,itp.location                                      location            --�ۊǑq�ɃR�[�h
           ,xilv.description                                  description         --�ۊǑq�ɖ�
           ,xilv.inventory_location_id                        inventory_location_id --�ۊǑq��ID
           ,xrpm.new_div_invent                               reason_code         --�V�敪
           ,xilv.distribution_block                           distribution_block  --�u���b�N
           ,xrpm.rcv_pay_div                                  rcv_pay_div         --�󕥋敪
           ,SUM(NVL(itp.trans_qty,0))                         in_qty_sum          --���ʍ��v
          FROM
            ic_tran_pnd                                       itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
           ,xxcmn_item_locations2_v                           xilv                --�ۊǏꏊ���VIEW2(�����p)
           ,rcv_shipment_lines                                rsl                 --�������
           ,oe_order_headers_all                              ooha                --�󒍃w�b�_
           ,xxwsh_order_headers_all                           xoha                --�󒍃w�b�_(�A�h�I��)
           ,oe_transaction_types_all                          otta                --�󒍃^�C�v
           ,xxcmn_rcv_pay_mst                                 xrpm                --�󕥋敪�A�h�I���}�X�^
          --OPM�ۗ��݌Ƀg�����U�N�V�������o
          WHERE itp.completed_ind = gv_tran_cmp                                   --�����t���O
          AND itp.doc_type = 'PORC'                                               --�����^�C�v
          --�ۊǏꏊ���VIEW2���o
          AND itp.location = xilv.segment1                                        --�ۊǑq�ɃR�[�h
          AND itp.trans_date
            BETWEEN xilv.date_from AND NVL(xilv.date_to,itp.trans_date)           --�K�p�J�n���E�I����
          --������ג��o
          AND itp.doc_id = rsl.shipment_header_id                                 --����w�b�_ID
          AND itp.doc_line = rsl.line_num                                         --���הԍ�
          AND rsl.source_document_code = 'RMA'                                    --�\�[�X����
          --�󒍃w�b�_���o
          AND rsl.oe_order_header_id = ooha.header_id                             --�󒍃w�b�_ID
          --�󒍃w�b�_�A�h�I�����o
          AND ooha.header_id = xoha.header_id                                     --�󒍃w�b�_ID
          --�󒍃^�C�v���o
          AND ooha.order_type_id = otta.transaction_type_id                       --�󒍃^�C�vID
          AND otta.attribute1 = gv_shipclass                                      --�o�׎x���敪
          --�󕥋敪�A�h�I���}�X�^���o
          AND otta.attribute1 = xrpm.shipment_provision_div                       --�o�׎x���敪
          AND otta.attribute11 = xrpm.ship_prov_rcv_pay_category                  --�o�׎x���󕥃J�e�S��
          AND xrpm.use_div_invent = gv_inventory                                  --�݌Ɏg�p�敪
          AND xrpm.doc_type = 'PORC'                                              --�����^�C�v
          AND xrpm.source_document_code = 'RMA'                                   --�\�[�X����
          GROUP BY
            xoha.header_id                                                        --�󒍃w�b�_ID
           ,itp.whse_code                                                         --�q�ɃR�[�h
           ,xilv.whse_name                                                        --�q�ɖ�
           ,itp.item_id                                                           --�i��ID
           ,itp.lot_id                                                            --���b�gID
           ,itp.location                                                          --�ۊǑq�ɃR�[�h
           ,xilv.description                                                      --�ۊǑq�ɖ�
           ,xilv.inventory_location_id                                            --�ۊǑq��ID
           ,xrpm.new_div_invent                                                   --�V�敪
           ,xilv.distribution_block                                               --�u���b�N
           ,xrpm.rcv_pay_div                                                      --�󕥋敪
        ) rt_info                                                                 --�q�֕ԕi�֘A���
        ,xxwsh_order_headers_all                              xoha                --�󒍃w�b�_(�A�h�I��)
        ,xxcmn_cust_accounts2_v                               xcav                --�ڋq���VIEW2
        ----------------------------------------------------------------------------------------
        --�󒍃w�b�_(�A�h�I��)���o
        WHERE rt_info.header_id = xoha.header_id                                  --�󒍃w�b�_ID
        AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --�X�e�[�^�X
        AND xoha.actual_confirm_class = gv_confirm_yes                            --���ьv��敪
        AND xoha.latest_external_flag = gv_latest_yes                             --�ŐV�t���O
        AND xoha.deliver_from_id = rt_info.inventory_location_id                  --�o�׌�ID
        --�ڋq���VIEW2���o
        AND xoha.head_sales_branch = xcav.account_number                          --�ڋq�ԍ�
        AND xcav.customer_class_code = gv_custclass                               --�ڋq�敪(���_)
        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
--mod start 1.3
--          BETWEEN TRUNC(xcav.start_date_active) AND TRUNC(xcav.end_date_active)   --�K�p�J�n���E�I����
          BETWEEN xcav.start_date_active AND xcav.end_date_active                 --�K�p�J�n���E�I����
--mod end 1.3
        --������̏ꍇ
        AND (
          (civ_base_date = gv_base_date_arrival                                --������̏ꍇ
--mod start 1.3
--            AND TRUNC(xoha.arrival_date)                                          --���ד�
            AND xoha.arrival_date                                                 --���ד�
--mod end 1.3
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          )
        --������̏ꍇ
        OR  
          (civ_base_date = gv_base_date_ship                                   --������̏ꍇ
--mod start 1.3
--            AND TRUNC(xoha.shipped_date)                                          --�o�ד�
            AND xoha.shipped_date                                                 --�o�ד�
--mod end 1.3
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          )
        )
        UNION ALL
        ------------------------------
        -- 5.���Y���я��
        ------------------------------
        SELECT
          gv_trtry_mf                                         territory           --�̈�(���Y)
         ,gmd.item_id                                         item_id             --�i��ID
         ,itp.lot_id                                          lot_id              --���b�gID
--mod start 1.9
--         ,SUBSTRB(gmd_d.attribute11,1,10)                     standard_date       --���t
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--         ,DECODE(grt.routing_desc                                               --�H���敪
         ,DECODE(grct.routing_class_desc                                        --�H���敪
-- mod end 1.20
                ,gv_item_transfer      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --�i�ڐU��
                ,gv_item_return        ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --�ԕi����
                ,gv_item_dissolve      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --��̔����i
                                       ,SUBSTRB(gmd_d.attribute11,1,10)         --���̑�
          )
--mod end 1.9
         ,xrpm.new_div_invent                                 reason_code         --�V�敪
         ,gbh.batch_no                                        slip_no             --�`�[No
--mod start 1.9
--         ,SUBSTRB(gmd_d.attribute11,1,10)                     out_date            --�o�ɓ�
--         ,SUBSTRB(gmd_d.attribute11,1,10)                     in_date             --����
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--         ,DECODE(grt.routing_desc                                               --�H���敪
         ,DECODE(grct.routing_class_desc                                        --�H���敪
-- mod end 1.20
                ,gv_item_transfer      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --�i�ڐU��
                ,gv_item_return        ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --�ԕi����
                ,gv_item_dissolve      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --��̔����i
                                       ,SUBSTRB(gmd_d.attribute11,1,10)         --���̑�
          )                                                   out_date
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--         ,DECODE(grt.routing_desc                                               --�H���敪
         ,DECODE(grct.routing_class_desc                                        --�H���敪
-- mod end 1.20
                ,gv_item_transfer      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --�i�ڐU��
                ,gv_item_return        ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --�ԕi����
                ,gv_item_dissolve      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --��̔����i
                                       ,SUBSTRB(gmd_d.attribute11,1,10)         --���̑�
          )                                                   in_date
--mod end 1.9
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,grb.routing_no                                      other_code          --�����R�[�h
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--         ,grt.routing_desc                                    other_name          --����於��
         ,grct.routing_class_desc                             other_name          --����於��
-- mod end 1.20
         ,SUM(CASE gmd.line_type --���C���^�C�v
            WHEN gn_linetype_mtrl THEN 0
            ELSE NVL(itp.trans_qty,0)
          END)                                                in_qty              --���ɐ�
-- mod start 1.18
--         ,SUM(CASE gmd.line_type --���C���^�C�v
         ,ABS(SUM(CASE gmd.line_type --���C���^�C�v
            WHEN gn_linetype_mtrl THEN NVL(itp.trans_qty,0)
            ELSE 0
--          END)                                                 out_qty             --�o�ɐ�
          END))                                                out_qty             --�o�ɐ�
-- mod end 1.18
         ,itp.whse_code                                       whse_code           --�q�ɃR�[�h
         ,xilv.whse_name                                      whse_name           --�q�ɖ�
         ,itp.location                                        location            --�ۊǑq�ɃR�[�h
         ,xilv.description                                    description         --�ۊǑq�ɖ�
         ,xilv.distribution_block                             distribution_block  --�u���b�N
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --�󕥋敪
        ----------------------------------------------------------------------------------------
        FROM
          gme_batch_header                                    gbh                 --���Y�o�b�`
         ,gme_material_details                                gmd                 --���Y�����ڍ�
         ,gme_material_details                                gmd_d               --���Y�����ڍ�(�����i)
         ,gmd_routings_b                                      grb                 --�H���}�X�^
-- mod start 1.20
--         ,gmd_routings_tl                                     grt                 --�H���}�X�^���{��
         ,gmd_routing_class_tl                                grct                --�H���敪�}�X�^���{��
-- mod end 1.20
         ,xxcmn_item_locations2_v                             xilv                --�ۊǏꏊ���VIEW2
         --���Y�����ڍ�(�U�֌���i��)
         ,(
           SELECT 
             gbh.batch_id                                     batch_id            --�o�b�`ID
            ,gmd.line_no                                      line_no             --���C��NO
            ,MAX(DECODE(gmd.line_type --���C���^�C�v
                       ,gn_linetype_mtrl,xicv.item_class_code
                       ,NULL
                )
             )                                                item_class_origin   --�U�֌��i�ڋ敪
            ,MAX(DECODE(gmd.line_type --���C���^�C�v
                       ,gn_linetype_prod,xicv.item_class_code
                       ,NULL
                )
             )                                                item_class_ahead    --�U�֐�i�ڋ敪
           FROM
             gme_batch_header                                 gbh                 --���Y�o�b�`
            ,gme_material_details                             gmd                 --���Y�����ڍ�

-- mod start 1.20
--            ,gmd_routings_tl                                  grt                 --�H���}�X�^���{��
            ,gmd_routings_b                                   grb                 --�H���}�X�^
            ,gmd_routing_class_tl                             grct                --�H���敪�}�X�^���{��
-- mod end 1.20
            ,xxcmn_item_categories5_v                         xicv                --OPM�i�ڃJ�e�S���������VIEW5
           --���Y�����ڍג��o����
           WHERE gbh.batch_id = gmd.batch_id                                      --�o�b�`ID
-- mod start 1.20
--           --�H���}�X�^���{�ꒊ�o����
--           AND gbh.routing_id = grt.routing_id                                    --�H��ID
--           AND grt.language = gv_lang                                             --����
--           AND grt.source_lang = gv_source_lang                                   --����
--           AND grt.routing_desc = gv_item_transfer                                --�H����
           --�H���}�X�^���o����
           AND gbh.routing_id          = grb.routing_id                             --�H��ID
           --�H���敪�}�X�^���{�ꒊ�o����
           AND grb.routing_class       = grct.routing_class                         --�H���R�[�h
           AND grct.language           = gv_lang                                    --����
           AND grct.source_lang        = gv_source_lang                             --����
           AND grct.routing_class_desc = gv_item_transfer                           --�H����
-- mod end 1.20
           --OPM�i�ڃJ�e�S���������VIEW5
           AND gmd.item_id = xicv.item_id
           GROUP BY gbh.batch_id
                   ,gmd.line_no
         ) gmd_t
         ,xxcmn_rcv_pay_mst                                   xrpm                --�󕥋敪�A�h�I���}�X�^
         ,ic_tran_pnd                                         itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
        ----------------------------------------------------------------------------------------
        --���Y�����ڍג��o����
        WHERE gbh.batch_id = gmd.batch_id                                         --�o�b�`ID
        --���Y�����ڍ�(�����i)
        AND gbh.batch_id = gmd_d.batch_id                                         --�o�b�`ID
        AND gmd_d.line_type = gn_linetype_prod                                    --���C���^�C�v(�����i)
        --���Y�����ڍ�(�U��)
        AND gmd.batch_id = gmd_t.batch_id(+)                                      --�o�b�`ID
        AND gmd.line_no = gmd_t.line_no(+)                                        --���C��NO
        --�H���}�X�^���o����
        AND gbh.routing_id = grb.routing_id                                       --�H��ID
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
        --�H���}�X�^���{�ꒊ�o����
--        AND grb.routing_id = grt.routing_id                                       --�H��ID
--        AND grt.language = gv_lang                                                --����
--        AND grt.source_lang = gv_source_lang                                      --����
        --�H���敪�}�X�^���{�ꒊ�o����
        AND grb.routing_class = grct.routing_class                                  --�H���R�[�h
        AND grct.language     = gv_lang                                             --����
        AND grct.source_lang  = gv_source_lang                                      --����
-- mod end 1.20
        --OPM�ۊǏꏊ�}�X�^���o����
-- mod start 1.19
--        AND xilv.segment1 = grb.attribute9                                        --�ۊǏꏊ�R�[�h
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--        AND xilv.segment1 = DECODE(grt.routing_desc
        AND xilv.segment1 = DECODE(grct.routing_class_desc
-- mod end 1.20
                                  ,gv_item_transfer  ,xilv.segment1               -- �i�ڐU��
                                  ,gv_item_return    ,xilv.segment1               -- �ԕi����
                                  ,gv_item_dissolve  ,xilv.segment1               -- ��̔����i
                                                     ,grb.attribute9)             --�ۊǏꏊ�R�[�h
-- mod end 1.19
--mod start 1.9
--        AND TO_DATE(gmd_d.attribute11,gv_fmt_ymd)
--          BETWEEN xilv.date_from
--          AND NVL(xilv.date_to,TO_DATE(gmd_d.attribute11,gv_fmt_ymd))             --�K�p�J�n���E�I����
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--        AND DECODE(grt.routing_desc                                               --�H���敪
        AND DECODE(grct.routing_class_desc                                          --�H���敪
-- mod end 1.20
                  ,gv_item_transfer      ,itp.trans_date                          --�i�ڐU��
                  ,gv_item_return        ,itp.trans_date                          --�ԕi����
                  ,gv_item_dissolve      ,itp.trans_date                          --��̔����i
                                         ,TO_DATE(gmd_d.attribute11,gv_fmt_ymd)   --���̑�
            )
          BETWEEN xilv.date_from
          AND NVL(xilv.date_to,
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--                DECODE(grt.routing_desc                                               --�H���敪
                DECODE(grct.routing_class_desc                                        --�H���敪
-- mod end 1.20
                      ,gv_item_transfer      ,itp.trans_date                          --�i�ڐU��
                      ,gv_item_return        ,itp.trans_date                          --�ԕi����
                      ,gv_item_dissolve      ,itp.trans_date                          --��̔����i
                                             ,TO_DATE(gmd_d.attribute11,gv_fmt_ymd)   --���̑�
                )
              )
--mod end 1.9
        --OPM�ۗ��݌Ƀg�����U�N�V�������o����
        AND itp.line_id = gmd.material_detail_id                                  --���C��ID
        AND itp.item_id = gmd.item_id                                             --�i��ID
        AND itp.location = xilv.segment1                                          --�ۊǑq�ɃR�[�h
        AND itp.completed_ind = gv_tran_cmp                                       --�����t���O
        AND itp.doc_type = 'PROD'                                                 --�����^�C�v
        AND itp.reverse_id IS NULL                                                --���o�[�XID
        AND itp.delete_mark = gn_delete_mark_no                                   --�폜�}�[�N
        --�󕥋敪�A�h�I���}�X�^���o����
        AND xrpm.doc_type = 'PROD'                                                --�����^�C�v
        AND xrpm.line_type = gmd.line_type                                        --���C���^�C�v
        AND NVL(xrpm.hit_in_div,gv_dummy) = NVL(gmd.attribute5,gv_dummy)          --�ō��敪
        AND NVL(xrpm.routing_class,gv_dummy) = NVL(grb.routing_class,gv_dummy)    --�H���敪
        AND (
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--          (   grt.routing_desc = gv_item_transfer                                 --�i�ڐU�ւ̏ꍇ
          (   grct.routing_class_desc = gv_item_transfer                          --�i�ڐU�ւ̏ꍇ
-- mod end 1.20
          AND xrpm.item_div_ahead = gmd_t.item_class_ahead                        --�U�֐�i�ڋ敪
          AND xrpm.item_div_origin = gmd_t.item_class_origin                      --�U�֌��i�ڋ敪
          )
        OR
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--          (   grt.routing_desc != gv_item_transfer)                                --�i�ڐU�ւł͂Ȃ��ꍇ
          (   grct.routing_class_desc != gv_item_transfer)                        --�i�ڐU�ւł͂Ȃ��ꍇ
-- mod end 1.20
        )
        AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪
        --���Y��
--mod start 1.9
--        AND SUBSTRB(gmd_d.attribute11,1,10) BETWEEN civ_ymd_from AND civ_ymd_to   --���Y��
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--        AND DECODE(grt.routing_desc                                               --�H���敪
        AND DECODE(grct.routing_class_desc                                        --�H���敪
-- mod end 1.20
                  ,gv_item_transfer      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --�i�ڐU��
                  ,gv_item_return        ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --�ԕi����
                  ,gv_item_dissolve      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --��̔����i
                                         ,SUBSTRB(gmd_d.attribute11,1,10)         --���̑�
            )
            BETWEEN civ_ymd_from AND civ_ymd_to
--mod end 1.9
        ----------------------------------------------------------------------------------------
        GROUP BY 
          gv_trtry_mf                                                             --�̈�(���Y)
         ,gmd.item_id                                                             --�i��ID
         ,itp.lot_id                                                              --���b�gID
         ,SUBSTRB(gmd_d.attribute11,1,10)                                         --���t
--add start 1.9
         ,TO_CHAR(itp.trans_date,gv_fmt_ymd)
--add end 1.9
         ,xrpm.new_div_invent                                                     --�V�敪
         ,gbh.batch_no                                                            --�`�[No
         ,grb.routing_no                                                          --�����R�[�h
-- mod start 1.20 �H�����͍H���敪�}�X�^����擾
--         ,grt.routing_desc                                                        --����於��
         ,grct.routing_class_desc
-- mod end 1.20
         ,itp.whse_code                                                           --�q�ɃR�[�h
         ,xilv.whse_name                                                          --�q�ɖ�
         ,itp.location                                                            --�ۊǑq�ɃR�[�h
         ,xilv.description                                                        --�ۊǑq�ɖ�
         ,xilv.distribution_block                                                 --�u���b�N
         ,xrpm.rcv_pay_div                                                        --�󕥋敪
        UNION ALL
        ------------------------------
        -- 6.�݌ɒ������я��
        ------------------------------
        SELECT
          gv_trtry_ad                                         territory           --�̈�(�݌ɒ���)
         ,itc.item_id                                         item_id             --�i��ID
         ,itc.lot_id                                          lot_id              --���b�gID
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  standard_date       --���t
         ,xrpm.new_div_invent                                 reason_code         --�V�敪
         ,ad_info.slip_no                                     slip_no             --�`�[No
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  out_date            --�o�ɓ�
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  in_date             --����
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,CASE ad_info.adji_type
            WHEN gv_adji_xrart THEN ad_info.other_code
            WHEN gv_adji_xnpt THEN xrpm.new_div_invent
            WHEN gv_adji_xvst THEN ad_info.other_code
            WHEN gv_adji_xmrih THEN ad_info.other_code
            WHEN gv_adji_ijm THEN xrpm.new_div_invent
          END                                                 other_code          --�����R�[�h
         ,CASE ad_info.adji_type
            WHEN gv_adji_xrart THEN ad_info.other_name
            WHEN gv_adji_xnpt THEN NULL
            WHEN gv_adji_xvst THEN ad_info.other_name
            WHEN gv_adji_xmrih THEN ad_info.other_name
            WHEN gv_adji_ijm THEN NULL
          END                                                 other_name          --����於��
         ,CASE xrpm.rcv_pay_div
            WHEN '1' THEN SUM(NVL(itc.trans_qty,0))
            ELSE 0
          END                                                 in_qty              --���ɐ�
         ,CASE xrpm.rcv_pay_div
            WHEN '-1' THEN SUM(NVL(itc.trans_qty,0) * -1)
            ELSE 0
          END                                                 out_qty             --�o�ɐ�
         ,itc.whse_code                                       whse_code           --�q�ɃR�[�h
         ,xilv.whse_name                                      whse_name           --�q�ɖ�
         ,itc.location                                        location            --�ۊǑq�ɃR�[�h
         ,xilv.description                                    description         --�ۊǑq�ɖ�
         ,xilv.distribution_block                             distribution_block  --�u���b�N
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --�󕥋敪
        FROM
          (
            -----------------------
            --����ԕi���я��(�d����ԕi)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xrart.rcv_rtn_number                            slip_no             --�`�[No
             ,xrart.vendor_code                               other_code          --�����R�[�h
             ,xvv.vendor_name                                 other_name          --����於��
             ,gv_adji_xrart                                   adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_rcv_and_rtn_txns                           xrart               --����ԕi���уA�h�I��
             ,xxcmn_vendors2_v                                xvv                 --�d������view2
            --����ԕi����(�A�h�I��)���o����
            WHERE xrart.txns_type != gv_txns_type_rcv                             --���ы敪
            AND TRUNC(xrart.txns_date)                                            --�����
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xrart.txns_id                                    --����ID
            --�d������view���o����
            AND xrart.vendor_id = xvv.vendor_id                                   --�����ID
            AND xrart.txns_date                                                   --�����
              BETWEEN start_date_active                                           --�K�p�J�n��
              AND NVL(end_date_active,xrart.txns_date)                            --�K�p�I����
--add start 1.16
            UNION ALL
            -----------------------
            --����ԕi���я��(�����݌�)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xrart.source_document_number                    slip_no             --�`�[No
-- mod start 1.17 �����R�[�h�͎���ԕi���уA�h�I��.�����R�[�h���o��
--             ,xrart.location_code                             other_code          --���o�ɐ�R�[�h
              ,xrart.vendor_code                              other_code          --�����R�[�h(�����)
-- mod end 1.17
-- mod start 1.17 ����於�͎d������VIEW.���������o��
--             ,xilv.description                                other_name          --�E�v�i���o�ɐ於�́j
              ,xvv.vendor_full_name                           other_name          --������(����於)
-- mod end 1.17
             ,gv_adji_xrart                                   adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_rcv_and_rtn_txns                           xrart               --����ԕi���уA�h�I��
-- mod start 1.17 ����於�͎d������VIEW.���������o��
--             ,xxcmn_item_locations2_v                         xilv                --OPM�ۊǏꏊ�}�X�^
             ,xxcmn_vendors2_v                                xvv                 --�d������VIEW
-- mod end 1.17
             ,po_headers_all                                  pha                 --�����w�b�_
            --����ԕi����(�A�h�I��)���o����
            WHERE xrart.txns_type  = gv_txns_type_rcv                             --���ы敪
            AND TRUNC(xrart.txns_date)                                            --�����
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xrart.txns_id                                    --����ID
-- mod start 1.17 ����於�͎d������VIEW.���������o��
--            --OPM�ۊǏꏊ�}�X�^view���o����
--            AND xrart.location_code = xilv.segment1                               --���o�ɐ�R�[�h
--            AND xrart.txns_date                                                   --�����
--              BETWEEN xilv.date_from AND NVL(xilv.date_to,xrart.txns_date)
            --�d������view���o����
            AND xrart.vendor_id = xvv.vendor_id                                   --�����ID
            AND xrart.txns_date                                                   --�����
              BETWEEN xvv.start_date_active                                       --�K�p�J�n��
              AND NVL(xvv.end_date_active, xrart.txns_date)                       --�K�p�I����
-- mod end 1.17
            --�����w�b�_
            AND xrart.source_document_number = pha.segment1                       --�����ԍ�
            AND pha.attribute11 = po_type_inv                                     --�����敪(�����݌�)
--add end 1.16
            UNION ALL
            -----------------------
            --���t���я��
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xnpt.entry_number                               slip_no             --�`�[No
             ,NULL                                            other_code          --�����R�[�h
             ,NULL                                            ohter_name          --����於
             ,gv_adji_xnpt                                    adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_namaha_prod_txns                           xnpt                --���t���уA�h�I��
            --���t���уA�h�I�����o����
            WHERE TRUNC(xnpt.creation_date)                                       --�쐬��
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xnpt.entry_number                                --�`�[No
            UNION ALL
            -----------------------
            --�O���o��������(�A�h�I��)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
              ,''                                             slip_no             --�`�[No
-- mod start 1.17 �����R�[�h�͊O���o��������(�A�h�I��).�����R�[�h���o��
--              ,itc.location                                   other_code          --�����R�[�h
              ,xvst.vendor_code                               other_code          --�����R�[�h(�����)
-- mod end 1.17
-- mod start 1.17 ����於�͎d������VIEW.���������o��
--              ,xilv.description                               other_name          --����於
              ,xvv.vendor_full_name                           other_name          --������(����於)
-- mod end 1.17
              ,gv_adji_xvst                                   adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_vendor_supply_txns                         xvst                --�O���o��������(�A�h�I��)
             ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
             ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
-- mod start 1.17 ����於�͎d������VIEW.���������o��
--             ,xxcmn_item_locations2_v                         xilv                --OPM�ۊǏꏊ�}�X�^
               ,xxcmn_vendors2_v                                xvv                 --�d������VIEW
-- mod end 1.17
            --�O���o�������уA�h�I�����o����
            WHERE ijm.attribute1 = xvst.txns_id                                   --����ID
            --OPM�݌ɒ����W���[�i�����o����
            AND ijm.journal_id = iaj.journal_id
            --OPM�����݌Ƀg�����U�N�V�������o����
            AND iaj.doc_id = itc.doc_id
            AND iaj.doc_line = itc.doc_line
            AND TRUNC(itc.trans_date)
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
-- mod start 1.17 ����於�͎d������VIEW.���������o��
--            --OPM�ۊǏꏊ�}�X�^view���o����
--            AND itc.location = xilv.segment1
--            AND itc.trans_date
--              BETWEEN xilv.date_from AND NVL(xilv.date_to,itc.trans_date)
            --�d������view���o����
            AND xvst.vendor_id = xvv.vendor_id                                   --�����ID
            AND itc.trans_date                                                   --�����
              BETWEEN xvv.start_date_active                                      --�K�p�J�n��
              AND NVL(xvv.end_date_active, itc.trans_date)                       --�K�p�I����
-- mod end 1.17
--del start 1.2

            UNION ALL
            -----------------------
            --�ړ����я��
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xmrih.mov_num                                   slip_no             --�`�[No
             ,xmrih.other_code                                other_code          --�����R�[�h
             ,xilv.description                                other_name          --����於
             ,gv_adji_xmrih                                   adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
                --���Ɏ���
             ,( SELECT
                  xmrih.mov_hdr_id                            mov_hdr_id          --�ړ��w�b�_ID
                  ,xmrih.mov_num                              mov_num             --�ړ�No
                  ,xmrih.ship_to_locat_code                   location            --�ۊǏꏊ
                  ,xmrih.shipped_locat_id                     other_id            --�����(�o�Ɍ�ID)
                  ,xmrih.shipped_locat_code                   other_code          --�����R�[�h(�o�׌��ۊǏꏊ)
                  ,xmrih.actual_arrival_date                  actual_date         --���ѓ�(���Ɏ��ѓ�)
                FROM xxinv_mov_req_instr_headers              xmrih
                UNION ALL
                --�o�Ɏ���
                SELECT
                  xmrih.mov_hdr_id                            mov_hdr_id          --�ړ��w�b�_ID
                 ,xmrih.mov_num                               mov_num             --�ړ�No
                 ,xmrih.shipped_locat_code                    location            --�ۊǏꏊ
                 ,xmrih.ship_to_locat_id                      other_id            --�����(���ɐ�ID)
                 ,xmrih.ship_to_locat_code                    other_code          --�����(���ɐ�ۊǏꏊ)
                 ,xmrih.actual_ship_date                      actual_date         --���ѓ�(�o�Ɏ��ѓ�)
                FROM xxinv_mov_req_instr_headers              xmrih
             )                                                xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
             ,xxinv_mov_req_instr_lines                       xmril               --�ړ��˗�/�w������(�A�h�I��)
             ,xxcmn_item_locations2_v                         xilv                --�ۊǏꏊ���VIEW2
            --�ړ��˗�/�w���w�b�_�A�h�I�����o����
            WHERE TRUNC(xmrih.actual_date)                                        --���ѓ�
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --�ړ��˗�/�w�����׃A�h�I�����o����
            AND xmrih.mov_hdr_id = xmril.mov_hdr_id                               --�ړ��w�b�_ID
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xmril.mov_line_id                                --�ړ�����ID
            --OPM�݌ɒ����W���[�i�����o����
            AND ijm.journal_id = iaj.journal_id                                   --�W���[�i��ID
            AND iaj.location = xmrih.location                                     --�ۊǏꏊ
            --OPM�ۊǏꏊ�}�X�^���o����
            AND xmrih.other_id = xilv.inventory_location_id
            AND xmrih.actual_date
              BETWEEN xilv.date_from AND NVL(xilv.date_to,xmrih.actual_date)      --�K�p�J�n���E�I����

--del end 1.2
            UNION ALL
            -----------------------
            --EBS�W���̍݌ɒ���
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,ijm.journal_no                                  slip_no             --�`�[No
             ,NULL                                            other_code          --�����R�[�h
             ,NULL                                            other_name          --����於
             ,gv_adji_ijm                                     adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
             ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
            --OPM�W���[�i���}�X�^���o����
            WHERE ijm.attribute1 IS NULL
            --OPM�݌ɒ����W���[�i�����o����
            AND ijm.journal_id = iaj.journal_id
            --OPM�����݌Ƀg�����U�N�V�������o����
            AND iaj.doc_id = itc.doc_id
            AND iaj.doc_line = itc.doc_line
            AND TRUNC(itc.trans_date)
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         ) ad_info
         ,ic_adjs_jnl                                         iaj                 --OPM�݌ɒ����W���[�i��
         ,ic_tran_cmp                                         itc                 --OPM�����݌Ƀg�����U�N�V����
         ,xxcmn_item_locations2_v                             xilv                --�ۊǏꏊ���VIEW2
         ,xxcmn_rcv_pay_mst                                   xrpm                --�󕥋敪�A�h�I���}�X�^
         ,xxcmn_lookup_values2_v                              xlvv                --�N�C�b�N�R�[�h
         ,sy_reas_cds_b                                       srcb                --���R�R�[�h�}�X�^
        ----------------------------------------------------------------------------------------
        --OPM�݌ɒ����W���[�i�����o����
        WHERE iaj.journal_id = ad_info.journal_id                                 --�W���[�i��ID
        AND iaj.trans_type = 'ADJI'                                               --�����^�C�v
        --OPM�����݌Ƀg�����U�N�V�������o����
        AND itc.doc_type = 'ADJI'                                                 --�����^�C�v
        AND itc.doc_id = iaj.doc_id                                               --����ID
        AND itc.doc_line = iaj.doc_line                                           --������הԍ�
        --�ۊǏꏊ���VIEW2���o����
        AND itc.location = xilv.segment1                                          --�ۊǑq�ɃR�[�h
        AND itc.trans_date
          BETWEEN xilv.date_from AND NVL(xilv.date_to,itc.trans_date)             --�K�p�J�n���E�I����
        --�󕥋敪�A�h�I���}�X�^���o����
        AND xrpm.doc_type = 'ADJI'                                                --�����^�C�v
        AND itc.reason_code = xrpm.reason_code                                    --���R�R�[�h
        AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪
-- del start 1.18
--        AND TO_CHAR(SIGN(itc.trans_qty)) = xrpm.rcv_pay_div                       --�󕥋敪
-- del end 1.18
        AND xrpm.reason_code = srcb.reason_code                                   --���R�R�[�h
        AND srcb.delete_mark = 0                                                  --�폜�}�[�N(���폜)
        --�N�C�b�N�R�[�h���o����
        AND xlvv.lookup_type =  gv_lookup_newdiv                                  --�Q�ƃ^�C�v(�V�敪)
        AND xrpm.new_div_invent = xlvv.lookup_code                                --�Q�ƃR�[�h
        AND itc.trans_date
          BETWEEN xlvv.start_date_active
          AND NVL(xlvv.end_date_active,itc.trans_date)                            --�K�p�J�n���E�I����
        ----------------------------------------------------------------------------------------
        GROUP BY 
          itc.doc_id                                                              --����ID
         ,itc.item_id                                                             --�i��ID
         ,itc.lot_id                                                              --���b�gID
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                                      --���t
         ,xrpm.new_div_invent                                                     --�V�敪
         ,ad_info.slip_no                                                         --�`�[No
         ,xlvv.description                                                        --����於��
         ,itc.whse_code                                                           --�q�ɃR�[�h
         ,xilv.whse_name                                                          --�q�ɖ�
         ,itc.location                                                            --�ۊǑq�ɃR�[�h
         ,xilv.description                                                        --�ۊǑq�ɖ�
         ,xilv.distribution_block                                                 --�u���b�N
         ,xrpm.rcv_pay_div                                                        --�󕥋敪
         ,ad_info.adji_type                                                       --�݌Ƀ^�C�v
         ,ad_info.other_name                                                      --����於
         ,ad_info.other_code                                                      --�����R�[�h
       ) slip
       ,xxcmn_item_categories2_v                               xicv1               --OPM�i�ڃJ�e�S���������VIEW(���i�敪)
       ,xxcmn_item_categories2_v                               xicv2               --OPM�i�ڃJ�e�S���������VIEW(�i�ڋ敪)
       ,xxcmn_lookup_values2_v                                 xlvv                --�N�C�b�N�R�[�h
       ,xxcmn_item_mst2_v                                      ximv                --OPM�i�ڏ��VIEW
       ,ic_lots_mst                                            ilm                 --OPM���b�g�}�X�^(�����p)
      --======================================================================================================
      --�J�e�S���Z�b�g�����i�敪�ł���i��
      WHERE slip.item_id = xicv1.item_id
      AND xicv1.category_set_name = gv_category_prod
      --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
      AND slip.item_id = xicv2.item_id
      AND xicv2.category_set_name = gv_category_item
      --�N�C�b�N�R�[�h���o����
      AND xlvv.lookup_type =  gv_lookup_newdiv                                    --�Q�ƃ^�C�v(�V�敪)
      AND slip.reason_code = xlvv.lookup_code                                     --�Q�ƃR�[�h
      AND TO_DATE(slip.standard_date,gv_fmt_ymd)
--mod start 1.3
--        BETWEEN TRUNC(xlvv.start_date_active)
--        AND NVL(TRUNC(xlvv.end_date_active),TO_DATE(slip.standard_date,gv_fmt_ymd))      --�K�p�J�n���E�I����
        BETWEEN xlvv.start_date_active
        AND NVL(xlvv.end_date_active,TO_DATE(slip.standard_date,gv_fmt_ymd))      --�K�p�J�n���E�I����
--mod end 1.3
      --OPM�i�ڏ��VIEW2���o����
      AND slip.item_id = ximv.item_id                                             --�i��ID
      AND TO_DATE(slip.standard_date,gv_fmt_ymd)
--mod start 1.3
--        BETWEEN TRUNC(ximv.start_date_active)
--        AND NVL(TRUNC(ximv.end_date_active),TO_DATE(slip.standard_date,gv_fmt_ymd))--�K�p�J�n���E�I����
        BETWEEN ximv.start_date_active
        AND NVL(ximv.end_date_active,TO_DATE(slip.standard_date,gv_fmt_ymd))--�K�p�J�n���E�I����
--mod end 1.3
      --OPM���b�g�}�X�^���o����
      AND slip.item_id = ilm.item_id
      AND slip.lot_id = ilm.lot_id
      --�p�����[�^�ɂ��i����(���i�敪)
      AND xicv1.segment1 = civ_prod_div
      --�p�����[�^�ɂ��i����(�i�ڋ敪)
      AND xicv2.segment1 = civ_item_div
      --�p�����[�^�ɂ��i����(���b�gNo)
      AND ( civ_lot_no_01 IS NULL
        AND civ_lot_no_02 IS NULL
        AND civ_lot_no_03 IS NULL
      OR civ_lot_no_01 = ilm.lot_no
      OR civ_lot_no_02 = ilm.lot_no
      OR civ_lot_no_03 = ilm.lot_no
      )
      --�p�����[�^�ɂ��i����(�����N����)
      AND ( civ_mnfctr_date_01 IS NULL
        AND civ_mnfctr_date_02 IS NULL
        AND civ_mnfctr_date_03 IS NULL
      OR civ_mnfctr_date_01 = ilm.attribute1
      OR civ_mnfctr_date_02 = ilm.attribute1
      OR civ_mnfctr_date_03 = ilm.attribute1
      )
      --�p�����[�^�ɂ��i����(�ŗL�L��)
      AND  ( civ_symbol IS NULL
      OR  civ_symbol = ilm.attribute2
      )
--mod start 1.13
--      --�p�����[�^�ɂ��i����(�����u���b�N)
--      AND ( civ_block_01 IS NULL
--        AND civ_block_02 IS NULL
--        AND civ_block_03 IS NULL
--      OR  civ_block_01 = slip.distribution_block
--      OR  civ_block_02 = slip.distribution_block
--      OR  civ_block_03 = slip.distribution_block
--      )
--      --�p�����[�^�ɂ��i����(�ۊǑq�ɁE�q��)
----mod start 1.3
----      AND ( civ_wh_code_01 IS NULL
----        AND civ_wh_code_02 IS NULL
----        AND civ_wh_code_03 IS NULL
----      OR (   civ_wh_loc_ctl = gv_wh_loc_ctl_loc --�ۊǑq�ɂ̏ꍇ
----        AND  civ_wh_code_01 = slip.location
----          OR civ_wh_code_02 = slip.location
----          OR civ_wh_code_03 = slip.location
----        )
----      OR (   civ_wh_loc_ctl = gv_wh_loc_ctl_wh --�q�ɂ̏ꍇ
----        AND  civ_wh_code_01 = slip.whse_code
----          OR civ_wh_code_02 = slip.whse_code
----          OR civ_wh_code_03 = slip.whse_code
----        )
----     )
--      AND ( NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
--        AND NVL(civ_wh_code_02,gv_nullvalue) = gv_nullvalue
--        AND NVL(civ_wh_code_03,gv_nullvalue) = gv_nullvalue
--      OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_loc
--        AND slip.location IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
--      OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_wh
--        AND  slip.whse_code IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03)
--        )
--      )
----mod end 1.3
      AND
      (
           NVL(civ_block_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_block_02,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_block_03,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
        --�p�����[�^�ɂ��i����(�����u���b�N)
        OR  slip.distribution_block IN (civ_block_01,civ_block_02,civ_block_03)
        --�p�����[�^�ɂ��i����(�ۊǑq��)
        OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_loc
          AND slip.location IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
        --�p�����[�^�ɂ��i����(�q��)
        OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_wh
          AND  slip.whse_code IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
      )
--mod end 1.13
--mod start 1.3
--      AND ( civ_item_code_01 IS NULL
--        AND civ_item_code_02 IS NULL
--        AND civ_item_code_03 IS NULL
--      OR  civ_item_code_01 = ximv.item_no
--      OR  civ_item_code_02 = ximv.item_no
--      OR  civ_item_code_03 = ximv.item_no
--      )
      --�p�����[�^�ɂ��i����(�i��)
      AND ( NVL(civ_item_code_01,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_item_code_02,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_item_code_03,gv_nullvalue) = gv_nullvalue
      OR  ximv.item_no IN (civ_item_code_01, civ_item_code_02, civ_item_code_03)
      )
--mod end 1.3
      --�p�����[�^�ɂ��i����(�V�敪)
--mod start 1.3
--      AND ( civ_reason_code_01 IS NULL
--        AND civ_reason_code_02 IS NULL
--        AND civ_reason_code_03 IS NULL
--      OR civ_reason_code_01 = slip.reason_code
--      OR civ_reason_code_02 = slip.reason_code
--      OR civ_reason_code_03 = slip.reason_code
--      )
      AND ( NVL(civ_reason_code_01,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_reason_code_02,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_reason_code_03,gv_nullvalue) = gv_nullvalue
      OR slip.reason_code IN (civ_reason_code_01, civ_reason_code_02, civ_reason_code_03)
      )
--mod end 1.3
      --�p�����[�^�ɂ��i����(���o�ɋ敪)
      AND ( civ_inout_ctl = gv_inout_ctl_all --���o�ɗ������w�肵���ꍇ
      OR    civ_inout_ctl = gv_inout_ctl_in  --���ɂ��w�肵���ꍇ
        AND slip.rcv_pay_div = gv_rcvdiv_rcv   --�󕥋敪�͎���̂ݑΏ�
      OR    civ_inout_ctl = gv_inout_ctl_out --�o�ɂ��w�肵���ꍇ
        AND slip.rcv_pay_div = gv_rcvdiv_pay   --�󕥋敪�͕��o�̂ݑΏ�
      )
      ORDER BY slip.location
              ,TO_NUMBER(ximv.item_no)
              ,slip.standard_date
              ,slip.reason_code
              ,slip.slip_no
      ;*/
      
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ������p�J�[�\��
    CURSOR cur_main_data1(
      civ_ymd_from VARCHAR2        --�N����_FROM
     ,civ_ymd_to VARCHAR2          --�N����_TO
     ,civ_base_date VARCHAR2       --������^�����
     ,civ_inout_ctl VARCHAR2       --���o�ɋ敪
     ,civ_prod_div VARCHAR2        --���i�敪
     ,civ_unit_ctl VARCHAR2        --�P�ʋ敪
     ,civ_wh_loc_ctl VARCHAR2      --�q��/�ۊǑq�ɑI���敪
     ,civ_wh_code_01 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h1
     ,civ_wh_code_02 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h2
     ,civ_wh_code_03 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h3
     ,civ_block_01 VARCHAR2        --�u���b�N1
     ,civ_block_02 VARCHAR2        --�u���b�N2
     ,civ_block_03 VARCHAR2        --�u���b�N3
     ,civ_item_div VARCHAR2        --�i�ڋ敪
     ,civ_item_code_01 VARCHAR2    --�i�ڃR�[�h1
     ,civ_item_code_02 VARCHAR2    --�i�ڃR�[�h2
     ,civ_item_code_03 VARCHAR2    --�i�ڃR�[�h3
     ,civ_lot_no_01 VARCHAR2       --���b�gNo1
     ,civ_lot_no_02 VARCHAR2       --���b�gNo2
     ,civ_lot_no_03 VARCHAR2       --���b�gNo3
     ,civ_mnfctr_date_01 VARCHAR2  --�����N����1
     ,civ_mnfctr_date_02 VARCHAR2  --�����N����2
     ,civ_mnfctr_date_03 VARCHAR2  --�����N����3
     ,civ_reason_code_01 VARCHAR2  --���R�R�[�h1
     ,civ_reason_code_02 VARCHAR2  --���R�R�[�h2
     ,civ_reason_code_03 VARCHAR2  --���R�R�[�h3
     ,civ_symbol VARCHAR2          --�ŗL�L��
    )
    IS 
      --======================================================================================================
      SELECT
        slip.whse_code                                        whse_code           --�q�ɃR�[�h
       ,slip.whse_name                                        whse_name           --�q�ɖ���
       ,slip.location                                         strg_wh_code        --�ۊǑq�ɃR�[�h
       ,slip.description                                      strg_wh_name        --�ۊǑq�ɖ���
       ,iimb.item_no                                          item_code           --�i�ڃR�[�h
       ,ximb.item_short_name                                  item_name           --�i�ږ���
       ,slip.standard_date                                    standard_date       --���t
       ,slip.reason_code                                      reason_code         --���R�R�[�h
       ,xlvv.meaning                                          reason_name         --���R�R�[�h����
       ,slip.slip_no                                          slip_no             --�`�[�ԍ�
       ,slip.out_date                                         out_date            --�o�ɓ�
       ,slip.in_date                                          in_date             --����
       ,slip.jrsd_code                                        jrsd_code           --�Ǌ����_�R�[�h
       ,slip.jrsd_name                                        jrsd_name           --�Ǌ����_����
       ,slip.other_code                                       other_code          --�����R�[�h
       ,CASE slip.territory
          WHEN gv_trtry_ad THEN
            NVL(slip.other_name,xlvv.meaning)
          ELSE slip.other_name
        END                                                   other_name          --����於
       ,DECODE(iimb.lot_ctl
              ,gn_lotctl_yes,ilm.lot_no
              ,NULL)                                          lot_no              --���b�gNo
       ,DECODE(iimb.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute1,1,10)
              ,NULL)                                          mnfctr_date         --�����N����
       ,DECODE(iimb.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute3,1,10)
              ,NULL)                                          limit_date          --�ܖ�����
       ,DECODE(iimb.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute2,1,6)
              ,NULL)                                          symbol              --�ŗL�L��
--mod start 2.1
--       ,CASE slip.territory
--          WHEN gv_trtry_po THEN ximv.item_um                                        --�����F�P��
--          WHEN gv_trtry_mv THEN ximv.item_um                                        --�ړ��F�P��
--          WHEN gv_trtry_sh THEN ximv.conv_unit                                      --�o�ׁF���o�Ɋ��Z�P��
--          WHEN gv_trtry_rt THEN ximv.conv_unit                                      --�q�֕ԕi�F���o�Ɋ��Z�P��
--          WHEN gv_trtry_mf THEN ximv.item_um                                        --���Y�F�P��
--          WHEN gv_trtry_ad THEN ximv.item_um                                        --�݌ɒ����F�P��
--          ELSE NULL
--        END                                                   unit                --�P��
       ,DECODE(civ_unit_ctl
              ,gv_unitctl_qty ,iimb.item_um
              ,gv_unitctl_case,iimb.attribute24
              ,NULL)                                          unit                --�P��
--mod end 2.1
       ,iimb.attribute11                                      num_of_cases        --�P�[�X���萔
       ,NVL(slip.in_qty,0)                                    in_qty              --���ɐ�
-- mod start 1.18
--mod start 1.5
       ,NVL(slip.out_qty,0)                                   out_qty             --�o�ɐ�
--       ,ABS(NVL(slip.out_qty,0))                                   out_qty             --�o�ɐ�
--mod end 1.5
-- mod end 1.18
       ,mct2.description                                      item_div_name       --�i�ڋ敪����
      FROM (
      --======================================================================================================
        ------------------------------
        -- 1.�������я��
        ------------------------------
-- mod start 1.25
        --SELECT /*+ leading(pha pla rsl itp iimb gic1 mcb1 gic2 mcb2 rt xrart xrpm pv xv mil iwm) use_nl(pha pla rsl itp iimb gic1 mcb1 gic2 mcb2 rt xrart xrpm pv xv mil iwm) */
        SELECT /*+ leading(pha pla rsl rt itp gic1 mcb1 gic2 mcb2) use_nl(pha pla rsl rt itp gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
          gv_trtry_po                                         territory           --�̈�(����)
         ,iimb.item_id                                        item_id             --�i��ID
         ,itp.lot_id                                          lot_id              --���b�gID
         ,pha.attribute4                                      standard_date       --���t
         ,xrpm.new_div_invent                                 reason_code         --�V�敪
         ,pha.segment1                                        slip_no             --�`�[No
         ,pha.attribute4                                      out_date            --�o�ɓ�
         ,pha.attribute4                                      in_date             --����
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,pv.segment1                                         other_code          --�����R�[�h
         ,pv.vendor_name                                      other_name          --����於��
         ,SUM(NVL(pla.quantity,0))                            in_qty              --���ɐ�
         ,0                                                   out_qty             --�o�ɐ�
         ,itp.whse_code                                       whse_code           --�q�ɃR�[�h
         ,iwm.whse_name                                       whse_name           --�q�ɖ�
         ,itp.location                                        location            --�ۊǑq�ɃR�[�h
         ,mil.description                                     description         --�ۊǑq�ɖ�
         ,mil.attribute6                                      distribution_block  --�u���b�N
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --�󕥋敪
        FROM
        ----------------------------------------------------------------------------------------
          po_headers_all                                      pha                 --�����w�b�_
         ,po_lines_all                                        pla                 --��������
         ,rcv_shipment_lines                                  rsl                 --�������
         ,rcv_transactions                                    rt                  --������
         ,ic_lots_mst                                         ilm                 --OPM���b�g�}�X�^(�����p)
         ,xxpo_rcv_and_rtn_txns                               xrart               --����ԕi����
         ,po_vendors                                          pv
         ,xxcmn_vendors                                       xv
         ,ic_whse_mst                                         iwm
         ,mtl_item_locations                                  mil
         ,ic_item_mst_b                                       iimb
         ,ic_tran_pnd                                         itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
         ,xxcmn_rcv_pay_mst                                   xrpm                --����敪�A�h�I���}�X�^
         ,mtl_categories_b                                    mcb1
         ,gmi_item_categories                                 gic1
         ,mtl_categories_b                                    mcb2
         ,gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --�����w�b�_���o����
        WHERE pha.attribute1 IN (gv_po_sts_rcv, gv_po_sts_qty_deci, gv_po_sts_price_deci)--�X�e�[�^�X
        AND pha.attribute4 BETWEEN civ_ymd_from AND civ_ymd_to                    --�[����
        --�������ג��o����
        AND pha.po_header_id = pla.po_header_id                                   --�����w�b�_ID
        AND pla.attribute13 = gv_po_flg_qty                                       --���ʊm��t���O
        --������ג��o����
        AND rsl.po_header_id = pha.po_header_id                                   --�����w�b�_ID
        AND rsl.po_line_id = pla.po_line_id                                       --��������ID
        --���������o����
        AND rsl.shipment_line_id = rt.shipment_line_id                            --�������ID
        --����ԕi���ђ��o����
        AND pha.segment1 = xrart.source_document_number                           --�������ԍ�
        AND pla.line_num = xrart.source_document_line_num                         --���������הԍ�
        AND xrart.txns_type = gv_txns_type_rcv                                    --���ы敪
        --�ۊǏꏊ�}�X�^VIEW���o����
        AND pha.vendor_id = pv.vendor_id                                         --�d����ID
        AND xv.start_date_active <= TO_DATE(civ_ymd_from,gv_fmt_ymd)
        AND xv.end_date_active >= TO_DATE(civ_ymd_from,gv_fmt_ymd)
        AND itp.doc_type = 'PORC'                                                 --�����^�C�v
        AND rsl.shipment_header_id = itp.doc_id                                   --����ID
        AND rsl.line_num = itp.doc_line                                           --������הԍ�
        AND rt.transaction_id = itp.line_id                                       --���C��ID
        AND iimb.item_id = itp.item_id                                            --�i��ID
        AND ilm.lot_id = itp.lot_id                                               --���b�gID
        AND mil.segment1 = itp.location                                          --�ۊǑq�ɃR�[�h
        AND itp.completed_ind = gv_tran_cmp                                       --�����t���O
        --�󕥋敪�}�X�^�A�h�I�����o����
        AND xrpm.doc_type = 'PORC'                                                --�����^�C�v
        AND xrpm.source_document_code = 'PO'                                      --�\�[�X����
        AND xrpm.transaction_type = rt.transaction_type                           --PO����^�C�v
        AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪
        AND iwm.mtl_organization_id = mil.organization_id
        AND pv.vendor_id = xv.vendor_id
        AND iimb.inactive_ind       <> '1'
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
-- mod start 1.25
        --AND iimb.item_id = gic1.item_id
        AND itp.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        --AND iimb.item_id = gic2.item_id
        AND itp.item_id = gic2.item_id
-- mod end 1.25
        AND gic2.category_set_id   = cn_item_class_id
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        AND ilm.item_id            = itp.item_id
        ----------------------------------------------------------------------------------------
        GROUP BY
          iimb.item_id                                                            --�i��ID
         ,itp.lot_id                                                              --���b�gID
         ,pha.attribute4                                                          --���t
         ,xrpm.new_div_invent                                                     --�V�敪
         ,pha.segment1                                                            --�`�[No
         ,pha.attribute4                                                          --�o�ɓ�/����
         ,pv.segment1
         ,pv.vendor_name
         ,itp.whse_code                                                           --�q�ɃR�[�h
         ,iwm.whse_name
         ,itp.location                                                            --�ۊǑq�ɃR�[�h
         ,mil.description
         ,mil.attribute6
         ,xrpm.rcv_pay_div                                                        --�󕥋敪
         ,xrpm.transaction_type                                                   --PO����^�C�v
        UNION ALL
        ------------------------------
        -- 2.�ړ����я��
        ------------------------------
        SELECT
          gv_trtry_mv                                         territory           --�̈�(�ړ�)
         ,iimb.item_id                                        item_id             --�i��ID
         ,xm.lot_id                                           lot_id              --���b�gID
         ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)          standard_date       --���t
         ,xm.new_div_invent                                   reason_code         --�V�敪
         ,xm.mov_num                                          slip_no             --�`�[No
         ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)             out_date            --�o�ɓ�
         ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)          in_date             --���ɓ�
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,xm.other_code                                       other_code          --�����R�[�h
         ,mil2.description                                    other_name          --����於��
         ,CASE xm.record_type
            WHEN gv_rectype_in THEN
              SUM(NVL(xm.trans_qty,0))
            ELSE 0 END                                        in_qty              --���ɐ�
         ,CASE xm.record_type
            WHEN gv_rectype_out THEN
              ABS(SUM(NVL(xm.trans_qty,0)) * -1)
            ELSE 0 END                                        out_qty             --�o�ɐ�
         ,CASE xm.mov_type --�ړ��^�C�v
            WHEN gv_movetype_yes THEN xm.whse_code --�ϑ�����
            WHEN gv_movetype_no THEN xm.whse_code --�ϑ��Ȃ�
            ELSE NULL
          END                                                 whse_code           --�q�ɃR�[�h
         ,iwm1.whse_name                                      whse_name           --�q�ɖ�
         ,CASE xm.mov_type --�ړ��^�C�v
            WHEN gv_movetype_yes THEN xm.location --�ϑ�����
            WHEN gv_movetype_no THEN xm.location --�ϑ��Ȃ�
            ELSE NULL
          END                                                 location            --�ۊǑq�ɃR�[�h
         ,mil1.description                                    description         --�ۊǑq�ɖ�
         ,mil1.attribute6                                     distribution_block  --�u���b�N
         ,xm.rcv_pay_div                                      rcv_pay_div         --�󕥋敪
       FROM
        (
-------------------------------------------------------------------------------------------------------------------
         --�ϑ�����(�o�Ɏ���)
-- mod start 1.25
         --SELECT /*+ leading(xmrih xmril xmld mil itp ixm gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld mil itp ixm gic1 mcb1 gic2 mcb2) */
         SELECT /*+ leading(xmrih xmril xmld ixm itp gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ixm itp gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_out                                  record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_ship_date                          arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          other_id                --�����ID(���ɐ�ID)
          ,xmrih.ship_to_locat_code                        other_code              --�����(���ɐ�ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil.segment1                                    segment1                --�ۊǏꏊ�R�[�h
          ,itp.doc_type                                    doc_type                --�����^�C�v
          ,itp.trans_qty                                   trans_qty               --����
          ,itp.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itp.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_pay                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_pay                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers      xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,xxinv_mov_req_instr_lines        xmril               --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details            xmld                --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations               mil
          ,ic_xfer_mst                      ixm                 --OPM�݌ɓ]���}�X�^
          ,ic_tran_pnd                      itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
          ,gmi_item_categories              gic1
          ,mtl_categories_b                 mcb1
          ,gmi_item_categories              gic2
          ,mtl_categories_b                 mcb2
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         AND xmrih.mov_type = gv_movetype_yes
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_out                               --���R�[�h�^�C�v
         AND xmrih.shipped_locat_id = mil.inventory_location_id                   --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ixm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ixm.attribute1                                   --�����\�[�XID
-- mod start 1.25
         AND itp.doc_type = 'XFER'                                                --�����^�C�v
         AND xmrih.actual_arrival_date                                            --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND gic1.item_id  = itp.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div
         AND gic2.item_id = itp.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND ixm.transfer_id = itp.doc_id                                         --����ID
         AND xmril.item_id = itp.item_id                                          --�i��ID
         AND xmld.lot_id (+) = itp.lot_id
         AND mil.segment1 = itp.location                                          --�ۊǑq�ɃR�[�h
         AND itp.completed_ind = gv_tran_cmp                                      --�����t���O
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT 1
             FROM ic_tran_pnd itp2                                                --OPM�ۗ��݌Ƀg�����U�N�V����
             WHERE itp.doc_id = itp2.doc_id                                       --����ID
             AND   itp.whse_code = itp2.whse_code                                 --�q�ɃR�[�h
             AND   itp.trans_id <> itp2.trans_id
             AND   ROWNUM   = 1
             )
         UNION ALL -- �ϑ�����(���Ɏ���)
-- mod start 1.25
         --SELECT /*+ leading(xmrih xmril xmld mil itp ixm gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld mil itp ixm gic1 mcb1 gic2 mcb2) */
         SELECT /*+ leading(xmrih xmril xmld ixm itp gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ixm itp gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_in                                   record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_arrival_date                       arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.ship_to_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_ship_date                          arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          other_id                --�����ID(���ɐ�ID)
          ,xmrih.shipped_locat_code                        other_code              --�����(���ɐ�ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itp.doc_type                                    doc_type                --�����^�C�v
          ,itp.trans_qty                                   trans_qty               --����
          ,itp.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itp.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_rcv                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_rcv                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers      xmrih
          ,xxinv_mov_req_instr_lines        xmril               --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details            xmld                --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations               mil
          ,ic_xfer_mst                      ixm                 --OPM�݌ɓ]���}�X�^
          ,ic_tran_pnd                      itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
          ,gmi_item_categories              gic1
          ,mtl_categories_b                 mcb1
          ,gmi_item_categories              gic2
          ,mtl_categories_b                 mcb2
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         AND xmrih.mov_type = gv_movetype_yes
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_in                            --���R�[�h�^�C�v
         AND xmrih.actual_arrival_date                                              --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND xmrih.ship_to_locat_id = mil.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         AND TO_CHAR(xmril.mov_line_id) = ixm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND itp.doc_type = 'XFER'                                                --�����^�C�v
         AND gic1.item_id = itp.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div
         AND gic2.item_id  = itp.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND ixm.transfer_id = itp.doc_id                                         --����ID
         AND xmril.item_id = itp.item_id                                          --�i��ID
         AND xmld.lot_id (+) = itp.lot_id
         AND mil.segment1 = itp.location                                         --�ۊǑq�ɃR�[�h
         AND itp.completed_ind = gv_tran_cmp                                      --�����t���O
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT 1
             FROM ic_tran_pnd itp2                                                --OPM�ۗ��݌Ƀg�����U�N�V����
             WHERE itp.doc_id = itp2.doc_id                                       --����ID
             AND   itp.whse_code = itp2.whse_code                                 --�q�ɃR�[�h
             AND   itp.trans_id <> itp2.trans_id
             AND   ROWNUM   = 1
             )
         UNION ALL
         --�ϑ�����(ADJI)(�o�Ɏ���)
-- mod start 1.25
         --SELECT
         SELECT /*+ leading(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_out                                  record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_ship_date                          arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          other_id                --�����ID(���ɐ�ID)
          ,xmrih.ship_to_locat_code                        other_code              --�����(���ɐ�ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil3.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itc.doc_type                                    doc_type                --�����^�C�v
          ,itc.trans_qty                                   trans_qty               --����
          ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itc.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_pay                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_pay                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers                     xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,mtl_item_locations                              mil1
          ,ic_whse_mst                                     iwm1
          ,mtl_item_locations                              mil2
          ,ic_whse_mst                                     iwm2
          ,xxinv_mov_req_instr_lines                       xmril               --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details                           xmld                --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations                              mil3
          ,ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
          ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
          ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
          ,gmi_item_categories                             gic1
          ,mtl_categories_b                                mcb1
          ,gmi_item_categories                             gic2
          ,mtl_categories_b                                mcb2
         --�ړ��˗�/�w������(�A�h�I��)���o����
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         AND xmrih.mov_type = gv_movetype_yes                                --�ړ��^�C�v(�ϑ�����)
          --OPM�ۊǏꏊ���VIEW2(�ۊǑq��)���o����
         AND iwm1.mtl_organization_id = mil1.organization_id
         AND iwm2.mtl_organization_id = mil2.organization_id
         AND xmrih.shipped_locat_id = mil1.inventory_location_id                        --�ۊǑq��ID
         AND xmrih.ship_to_locat_id = mil2.inventory_location_id                        --�ۊǑq��ID
         AND iwm1.whse_code <> iwm2.whse_code                      --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_out                            --���R�[�h�^�C�v
         AND xmrih.actual_arrival_date                                              --���Ɏ��ѓ�
               BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
               AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND xmrih.shipped_locat_id = mil3.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ijm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND mil3.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         AND itc.doc_type = 'ADJI'                                                --�����^�C�v
         AND gic1.item_id = itc.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div                                --�i��ID
         AND gic2.item_id = itc.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND xmld.lot_id (+) = itc.lot_id  
         UNION ALL
         --�ϑ�����(ADJI) (���Ɏ���)
-- mod start 1.25
         --SELECT
         SELECT /*+ leading(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_in                                   record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_arrival_date                       arvl_ship_date          --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          locat_id                --�ۊǑq��ID(���Ɍ�ID)
          ,xmrih.ship_to_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(���Ɍ��ۊǏꏊ)
          ,xmrih.actual_ship_date                          arvl_ship_date2          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          other_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        other_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil3.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itc.doc_type                                    doc_type                --�����^�C�v
          ,itc.trans_qty                                   trans_qty               --����
          ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itc.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_rcv                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_rcv                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers                     xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,mtl_item_locations                              mil1
          ,ic_whse_mst                                     iwm1
          ,mtl_item_locations                              mil2
          ,ic_whse_mst                                     iwm2
          ,xxinv_mov_req_instr_lines                       xmril               --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details                           xmld                --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations                              mil3
          ,ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
          ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
          ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
          ,gmi_item_categories                             gic1
          ,mtl_categories_b                                mcb1
          ,gmi_item_categories                             gic2
          ,mtl_categories_b                                mcb2
         --�ړ��˗�/�w������(�A�h�I��)���o����
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         AND xmrih.mov_type = gv_movetype_yes                                --�ړ��^�C�v(�ϑ�����)
         AND iwm1.mtl_organization_id = mil1.organization_id
         AND iwm2.mtl_organization_id = mil2.organization_id
            AND xmrih.shipped_locat_id = mil1.inventory_location_id                        --�ۊǑq��ID
            AND xmrih.ship_to_locat_id = mil2.inventory_location_id                        --�ۊǑq��ID
            AND iwm1.whse_code <> iwm2.whse_code                      --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_in                            --���R�[�h�^�C�v
         AND xmrih.actual_arrival_date                                              --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND xmrih.ship_to_locat_id = mil3.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ijm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND mil3.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         AND itc.doc_type = 'ADJI'                                                --�����^�C�v
         AND gic1.item_id = itc.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div                                 --�i��ID
         AND gic2.item_id = itc.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND ( xmld.lot_id IS NOT NULL 
           AND xmld.lot_id = itc.lot_id                                           --���b�gID
         OR    xmld.lot_id IS NULL
         )
-------------------------------------------------------------------------------------------------------------------
         UNION ALL
         --�ϑ��Ȃ� (�o�Ɏ���)
-- mod start 1.25
         --SELECT /*+ leading(xmrih xmril xmld mil itc ija ijm gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld mil itc ija ijm gic1 mcb1 gic2 mcb2) */
         SELECT /*+ leading(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_out                                  record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_ship_date                          arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          other_id                --�����ID(���ɐ�ID)
          ,xmrih.ship_to_locat_code                        other_code              --�����(���ɐ�ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itc.doc_type                                    doc_type                --�����^�C�v
          ,itc.trans_qty                                   trans_qty               --����
          ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itc.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_pay                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_pay                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers      xmrih                   --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,xxinv_mov_req_instr_lines        xmril                   --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details            xmld                    --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations               mil
          ,ic_jrnl_mst                      ijm                     --OPM�W���[�i���}�X�^
          ,ic_adjs_jnl                      iaj                     --OPM�݌ɒ����W���[�i��
          ,ic_tran_cmp                      itc                     --OPM�����݌Ƀg�����U�N�V����
          ,gmi_item_categories              gic1
          ,mtl_categories_b                 mcb1
          ,gmi_item_categories              gic2
          ,mtl_categories_b                 mcb2
         WHERE xmrih.actual_ship_date = xmrih.actual_arrival_date                 --�o�׎��ѓ������Ɏ��ѓ�
         AND  xmrih.mov_type = gv_movetype_no                                 --�ړ��^�C�v(�ϑ��Ȃ�)
         AND xmrih.mov_hdr_id = xmril.mov_hdr_id                                  --�ړ��w�b�_ID
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_out                            --���R�[�h�^�C�v
         AND xmrih.shipped_locat_id = mil.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ijm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND mil.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         AND itc.doc_type IN ('TRNI','ADJI')                                      --�����^�C�v
         AND gic1.item_id = itc.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div                                 --�i��ID
         AND gic2.item_id = itc.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND xmrih.actual_arrival_date                                              --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND xmld.lot_id (+)  = itc.lot_id
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT 1
             FROM ic_tran_cmp itc2                                                --OPM�����݌Ƀg�����U�N�V����
             WHERE itc.doc_id = itc2.doc_id                                       --����ID
             AND   itc.whse_code = itc2.whse_code                                 --�q�ɃR�[�h
             AND   itc.trans_id <> itc2.trans_id
             AND   ROWNUM = 1
             )
         UNION ALL
         --�ϑ��Ȃ� (���Ɏ���)
-- mod start 1.25
         --SELECT /*+ leading(xmrih xmril xmld mil itc ija ijm gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld mil itc ija ijm gic1 mcb1 gic2 mcb2) */
         SELECT /*+ leading(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_in                                   record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_arrival_date                       arvl_ship_date          --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          locat_id                --�ۊǑq��ID(���Ɍ�ID)
          ,xmrih.ship_to_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(���Ɍ��ۊǏꏊ)
          ,xmrih.actual_ship_date                          arvl_ship_date2          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          other_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        other_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itc.doc_type                                    doc_type                --�����^�C�v
          ,itc.trans_qty                                   trans_qty               --����
          ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itc.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_rcv                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_rcv                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers                     xmrih                   --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,xxinv_mov_req_instr_lines                       xmril                   --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details                           xmld                    --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations        mil
          ,ic_jrnl_mst                                     ijm                     --OPM�W���[�i���}�X�^
          ,ic_adjs_jnl                                     iaj                     --OPM�݌ɒ����W���[�i��
          ,ic_tran_cmp                                     itc                     --OPM�����݌Ƀg�����U�N�V����
          ,gmi_item_categories              gic1
          ,mtl_categories_b                 mcb1
          ,gmi_item_categories              gic2
          ,mtl_categories_b                 mcb2
         WHERE xmrih.actual_ship_date = xmrih.actual_arrival_date                 --�o�׎��ѓ������Ɏ��ѓ�
         AND  xmrih.mov_type = gv_movetype_no                                 --�ړ��^�C�v(�ϑ��Ȃ�)
         AND xmrih.mov_hdr_id = xmril.mov_hdr_id                                  --�ړ��w�b�_ID
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_in                            --���R�[�h�^�C�v
         AND xmrih.ship_to_locat_id = mil.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ijm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND mil.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         AND itc.doc_type IN ('TRNI','ADJI')                                      --�����^�C�v
         AND gic1.item_id = itc.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div                                 --�i��ID
         AND gic2.item_id = itc.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND xmrih.actual_arrival_date                                              --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND xmld.lot_id (+) = itc.lot_id
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT 1
             FROM ic_tran_cmp itc2                                                --OPM�����݌Ƀg�����U�N�V����
             WHERE itc.doc_id = itc2.doc_id                                       --����ID
             AND   itc.whse_code = itc2.whse_code                                 --�q�ɃR�[�h
             AND   itc.trans_id <> itc2.trans_id
             AND   ROWNUM = 1
             )
         )                          xm                  --�ړ����
         ,ic_item_mst_b             iimb
         ,xxcmn_item_mst_b          ximb
         ,mtl_item_locations        mil1
         ,ic_whse_mst               iwm1
         ,mtl_item_locations        mil2
         ,xxcmn_rcv_pay_mst         xrpm                --����敪�A�h�I���}�X�^
       WHERE xm.comp_actual_flg = gv_cmp_actl_yes                                --���ьv��t���O
       AND xm.delete_flg = gv_delete_no                                          --�폜�t���O
       AND xm.item_id = iimb.item_id                                             --�i��ID
       AND ximb.item_id = iimb.item_id
       AND xm.arvl_ship_date 
           BETWEEN ximb.start_date_active AND ximb.end_date_active                 --���ѓ�
       AND xm.locat_id = mil1.inventory_location_id                              --�ۊǑq��ID
       AND xm.other_id = mil2.inventory_location_id                             --�ۊǑq��ID(�����)
       AND xrpm.doc_type =xm.doc_type                                            --�����^�C�v
       AND TO_CHAR(SIGN(xm.trans_qty)) = xrpm.rcv_pay_div                        --�󕥋敪
       AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪
       AND xrpm.new_div_invent IN (gv_newdiv_pay,gv_newdiv_rcv)
         AND iwm1.mtl_organization_id = mil1.organization_id
       GROUP BY 
         iimb.item_id                                                            --�i��ID
        ,xm.lot_id                                                               --���b�gID
        ,xm.new_div_invent                                                       --�V�敪
        ,xm.mov_num                                                              --�`�[No
        ,mil1.description                                                        --�ۊǑq�ɖ�
        ,xm.mov_type                                                             --�ړ��^�C�v
        ,xm.whse_code                                                            --�ۗ�.�q�ɃR�[�h
        ,xm.location                                                             --�ۗ�.�ۊǑq�ɃR�[�h
        ,xm.whse_code                                                            --����.�q�ɃR�[�h
        ,xm.location                                                             --����.�ۊǑq�ɃR�[�h
        ,iwm1.whse_name                                                          --�q�ɖ�
        ,mil1.attribute6                                                 --�u���b�N
        ,xm.rcv_pay_div                                                          --�󕥋敪
        ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)
        ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)
        ,TO_CHAR(xm.arvl_ship_date,gv_fmt_ymd)
        ,xm.other_code
        ,mil2.description
        ,iimb.lot_ctl
        ,xm.record_type
       UNION ALL
       ------------------------------
       -- 3.�o��/�L���o�׎��я��
       ------------------------------
       SELECT
          gv_trtry_sh                                         territory           --�̈�(�o��)
         ,sh_info.item_id                                     item_id             --�i��ID
         ,sh_info.lot_id                                      lot_id              --���b�gID
         ,TO_CHAR(sh_info.arrival_date,gv_fmt_ymd)          standard_date       --���t
         ,sh_info.new_div_invent                              reason_code         --�V�敪
         ,sh_info.request_no                                  slip_no             --�`�[No
         ,TO_CHAR(sh_info.shipped_date,gv_fmt_ymd)          out_date            --�o�ɓ�
         ,TO_CHAR(sh_info.arrival_date,gv_fmt_ymd)          in_date             --����
         ,sh_info.head_sales_branch                           jrsd_code           --�Ǌ����_�R�[�h
         ,CASE
            WHEN hca.customer_class_code = '10'
              THEN xp.party_name
              ELSE xp.party_short_name
          END                                                 jrsd_name           --�Ǌ����_��
         ,sh_info.deliver_to                                  other_code          --�����R�[�h
         ,sh_info.party_site_full_name                        other_name          --����於��
         ,CASE sh_info.rcv_pay_div--�󕥋敪
            WHEN gv_rcvdiv_rcv THEN sh_info.trans_qty_sum
            ELSE 0
          END                                                 in_qty              --���ɐ�
         ,CASE sh_info.rcv_pay_div--�󕥋敪
            WHEN gv_rcvdiv_pay THEN 
              CASE
                WHEN (sh_info.new_div_invent = '104' AND sh_info.order_category_code = 'RETURN') THEN
                  ABS(sh_info.trans_qty_sum) * -1
                ELSE
                  ABS(sh_info.trans_qty_sum)
              END
            ELSE 0
          END                                                 out_qty             --�o�ɐ�
         ,sh_info.whse_code                                   whse_code           --�q�ɃR�[�h
         ,sh_info.whse_name                                   whse_name           --�q�ɖ�
         ,sh_info.location                                    location            --�ۊǑq�ɃR�[�h
         ,sh_info.description                                 description         --�ۊǑq�ɖ�
         ,sh_info.distribution_block                          distribution_block  --�u���b�N
         ,sh_info.rcv_pay_div                                 rcv_pay_div         --�󕥋敪
        ----------------------------------------------------------------------------------------
        FROM ( --OMSO�֘A���
-- mod start 1.25
-- 2008/11/28 H.Itou add Start �{�ԏ�Q#227
--          SELECT
--          SELECT /*+ leading(xoha ooha otta xola rsl itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) use_nl(xoha ooha otta xola rsl itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) */
          SELECT /*+ leading(xoha ooha otta xola wdd itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) use_nl(xoha ooha otta xola wdd itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) */
-- 2008/11/28 H.Itou add End
-- mod end 1.25
            itp.doc_type                                  doc_type            --�����^�C�v
           ,itp.item_id                                   item_id             --�i��ID
           ,itp.whse_code                                 whse_code           --�q�ɃR�[�h
           ,iwm.whse_name                                 whse_name           --�q�ɖ�
           ,itp.location                                  location            --�ۊǑq�ɃR�[�h
           ,mil.description                               description         --�ۊǑq�ɖ�
           ,mil.inventory_location_id                     inventory_location_id   --�ۊǑq��ID
           ,itp.lot_id                                    lot_id              --���b�gID
           ,itp.doc_id                                    doc_id              --����ID
           ,itp.doc_line                                  doc_line            --������הԍ�
           ,ooha.header_id                                header_id           --�󒍃w�b�_ID
           ,ooha.order_type_id                            order_type_id       --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                              rcv_pay_div         --�󕥋敪
           ,xrpm.new_div_invent                           new_div_invent      --�V�敪
           ,SUM(itp.trans_qty)                            trans_qty_sum       --���ʍ��v
           ,mil.attribute6                                distribution_block  --�u���b�N
           ,xoha.head_sales_branch                        head_sales_branch
           ,xoha.deliver_to_id                            deliver_to_id
           ,DECODE(xoha.req_status,gv_recsts_shipped,xoha.result_deliver_to
                                  ,gv_recsts_shipped2,xoha.vendor_site_code
            ) deliver_to
           ,xoha.arrival_date                             arrival_date
           ,xoha.shipped_date                             shipped_date
           ,xoha.request_no                               request_no
           ,DECODE(xoha.req_status,gv_recsts_shipped,hps.party_site_name
                                  ,gv_recsts_shipped2,xvsa.vendor_site_name
            ) party_site_full_name
           ,otta.order_category_code                      order_category_code
          FROM
           xxwsh_order_headers_all                        xoha                --�󒍃w�b�_(�A�h�I��)
           ,hz_party_sites                                hps
           ,xxcmn_vendor_sites_all                        xvsa
           ,xxwsh_order_lines_all                         xola                --�󒍖���(�A�h�I��)
           ,oe_transaction_types_all                      otta                --�󒍃^�C�v
           ,xxcmn_rcv_pay_mst                             xrpm                --����敪�A�h�I���}�X�^
           ,ic_item_mst_b                                 iimb
           ,xxcmn_item_mst_b                              ximb
           ,ic_item_mst_b                                 iimb2
           ,xxcmn_item_mst_b                              ximb2
           ,gmi_item_categories                           gic1
           ,mtl_categories_b                              mcb1
           ,gmi_item_categories                           gic2
           ,mtl_categories_b                              mcb2
           ,gmi_item_categories                           gic3
           ,mtl_categories_b                              mcb3
           ,ic_whse_mst                                   iwm
           ,mtl_item_locations                            mil
           ,ic_tran_pnd                                   itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
           ,wsh_delivery_details                          wdd                 --�o�ה�������
           ,oe_order_headers_all                          ooha                --�󒍃w�b�_
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          WHERE ooha.header_id = xoha.header_id                                --�󒍃w�b�_ID
          WHERE 
-- 2008/11/28 H.Itou del End
-- 2008/11/28 H.Itou add Start �{�ԏ�Q#227
                 wdd.delivery_detail_id  = itp.line_detail_id
          AND    wdd.source_header_id    = xoha.header_id
          AND    wdd.source_line_id      = xola.line_id
          AND    xoha.header_id          = ooha.header_id
          AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/28 H.Itou add End
          AND itp.doc_type = 'OMSO'
          AND itp.completed_ind = gv_tran_cmp                                 --�����t���O
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND itp.line_id = wdd.source_line_id                                --�\�[�X����ID
--          AND wdd.org_id = ooha.org_id                                        --�g�DID
--          AND wdd.source_header_id = ooha.header_id                           --�󒍃w�b�_ID
-- 2008/11/28 H.Itou del End
          AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --�X�e�[�^�X
          AND xoha.actual_confirm_class = gv_confirm_yes                            --���ьv��敪
          AND xoha.latest_external_flag = gv_latest_yes                             --�ŐV�t���O
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND xoha.order_header_id = xola.order_header_id                         --�󒍃A�h�I���w�b�_ID
-- 2008/11/28 H.Itou del End
          AND ooha.order_type_id = otta.transaction_type_id                    --�󒍃^�C�vID
          AND xola.shipping_item_code = iimb.item_no                            --�i�ڃR�[�h
          AND itp.item_id         = iimb.item_id                            --�i��ID
          AND ximb.item_id        = iimb.item_id                            --�i��ID
          AND itp.trans_date
            BETWEEN ximb.start_date_active
            AND ximb.end_date_active
          --  AND NVL(ximb.end_date_active,itp.trans_date)                    --�K�p�J�n���E�I����
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND iimb.item_id = gic1.item_id                                     --�i��ID
-- 2008/11/28 H.Itou del End
-- 2008/11/28 H.Itou Mod Start �{�ԏ�Q#227
--          AND gic1.item_id = iimb.item_id
          AND gic1.item_id = itp.item_id
-- 2008/11/28 H.Itou Mod End
          AND gic1.category_set_id = cn_item_class_id
          AND gic1.category_id = mcb1.category_id
          AND mcb1.segment1 = civ_item_div
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND iimb.item_id = gic3.item_id                                     --�i��ID
-- 2008/11/28 H.Itou del End
-- 2008/11/28 H.Itou Mod Start �{�ԏ�Q#227
--          AND gic3.item_id = iimb.item_id
          AND gic3.item_id = itp.item_id
-- 2008/11/28 H.Itou Mod End
          AND gic3.category_set_id = cn_prod_class_id
          AND gic3.category_id = mcb3.category_id
          AND mcb3.segment1 = civ_prod_div
          AND xola.request_item_code = iimb2.item_no                             --�i�ڃR�[�h
          AND ximb2.item_id = iimb2.item_id                            --�i��ID
          AND gic2.item_id = iimb2.item_id
          AND gic2.category_set_id = cn_item_class_id
          AND gic2.category_id = mcb2.category_id
          AND itp.trans_date
            BETWEEN ximb2.start_date_active
            AND ximb2.end_date_active
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND gic2.item_id = iimb2.item_id                                     --�i��ID
-- 2008/11/28 H.Itou del End
          AND xoha.result_deliver_to_id = hps.party_site_id(+)
          AND xoha.vendor_site_id = xvsa.vendor_site_id(+)
          AND NVL(xvsa.start_date_active,TO_DATE('1900/01/01',gv_fmt_ymd)) <= TO_DATE(civ_ymd_from,gv_fmt_ymd)
          AND NVL(xvsa.end_date_active,TO_DATE('9999/12/31',gv_fmt_ymd))   >= TO_DATE(civ_ymd_from,gv_fmt_ymd)
          AND itp.doc_type = xrpm.doc_type                                    --�����^�C�v
          AND xrpm.doc_type = 'OMSO'
          AND  otta.attribute1 = xrpm.shipment_provision_div                      --�o�׎x���敪
          AND  otta.attribute1 IN (gv_spdiv_ship,gv_spdiv_prov)
          AND xrpm.shipment_provision_div IN (gv_spdiv_ship,gv_spdiv_prov)
          AND (otta.attribute11 = xrpm.ship_prov_rcv_pay_category                 --�o�׎x���󕥃J�e�S��
            OR   xrpm.ship_prov_rcv_pay_category IS NULL)
            AND NVL(DECODE(mcb1.segment1
                          ,gv_item_class_prod,gv_item_class_prod,NULL),gv_dummy)
                = NVL(xrpm.item_div_origin,gv_dummy)
            AND NVL(DECODE(mcb2.segment1
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_ahead,gv_dummy)
          AND NVL(DECODE(otta.attribute4
                        ,gv_stock_adjm
                        ,gv_stock_adjm
                        ,NULL),gv_dummy
              ) = NVL(DECODE(xrpm.stock_adjustment_div                            --�݌ɒ����敪
                            ,gv_stock_adjm
                            ,gv_stock_adjm
                            ,NULL),gv_dummy
              )
          AND xrpm.use_div_invent = gv_inventory                                  --�݌Ɏg�p�敪
          AND (mcb1.segment1 = gv_item_class_prod AND mcb2.segment1 = gv_item_class_prod
            AND ( (iimb.item_id = iimb2.item_id
              AND xrpm.prod_div_origin IS NULL
              AND xrpm.prod_div_ahead IS NULL)
            OR    (iimb.item_id != iimb2.item_id
              AND xrpm.prod_div_origin IS NOT NULL
              AND xrpm.prod_div_ahead IS NOT NULL)
            )
          OR NOT( mcb1.segment1 = gv_item_class_prod AND mcb2.segment1 = gv_item_class_prod)
          )
          AND itp.location = mil.segment1                                    --�ۊǏꏊ�R�[�h
          AND iwm.mtl_organization_id = mil.organization_id
          AND xoha.arrival_date                                                 --���ד�
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          GROUP BY 
            itp.doc_type                                                      --�����^�C�v
           ,itp.item_id                                                       --�i��ID
           ,itp.whse_code                                                     --�q�ɃR�[�h
           ,iwm.whse_name                                                        --�q�ɖ�
           ,itp.location                                                      --�ۊǑq�ɃR�[�h
           ,mil.description                                                      --�ۊǑq�ɖ�
           ,mil.inventory_location_id                                            --�ۊǑq��ID
           ,itp.lot_id                                                        --���b�gID
           ,itp.doc_id                                                        --����ID
           ,itp.doc_line                                                      --������הԍ�
           ,ooha.header_id                                                     --�󒍃w�b�_ID
           ,ooha.order_type_id                                                 --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                                                      --�󕥋敪
           ,xrpm.new_div_invent                                                   --�V�敪
           ,mil.attribute6                                               --�u���b�N
           ,xoha.head_sales_branch
           ,xoha.deliver_to_id
           ,xoha.result_deliver_to
           ,xoha.vendor_site_code
           ,xoha.arrival_date
           ,xoha.shipped_date
           ,xoha.request_no
           ,xoha.req_status
           ,hps.party_site_name
           ,xvsa.vendor_site_name
           ,otta.order_category_code
          UNION ALL
           -- PORC�֘A
-- mod start 1.25
-- 2008/11/28 H.Itou Mod Start �{�ԏ�Q#227
--          SELECT
--          SELECT /*+ leading(xoha ooha otta xola wdd itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) use_nl(xoha ooha otta xola wdd itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) */
          SELECT /*+ leading(xoha ooha otta xola rsl itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) use_nl(xoha ooha otta xola rsl itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) */
-- 2008/11/28 H.Itou Mod End
-- mod end 1.25
            itp.doc_type                                  doc_type            --�����^�C�v
           ,itp.item_id                                   item_id             --�i��ID
           ,itp.whse_code                                 whse_code           --�q�ɃR�[�h
           ,iwm.whse_name                                 whse_name           --�q�ɖ�
           ,itp.location                                  location            --�ۊǑq�ɃR�[�h
           ,mil.description                               description         --�ۊǑq�ɖ�
           ,mil.inventory_location_id                     inventory_location_id   --�ۊǑq��ID
           ,itp.lot_id                                    lot_id              --���b�gID
           ,itp.doc_id                                    doc_id              --����ID
           ,itp.doc_line                                  doc_line            --������הԍ�
           ,ooha.header_id                                header_id           --�󒍃w�b�_ID
           ,ooha.order_type_id                            order_type_id       --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                              rcv_pay_div         --�󕥋敪
           ,xrpm.new_div_invent                           new_div_invent      --�V�敪
           ,SUM(itp.trans_qty)                            trans_qty_sum       --���ʍ��v
           ,mil.attribute6                                distribution_block  --�u���b�N
           ,xoha.head_sales_branch                        head_sales_branch
           ,xoha.deliver_to_id                            deliver_to_id
           ,DECODE(xoha.req_status,gv_recsts_shipped,xoha.result_deliver_to
                                  ,gv_recsts_shipped2,xoha.vendor_site_code
            ) deliver_to
           ,xoha.arrival_date                             arrival_date
           ,xoha.shipped_date                             shipped_date
           ,xoha.request_no                               request_no
           --,DECODE(xoha.req_status,'04',xpsv.party_site_full_name
           ,DECODE(xoha.req_status,gv_recsts_shipped,hps.party_site_name
           --                       ,'08',xvsv.vendor_site_name
                                  ,gv_recsts_shipped2,xvsa.vendor_site_name
            ) party_site_full_name
           ,otta.order_category_code                      order_category_code
          FROM
           xxwsh_order_headers_all                            xoha                --�󒍃w�b�_(�A�h�I��)
           ,hz_party_sites                                    hps
           ,xxcmn_vendor_sites_all                            xvsa
           ,xxwsh_order_lines_all                             xola                --�󒍖���(�A�h�I��)
           ,oe_transaction_types_all                          otta                --�󒍃^�C�v
           ,xxcmn_rcv_pay_mst                                 xrpm                --����敪�A�h�I���}�X�^
           ,ic_item_mst_b                                     iimb
           ,xxcmn_item_mst_b                                  ximb
           ,ic_item_mst_b                                     iimb2
           ,xxcmn_item_mst_b                                  ximb2
           ,gmi_item_categories                               gic1
           ,mtl_categories_b                                  mcb1
           ,gmi_item_categories                               gic2
           ,mtl_categories_b                                  mcb2
           ,gmi_item_categories                               gic3
           ,mtl_categories_b                                  mcb3
           ,ic_whse_mst                                       iwm
           ,mtl_item_locations                                mil
           ,ic_tran_pnd                                       itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
           ,rcv_shipment_lines                                rsl             --�������
           ,oe_order_headers_all                              ooha                --�󒍃w�b�_
-- 2008/11/28 H.Itou add End
--          WHERE ooha.header_id = xoha.header_id                                --�󒍃w�b�_ID
          WHERE
-- 2008/11/28 H.Itou del End
-- 2008/11/28 H.Itou add start
              rsl.shipment_header_id  = itp.doc_id
          AND rsl.line_num            = itp.doc_line
          AND rsl.oe_order_header_id  = xola.header_id
          AND rsl.oe_order_line_id    = xola.line_id
          AND xoha.header_id          = ooha.header_id
          AND xola.order_header_id    = xoha.order_header_id
-- 2008/11/28 H.Itou add end
          AND itp.doc_type = 'PORC'
          AND rsl.source_document_code = 'RMA'                                --�\�[�X����
          AND itp.completed_ind = gv_tran_cmp                                         --�����t���O
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND itp.doc_id = rsl.shipment_header_id                             --����w�b�_ID
--          AND itp.doc_line = rsl.line_num                                     --���הԍ�
--          AND rsl.oe_order_header_id = ooha.header_id                         --�󒍃w�b�_ID
-- 2008/11/28 H.Itou del End
          AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --�X�e�[�^�X
          AND xoha.actual_confirm_class = gv_confirm_yes                            --���ьv��敪
          AND xoha.latest_external_flag = gv_latest_yes                             --�ŐV�t���O
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND xoha.order_header_id = xola.order_header_id                         --�󒍃A�h�I���w�b�_ID
-- 2008/11/28 H.Itou del End
          AND ooha.order_type_id = otta.transaction_type_id                    --�󒍃^�C�vID
          AND xola.shipping_item_code = iimb.item_no                            --�i�ڃR�[�h
          AND itp.item_id         = iimb.item_id                            --�i��ID
          AND ximb.item_id            = iimb.item_id                            --�i��ID
          AND itp.trans_date
            BETWEEN ximb.start_date_active
            AND ximb.end_date_active
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND iimb.item_id = gic1.item_id                                     --�i��ID
-- 2008/11/28 H.Itou del End
-- 2008/11/28 H.Itou mod Start �{�ԏ�Q#227
--          AND gic1.item_id = iimb.item_id
          AND gic1.item_id = itp.item_id
-- 2008/11/28 H.Itou del End
          AND gic1.category_set_id = cn_item_class_id
          AND gic1.category_id = mcb1.category_id
          AND mcb1.segment1 = civ_item_div
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND iimb.item_id = gic3.item_id                                     --�i��ID
-- 2008/11/28 H.Itou del End
-- 2008/11/28 H.Itou mod Start �{�ԏ�Q#227
--          AND gic3.item_id = iimb.item_id
          AND gic3.item_id = itp.item_id
-- 2008/11/28 H.Itou mod end
          AND gic3.category_set_id = cn_prod_class_id
          AND gic3.category_id = mcb3.category_id
          AND mcb3.segment1 = civ_prod_div
          AND xola.request_item_code = iimb2.item_no                             --�i�ڃR�[�h
          AND ximb2.item_id = iimb2.item_id                            --�i��ID
          AND gic2.item_id = iimb2.item_id
          AND gic2.category_set_id = cn_item_class_id
          AND gic2.category_id = mcb2.category_id
          AND itp.trans_date
            BETWEEN ximb2.start_date_active
            AND ximb2.end_date_active
-- 2008/11/28 H.Itou del Start �{�ԏ�Q#227
--          AND gic2.item_id = iimb2.item_id                                     --�i��ID
-- 2008/11/28 H.Itou del End
          AND xoha.result_deliver_to_id = hps.party_site_id(+)
          AND xoha.vendor_site_id = xvsa.vendor_site_id(+)
          AND NVL(xvsa.start_date_active,TO_DATE('1900/01/01',gv_fmt_ymd)) <= TO_DATE(civ_ymd_from,gv_fmt_ymd)
          AND NVL(xvsa.end_date_active,TO_DATE('9999/12/31', gv_fmt_ymd))   >= TO_DATE(civ_ymd_from,gv_fmt_ymd)
          AND itp.doc_type = xrpm.doc_type                                    --�����^�C�v
          AND xrpm.doc_type = 'PORC'
          AND  otta.attribute1 = xrpm.shipment_provision_div                      --�o�׎x���敪
          AND  otta.attribute1 IN (gv_spdiv_ship,gv_spdiv_prov)
          AND xrpm.shipment_provision_div IN (gv_spdiv_ship,gv_spdiv_prov)
          AND (otta.attribute11 = xrpm.ship_prov_rcv_pay_category                 --�o�׎x���󕥃J�e�S��
            OR   xrpm.ship_prov_rcv_pay_category IS NULL)
            AND NVL(DECODE(mcb1.segment1
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_origin,gv_dummy)
            AND NVL(DECODE(mcb2.segment1
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_ahead,gv_dummy)
          AND NVL(DECODE(otta.attribute4
                        ,gv_stock_adjm
                        ,gv_stock_adjm
                        ,NULL),gv_dummy
              ) = NVL(DECODE(xrpm.stock_adjustment_div                            --�݌ɒ����敪
                            ,gv_stock_adjm
                            ,gv_stock_adjm
                            ,NULL),gv_dummy
              )
          AND xrpm.use_div_invent = gv_inventory                                  --�݌Ɏg�p�敪
          AND (mcb1.segment1 = gv_item_class_prod AND mcb2.segment1 = gv_item_class_prod
            AND ( (iimb.item_id = iimb2.item_id
              AND xrpm.prod_div_origin IS NULL
              AND xrpm.prod_div_ahead IS NULL)
            OR    (iimb.item_id != iimb2.item_id
              AND xrpm.prod_div_origin IS NOT NULL
              AND xrpm.prod_div_ahead IS NOT NULL)
            )
          OR NOT( mcb1.segment1 = gv_item_class_prod AND mcb2.segment1 = gv_item_class_prod)
          )
          AND itp.location = mil.segment1                                    --�ۊǏꏊ�R�[�h
          AND iwm.mtl_organization_id = mil.organization_id
          AND xoha.arrival_date                                                 --���ד�
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          GROUP BY 
            itp.doc_type                                                      --�����^�C�v
           ,itp.item_id                                                       --�i��ID
           ,itp.whse_code                                                     --�q�ɃR�[�h
           ,iwm.whse_name                                                        --�q�ɖ�
           ,itp.location                                                      --�ۊǑq�ɃR�[�h
           ,mil.description                                                      --�ۊǑq�ɖ�
           ,mil.inventory_location_id                                            --�ۊǑq��ID
           ,itp.lot_id                                                        --���b�gID
           ,itp.doc_id                                                        --����ID
           ,itp.doc_line                                                      --������הԍ�
           ,ooha.header_id                                                     --�󒍃w�b�_ID
           ,ooha.order_type_id                                                 --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                                                      --�󕥋敪
           ,xrpm.new_div_invent                                                   --�V�敪
           ,mil.attribute6                                               --�u���b�N
           ,xoha.head_sales_branch
           ,xoha.deliver_to_id
           ,xoha.result_deliver_to
           ,xoha.vendor_site_code
           ,xoha.arrival_date
           ,xoha.shipped_date
           ,xoha.request_no
           ,xoha.req_status
           ,hps.party_site_name
           ,xvsa.vendor_site_name
           ,otta.order_category_code
        )                                                     sh_info             --�o�׊֘A���
         ,xxcmn_parties                                       xp
         ,hz_cust_accounts                                    hca
        WHERE sh_info.head_sales_branch = hca.account_number(+)                          --�ڋq�ԍ�
        AND hca.customer_class_code(+) = '1'                               --�ڋq�敪(���_)
        AND hca.party_id = xp.party_id(+)
        UNION ALL
        ------------------------------
        -- 4.�q�֕ԕi���я��
        ------------------------------
        SELECT
          gv_trtry_rt                                         territory           --�̈�(�q�֕ԕi)
         ,rt_info.item_id                                     item_id             --�i��ID
         ,rt_info.lot_id                                      lot_id              --���b�gID
--         ,TO_CHAR(xoha.shipped_date,gv_fmt_ymd)               standard_date       --���t
         ,CASE '1'                                                                --�p�����[�^.�
            WHEN '1' THEN TO_CHAR(xoha.arrival_date,gv_fmt_ymd)
            WHEN '2' THEN TO_CHAR(xoha.shipped_date,gv_fmt_ymd)
            ELSE NULL
          END                                                 standard_date       --���t
         ,rt_info.reason_code                                 reason_code         --�V�敪
         ,xoha.request_no                                     slip_no             --�`�[No
         ,TO_CHAR(xoha.shipped_date,gv_fmt_ymd)               out_date            --�o�ɓ�
         ,TO_CHAR(xoha.arrival_date,gv_fmt_ymd)               in_date             --����
         ,xoha.head_sales_branch                              jrsd_code           --�Ǌ����_�R�[�h
         ,CASE
            WHEN hca.customer_class_code = '10'
              THEN xp.party_name
              ELSE xp.party_short_name
          END                                                 jrsd_name           --�Ǌ����_��
         ,xoha.head_sales_branch                              other_code          --�����R�[�h
         ,xp.party_name                                       other_name          --����於��
         ,rt_info.in_qty_sum                                  in_qty              --���ɐ�
         ,0                                                   out_qty             --�o�ɐ�
         ,rt_info.whse_code                                   whse_code           --�q�ɃR�[�h
         ,rt_info.whse_name                                   whse_name           --�q�ɖ�
         ,rt_info.location                                    location            --�ۊǑq�ɃR�[�h
         ,rt_info.description                                 description         --�ۊǑq�ɖ�
         ,rt_info.distribution_block                          distribution_block  --�u���b�N
         ,rt_info.rcv_pay_div                                 rcv_pay_div         --�󕥋敪
        ----------------------------------------------------------------------------------------
        FROM (
-- mod start 1.25
          --SELECT /*+ leading(xrpm otta rsl ooha xoha itp gic1 mcb1 gic2 mcb2 mil iwm) use_nl(xrpm otta rsl ooha xoha itp gic1 mcb1 gic2 mcb2 mil iwm) */
          SELECT /*+ leading(xoha ooha otta rsl itp gic1 mcb1 gic2 mcb2) use_nl(xoha ooha otta rsl itp gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
            xoha.header_id                                    header_id           --�󒍃w�b�_ID
           ,itp.whse_code                                     whse_code           --�q�ɃR�[�h
           ,iwm.whse_name                                     whse_name           --�q�ɖ�
           ,itp.item_id                                       item_id             --�i��ID
           ,itp.lot_id                                        lot_id              --���b�gID
           ,itp.location                                      location            --�ۊǑq�ɃR�[�h
           ,mil.description                                   description         --�ۊǑq�ɖ�
           ,mil.inventory_location_id                         inventory_location_id --�ۊǑq��ID
           ,xrpm.new_div_invent                               reason_code         --�V�敪
           ,mil.attribute6                                    distribution_block  --�u���b�N
           ,xrpm.rcv_pay_div                                  rcv_pay_div         --�󕥋敪
           ,SUM(NVL(itp.trans_qty,0))                         in_qty_sum          --���ʍ��v
          FROM
            ic_tran_pnd                                       itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
           --------------------------------------------------------
           ,ic_whse_mst                                       iwm                 --�ۊǏꏊ���VIEW2
           ,mtl_item_locations                                mil
           --------------------------------------------------------
           ,rcv_shipment_lines                                rsl                 --�������
           ,oe_order_headers_all                              ooha                --�󒍃w�b�_
           ,xxwsh_order_headers_all                           xoha                --�󒍃w�b�_(�A�h�I��)
           ,oe_transaction_types_all                          otta                --�󒍃^�C�v
           ,xxcmn_rcv_pay_mst                                 xrpm                --�󕥋敪�A�h�I���}�X�^
           --------------------------------------------------------
           ,gmi_item_categories                               gic1
           ,mtl_categories_b                                  mcb1
           ,gmi_item_categories                               gic2
           ,mtl_categories_b                                  mcb2
          --OPM�ۗ��݌Ƀg�����U�N�V�������o
          WHERE itp.completed_ind = gv_tran_cmp                                   --�����t���O
          AND itp.doc_type = 'PORC'                                               --�����^�C�v
          --�ۊǏꏊ���VIEW2���o
          AND itp.location = mil.segment1                                         --�ۊǑq�ɃR�[�h
          --������ג��o
          AND itp.doc_id = rsl.shipment_header_id                                 --����w�b�_ID
          AND itp.doc_line = rsl.line_num                                         --���הԍ�
          AND rsl.source_document_code = 'RMA'                                    --�\�[�X����
          --�󒍃w�b�_���o
          AND rsl.oe_order_header_id = ooha.header_id                             --�󒍃w�b�_ID
          --�󒍃w�b�_�A�h�I�����o
          AND ooha.header_id = xoha.header_id                                     --�󒍃w�b�_ID
          AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)           --�X�e�[�^�X
          AND xoha.actual_confirm_class = gv_confirm_yes                          --���ьv��敪
          AND xoha.latest_external_flag = gv_latest_yes                           --�ŐV�t���O
          AND xoha.deliver_from_id = mil.inventory_location_id                    --�o�׌�ID
          AND xoha.arrival_date                                                   --���ד�
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          --�󒍃^�C�v���o
          AND ooha.order_type_id = otta.transaction_type_id                       --�󒍃^�C�vID
          AND otta.attribute1 = '3'                                               --�o�׎x���敪
          --�󕥋敪�A�h�I���}�X�^���o
          AND otta.attribute1 = xrpm.shipment_provision_div                       --�o�׎x���敪
          AND otta.attribute11 = xrpm.ship_prov_rcv_pay_category                  --�o�׎x���󕥃J�e�S��
          AND xrpm.use_div_invent = gv_inventory                                  --�݌Ɏg�p�敪
          AND xrpm.doc_type = 'PORC'                                              --�����^�C�v
          AND xrpm.source_document_code = 'RMA'                                   --�\�[�X����
          AND xrpm.dealings_div IN ('201','203')
          -----------------------------------------------------------
          AND gic1.item_id            = itp.item_id
          AND gic1.category_set_id    = cn_item_class_id
          AND gic1.category_id        = mcb1.category_id
          AND mcb1.segment1           = civ_item_div
          AND gic2.item_id            = itp.item_id
          AND gic2.category_set_id    = cn_prod_class_id
          AND gic2.category_id        = mcb2.category_id
          AND mcb2.segment1           = civ_prod_div
          -----------------------------------------------------------
          AND iwm.mtl_organization_id = mil.organization_id
          GROUP BY
            xoha.header_id                                                        --�󒍃w�b�_ID
           ,itp.whse_code                                                         --�q�ɃR�[�h
           ,iwm.whse_name                                                         --�q�ɖ�
           ,itp.item_id                                                           --�i��ID
           ,itp.lot_id                                                            --���b�gID
           ,itp.location                                                          --�ۊǑq�ɃR�[�h
           ,mil.description                                                       --�ۊǑq�ɖ�
           ,mil.inventory_location_id                                             --�ۊǑq��ID
           ,xrpm.new_div_invent                                                   --�V�敪
           ,mil.attribute6                                                        --�u���b�N
           ,xrpm.rcv_pay_div                                                      --�󕥋敪
        ) rt_info                                                                 --�q�֕ԕi�֘A���
        ,xxwsh_order_headers_all                              xoha                --�󒍃w�b�_(�A�h�I��)
        -----------------------------------------------
        ,hz_parties                                           hp                  --�ڋq���VIEW2
        ,hz_cust_accounts                                     hca
        ,xxcmn_parties                                        xp
        ----------------------------------------------
        --�󒍃w�b�_(�A�h�I��)���o
        WHERE rt_info.header_id = xoha.header_id                                  --�󒍃w�b�_ID
          AND xoha.head_sales_branch = hca.account_number                         --�ڋq�ԍ�
          AND hca.customer_class_code = '1'                                       --�ڋq�敪(���_)
          AND hp.party_id = hca.party_id
          AND hp.party_id = xp.party_id
        UNION ALL
        ------------------------------
        -- 5.���Y���я��
        ------------------------------
        -- �i�ڐU��
        SELECT
           gv_trtry_mf                                         territory           -- �̈�(���Y)
         , gmd.item_id                                         item_id             -- �i��ID
         , itp.lot_id                                          lot_id              -- ���b�gID
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )                                   -- �i�ڐU��
         , xrpm.new_div_invent                                 reason_code         -- �V�敪
         , gbh.batch_no                                        slip_no             -- �`�[No
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )               out_date
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )               in_date
         , ''                                                  jrsd_code           -- �Ǌ����_�R�[�h
         , ''                                                  jrsd_name           -- �Ǌ����_��
         , grb.routing_no                                      other_code          -- �����R�[�h
         , grct.routing_class_desc                             other_name          -- ����於��
         , SUM( CASE gmd.line_type --���C���^�C�v
                  WHEN -1 THEN 0
                  ELSE NVL(itp.trans_qty,0)
                END )                                          in_qty              -- ���ɐ�
         , ABS( SUM( CASE gmd.line_type --���C���^�C�v
                       WHEN -1 THEN NVL(itp.trans_qty,0)
                       ELSE 0
                     END ) )                                   out_qty             --�o�ɐ�
         , itp.whse_code                                       whse_code           -- �q�ɃR�[�h
         , iwm.whse_name                                       whse_name           -- �q�ɖ�
         , itp.location                                        location            -- �ۊǑq�ɃR�[�h
         , mil.description                                     description         -- �ۊǑq�ɖ�
         , mil.attribute6                                      distribution_block  -- �u���b�N
         , xrpm.rcv_pay_div                                    rcv_pay_div         -- �󕥋敪
        ----------------------------------------------------------------------------------------
        FROM
           gme_batch_header                                  gbh                 -- ���Y�o�b�`
         , gme_material_details                              gmd                 -- ���Y�����ڍ�
         , gme_material_details                              gmd_d               -- ���Y�����ڍ�(�����i)
         , gmd_routings_b                                    grb                 -- �H���}�X�^
         , gmd_routing_class_tl                              grct                -- �H���敪�}�X�^���{��
         , ic_whse_mst                                       iwm
         , mtl_item_locations                                mil
         --���Y�����ڍ�(�U�֌���i��)
         ,(
           SELECT 
              gbh.batch_id                                     batch_id            -- �o�b�`ID
            , gmd.line_no                                      line_no             -- ���C��NO
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_mtrl, mcb.segment1
                        , NULL
                 )
              )                                                item_class_origin   -- �U�֌��i�ڋ敪
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_prod, mcb.segment1
                        , NULL
                 )
              )                                                item_class_ahead    -- �U�֐�i�ڋ敪
           FROM
              gme_batch_header                                 gbh                 -- ���Y�o�b�`
            , gme_material_details                             gmd                 -- ���Y�����ڍ�
            , gmd_routings_b                                   grb                 -- �H���}�X�^
            , gmi_item_categories                              gic
            , mtl_categories_b                                 mcb
           --���Y�����ڍג��o����
           WHERE gbh.batch_id           = gmd.batch_id                            -- �o�b�`ID
           --�H���}�X�^���o����
           AND   gbh.routing_id         = grb.routing_id                          -- �H��ID
           AND   grb.routing_class      = '70'
           --�J�e�S���������o����
           AND   gmd.item_id            = gic.item_id
           AND   gic.category_id        = mcb.category_id
           AND   gic.category_set_id    = cn_item_class_id
           --AND   mcb.segment1           = civ_item_div
           GROUP BY gbh.batch_id
                   ,gmd.line_no
          )                                                    gmd_t                 --
         , xxcmn_rcv_pay_mst                                   xrpm                  -- �󕥋敪�A�h�I���}�X�^
         , ic_tran_pnd                                         itp                   -- OPM�ۗ��݌Ƀg�����U�N�V����
         , mtl_categories_b                                    mcb1
         , gmi_item_categories                                 gic1
         , mtl_categories_b                                    mcb2
         , gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --���Y�����ڍג��o����
        WHERE gbh.batch_id      = gmd.batch_id                                        -- �o�b�`ID
        --���Y�����ڍ�(�����i)
        AND   gbh.batch_id      = gmd_d.batch_id                                      -- �o�b�`ID
        AND   gmd_d.line_type   = 1                                                   -- ���C���^�C�v(�����i)
        --���Y�����ڍ�(�U��)
        AND   gmd.batch_id      = gmd_t.batch_id(+)                                   -- �o�b�`ID
        AND   gmd.line_no       = gmd_t.line_no(+)                                    -- ���C��NO
        --�H���}�X�^���o����
        AND   gbh.routing_id    = grb.routing_id                                      -- �H��ID
        --�H���}�X�^���{�ꒊ�o����
        --�H���敪�}�X�^���{�ꒊ�o����
        AND   grb.routing_class = grct.routing_class                                  -- �H���R�[�h
        AND   grct.language     = gv_lang                                                -- ����
        AND   grct.source_lang  = gv_source_lang                                                -- ����
        AND   iwm.mtl_organization_id = mil.organization_id                       -- OPM�ۗ��݌Ƀg�����U�N�V�������o����
        AND   itp.line_id             = gmd.material_detail_id                    -- ���C��ID
        AND   itp.item_id             = gmd.item_id                               -- �i��ID
        AND   itp.location            = mil.segment1                              -- �ۊǑq�ɃR�[�h
        AND   itp.completed_ind       = gv_tran_cmp                                       -- �����t���O
        AND   itp.doc_type            = 'PROD'                                    -- �����^�C�v
        AND   itp.reverse_id          IS NULL                                     -- ���o�[�XID
        AND   itp.delete_mark         = gn_delete_mark_no                                         -- �폜�}�[�N
        --�󕥋敪�A�h�I���}�X�^���o����
        AND   xrpm.doc_type           = 'PROD'                                    -- �����^�C�v
        AND   xrpm.line_type          = gmd.line_type                             -- ���C���^�C�v
        AND   xrpm.use_div_invent     = gv_inventory                                                  -- �݌Ɏg�p�敪
        AND   NVL(xrpm.hit_in_div   , gv_dummy) = NVL(gmd.attribute5   , gv_dummy)  -- �ō��敪
        AND   xrpm.routing_class      = grb.routing_class(+)                       -- �H���敪
        AND   grct.routing_class_desc = gv_item_transfer
        AND   xrpm.item_div_ahead     = gmd_t.item_class_ahead                       -- �U�֐�i�ڋ敪
        AND   xrpm.item_div_origin    = gmd_t.item_class_origin                      -- �U�֌��i�ڋ敪
        --���Y��
        AND   itp.trans_date >= TO_DATE(civ_ymd_from, gv_fmt_ymd)
        AND   itp.trans_date <= TO_DATE(civ_ymd_to, gv_fmt_ymd)
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND itp.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND itp.item_id = gic2.item_id
        AND gic2.category_set_id    = cn_item_class_id
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        ----------------------------------------------------------------------------------------
        GROUP BY 
           gv_trtry_mf                                                                  -- �̈�(���Y)
         , gmd.item_id                                                             -- �i��ID
         , itp.lot_id                                                              -- ���b�gID
         , SUBSTRB(gmd_d.attribute11, 1, 10)                                       -- ���t
         , TO_CHAR(itp.trans_date, gv_fmt_ymd)
         , xrpm.new_div_invent                                                     -- �V�敪
         , gbh.batch_no                                                            -- �`�[No
         , grb.routing_no                                                          -- �����R�[�h
         , grct.routing_class_desc
         , itp.whse_code                                                           -- �q�ɃR�[�h
         , iwm.whse_name                                                           -- �q�ɖ�
         , itp.location                                                            -- �ۊǑq�ɃR�[�h
         , mil.description                                                         -- �ۊǑq�ɖ�
         , mil.attribute6                                                          -- �u���b�N
         , xrpm.rcv_pay_div                                                        -- �󕥋敪
        UNION ALL
        -- �ԕi�����A��̔����i
        SELECT
           gv_trtry_mf                                         territory           -- �̈�(���Y)
         , gmd.item_id                                         item_id             -- �i��ID
         , itp.lot_id                                          lot_id              -- ���b�gID
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )
         , xrpm.new_div_invent                                 reason_code         -- �V�敪
         , gbh.batch_no                                        slip_no             -- �`�[No
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )               out_date
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )               in_date
         , ''                                                  jrsd_code           -- �Ǌ����_�R�[�h
         , ''                                                  jrsd_name           -- �Ǌ����_��
         , grb.routing_no                                      other_code          -- �����R�[�h
         , grct.routing_class_desc                             other_name          -- ����於��
         , SUM( CASE gmd.line_type --���C���^�C�v
                  WHEN -1 THEN 0
                  ELSE NVL(itp.trans_qty,0)
                END )                                          in_qty              -- ���ɐ�
         , ABS( SUM( CASE gmd.line_type --���C���^�C�v
                       WHEN -1 THEN NVL(itp.trans_qty,0)
                       ELSE 0
                     END ) )                                   out_qty             --�o�ɐ�
         , itp.whse_code                                       whse_code           -- �q�ɃR�[�h
         , iwm.whse_name                                       whse_name           -- �q�ɖ�
         , itp.location                                        location            -- �ۊǑq�ɃR�[�h
         , mil.description                                     description         -- �ۊǑq�ɖ�
         , mil.attribute6                                      distribution_block  -- �u���b�N
         , xrpm.rcv_pay_div                                    rcv_pay_div         -- �󕥋敪
        ----------------------------------------------------------------------------------------
        FROM
           gme_batch_header                                  gbh                 -- ���Y�o�b�`
         , gme_material_details                              gmd                 -- ���Y�����ڍ�
         , gme_material_details                              gmd_d               -- ���Y�����ڍ�(�����i)
         , gmd_routings_b                                    grb                 -- �H���}�X�^
         , gmd_routing_class_tl                              grct                -- �H���敪�}�X�^���{��
         , ic_whse_mst                                       iwm
         , mtl_item_locations                                mil
         --���Y�����ڍ�(�U�֌���i��)
         ,(
           SELECT 
              gbh.batch_id                                     batch_id            -- �o�b�`ID
            , gmd.line_no                                      line_no             -- ���C��NO
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_mtrl, mcb.segment1
                        , NULL
                 )
              )                                                item_class_origin   -- �U�֌��i�ڋ敪
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_prod, mcb.segment1
                        , NULL
                 )
              )                                                item_class_ahead    -- �U�֐�i�ڋ敪
           FROM
              gme_batch_header                                 gbh                 -- ���Y�o�b�`
            , gme_material_details                             gmd                 -- ���Y�����ڍ�
            , gmd_routings_b                                   grb                 -- �H���}�X�^
            , gmi_item_categories                              gic
            , mtl_categories_b                                 mcb
           --���Y�����ڍג��o����
           WHERE gbh.batch_id           = gmd.batch_id                            -- �o�b�`ID
           --�H���}�X�^���o����
           AND   gbh.routing_id         = grb.routing_id                          -- �H��ID
           AND   grb.routing_class      = '70'
           --�J�e�S���������o����
           AND   gmd.item_id            = gic.item_id
           AND   gic.category_id        = mcb.category_id
           AND   gic.category_set_id    = cn_item_class_id
           --AND   mcb.segment1           = civ_item_div
           GROUP BY gbh.batch_id
                   ,gmd.line_no
          )                                                    gmd_t                 --
         , xxcmn_rcv_pay_mst                                   xrpm                  -- �󕥋敪�A�h�I���}�X�^
         , ic_tran_pnd                                         itp                   -- OPM�ۗ��݌Ƀg�����U�N�V����
         , mtl_categories_b                                    mcb1
         , gmi_item_categories                                 gic1
         , mtl_categories_b                                    mcb2
         , gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --���Y�����ڍג��o����
        WHERE gbh.batch_id      = gmd.batch_id                                        -- �o�b�`ID
        --���Y�����ڍ�(�����i)
        AND   gbh.batch_id      = gmd_d.batch_id                                      -- �o�b�`ID
        AND   gmd_d.line_type   = 1                                                   -- ���C���^�C�v(�����i)
        --���Y�����ڍ�(�U��)
        AND   gmd.batch_id      = gmd_t.batch_id(+)                                   -- �o�b�`ID
        AND   gmd.line_no       = gmd_t.line_no(+)                                    -- ���C��NO
        --�H���}�X�^���o����
        AND   gbh.routing_id    = grb.routing_id                                      -- �H��ID
        --�H���}�X�^���{�ꒊ�o����
        --�H���敪�}�X�^���{�ꒊ�o����
        AND   grb.routing_class = grct.routing_class                                  -- �H���R�[�h
        AND   grct.language     = gv_lang                                             -- ����
        AND   grct.source_lang  = gv_source_lang                                      -- ����
        AND   iwm.mtl_organization_id = mil.organization_id                       -- OPM�ۗ��݌Ƀg�����U�N�V�������o����
        AND   itp.line_id             = gmd.material_detail_id                    -- ���C��ID
        AND   itp.item_id             = gmd.item_id                               -- �i��ID
        AND   itp.location            = mil.segment1                              -- �ۊǑq�ɃR�[�h
        AND   itp.completed_ind       = gv_tran_cmp                                       -- �����t���O
        AND   itp.doc_type            = 'PROD'                                    -- �����^�C�v
        AND   itp.reverse_id          IS NULL                                     -- ���o�[�XID
        AND   itp.delete_mark         = gn_delete_mark_no                                         -- �폜�}�[�N
        --�󕥋敪�A�h�I���}�X�^���o����
        AND   xrpm.doc_type           = 'PROD'                                    -- �����^�C�v
        AND   xrpm.line_type          = gmd.line_type                             -- ���C���^�C�v
        AND   xrpm.use_div_invent     = gv_inventory                                                  -- �݌Ɏg�p�敪
        AND   NVL(xrpm.hit_in_div   , gv_dummy) = NVL(gmd.attribute5   , gv_dummy) -- �ō��敪
        AND   xrpm.routing_class      = grb.routing_class(+)                       -- �H���敪
        AND   grct.routing_class_desc IN (gv_item_return, gv_item_dissolve)
        --���Y��
        AND   itp.trans_date >= TO_DATE(civ_ymd_from, gv_fmt_ymd)
        AND   itp.trans_date <= TO_DATE(civ_ymd_to, gv_fmt_ymd)
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND itp.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND itp.item_id = gic2.item_id
        AND gic2.category_set_id    = cn_item_class_id
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        ----------------------------------------------------------------------------------------
        GROUP BY 
           gv_trtry_mf                                                                  -- �̈�(���Y)
         , gmd.item_id                                                             -- �i��ID
         , itp.lot_id                                                              -- ���b�gID
         , SUBSTRB(gmd_d.attribute11, 1, 10)                                       -- ���t
         , TO_CHAR(itp.trans_date, gv_fmt_ymd)
         , xrpm.new_div_invent                                                     -- �V�敪
         , gbh.batch_no                                                            -- �`�[No
         , grb.routing_no                                                          -- �����R�[�h
         , grct.routing_class_desc
         , itp.whse_code                                                           -- �q�ɃR�[�h
         , iwm.whse_name                                                           -- �q�ɖ�
         , itp.location                                                            -- �ۊǑq�ɃR�[�h
         , mil.description                                                         -- �ۊǑq�ɖ�
         , mil.attribute6                                                          -- �u���b�N
         , xrpm.rcv_pay_div                                                        -- �󕥋敪
        UNION ALL
        -- ���̑�
        SELECT /*+ leading(gmd_d gbh gmd itp gmd_t gic1 mcb1 gic2 mcb2 xrpm grb grct mil iwm) use_nl(gmd_d gbh gmd itp gmd_t gic1 mcb1 gic2 mcb2 xrpm grb grct mil iwm) */
           gv_trtry_mf                                         territory           -- �̈�(���Y)
         , gmd.item_id                                         item_id             -- �i��ID
         , itp.lot_id                                          lot_id              -- ���b�gID
         , SUBSTRB( gmd_d.attribute11, 1, 10 )
         , xrpm.new_div_invent                                 reason_code         -- �V�敪
         , gbh.batch_no                                        slip_no             -- �`�[No
         , SUBSTRB( gmd_d.attribute11, 1, 10 )                 out_date
         , SUBSTRB( gmd_d.attribute11, 1, 10 )                 in_date
         , ''                                                  jrsd_code           -- �Ǌ����_�R�[�h
         , ''                                                  jrsd_name           -- �Ǌ����_��
         , grb.routing_no                                      other_code          -- �����R�[�h
         , grct.routing_class_desc                             other_name          -- ����於��
         , SUM( CASE gmd.line_type --���C���^�C�v
                  WHEN -1 THEN 0
                  ELSE NVL(itp.trans_qty,0)
                END )                                          in_qty              -- ���ɐ�
         , ABS( SUM( CASE gmd.line_type --���C���^�C�v
                       WHEN -1 THEN NVL(itp.trans_qty,0)
                       ELSE 0
                     END ) )                                   out_qty             --�o�ɐ�
         , itp.whse_code                                       whse_code           -- �q�ɃR�[�h
         , iwm.whse_name                                       whse_name           -- �q�ɖ�
         , itp.location                                        location            -- �ۊǑq�ɃR�[�h
         , mil.description                                     description         -- �ۊǑq�ɖ�
         , mil.attribute6                                      distribution_block  -- �u���b�N
         , xrpm.rcv_pay_div                                    rcv_pay_div         -- �󕥋敪
        ----------------------------------------------------------------------------------------
        FROM
           gme_batch_header                                  gbh                 -- ���Y�o�b�`
         , gme_material_details                              gmd                 -- ���Y�����ڍ�
         , gme_material_details                              gmd_d               -- ���Y�����ڍ�(�����i)
         , gmd_routings_b                                    grb                 -- �H���}�X�^
         , gmd_routing_class_tl                              grct                -- �H���敪�}�X�^���{��
         , ic_whse_mst                                       iwm
         , mtl_item_locations                                mil
         --���Y�����ڍ�(�U�֌���i��)
         ,(
           SELECT /*+ leading(gbh grb gmd gic mcb) use_nl(gbh grb gmd gic mcb) */
              gbh.batch_id                                     batch_id            -- �o�b�`ID
            , gmd.line_no                                      line_no             -- ���C��NO
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_mtrl, mcb.segment1
                        , NULL
                 )
              )                                                item_class_origin   -- �U�֌��i�ڋ敪
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_prod, mcb.segment1
                        , NULL
                 )
              )                                                item_class_ahead    -- �U�֐�i�ڋ敪
           FROM
              gme_batch_header                                 gbh                 -- ���Y�o�b�`
            , gme_material_details                             gmd                 -- ���Y�����ڍ�
            , gmd_routings_b                                   grb                 -- �H���}�X�^
            , gmi_item_categories                              gic
            , mtl_categories_b                                 mcb
           --���Y�����ڍג��o����
           WHERE gbh.batch_id           = gmd.batch_id                            -- �o�b�`ID
           --�H���}�X�^���o����
           AND   gbh.routing_id         = grb.routing_id                          -- �H��ID
           AND   grb.routing_class      = '70'
           --�J�e�S���������o����
           AND   gmd.item_id            = gic.item_id
           AND   gic.category_id        = mcb.category_id
           AND   gic.category_set_id    = cn_item_class_id
           --AND   mcb.segment1           = civ_item_div
           GROUP BY gbh.batch_id
                   ,gmd.line_no
          )                                                    gmd_t                 --
         , xxcmn_rcv_pay_mst                                   xrpm                  -- �󕥋敪�A�h�I���}�X�^
         , ic_tran_pnd                                         itp                   -- OPM�ۗ��݌Ƀg�����U�N�V����
         , mtl_categories_b                                    mcb1
         , gmi_item_categories                                 gic1
         , mtl_categories_b                                    mcb2
         , gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --���Y�����ڍג��o����
        WHERE gbh.batch_id      = gmd.batch_id                                        -- �o�b�`ID
        --���Y�����ڍ�(�����i)
        AND   gbh.batch_id      = gmd_d.batch_id                                      -- �o�b�`ID
        AND   gmd_d.line_type   = 1                                                   -- ���C���^�C�v(�����i)
        --���Y�����ڍ�(�U��)
        AND   gmd.batch_id      = gmd_t.batch_id(+)                                   -- �o�b�`ID
        AND   gmd.line_no       = gmd_t.line_no(+)                                    -- ���C��NO
        --�H���}�X�^���o����
        AND   gbh.routing_id    = grb.routing_id                                      -- �H��ID
        --�H���}�X�^���{�ꒊ�o����
        --�H���敪�}�X�^���{�ꒊ�o����
        AND   grb.routing_class = grct.routing_class                                  -- �H���R�[�h
        AND   grct.language     = gv_lang                                             -- ����
        AND   grct.source_lang  = gv_source_lang                                      -- ����
        --OPM�ۊǏꏊ�}�X�^���o����
        AND   mil.segment1 = grb.attribute9
        AND   iwm.mtl_organization_id = mil.organization_id                       -- OPM�ۗ��݌Ƀg�����U�N�V�������o����
        AND   itp.line_id             = gmd.material_detail_id                    -- ���C��ID
        AND   itp.item_id             = gmd.item_id                               -- �i��ID
        AND   itp.location            = mil.segment1                              -- �ۊǑq�ɃR�[�h
        AND   itp.completed_ind       = gv_tran_cmp                                       -- �����t���O
        AND   itp.doc_type            = 'PROD'                                    -- �����^�C�v
        AND   itp.reverse_id          IS NULL                                     -- ���o�[�XID
        AND   itp.delete_mark         = gn_delete_mark_no                                         -- �폜�}�[�N
        --�󕥋敪�A�h�I���}�X�^���o����
        AND   xrpm.doc_type           = 'PROD'                                    -- �����^�C�v
        AND   xrpm.line_type          = gmd.line_type                             -- ���C���^�C�v
        AND   xrpm.use_div_invent     = gv_inventory                                                  -- �݌Ɏg�p�敪
        AND   NVL(xrpm.hit_in_div   , gv_dummy) = NVL(gmd.attribute5   , gv_dummy)  -- �ō��敪
        AND   xrpm.routing_class      = grb.routing_class(+)                        -- �H���敪
        AND   grct.routing_class_desc NOT IN (gv_item_transfer, gv_item_return, gv_item_dissolve)
        --���Y��
        AND   gmd_d.attribute11 >= civ_ymd_from
        AND   gmd_d.attribute11 <= civ_ymd_to
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND itp.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND itp.item_id = gic2.item_id
        AND gic2.category_set_id    = cn_item_class_id
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        ----------------------------------------------------------------------------------------
        GROUP BY 
           gv_trtry_mf                                                                  -- �̈�(���Y)
         , gmd.item_id                                                             -- �i��ID
         , itp.lot_id                                                              -- ���b�gID
         , SUBSTRB(gmd_d.attribute11, 1, 10)                                       -- ���t
         , TO_CHAR(itp.trans_date, gv_fmt_ymd)
         , xrpm.new_div_invent                                                     -- �V�敪
         , gbh.batch_no                                                            -- �`�[No
         , grb.routing_no                                                          -- �����R�[�h
         , grct.routing_class_desc
         , itp.whse_code                                                           -- �q�ɃR�[�h
         , iwm.whse_name                                                           -- �q�ɖ�
         , itp.location                                                            -- �ۊǑq�ɃR�[�h
         , mil.description                                                         -- �ۊǑq�ɖ�
         , mil.attribute6                                                          -- �u���b�N
         , xrpm.rcv_pay_div                                                        -- �󕥋敪
        UNION ALL
        ------------------------------
        -- 6.�݌ɒ������я��
        ------------------------------
        SELECT
          gv_trtry_ad                                         territory           --�̈�(�݌ɒ���)
         ,itc.item_id                                         item_id             --�i��ID
         ,itc.lot_id                                          lot_id              --���b�gID
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  standard_date       --���t
         ,xrpm.new_div_invent                                 reason_code         --�V�敪
         ,ad_info.slip_no                                     slip_no             --�`�[No
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  out_date            --�o�ɓ�
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  in_date             --����
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,CASE ad_info.adji_type
            WHEN gv_adji_xrart THEN ad_info.other_code
            WHEN gv_adji_xnpt THEN xrpm.new_div_invent
            WHEN gv_adji_xvst THEN ad_info.other_code
            WHEN gv_adji_xmrih THEN ad_info.other_code
            WHEN gv_adji_ijm THEN xrpm.new_div_invent
          END                                                 other_code          --�����R�[�h
         ,CASE ad_info.adji_type
            WHEN gv_adji_xrart THEN ad_info.other_name
            WHEN gv_adji_xnpt THEN NULL
            WHEN gv_adji_xvst THEN ad_info.other_name
            WHEN gv_adji_xmrih THEN ad_info.other_name
            WHEN gv_adji_ijm THEN NULL
          END                                                 other_name          --����於��
         ,CASE xrpm.rcv_pay_div
            WHEN '1' THEN SUM(NVL(itc.trans_qty,0))
            ELSE 0
          END                                                 in_qty              --���ɐ�
         ,CASE xrpm.rcv_pay_div
            WHEN '-1' THEN SUM(NVL(itc.trans_qty,0) * -1)
            ELSE 0
          END                                                 out_qty             --�o�ɐ�
         ,itc.whse_code                                       whse_code           --�q�ɃR�[�h
         ,iwm.whse_name                                       whse_name           --�q�ɖ�
         ,itc.location                                        location            --�ۊǑq�ɃR�[�h
         ,mil.description                                     description         --�ۊǑq�ɖ�
         ,mil.attribute6                                      distribution_block  --�u���b�N
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --�󕥋敪
        FROM
          (
            -----------------------
            --����ԕi���я��(�d����ԕi)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xrart.rcv_rtn_number                            slip_no             --�`�[No
             ,xrart.vendor_code                               other_code          --�����R�[�h
             ,pv.vendor_name                                 other_name          --����於��
             ,gv_adji_xrart                                   adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_rcv_and_rtn_txns                           xrart               --����ԕi���уA�h�I��
             ,po_vendors                                      pv
             ,xxcmn_vendors                                   xv
            --����ԕi����(�A�h�I��)���o����
            WHERE xrart.txns_type IN ('2', '3')                             --���ы敪
            AND TRUNC(xrart.txns_date)                                            --�����
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xrart.txns_id                                    --����ID
            --�d������view���o����
            AND xrart.vendor_id = pv.vendor_id                                   --�����ID
            AND xrart.txns_date                                                   --�����
              BETWEEN xv.start_date_active                                           --�K�p�J�n��
              AND NVL(xv.end_date_active,xrart.txns_date)                            --�K�p�I����
            AND pv.vendor_id = xv.vendor_id
            UNION ALL
            -----------------------
            --����ԕi���я��(�����݌�)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xrart.source_document_number                    slip_no             --�`�[No
              ,xrart.vendor_code                              other_code          --�����R�[�h(�����)
              ,xv.vendor_name                                 other_name          --������(����於)
             ,gv_adji_xrart                                   adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_rcv_and_rtn_txns                           xrart               --����ԕi���уA�h�I��
             ,po_vendors                                      pv
             ,xxcmn_vendors                                   xv
             ,po_headers_all                                  pha                 --�����w�b�_
            --����ԕi����(�A�h�I��)���o����
            WHERE xrart.txns_type  = gv_txns_type_rcv                             --���ы敪
            AND TRUNC(xrart.txns_date)                                            --�����
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xrart.txns_id                                    --����ID
            --�d������view���o����
            AND xrart.vendor_id = pv.vendor_id                                   --�����ID
            AND xrart.txns_date                                                   --�����
              BETWEEN xv.start_date_active                                       --�K�p�J�n��
              AND NVL(xv.end_date_active, xrart.txns_date)                       --�K�p�I����
            --�����w�b�_
            AND xrart.source_document_number = pha.segment1                       --�����ԍ�
            AND pha.attribute11 = po_type_inv                                     --�����敪(�����݌�)
            AND pv.vendor_id = xv.vendor_id
            UNION ALL
            -----------------------
            --���t���я��
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xnpt.entry_number                               slip_no             --�`�[No
             ,NULL                                            other_code          --�����R�[�h
             ,NULL                                            ohter_name          --����於
             ,gv_adji_xnpt                                    adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_namaha_prod_txns                           xnpt                --���t���уA�h�I��
            --���t���уA�h�I�����o����
            WHERE TRUNC(xnpt.creation_date)                                       --�쐬��
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xnpt.entry_number                                --�`�[No
            UNION ALL
            -----------------------
            --�O���o��������(�A�h�I��)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
              ,''                                             slip_no             --�`�[No
              ,xvst.vendor_code                               other_code          --�����R�[�h(�����)
              ,xv.vendor_name                                 other_name          --������(����於)
              ,gv_adji_xvst                                   adji_type           --�݌Ƀ^�C�v

            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_vendor_supply_txns                         xvst                --�O���o��������(�A�h�I��)
             ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
             ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
             ,po_vendors                                      pv
             ,xxcmn_vendors                                   xv
            --�O���o�������уA�h�I�����o����
            WHERE ijm.attribute1 = xvst.txns_id                                   --����ID
            --OPM�݌ɒ����W���[�i�����o����
            AND ijm.journal_id = iaj.journal_id
            --OPM�����݌Ƀg�����U�N�V�������o����
            AND iaj.doc_id = itc.doc_id
            AND iaj.doc_line = itc.doc_line
            AND itc.trans_date
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)

            --�d������view���o����
            AND xvst.vendor_id = pv.vendor_id                                   --�����ID
            AND itc.trans_date                                                   --�����
              BETWEEN xv.start_date_active                                      --�K�p�J�n��
              AND NVL(xv.end_date_active, itc.trans_date)                       --�K�p�I����
            AND pv.vendor_id = xv.vendor_id
            AND iaj.trans_type = 'ADJI'                                               --�����^�C�v
            AND itc.doc_type = 'ADJI'                                                 --�����^�C�v
            AND itc.doc_id = iaj.doc_id                                               --����ID
            AND itc.doc_line = iaj.doc_line                                           --������הԍ�
            UNION ALL
            -----------------------
            --EBS�W���̍݌ɒ���
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,ijm.journal_no                                  slip_no             --�`�[No
             ,NULL                                            other_code          --�����R�[�h
             ,NULL                                            other_name          --����於
             ,gv_adji_ijm                                     adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
             ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
            --OPM�W���[�i���}�X�^���o����
            WHERE ijm.attribute1 IS NULL
            --OPM�݌ɒ����W���[�i�����o����
            AND ijm.journal_id = iaj.journal_id
            --OPM�����݌Ƀg�����U�N�V�������o����
            AND iaj.doc_id = itc.doc_id
            AND iaj.doc_line = itc.doc_line
            AND itc.trans_date
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
              AND iaj.trans_type = 'ADJI'                                               --�����^�C�v
              AND itc.doc_type = 'ADJI'                                                 --�����^�C�v
              AND itc.doc_id = iaj.doc_id                                               --����ID
              AND itc.doc_line = iaj.doc_line                                           --������הԍ�
         ) ad_info
         ,ic_adjs_jnl                                         iaj                 --OPM�݌ɒ����W���[�i��
         ,ic_tran_cmp                                         itc                 --OPM�����݌Ƀg�����U�N�V����
         ,ic_whse_mst                                         iwm
         ,hr_all_organization_units                           haou
         ,mtl_item_locations                                  mil
         ,xxcmn_rcv_pay_mst                                   xrpm                --�󕥋敪�A�h�I���}�X�^
         ,xxcmn_lookup_values2_v                              xlvv                --�N�C�b�N�R�[�h
         ,sy_reas_cds_b                                       srcb                --���R�R�[�h�}�X�^
         ,mtl_categories_b                                    mcb1
         ,gmi_item_categories                                 gic1
         ,mtl_categories_b                                    mcb2
         ,gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --OPM�݌ɒ����W���[�i�����o����
        WHERE iaj.journal_id = ad_info.journal_id                                 --�W���[�i��ID
        AND iaj.trans_type = 'ADJI'                                               --�����^�C�v
        --OPM�����݌Ƀg�����U�N�V�������o����
        AND itc.doc_type = 'ADJI'                                                 --�����^�C�v
        AND itc.doc_id = iaj.doc_id                                               --����ID
        AND itc.doc_line = iaj.doc_line                                           --������הԍ�
        --�ۊǏꏊ���VIEW2���o����
        AND itc.location = mil.segment1                                          --�ۊǑq�ɃR�[�h
        AND itc.trans_date
          BETWEEN haou.date_from AND NVL(haou.date_to,itc.trans_date)             --�K�p�J�n���E�I����
        --�󕥋敪�A�h�I���}�X�^���o����
        AND xrpm.doc_type = 'ADJI'                                                --�����^�C�v
        AND itc.reason_code = xrpm.reason_code                                    --���R�R�[�h
        AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪

        AND xrpm.reason_code = srcb.reason_code                                   --���R�R�[�h
        AND srcb.delete_mark = 0                                                  --�폜�}�[�N(���폜)
        --�N�C�b�N�R�[�h���o����
        AND xlvv.lookup_type =  gv_lookup_newdiv                                  --�Q�ƃ^�C�v(�V�敪)
        AND xrpm.new_div_invent = xlvv.lookup_code                                --�Q�ƃR�[�h
        AND itc.trans_date
          BETWEEN xlvv.start_date_active
          AND NVL(xlvv.end_date_active,itc.trans_date)                            --�K�p�J�n���E�I����
        AND iwm.mtl_organization_id = haou.organization_id
        AND haou.organization_id    = mil.organization_id
--
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND itc.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND itc.item_id = gic2.item_id
        AND gic2.category_set_id    = cn_item_class_id
--
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        ----------------------------------------------------------------------------------------
        GROUP BY 
          itc.doc_id                                                              --����ID
         ,itc.item_id                                                             --�i��ID
         ,itc.lot_id                                                              --���b�gID
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                                      --���t
         ,xrpm.new_div_invent                                                     --�V�敪
         ,ad_info.slip_no                                                         --�`�[No
         ,xlvv.description                                                        --����於��
         ,itc.whse_code                                                           --�q�ɃR�[�h
         ,iwm.whse_name                                                          --�q�ɖ�
         ,itc.location                                                            --�ۊǑq�ɃR�[�h
         ,mil.description                                                        --�ۊǑq�ɖ�
         ,mil.attribute6                                                 --�u���b�N
         ,xrpm.rcv_pay_div                                                        --�󕥋敪
         ,ad_info.adji_type                                                       --�݌Ƀ^�C�v
         ,ad_info.other_name                                                      --����於
         ,ad_info.other_code                                                      --�����R�[�h
       ) slip
       ,mtl_categories_b                                       mcb1
       ,gmi_item_categories                                    gic1
       ,mtl_categories_b                                       mcb2
       ,gmi_item_categories                                    gic2
       ,mtl_categories_tl                                      mct2
       ,xxcmn_lookup_values2_v                                 xlvv                --�N�C�b�N�R�[�h
       ,ic_item_mst_b                                          iimb
       ,xxcmn_item_mst_b                                       ximb
       ,ic_lots_mst                                            ilm                 --OPM���b�g�}�X�^(�����p)
      --======================================================================================================
      --�J�e�S���Z�b�g�����i�敪�ł���i��
      WHERE slip.item_id = gic1.item_id
      AND gic1.category_set_id    = cn_prod_class_id
      AND mcb1.category_id       = gic1.category_id
      --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
      AND slip.item_id = gic2.item_id
      AND gic2.category_set_id    = cn_item_class_id
      AND mcb2.category_id        = gic2.category_id
      AND mcb2.category_id        = mct2.category_id
      AND mct2.language           = 'JA'
      AND mct2.source_lang        = 'JA'
      --�N�C�b�N�R�[�h���o����
      AND xlvv.lookup_type =  gv_lookup_newdiv                                    --�Q�ƃ^�C�v(�V�敪)
      AND slip.reason_code = xlvv.lookup_code                                     --�Q�ƃR�[�h
      AND TO_DATE(slip.standard_date,gv_fmt_ymd)
        BETWEEN xlvv.start_date_active
        AND NVL(xlvv.end_date_active,TO_DATE(slip.standard_date,gv_fmt_ymd))      --�K�p�J�n���E�I����
      AND slip.item_id = iimb.item_id                                             --�i��ID
      AND TO_DATE(slip.standard_date,gv_fmt_ymd)
        BETWEEN ximb.start_date_active
        AND NVL(ximb.end_date_active,TO_DATE(slip.standard_date,gv_fmt_ymd))--�K�p�J�n���E�I����
      AND slip.item_id = ilm.item_id
      AND slip.lot_id = ilm.lot_id
      AND iimb.item_id = ximb.item_id
      --�p�����[�^�ɂ��i����(���i�敪)
      AND mcb1.segment1 = civ_prod_div
      --�p�����[�^�ɂ��i����(�i�ڋ敪)
      AND mcb2.segment1 = civ_item_div
      --�p�����[�^�ɂ��i����(���b�gNo)
      AND ( civ_lot_no_01 IS NULL
        AND civ_lot_no_02 IS NULL
        AND civ_lot_no_03 IS NULL
      OR civ_lot_no_01 = ilm.lot_no
      OR civ_lot_no_02 = ilm.lot_no
      OR civ_lot_no_03 = ilm.lot_no
      )
      --�p�����[�^�ɂ��i����(�����N����)
      AND ( civ_mnfctr_date_01 IS NULL
        AND civ_mnfctr_date_02 IS NULL
        AND civ_mnfctr_date_03 IS NULL
      OR civ_mnfctr_date_01 = ilm.attribute1
      OR civ_mnfctr_date_02 = ilm.attribute1
      OR civ_mnfctr_date_03 = ilm.attribute1
      )
      --�p�����[�^�ɂ��i����(�ŗL�L��)
      AND  ( civ_symbol IS NULL
      OR  civ_symbol = ilm.attribute2
      )
      AND
      (
           NVL(civ_block_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_block_02,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_block_03,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
        --�p�����[�^�ɂ��i����(�����u���b�N)
        OR  slip.distribution_block IN (civ_block_01,civ_block_02,civ_block_03)
        --�p�����[�^�ɂ��i����(�ۊǑq��)
        OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_loc
          AND slip.location IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
        --�p�����[�^�ɂ��i����(�q��)
        OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_wh
          AND  slip.whse_code IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
      )
      --�p�����[�^�ɂ��i����(�i��)
      AND ( NVL(civ_item_code_01,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_item_code_02,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_item_code_03,gv_nullvalue) = gv_nullvalue
      OR  iimb.item_no IN (civ_item_code_01, civ_item_code_02, civ_item_code_03)
      )
      AND ( NVL(civ_reason_code_01,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_reason_code_02,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_reason_code_03,gv_nullvalue) = gv_nullvalue
      OR slip.reason_code IN (civ_reason_code_01, civ_reason_code_02, civ_reason_code_03)
      )
      --�p�����[�^�ɂ��i����(���o�ɋ敪)
      AND ( civ_inout_ctl = gv_inout_ctl_all --���o�ɗ������w�肵���ꍇ
      OR    civ_inout_ctl = gv_inout_ctl_in  --���ɂ��w�肵���ꍇ
        AND slip.rcv_pay_div = gv_rcvdiv_rcv   --�󕥋敪�͎���̂ݑΏ�
      OR    civ_inout_ctl = gv_inout_ctl_out --�o�ɂ��w�肵���ꍇ
        AND slip.rcv_pay_div = gv_rcvdiv_pay   --�󕥋敪�͕��o�̂ݑΏ�
      )
      ORDER BY slip.location
              ,TO_NUMBER(iimb.item_no)
              ,slip.standard_date
              ,slip.reason_code
              ,slip.slip_no
      ;
--
    -- ������p�J�[�\��
    CURSOR cur_main_data2(
      civ_ymd_from VARCHAR2        --�N����_FROM
     ,civ_ymd_to VARCHAR2          --�N����_TO
     ,civ_base_date VARCHAR2       --������^�����
     ,civ_inout_ctl VARCHAR2       --���o�ɋ敪
     ,civ_prod_div VARCHAR2        --���i�敪
     ,civ_unit_ctl VARCHAR2        --�P�ʋ敪
     ,civ_wh_loc_ctl VARCHAR2      --�q��/�ۊǑq�ɑI���敪
     ,civ_wh_code_01 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h1
     ,civ_wh_code_02 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h2
     ,civ_wh_code_03 VARCHAR2      --�q��/�ۊǑq�ɃR�[�h3
     ,civ_block_01 VARCHAR2        --�u���b�N1
     ,civ_block_02 VARCHAR2        --�u���b�N2
     ,civ_block_03 VARCHAR2        --�u���b�N3
     ,civ_item_div VARCHAR2        --�i�ڋ敪
     ,civ_item_code_01 VARCHAR2    --�i�ڃR�[�h1
     ,civ_item_code_02 VARCHAR2    --�i�ڃR�[�h2
     ,civ_item_code_03 VARCHAR2    --�i�ڃR�[�h3
     ,civ_lot_no_01 VARCHAR2       --���b�gNo1
     ,civ_lot_no_02 VARCHAR2       --���b�gNo2
     ,civ_lot_no_03 VARCHAR2       --���b�gNo3
     ,civ_mnfctr_date_01 VARCHAR2  --�����N����1
     ,civ_mnfctr_date_02 VARCHAR2  --�����N����2
     ,civ_mnfctr_date_03 VARCHAR2  --�����N����3
     ,civ_reason_code_01 VARCHAR2  --���R�R�[�h1
     ,civ_reason_code_02 VARCHAR2  --���R�R�[�h2
     ,civ_reason_code_03 VARCHAR2  --���R�R�[�h3
     ,civ_symbol VARCHAR2          --�ŗL�L��
    )
    IS 
      --======================================================================================================
      SELECT
        slip.whse_code                                        whse_code           --�q�ɃR�[�h
       ,slip.whse_name                                        whse_name           --�q�ɖ���
       ,slip.location                                         strg_wh_code        --�ۊǑq�ɃR�[�h
       ,slip.description                                      strg_wh_name        --�ۊǑq�ɖ���
       ,iimb.item_no                                          item_code           --�i�ڃR�[�h
       ,ximb.item_short_name                                  item_name           --�i�ږ���
       ,slip.standard_date                                    standard_date       --���t
       ,slip.reason_code                                      reason_code         --���R�R�[�h
       ,xlvv.meaning                                          reason_name         --���R�R�[�h����
       ,slip.slip_no                                          slip_no             --�`�[�ԍ�
       ,slip.out_date                                         out_date            --�o�ɓ�
       ,slip.in_date                                          in_date             --����
       ,slip.jrsd_code                                        jrsd_code           --�Ǌ����_�R�[�h
       ,slip.jrsd_name                                        jrsd_name           --�Ǌ����_����
       ,slip.other_code                                       other_code          --�����R�[�h
       ,CASE slip.territory
          WHEN gv_trtry_ad THEN
            NVL(slip.other_name,xlvv.meaning)
          ELSE slip.other_name
        END                                                   other_name          --����於
       ,DECODE(iimb.lot_ctl
              ,gn_lotctl_yes,ilm.lot_no
              ,NULL)                                          lot_no              --���b�gNo
       ,DECODE(iimb.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute1,1,10)
              ,NULL)                                          mnfctr_date         --�����N����
       ,DECODE(iimb.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute3,1,10)
              ,NULL)                                          limit_date          --�ܖ�����
       ,DECODE(iimb.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute2,1,6)
              ,NULL)                                          symbol              --�ŗL�L��
--mod start 2.1
--       ,CASE slip.territory
--          WHEN gv_trtry_po THEN ximv.item_um                                        --�����F�P��
--          WHEN gv_trtry_mv THEN ximv.item_um                                        --�ړ��F�P��
--          WHEN gv_trtry_sh THEN ximv.conv_unit                                      --�o�ׁF���o�Ɋ��Z�P��
--          WHEN gv_trtry_rt THEN ximv.conv_unit                                      --�q�֕ԕi�F���o�Ɋ��Z�P��
--          WHEN gv_trtry_mf THEN ximv.item_um                                        --���Y�F�P��
--          WHEN gv_trtry_ad THEN ximv.item_um                                        --�݌ɒ����F�P��
--          ELSE NULL
--        END                                                   unit                --�P��
       ,DECODE(civ_unit_ctl
              ,gv_unitctl_qty ,iimb.item_um
              ,gv_unitctl_case,iimb.attribute24
              ,NULL)                                          unit                --�P��
--mod end 2.1
       ,iimb.attribute11                                      num_of_cases        --�P�[�X���萔
       ,NVL(slip.in_qty,0)                                    in_qty              --���ɐ�
-- mod start 1.18
--mod start 1.5
       ,NVL(slip.out_qty,0)                                   out_qty             --�o�ɐ�
--       ,ABS(NVL(slip.out_qty,0))                                   out_qty             --�o�ɐ�
--mod end 1.5
-- mod end 1.18
       ,mct2.description                                      item_div_name       --�i�ڋ敪����
      FROM (
      --======================================================================================================
        ------------------------------
        -- 1.�������я��
        ------------------------------
-- mod start 1.25
        --SELECT /*+ leading(pha pla rsl itp iimb gic1 mcb1 gic2 mcb2 rt xrart xrpm pv xv mil iwm) use_nl(pha pla rsl itp iimb gic1 mcb1 gic2 mcb2 rt xrart xrpm pv xv mil iwm) */
        SELECT /*+ leading(pha pla rsl rt itp gic1 mcb1 gic2 mcb2) use_nl(pha pla rsl rt itp gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
          gv_trtry_po                                         territory           --�̈�(����)
         ,iimb.item_id                                        item_id             --�i��ID
         ,itp.lot_id                                          lot_id              --���b�gID
         ,pha.attribute4                                      standard_date       --���t
         ,xrpm.new_div_invent                                 reason_code         --�V�敪
         ,pha.segment1                                        slip_no             --�`�[No
         ,pha.attribute4                                      out_date            --�o�ɓ�
         ,pha.attribute4                                      in_date             --����
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,pv.segment1                                         other_code          --�����R�[�h
         ,pv.vendor_name                                      other_name          --����於��
         ,SUM(NVL(pla.quantity,0))                            in_qty              --���ɐ�
         ,0                                                   out_qty             --�o�ɐ�
         ,itp.whse_code                                       whse_code           --�q�ɃR�[�h
         ,iwm.whse_name                                       whse_name           --�q�ɖ�
         ,itp.location                                        location            --�ۊǑq�ɃR�[�h
         ,mil.description                                     description         --�ۊǑq�ɖ�
         ,mil.attribute6                                      distribution_block  --�u���b�N
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --�󕥋敪
        FROM
        ----------------------------------------------------------------------------------------
          po_headers_all                                      pha                 --�����w�b�_
         ,po_lines_all                                        pla                 --��������
         ,rcv_shipment_lines                                  rsl                 --�������
         ,rcv_transactions                                    rt                  --������
         ,ic_lots_mst                                         ilm                 --OPM���b�g�}�X�^(�����p)
         ,xxpo_rcv_and_rtn_txns                               xrart               --����ԕi����
         ,po_vendors                                          pv
         ,xxcmn_vendors                                       xv
         ,ic_whse_mst                                         iwm
         ,mtl_item_locations                                  mil
         ,ic_item_mst_b                                       iimb
         ,ic_tran_pnd                                         itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
         ,xxcmn_rcv_pay_mst                                   xrpm                --����敪�A�h�I���}�X�^
         ,mtl_categories_b                                    mcb1
         ,gmi_item_categories                                 gic1
         ,mtl_categories_b                                    mcb2
         ,gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --�����w�b�_���o����
        WHERE pha.attribute1 IN (gv_po_sts_rcv, gv_po_sts_qty_deci, gv_po_sts_price_deci)--�X�e�[�^�X
        AND pha.attribute4 BETWEEN civ_ymd_from AND civ_ymd_to                    --�[����
        --�������ג��o����
        AND pha.po_header_id = pla.po_header_id                                   --�����w�b�_ID
        AND pla.attribute13 = gv_po_flg_qty                                       --���ʊm��t���O
        --������ג��o����
        AND rsl.po_header_id = pha.po_header_id                                   --�����w�b�_ID
        AND rsl.po_line_id = pla.po_line_id                                       --��������ID
        --���������o����
        AND rsl.shipment_line_id = rt.shipment_line_id                            --�������ID
        --����ԕi���ђ��o����
        AND pha.segment1 = xrart.source_document_number                           --�������ԍ�
        AND pla.line_num = xrart.source_document_line_num                         --���������הԍ�
        AND xrart.txns_type = gv_txns_type_rcv                                    --���ы敪
        --�ۊǏꏊ�}�X�^VIEW���o����
        AND pha.vendor_id = pv.vendor_id                                         --�d����ID
        AND xv.start_date_active <= TO_DATE(civ_ymd_from,gv_fmt_ymd)
        AND xv.end_date_active >= TO_DATE(civ_ymd_from,gv_fmt_ymd)
        AND itp.doc_type = 'PORC'                                                 --�����^�C�v
        AND rsl.shipment_header_id = itp.doc_id                                   --����ID
        AND rsl.line_num = itp.doc_line                                           --������הԍ�
        AND rt.transaction_id = itp.line_id                                       --���C��ID
        AND iimb.item_id = itp.item_id                                            --�i��ID
        AND ilm.lot_id = itp.lot_id                                               --���b�gID
        AND mil.segment1 = itp.location                                          --�ۊǑq�ɃR�[�h
        AND itp.completed_ind = gv_tran_cmp                                       --�����t���O
        --�󕥋敪�}�X�^�A�h�I�����o����
        AND xrpm.doc_type = 'PORC'                                                --�����^�C�v
        AND xrpm.source_document_code = 'PO'                                      --�\�[�X����
        AND xrpm.transaction_type = rt.transaction_type                           --PO����^�C�v
        AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪
        AND iwm.mtl_organization_id = mil.organization_id
        AND pv.vendor_id = xv.vendor_id
        AND iimb.inactive_ind       <> '1'
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND iimb.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND iimb.item_id = gic2.item_id
        AND gic2.category_set_id   = cn_item_class_id
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        AND ilm.item_id            = itp.item_id
        ----------------------------------------------------------------------------------------
        GROUP BY
          iimb.item_id                                                            --�i��ID
         ,itp.lot_id                                                              --���b�gID
         ,pha.attribute4                                                          --���t
         ,xrpm.new_div_invent                                                     --�V�敪
         ,pha.segment1                                                            --�`�[No
         ,pha.attribute4                                                          --�o�ɓ�/����
         ,pv.segment1
         ,pv.vendor_name
         ,itp.whse_code                                                           --�q�ɃR�[�h
         ,iwm.whse_name
         ,itp.location                                                            --�ۊǑq�ɃR�[�h
         ,mil.description
         ,mil.attribute6
         ,xrpm.rcv_pay_div                                                        --�󕥋敪
         ,xrpm.transaction_type                                                   --PO����^�C�v
        UNION ALL
        ------------------------------
        -- 2.�ړ����я��
        ------------------------------
        SELECT
          gv_trtry_mv                                         territory           --�̈�(�ړ�)
         ,iimb.item_id                                        item_id             --�i��ID
         ,xm.lot_id                                           lot_id              --���b�gID
         ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)             standard_date       --���t
         ,xm.new_div_invent                                   reason_code         --�V�敪
         ,xm.mov_num                                          slip_no             --�`�[No
         ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)             out_date            --�o�ɓ�
         ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)          in_date             --���ɓ�
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,xm.other_code                                       other_code          --�����R�[�h
         ,mil2.description                                    other_name          --����於��
         ,CASE xm.record_type
            WHEN gv_rectype_in THEN
              SUM(NVL(xm.trans_qty,0))
            ELSE 0 END                                        in_qty              --���ɐ�
         ,CASE xm.record_type
            WHEN gv_rectype_out THEN
              ABS(SUM(NVL(xm.trans_qty,0)) * -1)
            ELSE 0 END                                        out_qty             --�o�ɐ�
         ,CASE xm.mov_type --�ړ��^�C�v
            WHEN gv_movetype_yes THEN xm.whse_code --�ϑ�����
            WHEN gv_movetype_no THEN xm.whse_code --�ϑ��Ȃ�
            ELSE NULL
          END                                                 whse_code           --�q�ɃR�[�h
         ,iwm1.whse_name                                      whse_name           --�q�ɖ�
         ,CASE xm.mov_type --�ړ��^�C�v
            WHEN gv_movetype_yes THEN xm.location --�ϑ�����
            WHEN gv_movetype_no THEN xm.location --�ϑ��Ȃ�
            ELSE NULL
          END                                                 location            --�ۊǑq�ɃR�[�h
         ,mil1.description                                    description         --�ۊǑq�ɖ�
         ,mil1.attribute6                                     distribution_block  --�u���b�N
         ,xm.rcv_pay_div                                      rcv_pay_div         --�󕥋敪
       FROM
        (
-------------------------------------------------------------------------------------------------------------------
         --�ϑ�����(�o�Ɏ���)
-- mod start 1.25
         --SELECT /*+ leading(xmrih xmril xmld mil itp ixm gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld mil itp ixm gic1 mcb1 gic2 mcb2) */
         SELECT /*+ leading(xmrih xmril xmld ixm itp gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ixm itp gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_out                                  record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_ship_date                          arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          other_id                --�����ID(���ɐ�ID)
          ,xmrih.ship_to_locat_code                        other_code              --�����(���ɐ�ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil.segment1                                    segment1                --�ۊǏꏊ�R�[�h
          ,itp.doc_type                                    doc_type                --�����^�C�v
          ,itp.trans_qty                                   trans_qty               --����
          ,itp.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itp.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_pay                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_pay                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers      xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,xxinv_mov_req_instr_lines        xmril               --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details            xmld                --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations               mil
          ,ic_xfer_mst                      ixm                 --OPM�݌ɓ]���}�X�^
          ,ic_tran_pnd                      itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
          ,gmi_item_categories              gic1
          ,mtl_categories_b                 mcb1
          ,gmi_item_categories              gic2
          ,mtl_categories_b                 mcb2
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         AND xmrih.mov_type = gv_movetype_yes
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_out                               --���R�[�h�^�C�v
         AND xmrih.shipped_locat_id = mil.inventory_location_id                   --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ixm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ixm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND itp.doc_type = 'XFER'                                                --�����^�C�v
         AND xmrih.actual_ship_date                                            --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND gic1.item_id  = itp.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div
         AND gic2.item_id = itp.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND ixm.transfer_id = itp.doc_id                                         --����ID
         AND xmril.item_id = itp.item_id                                          --�i��ID
         AND xmld.lot_id (+) = itp.lot_id
         AND mil.segment1 = itp.location                                          --�ۊǑq�ɃR�[�h
         AND itp.completed_ind = gv_tran_cmp                                      --�����t���O
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT 1
             FROM ic_tran_pnd itp2                                                --OPM�ۗ��݌Ƀg�����U�N�V����
             WHERE itp.doc_id = itp2.doc_id                                       --����ID
             AND   itp.whse_code = itp2.whse_code                                 --�q�ɃR�[�h
             AND   itp.trans_id <> itp2.trans_id
             AND   ROWNUM   = 1
             )
         UNION ALL -- �ϑ�����(���Ɏ���)
-- mod start 1.25
         --SELECT /*+ leading(xmrih xmril xmld mil itp ixm gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld mil itp ixm gic1 mcb1 gic2 mcb2) */
         SELECT /*+ leading(xmrih xmril xmld ixm itp gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ixm itp gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_in                                   record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_arrival_date                       arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.ship_to_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_ship_date                          arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          other_id                --�����ID(���ɐ�ID)
          ,xmrih.shipped_locat_code                        other_code              --�����(���ɐ�ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itp.doc_type                                    doc_type                --�����^�C�v
          ,itp.trans_qty                                   trans_qty               --����
          ,itp.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itp.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_rcv                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_rcv                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers      xmrih
          ,xxinv_mov_req_instr_lines        xmril               --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details            xmld                --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations               mil
          ,ic_xfer_mst                      ixm                 --OPM�݌ɓ]���}�X�^
          ,ic_tran_pnd                      itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
          ,gmi_item_categories              gic1
          ,mtl_categories_b                 mcb1
          ,gmi_item_categories              gic2
          ,mtl_categories_b                 mcb2
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         AND xmrih.mov_type = gv_movetype_yes
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_in                            --���R�[�h�^�C�v
         AND xmrih.actual_ship_date                                              --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND xmrih.ship_to_locat_id = mil.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ixm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ixm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND itp.doc_type = 'XFER'                                                --�����^�C�v
         AND gic1.item_id = itp.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div
         AND gic2.item_id  = itp.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND ixm.transfer_id = itp.doc_id                                         --����ID
         AND xmril.item_id = itp.item_id                                          --�i��ID
         AND xmld.lot_id (+) = itp.lot_id
         AND mil.segment1 = itp.location                                         --�ۊǑq�ɃR�[�h
         AND itp.completed_ind = gv_tran_cmp                                      --�����t���O
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT 1
             FROM ic_tran_pnd itp2                                                --OPM�ۗ��݌Ƀg�����U�N�V����
             WHERE itp.doc_id = itp2.doc_id                                       --����ID
             AND   itp.whse_code = itp2.whse_code                                 --�q�ɃR�[�h
             AND   itp.trans_id <> itp2.trans_id
             AND   ROWNUM   = 1
             )
         UNION ALL
         --�ϑ�����(ADJI)(�o�Ɏ���)
-- mod start 1.25
         --SELECT
         SELECT /*+ leading(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_out                                  record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_ship_date                          arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          other_id                --�����ID(���ɐ�ID)
          ,xmrih.ship_to_locat_code                        other_code              --�����(���ɐ�ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil3.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itc.doc_type                                    doc_type                --�����^�C�v
          ,itc.trans_qty                                   trans_qty               --����
          ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itc.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_pay                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_pay                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers                     xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,mtl_item_locations                              mil1
          ,ic_whse_mst                                     iwm1
          ,mtl_item_locations                              mil2
          ,ic_whse_mst                                     iwm2
          ,xxinv_mov_req_instr_lines                       xmril               --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details                           xmld                --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations                              mil3
          ,ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
          ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
          ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
          ,gmi_item_categories                             gic1
          ,mtl_categories_b                                mcb1
          ,gmi_item_categories                             gic2
          ,mtl_categories_b                                mcb2
         --�ړ��˗�/�w������(�A�h�I��)���o����
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         AND xmrih.mov_type = gv_movetype_yes                                --�ړ��^�C�v(�ϑ�����)
          --OPM�ۊǏꏊ���VIEW2(�ۊǑq��)���o����
         AND iwm1.mtl_organization_id = mil1.organization_id
         AND iwm2.mtl_organization_id = mil2.organization_id
         AND xmrih.shipped_locat_id = mil1.inventory_location_id                        --�ۊǑq��ID
         AND xmrih.ship_to_locat_id = mil2.inventory_location_id                        --�ۊǑq��ID
         AND iwm1.whse_code <> iwm2.whse_code                      --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_out                            --���R�[�h�^�C�v
         AND xmrih.actual_ship_date                                              --���Ɏ��ѓ�
               BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
               AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND xmrih.shipped_locat_id = mil3.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ijm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND mil3.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         AND itc.doc_type = 'ADJI'                                                --�����^�C�v
         AND gic1.item_id = itc.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div                                --�i��ID
         AND gic2.item_id = itc.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND xmld.lot_id (+) = itc.lot_id  
         UNION ALL
         --�ϑ�����(ADJI) (���Ɏ���)
-- mod start 1.25
         --SELECT 
         SELECT /*+ leading(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_in                                   record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_arrival_date                       arvl_ship_date          --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          locat_id                --�ۊǑq��ID(���Ɍ�ID)
          ,xmrih.ship_to_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(���Ɍ��ۊǏꏊ)
          ,xmrih.actual_ship_date                          arvl_ship_date2          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          other_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        other_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil3.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itc.doc_type                                    doc_type                --�����^�C�v
          ,itc.trans_qty                                   trans_qty               --����
          ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itc.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_rcv                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_rcv                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers                     xmrih               --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,mtl_item_locations                              mil1
          ,ic_whse_mst                                     iwm1
          ,mtl_item_locations                              mil2
          ,ic_whse_mst                                     iwm2
          ,xxinv_mov_req_instr_lines                       xmril               --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details                           xmld                --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations                              mil3
          ,ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
          ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
          ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
          ,gmi_item_categories                             gic1
          ,mtl_categories_b                                mcb1
          ,gmi_item_categories                             gic2
          ,mtl_categories_b                                mcb2
         --�ړ��˗�/�w������(�A�h�I��)���o����
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --�ړ��w�b�_ID
         AND xmrih.mov_type = gv_movetype_yes                                --�ړ��^�C�v(�ϑ�����)
         AND iwm1.mtl_organization_id = mil1.organization_id
         AND iwm2.mtl_organization_id = mil2.organization_id
            AND xmrih.shipped_locat_id = mil1.inventory_location_id                        --�ۊǑq��ID
            AND xmrih.ship_to_locat_id = mil2.inventory_location_id                        --�ۊǑq��ID
            AND iwm1.whse_code <> iwm2.whse_code                      --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_in                            --���R�[�h�^�C�v
         AND xmrih.actual_ship_date                                              --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND xmrih.ship_to_locat_id = mil3.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ijm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND mil3.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         AND itc.doc_type = 'ADJI'                                                --�����^�C�v
         AND gic1.item_id = itc.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div                                 --�i��ID
         AND gic2.item_id = itc.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND ( xmld.lot_id IS NOT NULL 
           AND xmld.lot_id = itc.lot_id                                           --���b�gID
         OR    xmld.lot_id IS NULL
         )
-------------------------------------------------------------------------------------------------------------------
         UNION ALL
         --�ϑ��Ȃ� (�o�Ɏ���)
-- mod start 1.25
         --SELECT /*+ leading(xmrih xmril xmld mil itc ija ijm gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld mil itc ija ijm gic1 mcb1 gic2 mcb2) */
         SELECT /*+ leading(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_out                                  record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_ship_date                          arvl_ship_date          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          locat_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       arvl_ship_date2         --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          other_id                --�����ID(���ɐ�ID)
          ,xmrih.ship_to_locat_code                        other_code              --�����(���ɐ�ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itc.doc_type                                    doc_type                --�����^�C�v
          ,itc.trans_qty                                   trans_qty               --����
          ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itc.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_pay                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_pay                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers      xmrih                   --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,xxinv_mov_req_instr_lines        xmril                   --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details            xmld                    --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations               mil
          ,ic_jrnl_mst                      ijm                     --OPM�W���[�i���}�X�^
          ,ic_adjs_jnl                      iaj                     --OPM�݌ɒ����W���[�i��
          ,ic_tran_cmp                      itc                     --OPM�����݌Ƀg�����U�N�V����
          ,gmi_item_categories              gic1
          ,mtl_categories_b                 mcb1
          ,gmi_item_categories              gic2
          ,mtl_categories_b                 mcb2
         WHERE xmrih.actual_ship_date = xmrih.actual_arrival_date                 --�o�׎��ѓ������Ɏ��ѓ�
         AND  xmrih.mov_type = gv_movetype_no                                 --�ړ��^�C�v(�ϑ��Ȃ�)
         AND xmrih.mov_hdr_id = xmril.mov_hdr_id                                  --�ړ��w�b�_ID
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_out                            --���R�[�h�^�C�v
         AND xmrih.shipped_locat_id = mil.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ijm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND mil.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         AND itc.doc_type IN ('TRNI','ADJI')                                      --�����^�C�v
         AND gic1.item_id = itc.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div                                 --�i��ID
         AND gic2.item_id = itc.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND xmrih.actual_ship_date                                              --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND xmld.lot_id (+)  = itc.lot_id
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT 1
             FROM ic_tran_cmp itc2                                                --OPM�����݌Ƀg�����U�N�V����
             WHERE itc.doc_id = itc2.doc_id                                       --����ID
             AND   itc.whse_code = itc2.whse_code                                 --�q�ɃR�[�h
             AND   itc.trans_id <> itc2.trans_id
             AND   ROWNUM = 1
             )
         UNION ALL
         --�ϑ��Ȃ� (���Ɏ���)
-- mod start 1.25
         --SELECT /*+ leading(xmrih xmril xmld mil itc ija ijm gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld mil itc ija ijm gic1 mcb1 gic2 mcb2) */
         SELECT /*+ leading(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril xmld ijm iaj itc gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
           xmrih.mov_hdr_id                                mov_hdr_id              --�ړ��w�b�_ID
          ,gv_rectype_in                                   record_type             --���R�[�h�^�C�v
          ,xmrih.comp_actual_flg                           comp_actual_flg         --���ьv��σt���O
          ,xmrih.mov_type                                  mov_type                --�ړ��^�C�v
          ,xmrih.mov_num                                   mov_num                 --�ړ��ԍ�
          ,xmrih.actual_arrival_date                       arvl_ship_date          --���ѓ�(���Ɏ��ѓ�)
          ,xmrih.ship_to_locat_id                          locat_id                --�ۊǑq��ID(���Ɍ�ID)
          ,xmrih.ship_to_locat_code                        locat_code              --�ۊǑq�ɃR�[�h(���Ɍ��ۊǏꏊ)
          ,xmrih.actual_ship_date                          arvl_ship_date2          --���ѓ�(�o�Ɏ��ѓ�)
          ,xmrih.shipped_locat_id                          other_id                --�ۊǑq��ID(�o�Ɍ�ID)
          ,xmrih.shipped_locat_code                        other_code              --�ۊǑq�ɃR�[�h(�o�Ɍ��ۊǏꏊ)
          ,xmrih.actual_arrival_date                       actual_arrival_date     --���Ɏ��ѓ�
          ,xmrih.actual_ship_date                          actual_ship_date        --�o�Ɏ��ѓ�
          ,xmril.item_id                                   item_id                 --�i��ID
          ,xmril.delete_flg                                delete_flg              --����t���O
          ,xmril.ship_to_quantity                          ship_to_quantity        --���Ɏ��ѐ���
          ,xmril.shipped_quantity                          shipped_quantity        --�o�Ɏ��ѐ���
          ,xmld.document_type_code                         document_type_code      --�����^�C�v
          ,xmld.actual_date                                actual_date             --���ѓ�
          ,xmld.lot_id                                     lot_id                  --���b�gID
          ,xmld.actual_quantity                            actual_quantity         --���ѐ���
          ,mil.segment1                                   segment1                --�ۊǏꏊ�R�[�h
          ,itc.doc_type                                    doc_type                --�����^�C�v
          ,itc.trans_qty                                   trans_qty               --����
          ,itc.whse_code                                   whse_code               --�q�ɃR�[�h
          ,itc.location                                    location                --�ۊǑq�ɃR�[�h
          ,gv_newdiv_rcv                                   new_div_invent          --�V�敪
          ,gv_rcvdiv_rcv                                   rcv_pay_div             --�󕥋敪
         FROM
           xxinv_mov_req_instr_headers                     xmrih                   --�ړ��˗�/�w���w�b�_(�A�h�I��)
          ,xxinv_mov_req_instr_lines                       xmril                   --�ړ��˗�/�w������(�A�h�I��)
          ,xxinv_mov_lot_details                           xmld                    --�ړ����b�g�ڍ�(�A�h�I��)
          ,mtl_item_locations        mil
          ,ic_jrnl_mst                                     ijm                     --OPM�W���[�i���}�X�^
          ,ic_adjs_jnl                                     iaj                     --OPM�݌ɒ����W���[�i��
          ,ic_tran_cmp                                     itc                     --OPM�����݌Ƀg�����U�N�V����
          ,gmi_item_categories              gic1
          ,mtl_categories_b                 mcb1
          ,gmi_item_categories              gic2
          ,mtl_categories_b                 mcb2
         WHERE xmrih.actual_ship_date = xmrih.actual_arrival_date                 --�o�׎��ѓ������Ɏ��ѓ�
         AND  xmrih.mov_type = gv_movetype_no                                 --�ړ��^�C�v(�ϑ��Ȃ�)
         AND xmrih.mov_hdr_id = xmril.mov_hdr_id                                  --�ړ��w�b�_ID
         AND xmld.mov_line_id = xmril.mov_line_id                                 --�ړ�����ID
         AND xmld.document_type_code = gv_dctype_move                             --�����^�C�v
         AND xmld.record_type_code = gv_rectype_in                            --���R�[�h�^�C�v
         AND xmrih.ship_to_locat_id = mil.inventory_location_id                          --�ۊǑq��ID
-- mod start 1.25
         --AND xmril.mov_line_id = ijm.attribute1                                   --�����\�[�XID
         AND TO_CHAR(xmril.mov_line_id) = ijm.attribute1                                   --�����\�[�XID
-- mod end 1.25
         AND ijm.journal_id = iaj.journal_id                                      --�W���[�i��ID
         AND mil.segment1 = iaj.location                                         --�ۊǑq�ɃR�[�h
         AND itc.doc_type IN ('TRNI','ADJI')                                      --�����^�C�v
         AND gic1.item_id = itc.item_id
         AND gic1.category_set_id = cn_item_class_id
         AND gic1.category_id = mcb1.category_id
         AND mcb1.segment1 = civ_item_div                                 --�i��ID
         AND gic2.item_id = itc.item_id
         AND gic2.category_set_id = cn_prod_class_id
         AND gic2.category_id = mcb2.category_id
         AND mcb2.segment1 = civ_prod_div
         AND xmrih.actual_ship_date                                              --���Ɏ��ѓ�
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         AND itc.doc_id = iaj.doc_id                                              --����ID
         AND itc.doc_line = iaj.doc_line                                          --������הԍ�
         AND xmril.item_id = itc.item_id                                          --�i��ID
         AND xmld.lot_id (+) = itc.lot_id
         AND NOT EXISTS (                                                         --����q�ɓ��̈ړ����͑ΏۊO�Ƃ���
             SELECT 1
             FROM ic_tran_cmp itc2                                                --OPM�����݌Ƀg�����U�N�V����
             WHERE itc.doc_id = itc2.doc_id                                       --����ID
             AND   itc.whse_code = itc2.whse_code                                 --�q�ɃR�[�h
             AND   itc.trans_id <> itc2.trans_id
             AND   ROWNUM = 1
             )
         )                          xm                  --�ړ����
         ,ic_item_mst_b             iimb
         ,xxcmn_item_mst_b          ximb
         ,mtl_item_locations        mil1
         ,ic_whse_mst               iwm1
         ,mtl_item_locations        mil2
         ,xxcmn_rcv_pay_mst         xrpm                --����敪�A�h�I���}�X�^
       WHERE xm.comp_actual_flg = gv_cmp_actl_yes                                --���ьv��t���O
       AND xm.delete_flg = gv_delete_no                                          --�폜�t���O
       AND xm.item_id = iimb.item_id                                             --�i��ID
       AND ximb.item_id = iimb.item_id
       AND xm.arvl_ship_date 
           BETWEEN ximb.start_date_active AND ximb.end_date_active                 --���ѓ�
       AND xm.locat_id = mil1.inventory_location_id                              --�ۊǑq��ID
       AND xm.other_id = mil2.inventory_location_id                             --�ۊǑq��ID(�����)
       AND xrpm.doc_type =xm.doc_type                                            --�����^�C�v
       AND TO_CHAR(SIGN(xm.trans_qty)) = xrpm.rcv_pay_div                        --�󕥋敪
       AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪
       AND xrpm.new_div_invent IN (gv_newdiv_pay,gv_newdiv_rcv)
         AND iwm1.mtl_organization_id = mil1.organization_id
       GROUP BY 
         iimb.item_id                                                            --�i��ID
        ,xm.lot_id                                                               --���b�gID
        ,xm.new_div_invent                                                       --�V�敪
        ,xm.mov_num                                                              --�`�[No
        ,mil1.description                                                        --�ۊǑq�ɖ�
        ,xm.mov_type                                                             --�ړ��^�C�v
        ,xm.whse_code                                                            --�ۗ�.�q�ɃR�[�h
        ,xm.location                                                             --�ۗ�.�ۊǑq�ɃR�[�h
        ,xm.whse_code                                                            --����.�q�ɃR�[�h
        ,xm.location                                                             --����.�ۊǑq�ɃR�[�h
        ,iwm1.whse_name                                                          --�q�ɖ�
        ,mil1.attribute6                                                 --�u���b�N
        ,xm.rcv_pay_div                                                          --�󕥋敪
        ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)
        ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)
        ,TO_CHAR(xm.arvl_ship_date,gv_fmt_ymd)
        ,xm.other_code
        ,mil2.description
        ,iimb.lot_ctl
        ,xm.record_type
       UNION ALL
       ------------------------------
       -- 3.�o��/�L���o�׎��я��
       ------------------------------
       SELECT
          gv_trtry_sh                                         territory           --�̈�(�o��)
         ,sh_info.item_id                                     item_id             --�i��ID
         ,sh_info.lot_id                                      lot_id              --���b�gID
         ,TO_CHAR(sh_info.shipped_date,gv_fmt_ymd)          standard_date       --���t
         ,sh_info.new_div_invent                              reason_code         --�V�敪
         ,sh_info.request_no                                  slip_no             --�`�[No
         ,TO_CHAR(sh_info.shipped_date,gv_fmt_ymd)          out_date            --�o�ɓ�
         ,TO_CHAR(sh_info.arrival_date,gv_fmt_ymd)          in_date             --����
         ,sh_info.head_sales_branch                           jrsd_code           --�Ǌ����_�R�[�h
         ,CASE
            WHEN hca.customer_class_code = '10'
              THEN xp.party_name
              ELSE xp.party_short_name
          END                                                 jrsd_name           --�Ǌ����_��
         ,sh_info.deliver_to                                  other_code          --�����R�[�h
         ,sh_info.party_site_full_name                        other_name          --����於��
         ,CASE sh_info.rcv_pay_div--�󕥋敪
            WHEN gv_rcvdiv_rcv THEN sh_info.trans_qty_sum
            ELSE 0
          END                                                 in_qty              --���ɐ�
         ,CASE sh_info.rcv_pay_div--�󕥋敪
            WHEN gv_rcvdiv_pay THEN 
              CASE
                WHEN (sh_info.new_div_invent = '104' AND sh_info.order_category_code = 'RETURN') THEN
                  ABS(sh_info.trans_qty_sum) * -1
                ELSE
                  ABS(sh_info.trans_qty_sum)
              END
            ELSE 0
          END                                                 out_qty             --�o�ɐ�
         ,sh_info.whse_code                                   whse_code           --�q�ɃR�[�h
         ,sh_info.whse_name                                   whse_name           --�q�ɖ�
         ,sh_info.location                                    location            --�ۊǑq�ɃR�[�h
         ,sh_info.description                                 description         --�ۊǑq�ɖ�
         ,sh_info.distribution_block                          distribution_block  --�u���b�N
         ,sh_info.rcv_pay_div                                 rcv_pay_div         --�󕥋敪
        ----------------------------------------------------------------------------------------
        FROM ( --OMSO�֘A���
-- mod start 1.25
          --SELECT
          SELECT /*+ leading(xoha ooha otta xola wdd itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) use_nl(xoha ooha otta xola wdd itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) */
-- mod end 1.25
            itp.doc_type                                  doc_type            --�����^�C�v
           ,itp.item_id                                   item_id             --�i��ID
           ,itp.whse_code                                 whse_code           --�q�ɃR�[�h
           ,iwm.whse_name                                 whse_name           --�q�ɖ�
           ,itp.location                                  location            --�ۊǑq�ɃR�[�h
           ,mil.description                               description         --�ۊǑq�ɖ�
           ,mil.inventory_location_id                     inventory_location_id   --�ۊǑq��ID
           ,itp.lot_id                                    lot_id              --���b�gID
           ,itp.doc_id                                    doc_id              --����ID
           ,itp.doc_line                                  doc_line            --������הԍ�
           ,ooha.header_id                                header_id           --�󒍃w�b�_ID
           ,ooha.order_type_id                            order_type_id       --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                              rcv_pay_div         --�󕥋敪
           ,xrpm.new_div_invent                           new_div_invent      --�V�敪
           ,SUM(itp.trans_qty)                            trans_qty_sum       --���ʍ��v
           ,mil.attribute6                                distribution_block  --�u���b�N
           ,xoha.head_sales_branch                        head_sales_branch
           ,xoha.deliver_to_id                            deliver_to_id
           ,DECODE(xoha.req_status,gv_recsts_shipped,xoha.result_deliver_to
                                  ,gv_recsts_shipped2,xoha.vendor_site_code
            ) deliver_to
           ,xoha.arrival_date                             arrival_date
           ,xoha.shipped_date                             shipped_date
           ,xoha.request_no                               request_no
           ,DECODE(xoha.req_status,gv_recsts_shipped,hps.party_site_name
                                  ,gv_recsts_shipped2,xvsa.vendor_site_name
            ) party_site_full_name
           ,otta.order_category_code                      order_category_code
          FROM
           xxwsh_order_headers_all                        xoha                --�󒍃w�b�_(�A�h�I��)
           ,hz_party_sites                                hps
           ,xxcmn_vendor_sites_all                        xvsa
           ,xxwsh_order_lines_all                         xola                --�󒍖���(�A�h�I��)
           ,oe_transaction_types_all                      otta                --�󒍃^�C�v
           ,xxcmn_rcv_pay_mst                             xrpm                --����敪�A�h�I���}�X�^
           ,ic_item_mst_b                                 iimb
           ,xxcmn_item_mst_b                              ximb
           ,ic_item_mst_b                                 iimb2
           ,xxcmn_item_mst_b                              ximb2
           ,gmi_item_categories                           gic1
           ,mtl_categories_b                              mcb1
           ,gmi_item_categories                           gic2
           ,mtl_categories_b                              mcb2
           ,gmi_item_categories                           gic3
           ,mtl_categories_b                              mcb3
           ,ic_whse_mst                                   iwm
           ,mtl_item_locations                            mil
           ,ic_tran_pnd                                   itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
           ,wsh_delivery_details                          wdd                 --�o�ה�������
           ,oe_order_headers_all                          ooha                --�󒍃w�b�_
-- mod start 1.25
          --WHERE ooha.header_id = xoha.header_id                                --�󒍃w�b�_ID
          WHERE  wdd.delivery_detail_id  = itp.line_detail_id
          AND wdd.source_header_id    = xoha.header_id
          AND wdd.source_line_id      = xola.line_id
          AND xoha.header_id          = ooha.header_id
          AND xola.order_header_id    = xoha.order_header_id
          AND itp.doc_type = 'OMSO'
          AND itp.completed_ind = gv_tran_cmp                                 --�����t���O
          --AND itp.line_id = wdd.source_line_id                                --�\�[�X����ID
          --AND wdd.org_id = ooha.org_id                                        --�g�DID
          --AND wdd.source_header_id = ooha.header_id                           --�󒍃w�b�_ID
          AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --�X�e�[�^�X
          AND xoha.actual_confirm_class = gv_confirm_yes                            --���ьv��敪
          AND xoha.latest_external_flag = gv_latest_yes                             --�ŐV�t���O
          --AND xoha.order_header_id = xola.order_header_id                         --�󒍃A�h�I���w�b�_ID
-- mod end 1.25
          AND ooha.order_type_id = otta.transaction_type_id                    --�󒍃^�C�vID
          AND xola.shipping_item_code = iimb.item_no                            --�i�ڃR�[�h
          AND itp.item_id         = iimb.item_id                            --�i��ID
          AND ximb.item_id        = iimb.item_id                            --�i��ID
          AND itp.trans_date
            BETWEEN ximb.start_date_active
            AND ximb.end_date_active
          --  AND NVL(ximb.end_date_active,itp.trans_date)                    --�K�p�J�n���E�I����
          --AND iimb.item_id = gic1.item_id                                     --�i��ID
          AND gic1.item_id = itp.item_id
          AND gic1.category_set_id = cn_item_class_id
          AND gic1.category_id = mcb1.category_id
          AND mcb1.segment1 = civ_item_div
          --AND iimb.item_id = gic3.item_id                                     --�i��ID
          AND gic3.item_id = itp.item_id
          AND gic3.category_set_id = cn_prod_class_id
          AND gic3.category_id = mcb3.category_id
          AND mcb3.segment1 = civ_prod_div
          AND xola.request_item_code = iimb2.item_no                             --�i�ڃR�[�h
          AND ximb2.item_id = iimb2.item_id                            --�i��ID
          AND gic2.item_id = iimb2.item_id
          AND gic2.category_set_id = cn_item_class_id
          AND gic2.category_id = mcb2.category_id
          AND itp.trans_date
            BETWEEN ximb2.start_date_active
            AND ximb2.end_date_active
          --AND gic2.item_id = iimb2.item_id                                     --�i��ID
          AND xoha.result_deliver_to_id = hps.party_site_id(+)
          AND xoha.vendor_site_id = xvsa.vendor_site_id(+)
          AND NVL(xvsa.start_date_active,TO_DATE('1900/01/01',gv_fmt_ymd)) <= TO_DATE(civ_ymd_from,gv_fmt_ymd)
          AND NVL(xvsa.end_date_active,TO_DATE('9999/12/31',gv_fmt_ymd))   >= TO_DATE(civ_ymd_from,gv_fmt_ymd)
          AND itp.doc_type = xrpm.doc_type                                    --�����^�C�v
          AND xrpm.doc_type = 'OMSO'
          AND  otta.attribute1 = xrpm.shipment_provision_div                      --�o�׎x���敪
          AND  otta.attribute1 IN (gv_spdiv_ship,gv_spdiv_prov)
          AND xrpm.shipment_provision_div IN (gv_spdiv_ship,gv_spdiv_prov)
          AND (otta.attribute11 = xrpm.ship_prov_rcv_pay_category                 --�o�׎x���󕥃J�e�S��
            OR   xrpm.ship_prov_rcv_pay_category IS NULL)
            AND NVL(DECODE(mcb1.segment1
                          ,gv_item_class_prod,gv_item_class_prod,NULL),gv_dummy)
                = NVL(xrpm.item_div_origin,gv_dummy)
            AND NVL(DECODE(mcb2.segment1
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_ahead,gv_dummy)
          AND NVL(DECODE(otta.attribute4
                        ,gv_stock_adjm
                        ,gv_stock_adjm
                        ,NULL),gv_dummy
              ) = NVL(DECODE(xrpm.stock_adjustment_div                            --�݌ɒ����敪
                            ,gv_stock_adjm
                            ,gv_stock_adjm
                            ,NULL),gv_dummy
              )
          AND xrpm.use_div_invent = gv_inventory                                  --�݌Ɏg�p�敪
          AND (mcb1.segment1 = gv_item_class_prod AND mcb2.segment1 = gv_item_class_prod
            AND ( (iimb.item_id = iimb2.item_id
              AND xrpm.prod_div_origin IS NULL
              AND xrpm.prod_div_ahead IS NULL)
            OR    (iimb.item_id != iimb2.item_id
              AND xrpm.prod_div_origin IS NOT NULL
              AND xrpm.prod_div_ahead IS NOT NULL)
            )
          OR NOT( mcb1.segment1 = gv_item_class_prod AND mcb2.segment1 = gv_item_class_prod)
          )
          AND itp.location = mil.segment1                                    --�ۊǏꏊ�R�[�h
          AND iwm.mtl_organization_id = mil.organization_id
          AND xoha.shipped_date                                                 --���ד�
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          GROUP BY 
            itp.doc_type                                                      --�����^�C�v
           ,itp.item_id                                                       --�i��ID
           ,itp.whse_code                                                     --�q�ɃR�[�h
           ,iwm.whse_name                                                        --�q�ɖ�
           ,itp.location                                                      --�ۊǑq�ɃR�[�h
           ,mil.description                                                      --�ۊǑq�ɖ�
           ,mil.inventory_location_id                                            --�ۊǑq��ID
           ,itp.lot_id                                                        --���b�gID
           ,itp.doc_id                                                        --����ID
           ,itp.doc_line                                                      --������הԍ�
           ,ooha.header_id                                                     --�󒍃w�b�_ID
           ,ooha.order_type_id                                                 --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                                                      --�󕥋敪
           ,xrpm.new_div_invent                                                   --�V�敪
           ,mil.attribute6                                               --�u���b�N
           ,xoha.head_sales_branch
           ,xoha.deliver_to_id
           ,xoha.result_deliver_to
           ,xoha.vendor_site_code
           ,xoha.arrival_date
           ,xoha.shipped_date
           ,xoha.request_no
           ,xoha.req_status
           ,hps.party_site_name
           ,xvsa.vendor_site_name
           ,otta.order_category_code
          UNION ALL
           -- PORC�֘A
-- mod start 1.25
          --SELECT
          SELECT /*+ leading(xoha ooha otta xola rsl itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) use_nl(xoha ooha otta xola rsl itp gic1 mcb1 gic3 mcb3 iimb2 gic2 mcb2) */
-- mod end 1.25
            itp.doc_type                                  doc_type            --�����^�C�v
           ,itp.item_id                                   item_id             --�i��ID
           ,itp.whse_code                                 whse_code           --�q�ɃR�[�h
           ,iwm.whse_name                                 whse_name           --�q�ɖ�
           ,itp.location                                  location            --�ۊǑq�ɃR�[�h
           ,mil.description                               description         --�ۊǑq�ɖ�
           ,mil.inventory_location_id                     inventory_location_id   --�ۊǑq��ID
           ,itp.lot_id                                    lot_id              --���b�gID
           ,itp.doc_id                                    doc_id              --����ID
           ,itp.doc_line                                  doc_line            --������הԍ�
           ,ooha.header_id                                header_id           --�󒍃w�b�_ID
           ,ooha.order_type_id                            order_type_id       --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                              rcv_pay_div         --�󕥋敪
           ,xrpm.new_div_invent                           new_div_invent      --�V�敪
           ,SUM(itp.trans_qty)                            trans_qty_sum       --���ʍ��v
           ,mil.attribute6                                distribution_block  --�u���b�N
           ,xoha.head_sales_branch                        head_sales_branch
           ,xoha.deliver_to_id                            deliver_to_id
           ,DECODE(xoha.req_status,gv_recsts_shipped,xoha.result_deliver_to
                                  ,gv_recsts_shipped2,xoha.vendor_site_code
            ) deliver_to
           ,xoha.arrival_date                             arrival_date
           ,xoha.shipped_date                             shipped_date
           ,xoha.request_no                               request_no
           --,DECODE(xoha.req_status,'04',xpsv.party_site_full_name
           ,DECODE(xoha.req_status,gv_recsts_shipped,hps.party_site_name
           --                       ,'08',xvsv.vendor_site_name
                                  ,gv_recsts_shipped2,xvsa.vendor_site_name
            ) party_site_full_name
           ,otta.order_category_code                      order_category_code
          FROM
           xxwsh_order_headers_all                            xoha                --�󒍃w�b�_(�A�h�I��)
           ,hz_party_sites                                    hps
           ,xxcmn_vendor_sites_all                            xvsa
           ,xxwsh_order_lines_all                             xola                --�󒍖���(�A�h�I��)
           ,oe_transaction_types_all                          otta                --�󒍃^�C�v
           ,xxcmn_rcv_pay_mst                                 xrpm                --����敪�A�h�I���}�X�^
           ,ic_item_mst_b                                     iimb
           ,xxcmn_item_mst_b                                  ximb
           ,ic_item_mst_b                                     iimb2
           ,xxcmn_item_mst_b                                  ximb2
           ,gmi_item_categories                               gic1
           ,mtl_categories_b                                  mcb1
           ,gmi_item_categories                               gic2
           ,mtl_categories_b                                  mcb2
           ,gmi_item_categories                               gic3
           ,mtl_categories_b                                  mcb3
           ,ic_whse_mst                                       iwm
           ,mtl_item_locations                                mil
           ,ic_tran_pnd                                       itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
           ,rcv_shipment_lines                                rsl             --�������
           ,oe_order_headers_all                              ooha                --�󒍃w�b�_
-- mod start 1.25
          --WHERE ooha.header_id = xoha.header_id                                --�󒍃w�b�_ID
          WHERE rsl.shipment_header_id  = itp.doc_id
          AND rsl.line_num            = itp.doc_line
          AND rsl.oe_order_header_id  = xola.header_id
          AND rsl.oe_order_line_id    = xola.line_id
          AND xoha.header_id          = ooha.header_id
          AND xola.order_header_id    = xoha.order_header_id
          AND itp.doc_type = 'PORC'
          AND rsl.source_document_code = 'RMA'                                --�\�[�X����
          AND itp.completed_ind = gv_tran_cmp                                         --�����t���O
          --AND itp.doc_id = rsl.shipment_header_id                             --����w�b�_ID
          --AND itp.doc_line = rsl.line_num                                     --���הԍ�
          --AND rsl.oe_order_header_id = ooha.header_id                         --�󒍃w�b�_ID
          AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --�X�e�[�^�X
          AND xoha.actual_confirm_class = gv_confirm_yes                            --���ьv��敪
          AND xoha.latest_external_flag = gv_latest_yes                             --�ŐV�t���O
          --AND xoha.order_header_id = xola.order_header_id                         --�󒍃A�h�I���w�b�_ID
-- mod end 1.25
          AND ooha.order_type_id = otta.transaction_type_id                    --�󒍃^�C�vID
          AND xola.shipping_item_code = iimb.item_no                            --�i�ڃR�[�h
          AND itp.item_id         = iimb.item_id                            --�i��ID
          AND ximb.item_id            = iimb.item_id                            --�i��ID
          AND itp.trans_date
            BETWEEN ximb.start_date_active
            AND ximb.end_date_active
          --AND iimb.item_id = gic1.item_id                                     --�i��ID
          AND gic1.item_id = itp.item_id
          AND gic1.category_set_id = cn_item_class_id
          AND gic1.category_id = mcb1.category_id
          AND mcb1.segment1 = civ_item_div
          --AND iimb.item_id = gic3.item_id                                     --�i��ID
          AND gic3.item_id = itp.item_id
          AND gic3.category_set_id = cn_prod_class_id
          AND gic3.category_id = mcb3.category_id
          AND mcb3.segment1 = civ_prod_div
          AND xola.request_item_code = iimb2.item_no                             --�i�ڃR�[�h
          AND ximb2.item_id = iimb2.item_id                            --�i��ID
          AND gic2.item_id = iimb2.item_id
          AND gic2.category_set_id = cn_item_class_id
          AND gic2.category_id = mcb2.category_id
          AND itp.trans_date
            BETWEEN ximb2.start_date_active
            AND ximb2.end_date_active
          --AND gic2.item_id = iimb2.item_id                                     --�i��ID
          AND xoha.result_deliver_to_id = hps.party_site_id(+)
          AND xoha.vendor_site_id = xvsa.vendor_site_id(+)
          AND NVL(xvsa.start_date_active,TO_DATE('1900/01/01',gv_fmt_ymd)) <= TO_DATE(civ_ymd_from,gv_fmt_ymd)
          AND NVL(xvsa.end_date_active,TO_DATE('9999/12/31', gv_fmt_ymd))   >= TO_DATE(civ_ymd_from,gv_fmt_ymd)
          AND itp.doc_type = xrpm.doc_type                                    --�����^�C�v
          AND xrpm.doc_type = 'PORC'
          AND  otta.attribute1 = xrpm.shipment_provision_div                      --�o�׎x���敪
          AND  otta.attribute1 IN (gv_spdiv_ship,gv_spdiv_prov)
          AND xrpm.shipment_provision_div IN (gv_spdiv_ship,gv_spdiv_prov)
          AND (otta.attribute11 = xrpm.ship_prov_rcv_pay_category                 --�o�׎x���󕥃J�e�S��
            OR   xrpm.ship_prov_rcv_pay_category IS NULL)
            AND NVL(DECODE(mcb1.segment1
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_origin,gv_dummy)
            AND NVL(DECODE(mcb2.segment1
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_ahead,gv_dummy)
          AND NVL(DECODE(otta.attribute4
                        ,gv_stock_adjm
                        ,gv_stock_adjm
                        ,NULL),gv_dummy
              ) = NVL(DECODE(xrpm.stock_adjustment_div                            --�݌ɒ����敪
                            ,gv_stock_adjm
                            ,gv_stock_adjm
                            ,NULL),gv_dummy
              )
          AND xrpm.use_div_invent = gv_inventory                                  --�݌Ɏg�p�敪
          AND (mcb1.segment1 = gv_item_class_prod AND mcb2.segment1 = gv_item_class_prod
            AND ( (iimb.item_id = iimb2.item_id
              AND xrpm.prod_div_origin IS NULL
              AND xrpm.prod_div_ahead IS NULL)
            OR    (iimb.item_id != iimb2.item_id
              AND xrpm.prod_div_origin IS NOT NULL
              AND xrpm.prod_div_ahead IS NOT NULL)
            )
          OR NOT( mcb1.segment1 = gv_item_class_prod AND mcb2.segment1 = gv_item_class_prod)
          )
          AND itp.location = mil.segment1                                    --�ۊǏꏊ�R�[�h
          AND iwm.mtl_organization_id = mil.organization_id
          AND xoha.shipped_date                                                 --���ד�
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          GROUP BY 
            itp.doc_type                                                      --�����^�C�v
           ,itp.item_id                                                       --�i��ID
           ,itp.whse_code                                                     --�q�ɃR�[�h
           ,iwm.whse_name                                                        --�q�ɖ�
           ,itp.location                                                      --�ۊǑq�ɃR�[�h
           ,mil.description                                                      --�ۊǑq�ɖ�
           ,mil.inventory_location_id                                            --�ۊǑq��ID
           ,itp.lot_id                                                        --���b�gID
           ,itp.doc_id                                                        --����ID
           ,itp.doc_line                                                      --������הԍ�
           ,ooha.header_id                                                     --�󒍃w�b�_ID
           ,ooha.order_type_id                                                 --�󒍃^�C�vID
           ,xrpm.rcv_pay_div                                                      --�󕥋敪
           ,xrpm.new_div_invent                                                   --�V�敪
           ,mil.attribute6                                               --�u���b�N
           ,xoha.head_sales_branch
           ,xoha.deliver_to_id
           ,xoha.result_deliver_to
           ,xoha.vendor_site_code
           ,xoha.arrival_date
           ,xoha.shipped_date
           ,xoha.request_no
           ,xoha.req_status
           ,hps.party_site_name
           ,xvsa.vendor_site_name
           ,otta.order_category_code
        )                                                     sh_info             --�o�׊֘A���
         ,xxcmn_parties                                       xp
         ,hz_cust_accounts                                    hca
        WHERE sh_info.head_sales_branch = hca.account_number(+)                          --�ڋq�ԍ�
        AND hca.customer_class_code(+) = '1'                               --�ڋq�敪(���_)
        AND hca.party_id = xp.party_id(+)
        UNION ALL
        ------------------------------
        -- 4.�q�֕ԕi���я��
        ------------------------------
        SELECT
          gv_trtry_rt                                         territory           --�̈�(�q�֕ԕi)
         ,rt_info.item_id                                     item_id             --�i��ID
         ,rt_info.lot_id                                      lot_id              --���b�gID
         ,TO_CHAR(xoha.shipped_date,gv_fmt_ymd)               standard_date       --���t
         ,rt_info.reason_code                                 reason_code         --�V�敪
         ,xoha.request_no                                     slip_no             --�`�[No
         ,TO_CHAR(xoha.shipped_date,gv_fmt_ymd)               out_date            --�o�ɓ�
         ,TO_CHAR(xoha.arrival_date,gv_fmt_ymd)               in_date             --����
         ,xoha.head_sales_branch                              jrsd_code           --�Ǌ����_�R�[�h
         ,CASE
            WHEN hca.customer_class_code = '10'
              THEN xp.party_name
              ELSE xp.party_short_name
          END                                                 jrsd_name           --�Ǌ����_��
         ,xoha.head_sales_branch                              other_code          --�����R�[�h
         ,xp.party_name                                       other_name          --����於��
         ,rt_info.in_qty_sum                                  in_qty              --���ɐ�
         ,0                                                   out_qty             --�o�ɐ�
         ,rt_info.whse_code                                   whse_code           --�q�ɃR�[�h
         ,rt_info.whse_name                                   whse_name           --�q�ɖ�
         ,rt_info.location                                    location            --�ۊǑq�ɃR�[�h
         ,rt_info.description                                 description         --�ۊǑq�ɖ�
         ,rt_info.distribution_block                          distribution_block  --�u���b�N
         ,rt_info.rcv_pay_div                                 rcv_pay_div         --�󕥋敪
        ----------------------------------------------------------------------------------------
        FROM (
-- mod start 1.25
          --SELECT /*+ leading(xrpm otta rsl ooha xoha itp gic1 mcb1 gic2 mcb2 mil iwm) use_nl(xrpm otta rsl ooha xoha itp gic1 mcb1 gic2 mcb2 mil iwm) */
          SELECT /*+ leading(xoha ooha otta rsl itp gic1 mcb1 gic2 mcb2) use_nl(xoha ooha otta rsl itp gic1 mcb1 gic2 mcb2) */
-- mod end 1.25
            xoha.header_id                                    header_id           --�󒍃w�b�_ID
           ,itp.whse_code                                     whse_code           --�q�ɃR�[�h
           ,iwm.whse_name                                     whse_name           --�q�ɖ�
           ,itp.item_id                                       item_id             --�i��ID
           ,itp.lot_id                                        lot_id              --���b�gID
           ,itp.location                                      location            --�ۊǑq�ɃR�[�h
           ,mil.description                                   description         --�ۊǑq�ɖ�
           ,mil.inventory_location_id                         inventory_location_id --�ۊǑq��ID
           ,xrpm.new_div_invent                               reason_code         --�V�敪
           ,mil.attribute6                                    distribution_block  --�u���b�N
           ,xrpm.rcv_pay_div                                  rcv_pay_div         --�󕥋敪
           ,SUM(NVL(itp.trans_qty,0))                         in_qty_sum          --���ʍ��v
          FROM
            ic_tran_pnd                                       itp                 --OPM�ۗ��݌Ƀg�����U�N�V����
           --------------------------------------------------------
           ,ic_whse_mst                                       iwm                 --�ۊǏꏊ���VIEW2
           ,mtl_item_locations                                mil
           --------------------------------------------------------
           ,rcv_shipment_lines                                rsl                 --�������
           ,oe_order_headers_all                              ooha                --�󒍃w�b�_
           ,xxwsh_order_headers_all                           xoha                --�󒍃w�b�_(�A�h�I��)
           ,oe_transaction_types_all                          otta                --�󒍃^�C�v
           ,xxcmn_rcv_pay_mst                                 xrpm                --�󕥋敪�A�h�I���}�X�^
           --------------------------------------------------------
           ,gmi_item_categories                               gic1
           ,mtl_categories_b                                  mcb1
           ,gmi_item_categories                               gic2
           ,mtl_categories_b                                  mcb2
          --OPM�ۗ��݌Ƀg�����U�N�V�������o
          WHERE itp.completed_ind = gv_tran_cmp                                   --�����t���O
          AND itp.doc_type = 'PORC'                                               --�����^�C�v
          --�ۊǏꏊ���VIEW2���o
          AND itp.location = mil.segment1                                         --�ۊǑq�ɃR�[�h
          --������ג��o
          AND itp.doc_id = rsl.shipment_header_id                                 --����w�b�_ID
          AND itp.doc_line = rsl.line_num                                         --���הԍ�
          AND rsl.source_document_code = 'RMA'                                    --�\�[�X����
          --�󒍃w�b�_���o
          AND rsl.oe_order_header_id = ooha.header_id                             --�󒍃w�b�_ID
          --�󒍃w�b�_�A�h�I�����o
          AND ooha.header_id = xoha.header_id                                     --�󒍃w�b�_ID
          AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)           --�X�e�[�^�X
          AND xoha.actual_confirm_class = gv_confirm_yes                          --���ьv��敪
          AND xoha.latest_external_flag = gv_latest_yes                           --�ŐV�t���O
          AND xoha.deliver_from_id = mil.inventory_location_id                    --�o�׌�ID
          AND xoha.shipped_date                                                   --���ד�
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          --�󒍃^�C�v���o
          AND ooha.order_type_id = otta.transaction_type_id                       --�󒍃^�C�vID
          AND otta.attribute1 = '3'                                               --�o�׎x���敪
          --�󕥋敪�A�h�I���}�X�^���o
          AND otta.attribute1 = xrpm.shipment_provision_div                       --�o�׎x���敪
          AND otta.attribute11 = xrpm.ship_prov_rcv_pay_category                  --�o�׎x���󕥃J�e�S��
          AND xrpm.use_div_invent = gv_inventory                                  --�݌Ɏg�p�敪
          AND xrpm.doc_type = 'PORC'                                              --�����^�C�v
          AND xrpm.source_document_code = 'RMA'                                   --�\�[�X����
          AND xrpm.dealings_div IN ('201','203')
          -----------------------------------------------------------
          AND gic1.item_id            = itp.item_id
          AND gic1.category_set_id    = cn_item_class_id
          AND gic1.category_id        = mcb1.category_id
          AND mcb1.segment1           = civ_item_div
          AND gic2.item_id            = itp.item_id
          AND gic2.category_set_id    = cn_prod_class_id
          AND gic2.category_id        = mcb2.category_id
          AND mcb2.segment1           = civ_prod_div
          -----------------------------------------------------------
          AND iwm.mtl_organization_id = mil.organization_id
          GROUP BY
            xoha.header_id                                                        --�󒍃w�b�_ID
           ,itp.whse_code                                                         --�q�ɃR�[�h
           ,iwm.whse_name                                                         --�q�ɖ�
           ,itp.item_id                                                           --�i��ID
           ,itp.lot_id                                                            --���b�gID
           ,itp.location                                                          --�ۊǑq�ɃR�[�h
           ,mil.description                                                       --�ۊǑq�ɖ�
           ,mil.inventory_location_id                                             --�ۊǑq��ID
           ,xrpm.new_div_invent                                                   --�V�敪
           ,mil.attribute6                                                        --�u���b�N
           ,xrpm.rcv_pay_div                                                      --�󕥋敪
        ) rt_info                                                                 --�q�֕ԕi�֘A���
        ,xxwsh_order_headers_all                              xoha                --�󒍃w�b�_(�A�h�I��)
        -----------------------------------------------
        ,hz_parties                                           hp                  --�ڋq���VIEW2
        ,hz_cust_accounts                                     hca
        ,xxcmn_parties                                        xp
        ----------------------------------------------
        --�󒍃w�b�_(�A�h�I��)���o
        WHERE rt_info.header_id = xoha.header_id                                  --�󒍃w�b�_ID
          AND xoha.head_sales_branch = hca.account_number                         --�ڋq�ԍ�
          AND hca.customer_class_code = '1'                                       --�ڋq�敪(���_)
          AND hp.party_id = hca.party_id
          AND hp.party_id = xp.party_id
        UNION ALL
        ------------------------------
        -- 5.���Y���я��
        ------------------------------
        -- �i�ڐU��
        SELECT
           gv_trtry_mf                                         territory           -- �̈�(���Y)
         , gmd.item_id                                         item_id             -- �i��ID
         , itp.lot_id                                          lot_id              -- ���b�gID
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )                                   -- �i�ڐU��
         , xrpm.new_div_invent                                 reason_code         -- �V�敪
         , gbh.batch_no                                        slip_no             -- �`�[No
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )               out_date
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )               in_date
         , ''                                                  jrsd_code           -- �Ǌ����_�R�[�h
         , ''                                                  jrsd_name           -- �Ǌ����_��
         , grb.routing_no                                      other_code          -- �����R�[�h
         , grct.routing_class_desc                             other_name          -- ����於��
         , SUM( CASE gmd.line_type --���C���^�C�v
                  WHEN -1 THEN 0
                  ELSE NVL(itp.trans_qty,0)
                END )                                          in_qty              -- ���ɐ�
         , ABS( SUM( CASE gmd.line_type --���C���^�C�v
                       WHEN -1 THEN NVL(itp.trans_qty,0)
                       ELSE 0
                     END ) )                                   out_qty             --�o�ɐ�
         , itp.whse_code                                       whse_code           -- �q�ɃR�[�h
         , iwm.whse_name                                       whse_name           -- �q�ɖ�
         , itp.location                                        location            -- �ۊǑq�ɃR�[�h
         , mil.description                                     description         -- �ۊǑq�ɖ�
         , mil.attribute6                                      distribution_block  -- �u���b�N
         , xrpm.rcv_pay_div                                    rcv_pay_div         -- �󕥋敪
        ----------------------------------------------------------------------------------------
        FROM
           gme_batch_header                                  gbh                 -- ���Y�o�b�`
         , gme_material_details                              gmd                 -- ���Y�����ڍ�
         , gme_material_details                              gmd_d               -- ���Y�����ڍ�(�����i)
         , gmd_routings_b                                    grb                 -- �H���}�X�^
         , gmd_routing_class_tl                              grct                -- �H���敪�}�X�^���{��
         , ic_whse_mst                                       iwm
         , mtl_item_locations                                mil
         --���Y�����ڍ�(�U�֌���i��)
         ,(
           SELECT 
              gbh.batch_id                                     batch_id            -- �o�b�`ID
            , gmd.line_no                                      line_no             -- ���C��NO
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_mtrl, mcb.segment1
                        , NULL
                 )
              )                                                item_class_origin   -- �U�֌��i�ڋ敪
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_prod, mcb.segment1
                        , NULL
                 )
              )                                                item_class_ahead    -- �U�֐�i�ڋ敪
           FROM
              gme_batch_header                                 gbh                 -- ���Y�o�b�`
            , gme_material_details                             gmd                 -- ���Y�����ڍ�
            , gmd_routings_b                                   grb                 -- �H���}�X�^
            , gmi_item_categories                              gic
            , mtl_categories_b                                 mcb
           --���Y�����ڍג��o����
           WHERE gbh.batch_id           = gmd.batch_id                            -- �o�b�`ID
           --�H���}�X�^���o����
           AND   gbh.routing_id         = grb.routing_id                          -- �H��ID
           AND   grb.routing_class      = '70'
           --�J�e�S���������o����
           AND   gmd.item_id            = gic.item_id
           AND   gic.category_id        = mcb.category_id
           AND   gic.category_set_id    = cn_item_class_id
           --AND   mcb.segment1           = civ_item_div
           GROUP BY gbh.batch_id
                   ,gmd.line_no
          )                                                    gmd_t                 --
         , xxcmn_rcv_pay_mst                                   xrpm                  -- �󕥋敪�A�h�I���}�X�^
         , ic_tran_pnd                                         itp                   -- OPM�ۗ��݌Ƀg�����U�N�V����
         , mtl_categories_b                                    mcb1
         , gmi_item_categories                                 gic1
         , mtl_categories_b                                    mcb2
         , gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --���Y�����ڍג��o����
        WHERE gbh.batch_id      = gmd.batch_id                                        -- �o�b�`ID
        --���Y�����ڍ�(�����i)
        AND   gbh.batch_id      = gmd_d.batch_id                                      -- �o�b�`ID
        AND   gmd_d.line_type   = 1                                                   -- ���C���^�C�v(�����i)
        --���Y�����ڍ�(�U��)
        AND   gmd.batch_id      = gmd_t.batch_id(+)                                   -- �o�b�`ID
        AND   gmd.line_no       = gmd_t.line_no(+)                                    -- ���C��NO
        --�H���}�X�^���o����
        AND   gbh.routing_id    = grb.routing_id                                      -- �H��ID
        --�H���}�X�^���{�ꒊ�o����
        --�H���敪�}�X�^���{�ꒊ�o����
        AND   grb.routing_class = grct.routing_class                                  -- �H���R�[�h
        AND   grct.language     = gv_lang                                                -- ����
        AND   grct.source_lang  = gv_source_lang                                                -- ����
        AND   iwm.mtl_organization_id = mil.organization_id                       -- OPM�ۗ��݌Ƀg�����U�N�V�������o����
        AND   itp.line_id             = gmd.material_detail_id                    -- ���C��ID
        AND   itp.item_id             = gmd.item_id                               -- �i��ID
        AND   itp.location            = mil.segment1                              -- �ۊǑq�ɃR�[�h
        AND   itp.completed_ind       = gv_tran_cmp                                       -- �����t���O
        AND   itp.doc_type            = 'PROD'                                    -- �����^�C�v
        AND   itp.reverse_id          IS NULL                                     -- ���o�[�XID
        AND   itp.delete_mark         = gn_delete_mark_no                                         -- �폜�}�[�N
        --�󕥋敪�A�h�I���}�X�^���o����
        AND   xrpm.doc_type           = 'PROD'                                    -- �����^�C�v
        AND   xrpm.line_type          = gmd.line_type                             -- ���C���^�C�v
        AND   xrpm.use_div_invent     = gv_inventory                                                  -- �݌Ɏg�p�敪
        AND   NVL(xrpm.hit_in_div   , gv_dummy) = NVL(gmd.attribute5   , gv_dummy)  -- �ō��敪
        AND   xrpm.routing_class      = grb.routing_class(+)                       -- �H���敪
        AND   grct.routing_class_desc = gv_item_transfer
        AND   xrpm.item_div_ahead     = gmd_t.item_class_ahead                       -- �U�֐�i�ڋ敪
        AND   xrpm.item_div_origin    = gmd_t.item_class_origin                      -- �U�֌��i�ڋ敪
        --���Y��
        AND   itp.trans_date >= TO_DATE(civ_ymd_from, gv_fmt_ymd)
        AND   itp.trans_date <= TO_DATE(civ_ymd_to, gv_fmt_ymd)
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND itp.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND itp.item_id = gic2.item_id
        AND gic2.category_set_id    = cn_item_class_id
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        ----------------------------------------------------------------------------------------
        GROUP BY 
           gv_trtry_mf                                                                  -- �̈�(���Y)
         , gmd.item_id                                                             -- �i��ID
         , itp.lot_id                                                              -- ���b�gID
         , SUBSTRB(gmd_d.attribute11, 1, 10)                                       -- ���t
         , TO_CHAR(itp.trans_date, gv_fmt_ymd)
         , xrpm.new_div_invent                                                     -- �V�敪
         , gbh.batch_no                                                            -- �`�[No
         , grb.routing_no                                                          -- �����R�[�h
         , grct.routing_class_desc
         , itp.whse_code                                                           -- �q�ɃR�[�h
         , iwm.whse_name                                                           -- �q�ɖ�
         , itp.location                                                            -- �ۊǑq�ɃR�[�h
         , mil.description                                                         -- �ۊǑq�ɖ�
         , mil.attribute6                                                          -- �u���b�N
         , xrpm.rcv_pay_div                                                        -- �󕥋敪
        UNION ALL
        -- �ԕi�����A��̔����i
        SELECT
           gv_trtry_mf                                         territory           -- �̈�(���Y)
         , gmd.item_id                                         item_id             -- �i��ID
         , itp.lot_id                                          lot_id              -- ���b�gID
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )
         , xrpm.new_div_invent                                 reason_code         -- �V�敪
         , gbh.batch_no                                        slip_no             -- �`�[No
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )               out_date
         , TO_CHAR( itp.trans_date, gv_fmt_ymd )               in_date
         , ''                                                  jrsd_code           -- �Ǌ����_�R�[�h
         , ''                                                  jrsd_name           -- �Ǌ����_��
         , grb.routing_no                                      other_code          -- �����R�[�h
         , grct.routing_class_desc                             other_name          -- ����於��
         , SUM( CASE gmd.line_type --���C���^�C�v
                  WHEN -1 THEN 0
                  ELSE NVL(itp.trans_qty,0)
                END )                                          in_qty              -- ���ɐ�
         , ABS( SUM( CASE gmd.line_type --���C���^�C�v
                       WHEN -1 THEN NVL(itp.trans_qty,0)
                       ELSE 0
                     END ) )                                   out_qty             --�o�ɐ�
         , itp.whse_code                                       whse_code           -- �q�ɃR�[�h
         , iwm.whse_name                                       whse_name           -- �q�ɖ�
         , itp.location                                        location            -- �ۊǑq�ɃR�[�h
         , mil.description                                     description         -- �ۊǑq�ɖ�
         , mil.attribute6                                      distribution_block  -- �u���b�N
         , xrpm.rcv_pay_div                                    rcv_pay_div         -- �󕥋敪
        ----------------------------------------------------------------------------------------
        FROM
           gme_batch_header                                  gbh                 -- ���Y�o�b�`
         , gme_material_details                              gmd                 -- ���Y�����ڍ�
         , gme_material_details                              gmd_d               -- ���Y�����ڍ�(�����i)
         , gmd_routings_b                                    grb                 -- �H���}�X�^
         , gmd_routing_class_tl                              grct                -- �H���敪�}�X�^���{��
         , ic_whse_mst                                       iwm
         , mtl_item_locations                                mil
         --���Y�����ڍ�(�U�֌���i��)
         ,(
           SELECT 
              gbh.batch_id                                     batch_id            -- �o�b�`ID
            , gmd.line_no                                      line_no             -- ���C��NO
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_mtrl, mcb.segment1
                        , NULL
                 )
              )                                                item_class_origin   -- �U�֌��i�ڋ敪
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_prod, mcb.segment1
                        , NULL
                 )
              )                                                item_class_ahead    -- �U�֐�i�ڋ敪
           FROM
              gme_batch_header                                 gbh                 -- ���Y�o�b�`
            , gme_material_details                             gmd                 -- ���Y�����ڍ�
            , gmd_routings_b                                   grb                 -- �H���}�X�^
            , gmi_item_categories                              gic
            , mtl_categories_b                                 mcb
           --���Y�����ڍג��o����
           WHERE gbh.batch_id           = gmd.batch_id                            -- �o�b�`ID
           --�H���}�X�^���o����
           AND   gbh.routing_id         = grb.routing_id                          -- �H��ID
           AND   grb.routing_class      = '70'
           --�J�e�S���������o����
           AND   gmd.item_id            = gic.item_id
           AND   gic.category_id        = mcb.category_id
           AND   gic.category_set_id    = cn_item_class_id
           --AND   mcb.segment1           = civ_item_div
           GROUP BY gbh.batch_id
                   ,gmd.line_no
          )                                                    gmd_t                 --
         , xxcmn_rcv_pay_mst                                   xrpm                  -- �󕥋敪�A�h�I���}�X�^
         , ic_tran_pnd                                         itp                   -- OPM�ۗ��݌Ƀg�����U�N�V����
         , mtl_categories_b                                    mcb1
         , gmi_item_categories                                 gic1
         , mtl_categories_b                                    mcb2
         , gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --���Y�����ڍג��o����
        WHERE gbh.batch_id      = gmd.batch_id                                        -- �o�b�`ID
        --���Y�����ڍ�(�����i)
        AND   gbh.batch_id      = gmd_d.batch_id                                      -- �o�b�`ID
        AND   gmd_d.line_type   = 1                                                   -- ���C���^�C�v(�����i)
        --���Y�����ڍ�(�U��)
        AND   gmd.batch_id      = gmd_t.batch_id(+)                                   -- �o�b�`ID
        AND   gmd.line_no       = gmd_t.line_no(+)                                    -- ���C��NO
        --�H���}�X�^���o����
        AND   gbh.routing_id    = grb.routing_id                                      -- �H��ID
        --�H���}�X�^���{�ꒊ�o����
        --�H���敪�}�X�^���{�ꒊ�o����
        AND   grb.routing_class = grct.routing_class                                  -- �H���R�[�h
        AND   grct.language     = gv_lang                                             -- ����
        AND   grct.source_lang  = gv_source_lang                                      -- ����
        AND   iwm.mtl_organization_id = mil.organization_id                       -- OPM�ۗ��݌Ƀg�����U�N�V�������o����
        AND   itp.line_id             = gmd.material_detail_id                    -- ���C��ID
        AND   itp.item_id             = gmd.item_id                               -- �i��ID
        AND   itp.location            = mil.segment1                              -- �ۊǑq�ɃR�[�h
        AND   itp.completed_ind       = gv_tran_cmp                                       -- �����t���O
        AND   itp.doc_type            = 'PROD'                                    -- �����^�C�v
        AND   itp.reverse_id          IS NULL                                     -- ���o�[�XID
        AND   itp.delete_mark         = gn_delete_mark_no                                         -- �폜�}�[�N
        --�󕥋敪�A�h�I���}�X�^���o����
        AND   xrpm.doc_type           = 'PROD'                                    -- �����^�C�v
        AND   xrpm.line_type          = gmd.line_type                             -- ���C���^�C�v
        AND   xrpm.use_div_invent     = gv_inventory                                                  -- �݌Ɏg�p�敪
        AND   NVL(xrpm.hit_in_div   , gv_dummy) = NVL(gmd.attribute5   , gv_dummy) -- �ō��敪
        AND   xrpm.routing_class      = grb.routing_class(+)                       -- �H���敪
        AND   grct.routing_class_desc IN (gv_item_return, gv_item_dissolve)
        --���Y��
        AND   itp.trans_date >= TO_DATE(civ_ymd_from, gv_fmt_ymd)
        AND   itp.trans_date <= TO_DATE(civ_ymd_to, gv_fmt_ymd)
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND itp.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND itp.item_id = gic2.item_id
        AND gic2.category_set_id    = cn_item_class_id
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        ----------------------------------------------------------------------------------------
        GROUP BY 
           gv_trtry_mf                                                                  -- �̈�(���Y)
         , gmd.item_id                                                             -- �i��ID
         , itp.lot_id                                                              -- ���b�gID
         , SUBSTRB(gmd_d.attribute11, 1, 10)                                       -- ���t
         , TO_CHAR(itp.trans_date, gv_fmt_ymd)
         , xrpm.new_div_invent                                                     -- �V�敪
         , gbh.batch_no                                                            -- �`�[No
         , grb.routing_no                                                          -- �����R�[�h
         , grct.routing_class_desc
         , itp.whse_code                                                           -- �q�ɃR�[�h
         , iwm.whse_name                                                           -- �q�ɖ�
         , itp.location                                                            -- �ۊǑq�ɃR�[�h
         , mil.description                                                         -- �ۊǑq�ɖ�
         , mil.attribute6                                                          -- �u���b�N
         , xrpm.rcv_pay_div                                                        -- �󕥋敪
        UNION ALL
        -- ���̑�
        SELECT /*+ leading(gmd_d gbh gmd itp gmd_t gic1 mcb1 gic2 mcb2 xrpm grb grct mil iwm) use_nl(gmd_d gbh gmd itp gmd_t gic1 mcb1 gic2 mcb2 xrpm grb grct mil iwm) */
           gv_trtry_mf                                         territory           -- �̈�(���Y)
         , gmd.item_id                                         item_id             -- �i��ID
         , itp.lot_id                                          lot_id              -- ���b�gID
         , SUBSTRB( gmd_d.attribute11, 1, 10 )
         , xrpm.new_div_invent                                 reason_code         -- �V�敪
         , gbh.batch_no                                        slip_no             -- �`�[No
         , SUBSTRB( gmd_d.attribute11, 1, 10 )                 out_date
         , SUBSTRB( gmd_d.attribute11, 1, 10 )                 in_date
         , ''                                                  jrsd_code           -- �Ǌ����_�R�[�h
         , ''                                                  jrsd_name           -- �Ǌ����_��
         , grb.routing_no                                      other_code          -- �����R�[�h
         , grct.routing_class_desc                             other_name          -- ����於��
         , SUM( CASE gmd.line_type --���C���^�C�v
                  WHEN -1 THEN 0
                  ELSE NVL(itp.trans_qty,0)
                END )                                          in_qty              -- ���ɐ�
         , ABS( SUM( CASE gmd.line_type --���C���^�C�v
                       WHEN -1 THEN NVL(itp.trans_qty,0)
                       ELSE 0
                     END ) )                                   out_qty             --�o�ɐ�
         , itp.whse_code                                       whse_code           -- �q�ɃR�[�h
         , iwm.whse_name                                       whse_name           -- �q�ɖ�
         , itp.location                                        location            -- �ۊǑq�ɃR�[�h
         , mil.description                                     description         -- �ۊǑq�ɖ�
         , mil.attribute6                                      distribution_block  -- �u���b�N
         , xrpm.rcv_pay_div                                    rcv_pay_div         -- �󕥋敪
        ----------------------------------------------------------------------------------------
        FROM
           gme_batch_header                                  gbh                 -- ���Y�o�b�`
         , gme_material_details                              gmd                 -- ���Y�����ڍ�
         , gme_material_details                              gmd_d               -- ���Y�����ڍ�(�����i)
         , gmd_routings_b                                    grb                 -- �H���}�X�^
         , gmd_routing_class_tl                              grct                -- �H���敪�}�X�^���{��
         , ic_whse_mst                                       iwm
         , mtl_item_locations                                mil
         --���Y�����ڍ�(�U�֌���i��)
         ,(
           SELECT /*+ leading(gbh grb gmd gic mcb) use_nl(gbh grb gmd gic mcb) */
              gbh.batch_id                                     batch_id            -- �o�b�`ID
            , gmd.line_no                                      line_no             -- ���C��NO
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_mtrl, mcb.segment1
                        , NULL
                 )
              )                                                item_class_origin   -- �U�֌��i�ڋ敪
            , MAX(DECODE(gmd.line_type --���C���^�C�v
                        , gn_linetype_prod, mcb.segment1
                        , NULL
                 )
              )                                                item_class_ahead    -- �U�֐�i�ڋ敪
           FROM
              gme_batch_header                                 gbh                 -- ���Y�o�b�`
            , gme_material_details                             gmd                 -- ���Y�����ڍ�
            , gmd_routings_b                                   grb                 -- �H���}�X�^
            , gmi_item_categories                              gic
            , mtl_categories_b                                 mcb
           --���Y�����ڍג��o����
           WHERE gbh.batch_id           = gmd.batch_id                            -- �o�b�`ID
           --�H���}�X�^���o����
           AND   gbh.routing_id         = grb.routing_id                          -- �H��ID
           AND   grb.routing_class      = '70'
           --�J�e�S���������o����
           AND   gmd.item_id            = gic.item_id
           AND   gic.category_id        = mcb.category_id
           AND   gic.category_set_id    = cn_item_class_id
           --AND   mcb.segment1           = civ_item_div
           GROUP BY gbh.batch_id
                   ,gmd.line_no
          )                                                    gmd_t                 --
         , xxcmn_rcv_pay_mst                                   xrpm                  -- �󕥋敪�A�h�I���}�X�^
         , ic_tran_pnd                                         itp                   -- OPM�ۗ��݌Ƀg�����U�N�V����
         , mtl_categories_b                                    mcb1
         , gmi_item_categories                                 gic1
         , mtl_categories_b                                    mcb2
         , gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --���Y�����ڍג��o����
        WHERE gbh.batch_id      = gmd.batch_id                                        -- �o�b�`ID
        --���Y�����ڍ�(�����i)
        AND   gbh.batch_id      = gmd_d.batch_id                                      -- �o�b�`ID
        AND   gmd_d.line_type   = 1                                                   -- ���C���^�C�v(�����i)
        --���Y�����ڍ�(�U��)
        AND   gmd.batch_id      = gmd_t.batch_id(+)                                   -- �o�b�`ID
        AND   gmd.line_no       = gmd_t.line_no(+)                                    -- ���C��NO
        --�H���}�X�^���o����
        AND   gbh.routing_id    = grb.routing_id                                      -- �H��ID
        --�H���}�X�^���{�ꒊ�o����
        --�H���敪�}�X�^���{�ꒊ�o����
        AND   grb.routing_class = grct.routing_class                                  -- �H���R�[�h
        AND   grct.language     = gv_lang                                             -- ����
        AND   grct.source_lang  = gv_source_lang                                      -- ����
        --OPM�ۊǏꏊ�}�X�^���o����
        AND   mil.segment1 = grb.attribute9
        AND   iwm.mtl_organization_id = mil.organization_id                       -- OPM�ۗ��݌Ƀg�����U�N�V�������o����
        AND   itp.line_id             = gmd.material_detail_id                    -- ���C��ID
        AND   itp.item_id             = gmd.item_id                               -- �i��ID
        AND   itp.location            = mil.segment1                              -- �ۊǑq�ɃR�[�h
        AND   itp.completed_ind       = gv_tran_cmp                                       -- �����t���O
        AND   itp.doc_type            = 'PROD'                                    -- �����^�C�v
        AND   itp.reverse_id          IS NULL                                     -- ���o�[�XID
        AND   itp.delete_mark         = gn_delete_mark_no                                         -- �폜�}�[�N
        --�󕥋敪�A�h�I���}�X�^���o����
        AND   xrpm.doc_type           = 'PROD'                                    -- �����^�C�v
        AND   xrpm.line_type          = gmd.line_type                             -- ���C���^�C�v
        AND   xrpm.use_div_invent     = gv_inventory                                                  -- �݌Ɏg�p�敪
        AND   NVL(xrpm.hit_in_div   , gv_dummy) = NVL(gmd.attribute5   , gv_dummy)  -- �ō��敪
        AND   xrpm.routing_class      = grb.routing_class(+)                        -- �H���敪
        AND   grct.routing_class_desc NOT IN (gv_item_transfer, gv_item_return, gv_item_dissolve)
        --���Y��
        AND   gmd_d.attribute11 >= civ_ymd_from
        AND   gmd_d.attribute11 <= civ_ymd_to
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND itp.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND itp.item_id = gic2.item_id
        AND gic2.category_set_id    = cn_item_class_id
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        ----------------------------------------------------------------------------------------
        GROUP BY 
           gv_trtry_mf                                                                  -- �̈�(���Y)
         , gmd.item_id                                                             -- �i��ID
         , itp.lot_id                                                              -- ���b�gID
         , SUBSTRB(gmd_d.attribute11, 1, 10)                                       -- ���t
         , TO_CHAR(itp.trans_date, gv_fmt_ymd)
         , xrpm.new_div_invent                                                     -- �V�敪
         , gbh.batch_no                                                            -- �`�[No
         , grb.routing_no                                                          -- �����R�[�h
         , grct.routing_class_desc
         , itp.whse_code                                                           -- �q�ɃR�[�h
         , iwm.whse_name                                                           -- �q�ɖ�
         , itp.location                                                            -- �ۊǑq�ɃR�[�h
         , mil.description                                                         -- �ۊǑq�ɖ�
         , mil.attribute6                                                          -- �u���b�N
         , xrpm.rcv_pay_div                                                        -- �󕥋敪
        UNION ALL
        ------------------------------
        -- 6.�݌ɒ������я��
        ------------------------------
        SELECT
          gv_trtry_ad                                         territory           --�̈�(�݌ɒ���)
         ,itc.item_id                                         item_id             --�i��ID
         ,itc.lot_id                                          lot_id              --���b�gID
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  standard_date       --���t
         ,xrpm.new_div_invent                                 reason_code         --�V�敪
         ,ad_info.slip_no                                     slip_no             --�`�[No
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  out_date            --�o�ɓ�
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  in_date             --����
         ,''                                                  jrsd_code           --�Ǌ����_�R�[�h
         ,''                                                  jrsd_name           --�Ǌ����_��
         ,CASE ad_info.adji_type
            WHEN gv_adji_xrart THEN ad_info.other_code
            WHEN gv_adji_xnpt THEN xrpm.new_div_invent
            WHEN gv_adji_xvst THEN ad_info.other_code
            WHEN gv_adji_xmrih THEN ad_info.other_code
            WHEN gv_adji_ijm THEN xrpm.new_div_invent
          END                                                 other_code          --�����R�[�h
         ,CASE ad_info.adji_type
            WHEN gv_adji_xrart THEN ad_info.other_name
            WHEN gv_adji_xnpt THEN NULL
            WHEN gv_adji_xvst THEN ad_info.other_name
            WHEN gv_adji_xmrih THEN ad_info.other_name
            WHEN gv_adji_ijm THEN NULL
          END                                                 other_name          --����於��
         ,CASE xrpm.rcv_pay_div
            WHEN '1' THEN SUM(NVL(itc.trans_qty,0))
            ELSE 0
          END                                                 in_qty              --���ɐ�
         ,CASE xrpm.rcv_pay_div
            WHEN '-1' THEN SUM(NVL(itc.trans_qty,0) * -1)
            ELSE 0
          END                                                 out_qty             --�o�ɐ�
         ,itc.whse_code                                       whse_code           --�q�ɃR�[�h
         ,iwm.whse_name                                       whse_name           --�q�ɖ�
         ,itc.location                                        location            --�ۊǑq�ɃR�[�h
         ,mil.description                                     description         --�ۊǑq�ɖ�
         ,mil.attribute6                                      distribution_block  --�u���b�N
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --�󕥋敪
        FROM
          (
            -----------------------
            --����ԕi���я��(�d����ԕi)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xrart.rcv_rtn_number                            slip_no             --�`�[No
             ,xrart.vendor_code                               other_code          --�����R�[�h
             ,pv.vendor_name                                 other_name          --����於��
             ,gv_adji_xrart                                   adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_rcv_and_rtn_txns                           xrart               --����ԕi���уA�h�I��
             ,po_vendors                                      pv
             ,xxcmn_vendors                                   xv
            --����ԕi����(�A�h�I��)���o����
            WHERE xrart.txns_type IN ('2', '3')                             --���ы敪
            AND TRUNC(xrart.txns_date)                                            --�����
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xrart.txns_id                                    --����ID
            --�d������view���o����
            AND xrart.vendor_id = pv.vendor_id                                   --�����ID
            AND xrart.txns_date                                                   --�����
              BETWEEN xv.start_date_active                                           --�K�p�J�n��
              AND NVL(xv.end_date_active,xrart.txns_date)                            --�K�p�I����
            AND pv.vendor_id = xv.vendor_id
            UNION ALL
            -----------------------
            --����ԕi���я��(�����݌�)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xrart.source_document_number                    slip_no             --�`�[No
              ,xrart.vendor_code                              other_code          --�����R�[�h(�����)
              ,xv.vendor_name                                 other_name          --������(����於)
             ,gv_adji_xrart                                   adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_rcv_and_rtn_txns                           xrart               --����ԕi���уA�h�I��
             ,po_vendors                                      pv
             ,xxcmn_vendors                                   xv
             ,po_headers_all                                  pha                 --�����w�b�_
            --����ԕi����(�A�h�I��)���o����
            WHERE xrart.txns_type  = gv_txns_type_rcv                             --���ы敪
            AND TRUNC(xrart.txns_date)                                            --�����
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xrart.txns_id                                    --����ID
            --�d������view���o����
            AND xrart.vendor_id = pv.vendor_id                                   --�����ID
            AND xrart.txns_date                                                   --�����
              BETWEEN xv.start_date_active                                       --�K�p�J�n��
              AND NVL(xv.end_date_active, xrart.txns_date)                       --�K�p�I����
            --�����w�b�_
            AND xrart.source_document_number = pha.segment1                       --�����ԍ�
            AND pha.attribute11 = po_type_inv                                     --�����敪(�����݌�)
            AND pv.vendor_id = xv.vendor_id
            UNION ALL
            -----------------------
            --���t���я��
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,xnpt.entry_number                               slip_no             --�`�[No
             ,NULL                                            other_code          --�����R�[�h
             ,NULL                                            ohter_name          --����於
             ,gv_adji_xnpt                                    adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_namaha_prod_txns                           xnpt                --���t���уA�h�I��
            --���t���уA�h�I�����o����
            WHERE TRUNC(xnpt.creation_date)                                       --�쐬��
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPM�W���[�i���}�X�^���o����
            AND ijm.attribute1 = xnpt.entry_number                                --�`�[No
            UNION ALL
            -----------------------
            --�O���o��������(�A�h�I��)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
              ,''                                             slip_no             --�`�[No
              ,xvst.vendor_code                               other_code          --�����R�[�h(�����)
              ,xv.vendor_name                                 other_name          --������(����於)
              ,gv_adji_xvst                                   adji_type           --�݌Ƀ^�C�v

            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,xxpo_vendor_supply_txns                         xvst                --�O���o��������(�A�h�I��)
             ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
             ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
             ,po_vendors                                      pv
             ,xxcmn_vendors                                   xv
            --�O���o�������уA�h�I�����o����
            WHERE ijm.attribute1 = xvst.txns_id                                   --����ID
            --OPM�݌ɒ����W���[�i�����o����
            AND ijm.journal_id = iaj.journal_id
            --OPM�����݌Ƀg�����U�N�V�������o����
            AND iaj.doc_id = itc.doc_id
            AND iaj.doc_line = itc.doc_line
            AND itc.trans_date
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)

            --�d������view���o����
            AND xvst.vendor_id = pv.vendor_id                                   --�����ID
            AND itc.trans_date                                                   --�����
              BETWEEN xv.start_date_active                                      --�K�p�J�n��
              AND NVL(xv.end_date_active, itc.trans_date)                       --�K�p�I����
            AND pv.vendor_id = xv.vendor_id
            AND iaj.trans_type = 'ADJI'                                               --�����^�C�v
            AND itc.doc_type = 'ADJI'                                                 --�����^�C�v
            AND itc.doc_id = iaj.doc_id                                               --����ID
            AND itc.doc_line = iaj.doc_line                                           --������הԍ�
            UNION ALL
            -----------------------
            --EBS�W���̍݌ɒ���
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --�W���[�i��ID
             ,ijm.journal_no                                  slip_no             --�`�[No
             ,NULL                                            other_code          --�����R�[�h
             ,NULL                                            other_name          --����於
             ,gv_adji_ijm                                     adji_type           --�݌Ƀ^�C�v
            FROM
              ic_jrnl_mst                                     ijm                 --OPM�W���[�i���}�X�^
             ,ic_adjs_jnl                                     iaj                 --OPM�݌ɒ����W���[�i��
             ,ic_tran_cmp                                     itc                 --OPM�����݌Ƀg�����U�N�V����
            --OPM�W���[�i���}�X�^���o����
            WHERE ijm.attribute1 IS NULL
            --OPM�݌ɒ����W���[�i�����o����
            AND ijm.journal_id = iaj.journal_id
            --OPM�����݌Ƀg�����U�N�V�������o����
            AND iaj.doc_id = itc.doc_id
            AND iaj.doc_line = itc.doc_line
            AND itc.trans_date
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
              AND iaj.trans_type = 'ADJI'                                               --�����^�C�v
              AND itc.doc_type = 'ADJI'                                                 --�����^�C�v
              AND itc.doc_id = iaj.doc_id                                               --����ID
              AND itc.doc_line = iaj.doc_line                                           --������הԍ�
         ) ad_info
         ,ic_adjs_jnl                                         iaj                 --OPM�݌ɒ����W���[�i��
         ,ic_tran_cmp                                         itc                 --OPM�����݌Ƀg�����U�N�V����
         ,ic_whse_mst                                         iwm
         ,hr_all_organization_units                           haou
         ,mtl_item_locations                                  mil
         ,xxcmn_rcv_pay_mst                                   xrpm                --�󕥋敪�A�h�I���}�X�^
         ,xxcmn_lookup_values2_v                              xlvv                --�N�C�b�N�R�[�h
         ,sy_reas_cds_b                                       srcb                --���R�R�[�h�}�X�^
         ,mtl_categories_b                                    mcb1
         ,gmi_item_categories                                 gic1
         ,mtl_categories_b                                    mcb2
         ,gmi_item_categories                                 gic2
        ----------------------------------------------------------------------------------------
        --OPM�݌ɒ����W���[�i�����o����
        WHERE iaj.journal_id = ad_info.journal_id                                 --�W���[�i��ID
        AND iaj.trans_type = 'ADJI'                                               --�����^�C�v
        --OPM�����݌Ƀg�����U�N�V�������o����
        AND itc.doc_type = 'ADJI'                                                 --�����^�C�v
        AND itc.doc_id = iaj.doc_id                                               --����ID
        AND itc.doc_line = iaj.doc_line                                           --������הԍ�
        --�ۊǏꏊ���VIEW2���o����
        AND itc.location = mil.segment1                                          --�ۊǑq�ɃR�[�h
        AND itc.trans_date
          BETWEEN haou.date_from AND NVL(haou.date_to,itc.trans_date)             --�K�p�J�n���E�I����
        --�󕥋敪�A�h�I���}�X�^���o����
        AND xrpm.doc_type = 'ADJI'                                                --�����^�C�v
        AND itc.reason_code = xrpm.reason_code                                    --���R�R�[�h
        AND xrpm.use_div_invent = gv_inventory                                    --�݌Ɏg�p�敪

        AND xrpm.reason_code = srcb.reason_code                                   --���R�R�[�h
        AND srcb.delete_mark = 0                                                  --�폜�}�[�N(���폜)
        --�N�C�b�N�R�[�h���o����
        AND xlvv.lookup_type =  gv_lookup_newdiv                                  --�Q�ƃ^�C�v(�V�敪)
        AND xrpm.new_div_invent = xlvv.lookup_code                                --�Q�ƃR�[�h
        AND itc.trans_date
          BETWEEN xlvv.start_date_active
          AND NVL(xlvv.end_date_active,itc.trans_date)                            --�K�p�J�n���E�I����
        AND iwm.mtl_organization_id = haou.organization_id
        AND haou.organization_id    = mil.organization_id
--
        --�p�����[�^�ɂ��i����(���i�敪)
        AND mcb1.segment1 = civ_prod_div
        --�p�����[�^�ɂ��i����(�i�ڋ敪)
        AND mcb2.segment1 = civ_item_div
        --�J�e�S���Z�b�g�����i�敪�ł���i��
        AND itc.item_id = gic1.item_id
        AND gic1.category_set_id    = cn_prod_class_id
        --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
        AND itc.item_id = gic2.item_id
        AND gic2.category_set_id    = cn_item_class_id
--
        AND mcb1.category_id       = gic1.category_id
        AND mcb2.category_id       = gic2.category_id
        ----------------------------------------------------------------------------------------
        GROUP BY 
          itc.doc_id                                                              --����ID
         ,itc.item_id                                                             --�i��ID
         ,itc.lot_id                                                              --���b�gID
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                                      --���t
         ,xrpm.new_div_invent                                                     --�V�敪
         ,ad_info.slip_no                                                         --�`�[No
         ,xlvv.description                                                        --����於��
         ,itc.whse_code                                                           --�q�ɃR�[�h
         ,iwm.whse_name                                                          --�q�ɖ�
         ,itc.location                                                            --�ۊǑq�ɃR�[�h
         ,mil.description                                                        --�ۊǑq�ɖ�
         ,mil.attribute6                                                 --�u���b�N
         ,xrpm.rcv_pay_div                                                        --�󕥋敪
         ,ad_info.adji_type                                                       --�݌Ƀ^�C�v
         ,ad_info.other_name                                                      --����於
         ,ad_info.other_code                                                      --�����R�[�h
       ) slip
       ,mtl_categories_b                                       mcb1
       ,gmi_item_categories                                    gic1
       ,mtl_categories_b                                       mcb2
       ,gmi_item_categories                                    gic2
       ,mtl_categories_tl                                      mct2
       ,xxcmn_lookup_values2_v                                 xlvv                --�N�C�b�N�R�[�h
       ,ic_item_mst_b                                          iimb
       ,xxcmn_item_mst_b                                       ximb
       ,ic_lots_mst                                            ilm                 --OPM���b�g�}�X�^(�����p)
      --======================================================================================================
      --�J�e�S���Z�b�g�����i�敪�ł���i��
      WHERE slip.item_id = gic1.item_id
      AND gic1.category_set_id    = cn_prod_class_id
      AND mcb1.category_id       = gic1.category_id
      --�J�e�S���Z�b�g���i�ڋ敪�ł���i��
      AND slip.item_id = gic2.item_id
      AND gic2.category_set_id    = cn_item_class_id
      AND mcb2.category_id        = gic2.category_id
      AND mcb2.category_id        = mct2.category_id
      AND mct2.language           = 'JA'
      AND mct2.source_lang        = 'JA'
      --�N�C�b�N�R�[�h���o����
      AND xlvv.lookup_type =  gv_lookup_newdiv                                    --�Q�ƃ^�C�v(�V�敪)
      AND slip.reason_code = xlvv.lookup_code                                     --�Q�ƃR�[�h
      AND TO_DATE(slip.standard_date,gv_fmt_ymd)
        BETWEEN xlvv.start_date_active
        AND NVL(xlvv.end_date_active,TO_DATE(slip.standard_date,gv_fmt_ymd))      --�K�p�J�n���E�I����
      AND slip.item_id = iimb.item_id                                             --�i��ID
      AND TO_DATE(slip.standard_date,gv_fmt_ymd)
        BETWEEN ximb.start_date_active
        AND NVL(ximb.end_date_active,TO_DATE(slip.standard_date,gv_fmt_ymd))--�K�p�J�n���E�I����
      AND slip.item_id = ilm.item_id
      AND slip.lot_id = ilm.lot_id
      AND iimb.item_id = ximb.item_id
      --�p�����[�^�ɂ��i����(���i�敪)
      AND mcb1.segment1 = civ_prod_div
      --�p�����[�^�ɂ��i����(�i�ڋ敪)
      AND mcb2.segment1 = civ_item_div
      --�p�����[�^�ɂ��i����(���b�gNo)
      AND ( civ_lot_no_01 IS NULL
        AND civ_lot_no_02 IS NULL
        AND civ_lot_no_03 IS NULL
      OR civ_lot_no_01 = ilm.lot_no
      OR civ_lot_no_02 = ilm.lot_no
      OR civ_lot_no_03 = ilm.lot_no
      )
      --�p�����[�^�ɂ��i����(�����N����)
      AND ( civ_mnfctr_date_01 IS NULL
        AND civ_mnfctr_date_02 IS NULL
        AND civ_mnfctr_date_03 IS NULL
      OR civ_mnfctr_date_01 = ilm.attribute1
      OR civ_mnfctr_date_02 = ilm.attribute1
      OR civ_mnfctr_date_03 = ilm.attribute1
      )
      --�p�����[�^�ɂ��i����(�ŗL�L��)
      AND  ( civ_symbol IS NULL
      OR  civ_symbol = ilm.attribute2
      )
      AND
      (
           NVL(civ_block_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_block_02,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_block_03,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
        --�p�����[�^�ɂ��i����(�����u���b�N)
        OR  slip.distribution_block IN (civ_block_01,civ_block_02,civ_block_03)
        --�p�����[�^�ɂ��i����(�ۊǑq��)
        OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_loc
          AND slip.location IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
        --�p�����[�^�ɂ��i����(�q��)
        OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_wh
          AND  slip.whse_code IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
      )
      --�p�����[�^�ɂ��i����(�i��)
      AND ( NVL(civ_item_code_01,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_item_code_02,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_item_code_03,gv_nullvalue) = gv_nullvalue
      OR  iimb.item_no IN (civ_item_code_01, civ_item_code_02, civ_item_code_03)
      )
      AND ( NVL(civ_reason_code_01,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_reason_code_02,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_reason_code_03,gv_nullvalue) = gv_nullvalue
      OR slip.reason_code IN (civ_reason_code_01, civ_reason_code_02, civ_reason_code_03)
      )
      --�p�����[�^�ɂ��i����(���o�ɋ敪)
      AND ( civ_inout_ctl = gv_inout_ctl_all --���o�ɗ������w�肵���ꍇ
      OR    civ_inout_ctl = gv_inout_ctl_in  --���ɂ��w�肵���ꍇ
        AND slip.rcv_pay_div = gv_rcvdiv_rcv   --�󕥋敪�͎���̂ݑΏ�
      OR    civ_inout_ctl = gv_inout_ctl_out --�o�ɂ��w�肵���ꍇ
        AND slip.rcv_pay_div = gv_rcvdiv_pay   --�󕥋敪�͕��o�̂ݑΏ�
      )
      ORDER BY slip.location
              ,TO_NUMBER(iimb.item_no)
              ,slip.standard_date
              ,slip.reason_code
              ,slip.slip_no
      ;
--
  BEGIN
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    IF (ir_prm.base_date = gv_base_date_arrival) THEN
      -- �J�[�\���I�[�v��
      OPEN cur_main_data1(
        ir_prm.ymd_from
       ,ir_prm.ymd_to
       ,ir_prm.base_date
       ,ir_prm.inout_ctl
       ,ir_prm.prod_div
       ,ir_prm.unit_ctl
       ,ir_prm.wh_loc_ctl
       ,ir_prm.wh_code_01
       ,ir_prm.wh_code_02
       ,ir_prm.wh_code_03
       ,ir_prm.block_01
       ,ir_prm.block_02
       ,ir_prm.block_03
       ,ir_prm.item_div
       ,ir_prm.item_code_01
       ,ir_prm.item_code_02
       ,ir_prm.item_code_03
       ,ir_prm.lot_no_01
       ,ir_prm.lot_no_02
       ,ir_prm.lot_no_03
       ,ir_prm.mnfctr_date_01
       ,ir_prm.mnfctr_date_02
       ,ir_prm.mnfctr_date_03
       ,ir_prm.reason_code_01
       ,ir_prm.reason_code_02
       ,ir_prm.reason_code_03
       ,ir_prm.symbol
      );
--
      --�o���N�t�F�b�`
      FETCH cur_main_data1 BULK COLLECT INTO ot_main_data;
--
      ln_main_data_cnt := ot_main_data.count;
      --�N���[�Y
      CLOSE cur_main_data1;
--
    ELSIF (ir_prm.base_date = gv_base_date_ship) THEN
      -- �J�[�\���I�[�v��
      OPEN cur_main_data2(
        ir_prm.ymd_from
       ,ir_prm.ymd_to
       ,ir_prm.base_date
       ,ir_prm.inout_ctl
       ,ir_prm.prod_div
       ,ir_prm.unit_ctl
       ,ir_prm.wh_loc_ctl
       ,ir_prm.wh_code_01
       ,ir_prm.wh_code_02
       ,ir_prm.wh_code_03
       ,ir_prm.block_01
       ,ir_prm.block_02
       ,ir_prm.block_03
       ,ir_prm.item_div
       ,ir_prm.item_code_01
       ,ir_prm.item_code_02
       ,ir_prm.item_code_03
       ,ir_prm.lot_no_01
       ,ir_prm.lot_no_02
       ,ir_prm.lot_no_03
       ,ir_prm.mnfctr_date_01
       ,ir_prm.mnfctr_date_02
       ,ir_prm.mnfctr_date_03
       ,ir_prm.reason_code_01
       ,ir_prm.reason_code_02
       ,ir_prm.reason_code_03
       ,ir_prm.symbol
      );
--
      --�o���N�t�F�b�`
      FETCH cur_main_data2 BULK COLLECT INTO ot_main_data;
--
      ln_main_data_cnt := ot_main_data.count;
      --�N���[�Y
      CLOSE cur_main_data2;
--
    END IF;
--
    IF (ln_main_data_cnt > 0) THEN
      ov_retcode := gv_status_normal;
    ELSE
      ov_retcode := gv_status_warn;
    END IF;
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
      IF (ir_prm.base_date = gv_base_date_arrival) THEN
        IF cur_main_data1%ISOPEN THEN
          CLOSE cur_main_data1;
        END IF;
      ELSIF (ir_prm.base_date = gv_base_date_ship) THEN
        IF cur_main_data2%ISOPEN THEN
          CLOSE cur_main_data2;
        END IF;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_record;
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : �p�����[�^�`�F�b�N ==> (OPTION)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ir_prm        IN  rec_param_data
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lb_item_01_p   BOOLEAN;
    lb_item_01_i   BOOLEAN;
    lb_item_02_p   BOOLEAN;
    lb_item_02_i   BOOLEAN;
    lb_item_03_p   BOOLEAN;
    lb_item_03_i   BOOLEAN;
--
    lb_wh_code_01  BOOLEAN;
    lb_wh_code_02  BOOLEAN;
    lb_wh_code_03  BOOLEAN;
--
    lb_block_01    BOOLEAN;
    lb_block_02    BOOLEAN;
    lb_block_03    BOOLEAN;
--
    lv_err_code    VARCHAR2(100);
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ===============================================
    -- OPM�i�ڃ}�X�^�`�F�b�N�p�J�[�\��
    -- ===============================================
    CURSOR cur_item(
      civ_item_01 VARCHAR2
     ,civ_item_02 VARCHAR2
     ,civ_item_03 VARCHAR2
--add start 1.12
     ,civ_prod_div VARCHAR2
     ,civ_item_div VARCHAR2
--add end 1.12
    )
    IS
      SELECT xicv.category_set_name                           category_set_name   --�J�e�S���Z�b�g��
            ,xicv.item_no                                     item_no             --�i�ڃR�[�h
      FROM   xxcmn_item_categories2_v                         xicv                --OPM�i�ڃJ�e�S���Z�b�g�������
      WHERE  xicv.category_set_name IN (gv_category_prod,gv_category_item)        --�J�e�S���Z�b�g��(���i�敪,�i�ڋ敪)
      AND    xicv.item_no IN (civ_item_01,civ_item_02,civ_item_03)                --�i�ڃR�[�h(�p�����[�^.�i��1�`3)
      AND    xicv.enabled_flag = 'Y'                                              --�g�p�\�t���O
      AND    xicv.disable_date IS NULL                                            --������
--add start 1.12
      AND   (xicv.category_set_name = gv_category_prod
        AND  xicv.segment1 = NVL(civ_prod_div,xicv.segment1)
      OR     xicv.category_set_name = gv_category_item
        AND  xicv.segment1 = NVL(civ_item_div,xicv.segment1))
--add end 1.12
      ;
--
    TYPE lr_item IS RECORD(
      category_set_name xxcmn_item_categories2_v.category_set_name%TYPE
     ,item_no xxcmn_item_categories2_v.item_no%TYPE
    );
--
    TYPE lt_item_tbl IS TABLE OF lr_item INDEX BY BINARY_INTEGER;
--
    lt_item          lt_item_tbl;
--
    -- ===============================================
    -- OPM�q�Ƀ}�X�^�E�ۊǏꏊ�}�X�^�`�F�b�N�p�J�[�\���ϐ�
    -- ===============================================
    TYPE lref_wh IS REF CURSOR;
    cur_wh         lref_wh;
    lv_wh_code     VARCHAR2(4000);
--
    -- ===============================================
    -- OPM�ۊǏꏊ�}�X�^�`�F�b�N�p�J�[�\��
    -- ===============================================
    CURSOR cur_block(
      civ_block_01 VARCHAR2
     ,civ_block_02 VARCHAR2
     ,civ_block_03 VARCHAR2
    )
    IS
      SELECT xilv.distribution_block                          block_name          --�u���b�N
      FROM   xxcmn_item_locations2_v                          xilv                --OPM�ۊǏꏊ���
      WHERE  xilv.distribution_block IN (civ_block_01,civ_block_02,civ_block_03)  --�u���b�N
      AND    xilv.disable_date IS NULL                                            --������
      ;
--
    -- *** ���[�J���E��O ***
    data_check_expt              EXCEPTION ;             -- �f�[�^�`�F�b�N�G�N�Z�v�V����
--
  BEGIN
--
    -- ===============================================
    -- �N����FROM,TO�`�F�b�N
    -- ===============================================
    IF (ir_prm.ymd_from > ir_prm.ymd_to) THEN
      lv_err_code := gv_xxinv_10096;
      RAISE data_check_expt;
    END IF;
--
    -- ===============================================
    -- �i�ڃ}�X�^�`�F�b�N
    -- ===============================================
    IF ((ir_prm.item_code_01 IS NULL)
    AND (ir_prm.item_code_02 IS NULL)
    AND (ir_prm.item_code_03 IS NULL)) THEN
      --�i�ڂ������w�肳��Ȃ������ꍇ�̓`�F�b�N���Ȃ�
      NULL;
    ELSE
      --�i�ځE�J�e�S���擾�J�[�\��OPEN
      OPEN cur_item (
        ir_prm.item_code_01
       ,ir_prm.item_code_02
       ,ir_prm.item_code_03
--add start 1.12
       ,ir_prm.prod_div
       ,ir_prm.item_div
--add end 1.12
      );
      --�o���N�t�F�b�`
      FETCH cur_item BULK COLLECT INTO lt_item;
      --�N���[�Y
      CLOSE cur_item;
--
      --�i��1�̐^�U�l�������ݒ�
      IF (ir_prm.item_code_01 IS NULL) THEN
        lb_item_01_p := TRUE;
        lb_item_01_i := TRUE;
      ELSE
        lb_item_01_p := FALSE;
        lb_item_01_i := FALSE;
      END IF;
--
      --�i��2�̐^�U�l�������ݒ�
      IF (ir_prm.item_code_02 IS NULL) THEN
        lb_item_02_p := TRUE;
        lb_item_02_i := TRUE;
      ELSE
        lb_item_02_p := FALSE;
        lb_item_02_i := FALSE;
      END IF;
--
      --�i��3�̐^�U�l�������ݒ�
      IF (ir_prm.item_code_03 IS NULL) THEN
        lb_item_03_p := TRUE;
        lb_item_03_i := TRUE;
      ELSE
        lb_item_03_p := FALSE;
        lb_item_03_i := FALSE;
      END IF;
--
      <<item_loop>>
      FOR i IN 1..lt_item.COUNT LOOP
--
        --�J�e�S���Z�b�g.���i�敪�`�F�b�N
        IF (lt_item(i).category_set_name = gv_category_prod) THEN
          IF (lt_item(i).item_no = ir_prm.item_code_01) THEN
            lb_item_01_p := TRUE;
          ELSIF (lt_item(i).item_no = ir_prm.item_code_02) THEN
            lb_item_02_p := TRUE;
          ELSIF (lt_item(i).item_no = ir_prm.item_code_03) THEN
            lb_item_03_p := TRUE;
          END IF;
        END IF;
--
        --�J�e�S���Z�b�g.�i�ڋ敪�`�F�b�N
        IF (lt_item(i).category_set_name = gv_category_item) THEN
          IF (lt_item(i).item_no = ir_prm.item_code_01) THEN
            lb_item_01_i := TRUE;
          ELSIF (lt_item(i).item_no = ir_prm.item_code_02) THEN
            lb_item_02_i := TRUE;
          ELSIF (lt_item(i).item_no = ir_prm.item_code_03) THEN
            lb_item_03_i := TRUE;
          END IF;
        END IF;
--
      END LOOP item_loop;
--
--
      IF (lb_item_01_p AND lb_item_02_p AND lb_item_03_p
      AND lb_item_01_i AND lb_item_02_i AND lb_item_03_i) THEN
        NULL;
      ELSE
        lv_err_code := gv_xxinv_10111;
        RAISE data_check_expt;
      END IF;
    END IF;
--
    -- ===============================================
    -- �q�Ƀ}�X�^�`�F�b�N
    -- ===============================================
    IF ((ir_prm.wh_code_01 IS NULL)
    AND (ir_prm.wh_code_02 IS NULL)
    AND (ir_prm.wh_code_03 IS NULL)) THEN
      NULL;
    ELSE
      --�q�ɕۊǑq�ɋ敪=�q�ɂ̏ꍇ
      IF (ir_prm.wh_loc_ctl = gv_wh_loc_ctl_wh) THEN
        OPEN cur_wh FOR
          SELECT xilv.whse_code                               wh_code             --�q�ɃR�[�h
          FROM   xxcmn_item_locations2_v                      xilv                --�q�Ƀ}�X�^
          WHERE  xilv.whse_code IN (ir_prm.wh_code_01,ir_prm.wh_code_02,ir_prm.wh_code_03)
          AND    xilv.disable_date IS NULL                                        --������
          ;
      --�q�ɕۊǑq�ɋ敪=�ۊǑq�ɂ̏ꍇ
      ELSIF (ir_prm.wh_loc_ctl = gv_wh_loc_ctl_loc) THEN
        OPEN cur_wh FOR
          SELECT xilv.segment1                                wh_code             --�ۊǑq�ɃR�[�h
          FROM   xxcmn_item_locations2_v                      xilv                --�ۊǑq�Ƀ}�X�^
          WHERE  xilv.segment1 IN (ir_prm.wh_code_01,ir_prm.wh_code_02,ir_prm.wh_code_03)
          AND    xilv.disable_date IS NULL                                        --������
          ;
      END IF;
--
      --�q��1�̐^�U�l�������ݒ�
      IF (ir_prm.wh_code_01 IS NULL) THEN
        lb_wh_code_01 := TRUE;
      ELSE
        lb_wh_code_01 := FALSE;
      END IF;
--
      --�q��2�̐^�U�l�������ݒ�
      IF (ir_prm.wh_code_02 IS NULL) THEN
        lb_wh_code_02 := TRUE;
      ELSE
        lb_wh_code_02 := FALSE;
      END IF;
--
      --�q��3�̐^�U�l�������ݒ�
      IF (ir_prm.wh_code_03 IS NULL) THEN
        lb_wh_code_03 := TRUE;
      ELSE
        lb_wh_code_03 := FALSE;
      END IF;
--
      <<wh_loop>>
      LOOP
        FETCH cur_wh INTO lv_wh_code;
        EXIT WHEN cur_wh%NOTFOUND;
--
        IF (lv_wh_code = ir_prm.wh_code_01) THEN
          lb_wh_code_01 := TRUE;
        END IF;
--
        IF (lv_wh_code = ir_prm.wh_code_02) THEN
          lb_wh_code_02 := TRUE;
        END IF;
--
        IF (lv_wh_code = ir_prm.wh_code_03) THEN
          lb_wh_code_03 := TRUE;
        END IF;
--
      END LOOP wh_loop;
--
      --�J�[�\���N���[�Y
      CLOSE cur_wh;
--
      IF (lb_wh_code_01 AND lb_wh_code_02 AND lb_wh_code_03) THEN
        NULL;
      ELSE
        --�q�ɕۊǑq�ɑI���敪���q�ɂ̏ꍇ
        IF (ir_prm.wh_loc_ctl = gv_wh_loc_ctl_wh) THEN
          lv_err_code := gv_xxinv_10112;
        --�q�ɕۊǑq�ɑI���敪���ۊǑq�ɂ̏ꍇ
        ELSIF (ir_prm.wh_loc_ctl = gv_wh_loc_ctl_loc) THEN
          lv_err_code := gv_xxinv_10153;
        END IF;
        RAISE data_check_expt;
      END IF;
--
    END IF;
--
    -- ===============================================
    -- �����u���b�N�`�F�b�N
    -- ===============================================
    IF ((ir_prm.block_01 IS NULL)
    AND (ir_prm.block_02 IS NULL)
    AND (ir_prm.block_03 IS NULL)) THEN
      NULL;
    ELSE
      --�u���b�N1�̐^�U�l�������ݒ�
      IF (ir_prm.block_01 IS NULL) THEN
        lb_block_01 := TRUE;
      ELSE
        lb_block_01 := FALSE;
      END IF;
--
      --�u���b�N2�̐^�U�l�������ݒ�
      IF (ir_prm.block_02 IS NULL) THEN
        lb_block_02 := TRUE;
      ELSE
        lb_block_02 := FALSE;
      END IF;
--
      --�u���b�N3�̐^�U�l�������ݒ�
      IF (ir_prm.block_03 IS NULL) THEN
        lb_block_03 := TRUE;
      ELSE
        lb_block_03 := FALSE;
      END IF;
--
      <<block_loop>>
      FOR rec_block IN cur_block(ir_prm.block_01, ir_prm.block_02, ir_prm.block_03) LOOP
        IF (rec_block.block_name = ir_prm.block_01) THEN
          lb_block_01 := TRUE;
        END IF;
--
        IF (rec_block.block_name = ir_prm.block_02) THEN
          lb_block_02 := TRUE;
        END IF;
--
        IF (rec_block.block_name = ir_prm.block_03) THEN
          lb_block_03 := TRUE;
        END IF;
--
      END LOOP block_loop;
--
      IF  (lb_block_01 AND lb_block_02 AND lb_block_03) THEN
        NULL;
      ELSE
        lv_err_code := gv_xxinv_10113;
        RAISE data_check_expt;
      END IF;
--
    END IF;
--
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    WHEN data_check_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv
                                            ,lv_err_code    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
      IF cur_item%ISOPEN THEN
        CLOSE cur_item;
      END IF;
--
      IF cur_wh%ISOPEN THEN
        CLOSE cur_wh;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ymd_from          IN     VARCHAR2         --    1. �N����_FROM
   ,iv_ymd_to            IN     VARCHAR2         --    2. �N����_TO
   ,iv_base_date         IN     VARCHAR2         --    3. ������^�����
   ,iv_inout_ctl         IN     VARCHAR2         --    4. ���o�ɋ敪
   ,iv_prod_div          IN     VARCHAR2         --    5. ���i�敪
   ,iv_unit_ctl          IN     VARCHAR2         --    6. �P�ʋ敪
   ,iv_wh_loc_ctl        IN     VARCHAR2         --    7. �q��/�ۊǑq�ɑI���敪
   ,iv_wh_code_01        IN     VARCHAR2         --    8. �q��/�ۊǑq�ɃR�[�h1
   ,iv_wh_code_02        IN     VARCHAR2         --    9. �q��/�ۊǑq�ɃR�[�h2
   ,iv_wh_code_03        IN     VARCHAR2         --   10. �q��/�ۊǑq�ɃR�[�h3
   ,iv_block_01          IN     VARCHAR2         --   11. �u���b�N1
   ,iv_block_02          IN     VARCHAR2         --   12. �u���b�N2
   ,iv_block_03          IN     VARCHAR2         --   13. �u���b�N3
   ,iv_item_div          IN     VARCHAR2         --   14. �i�ڋ敪
   ,iv_item_code_01      IN     VARCHAR2         --   15. �i�ڃR�[�h1
   ,iv_item_code_02      IN     VARCHAR2         --   16. �i�ڃR�[�h2
   ,iv_item_code_03      IN     VARCHAR2         --   17. �i�ڃR�[�h3
   ,iv_lot_no_01         IN     VARCHAR2         --   18. ���b�gNo1
   ,iv_lot_no_02         IN     VARCHAR2         --   19. ���b�gNo2
   ,iv_lot_no_03         IN     VARCHAR2         --   20. ���b�gNo3
   ,iv_mnfctr_date_01    IN     VARCHAR2         --   21. �����N����1
   ,iv_mnfctr_date_02    IN     VARCHAR2         --   22. �����N����2
   ,iv_mnfctr_date_03    IN     VARCHAR2         --   23. �����N����3
   ,iv_reason_code_01    IN     VARCHAR2         --   24. ���R�R�[�h1
   ,iv_reason_code_02    IN     VARCHAR2         --   25. ���R�R�[�h2
   ,iv_reason_code_03    IN     VARCHAR2         --   26. ���R�R�[�h3
   ,iv_symbol            IN     VARCHAR2         --   27. �ŗL�L��
   ,ov_errbuf            OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    xml_data_table   XML_DATA;
    lv_xml_string    VARCHAR2(32000);
    ln_retcode       NUMBER;
--
    -- *** ���[�J���ϐ� ***
    lr_prm           rec_param_data;
    lt_main_data     tab_main_data;
    lv_output_mode   NUMBER;
--
  BEGIN
--dbms_output.put_line('submain start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���̓p�����[�^ ���R�[�h�ϐ��Z�b�g
    -- ===============================================
    lr_prm.ymd_from        := SUBSTRB(iv_ymd_from,1,10);
    lr_prm.ymd_to          := SUBSTRB(iv_ymd_to,1,10);
    lr_prm.base_date       := iv_base_date;
    lr_prm.inout_ctl       := iv_inout_ctl;
    lr_prm.prod_div        := iv_prod_div;
    lr_prm.unit_ctl        := iv_unit_ctl;
    lr_prm.wh_loc_ctl      := iv_wh_loc_ctl;
    lr_prm.wh_code_01      := iv_wh_code_01;
    lr_prm.wh_code_02      := iv_wh_code_02;
    lr_prm.wh_code_03      := iv_wh_code_03;
    lr_prm.block_01        := iv_block_01;
    lr_prm.block_02        := iv_block_02;
    lr_prm.block_03        := iv_block_03;
    lr_prm.item_div        := iv_item_div;
    lr_prm.item_code_01    := iv_item_code_01;
    lr_prm.item_code_02    := iv_item_code_02;
    lr_prm.item_code_03    := iv_item_code_03;
    lr_prm.lot_no_01       := iv_lot_no_01;
    lr_prm.lot_no_02       := iv_lot_no_02;
    lr_prm.lot_no_03       := iv_lot_no_03;
    lr_prm.mnfctr_date_01  := SUBSTRB(iv_mnfctr_date_01,1,10);
    lr_prm.mnfctr_date_02  := SUBSTRB(iv_mnfctr_date_02,1,10);
    lr_prm.mnfctr_date_03  := SUBSTRB(iv_mnfctr_date_03,1,10);
    lr_prm.reason_code_01  := iv_reason_code_01;
    lr_prm.reason_code_02  := iv_reason_code_02;
    lr_prm.reason_code_03  := iv_reason_code_03;
    lr_prm.symbol          := iv_symbol;
--
    -- ===============================================
    -- �v���t�@�C���擾
    -- ===============================================
    BEGIN
      SELECT
        FND_PROFILE.VALUE(gv_prf_prod_div) --���i�敪
       ,FND_PROFILE.VALUE(gv_prf_item_div) --�i�ڋ敪
      INTO
        gv_category_prod
       ,gv_category_item
      FROM DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- ===============================================
    -- ���̓p�����[�^�`�F�b�N
    -- ===============================================
    check_parameter(
      lr_prm            -- ���̓p�����[�^
     ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �f�[�^���o����
    -- ===============================================
    get_record(
      lr_prm            -- ���̓p�����[�^
     ,lt_main_data      -- ���o�f�[�^
     ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      --�G���[����
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      --�Ώۃf�[�^0��
      lv_output_mode := gv_output_notfound;
    ELSIF (lv_retcode = gv_status_normal) THEN
      --����
      -- ===============================================
      -- XML�f�[�^�쐬
      -- ===============================================
      create_xml(
        xml_data_table
       ,lr_prm
       ,lt_main_data
       ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      lv_output_mode := gv_output_normal;
--
    END IF;
--
    -- ===============================================
    -- XML�f�[�^�o��
    -- ===============================================
    output_xml(
      iox_xml_data   => xml_data_table  -- XML�f�[�^
     ,iv_output_mode => lv_output_mode
     ,ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg      => lv_errmsg
    ) ;
  --
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      ov_errmsg := lv_errmsg;
    END IF ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf               OUT    VARCHAR2         --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode              OUT    VARCHAR2         --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_ymd_from          IN     VARCHAR2         --    1. �N����_FROM
   ,iv_ymd_to            IN     VARCHAR2         --    2. �N����_TO
   ,iv_base_date         IN     VARCHAR2         --    3. ������^�����
   ,iv_inout_ctl         IN     VARCHAR2         --    4. ���o�ɋ敪
   ,iv_prod_div          IN     VARCHAR2         --    5. ���i�敪
   ,iv_unit_ctl          IN     VARCHAR2         --    6. �P�ʋ敪
   ,iv_wh_loc_ctl        IN     VARCHAR2         --    7. �q��/�ۊǑq�ɑI���敪
   ,iv_wh_code_01        IN     VARCHAR2         --    8. �q��/�ۊǑq�ɃR�[�h1
   ,iv_wh_code_02        IN     VARCHAR2         --    9. �q��/�ۊǑq�ɃR�[�h2
   ,iv_wh_code_03        IN     VARCHAR2         --   10. �q��/�ۊǑq�ɃR�[�h3
   ,iv_block_01          IN     VARCHAR2         --   11. �u���b�N1
   ,iv_block_02          IN     VARCHAR2         --   12. �u���b�N2
   ,iv_block_03          IN     VARCHAR2         --   13. �u���b�N3
   ,iv_item_div          IN     VARCHAR2         --   14. �i�ڋ敪
   ,iv_item_code_01      IN     VARCHAR2         --   15. �i�ڃR�[�h1
   ,iv_item_code_02      IN     VARCHAR2         --   16. �i�ڃR�[�h2
   ,iv_item_code_03      IN     VARCHAR2         --   17. �i�ڃR�[�h3
   ,iv_lot_no_01         IN     VARCHAR2         --   18. ���b�gNo1
   ,iv_lot_no_02         IN     VARCHAR2         --   19. ���b�gNo2
   ,iv_lot_no_03         IN     VARCHAR2         --   20. ���b�gNo3
   ,iv_mnfctr_date_01    IN     VARCHAR2         --   21. �����N����1
   ,iv_mnfctr_date_02    IN     VARCHAR2         --   22. �����N����2
   ,iv_mnfctr_date_03    IN     VARCHAR2         --   23. �����N����3
   ,iv_reason_code_01    IN     VARCHAR2         --   24. ���R�R�[�h1
   ,iv_reason_code_02    IN     VARCHAR2         --   25. ���R�R�[�h2
   ,iv_reason_code_03    IN     VARCHAR2         --   26. ���R�R�[�h3
   ,iv_symbol            IN     VARCHAR2         --   27. �ŗL�L��
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_ymd_from       
     ,iv_ymd_to         
     ,iv_base_date      
     ,iv_inout_ctl      
     ,iv_prod_div       
     ,iv_unit_ctl       
     ,iv_wh_loc_ctl     
     ,iv_wh_code_01     
     ,iv_wh_code_02     
     ,iv_wh_code_03     
     ,iv_block_01       
     ,iv_block_02       
     ,iv_block_03       
     ,iv_item_div       
     ,iv_item_code_01   
     ,iv_item_code_02   
     ,iv_item_code_03   
     ,iv_lot_no_01      
     ,iv_lot_no_02      
     ,iv_lot_no_03      
     ,iv_mnfctr_date_01 
     ,iv_mnfctr_date_02 
     ,iv_mnfctr_date_03 
     ,iv_reason_code_01 
     ,iv_reason_code_02 
     ,iv_reason_code_03 
     ,iv_symbol         
     ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      put_line(FND_FILE.LOG,lv_errbuf) ;
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      put_line(FND_FILE.LOG,lv_errmsg) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXINV550002C;
/
