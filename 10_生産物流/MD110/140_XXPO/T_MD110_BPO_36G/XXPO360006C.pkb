CREATE OR REPLACE PACKAGE BODY xxpo360006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360006C(body)
 * Description      : �d��������ו\
 * MD.050           : �L���x�����[Issue1.0(T_MD050_BPO_360)
 * MD.070           : �L���x�����[Issue1.0(T_MD070_BPO_36G)
 * Version          : 1.15
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_get_in_statement      FUNCTION  : IN��̓��e��Ԃ��B(vendor_type)
 *  fnc_get_in_statement      FUNCTION  : IN��̓��e��Ԃ��B(dept_code_type)
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  fnc_set_xml               FUNCTION  : �w�l�k�p�z��Ɋi�[����B
 *  prc_initialize            PROCEDURE : �O����(G-2)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(G-3)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬(G-4)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/13    1.0   K.Kamiyoshi      �V�K�쐬
 *  2008/05/09    1.1   K.Kamiyoshi      �s�ID5-9�Ή�
 *  2008/05/12    1.2   K.Kamiyoshi      �s�ID10�Ή�
 *  2008/05/13    1.3   K.Kamiyoshi      �s�ID11�Ή�
 *  2008/05/13    1.4   T.Endou         (�O�����[�U�[)�����Ȃ��ԕi���A�Z�L�����e�B�v���̑Ή�
 *  2008/05/22    1.5   T.Endou          �ʏ������A�����[������.���K�敪�A���ۋ��敪���g�p����B
 *                                       �����҂͊O�������Ƃ���B
 *                                       �[�����͈͎̔w��́A���ׂĂŎ���ԕi�A�h�I�����g�p����B
 *  2008/05/23    1.6   Y.Majikina       ���ʎ擾���ڂ̕ύX�B���z�v�Z�̕s�����C��
 *  2008/05/24    1.7   Y.Majikina       �d���ԕi���̕������C��
 *  2008/05/26    1.8   Y.Majikina       ��������d����ԕi���A�������A������P���A�P���A
 *                                       ���K�敪�A���K�A�a����K���z�A���ۋ��敪�A���ۋ��A
 *                                       ���ۋ��z�́A����ԕi���уA�h�I�����擾����
 *  2008/05/28    1.9   Y.Majikina       ���b�`�e�L�X�g�̉��y�[�W�Z�N�V�����̕ύX�ɂ��
 *                                       XML�\���̏C��
 *  2008/05/29    1.10  T.Endou          �[�����͈͎̔w��́A���ׂĎ���ԕi�A�h�I�����g�p����
 *                                       �C���͂��Ă��������A���[�ɕ\�����镔�����C������B
 *  2008/06/03    1.11  T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/11    1.12  T.Endou          �����Ȃ��d����ԕi�̏ꍇ�A�ԕi�A�h�I���̈�����ID���g�p����
 *  2008/06/17    1.13  T.Ikehara        TEMP�̈�G���[����̂��߁Axxpo_categories_v��
 *                                       �g�p���Ȃ��悤�ɂ���
 *  2008/06/24    1.14  T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/23    1.15  Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V��XXCMN_ITEM_CATEGORIES6_V�ύX
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo360006c' ;   -- �p�b�P�[�W��
  gv_print_name           CONSTANT VARCHAR2(20) := '�d��������ו\' ;    -- ���[��
  gv_lot_n_div            CONSTANT VARCHAR2(1) := '0';               -- ���b�g�Ǘ��Ȃ�
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_language_code              CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_enable_flag                CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_lookup_type_tax_rate       CONSTANT VARCHAR2(100) := 'XXCMN_CONSUMPTION_TAX_RATE' ;
  gc_lookup_type_kousen         CONSTANT VARCHAR2(100) := 'XXPO_KOUSEN_TYPE' ;
  gc_lookup_type_fukakin        CONSTANT VARCHAR2(100) := 'XXPO_FUKAKIN_TYPE' ;
--
  ------------------------------
  -- �S�p����
  ------------------------------
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;      -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;       -- �A�v���P�[�V�����iXXPO�j
--
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '�L���x���Z�L�����e�BVIEW' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := '���[�U�[ID' ;
--
  ------------------------------
  -- ���t���ڕҏW�֘A
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '�N' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '��' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '��' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_md_format       CONSTANT VARCHAR2(30) := 'MM/DD' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_d                   CONSTANT VARCHAR2(1) := 'D';
  gc_n                   CONSTANT VARCHAR2(1) := 'N';
  gc_t                   CONSTANT VARCHAR2(1) := 'T';
  gc_z                   CONSTANT VARCHAR2(1) := 'Z';
--
  gn_one                 CONSTANT NUMBER        := 1   ;
  gn_two                 CONSTANT NUMBER        := 2   ;
  gv_out_assen           CONSTANT VARCHAR2(100) := '1' ;               --�o�͋敪 �����ҕ�
  gv_out_torihiki        CONSTANT VARCHAR2(100) := '2' ;               --�o�͋敪 ������
  gv_out_syukei          CONSTANT VARCHAR2(100) := '3' ;               --�o�͋敪 �W�v
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE vendor_type    IS TABLE OF xxcmn_vendors2_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE dept_code_type IS TABLE OF po_headers_all.attribute10%TYPE INDEX BY BINARY_INTEGER;
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
      out_flg             VARCHAR2(1)    --�o�͋敪    1:�����ҕ�(��:���� ��:����� ��:������)
                                         --            2:������(��:���� ��:������ ��:�����)
     ,deliver_from        VARCHAR2(10)   --�[����FROM
     ,deliver_from_date   DATE           --�[����FROM(���t) - 1
     ,deliver_to          VARCHAR2(10)   --�[����TO
     ,deliver_to_date     DATE           --�[����TO(���t) + 1
     ,dept_code           dept_code_type -- �S�������P�`�T
     ,vendor_code         vendor_type    -- �����P�`�T
     ,mediator_code       vendor_type    -- �����҂P�`�T
     ,po_num              po_headers_all.segment1%TYPE          -- �����ԍ�
     ,item_code           xxcmn_item_mst_v.item_no%TYPE         -- �i�ڃR�[�h
     ,security_flg        xxpo_security_supply_v.security_class%TYPE
                                                            -- �Z�L�����e�B�敪
    ) ;
--
    gr_param_rec
             rec_param_data ;          -- �p�����[�^��n���p
--
  -- �d��������ו\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
      txns_id         xxpo_rcv_and_rtn_txns.txns_id%TYPE                    --���ID
     ,break_dtl       VARCHAR2(12)                                          --���u���[�N�L�[
     ,break_mid       VARCHAR2(8)                                           --���u���[�N�L�[
     ,dept_code       xxpo_rcv_and_rtn_txns.department_code%TYPE            --�����R�[�h
     ,dept_name       xxcmn_locations_v.description%TYPE                    --������
     ,siire_no        xxcmn_vendors_v.segment1%TYPE                         --�d����ԍ�
     ,siire_sht       xxcmn_vendors_v.vendor_short_name%TYPE                --����
     ,assen_no        xxcmn_vendors_v.segment1%TYPE                         --�����Ҏd����ԍ�
     ,assen_order     xxcmn_vendors_v.segment1%TYPE                         --�����ҏ���
     ,assen_sht       xxcmn_vendors_v.vendor_short_name%TYPE                --����
     ,po_header_id    po_headers_all.po_header_id%TYPE                      --����ID
     ,txns_date       VARCHAR2(5)                                           --�����
     ,txns_type       xxpo_rcv_and_rtn_txns.txns_type%TYPE                  --����^�C�v
     ,po_no           xxpo_rcv_and_rtn_txns.source_document_number%TYPE     --�������ԍ�
     ,moto_line_no    xxpo_rcv_and_rtn_txns.source_document_line_num%TYPE   --���������הԍ�
     ,rcv_rtn_no      xxpo_rcv_and_rtn_txns.rcv_rtn_number%TYPE             --����ԕi�ԍ�
     ,item_no         xxcmn_item_mst2_v.item_no%TYPE                        --�i��
     ,item_name       xxcmn_item_mst2_v.item_name%TYPE                      --�i�ږ���
     ,item_sht        xxcmn_item_mst2_v.item_short_name%TYPE                --�i�ڗ���
     ,futai_code      xxpo_rcv_and_rtn_txns.futai_code%TYPE                 --�t��
     ,kobiki_rate     xxpo_rcv_and_rtn_txns.kobiki_rate%TYPE                --������
     ,kobikigo        xxpo_rcv_and_rtn_txns.kobki_converted_unit_price%TYPE --������P��
     ,kousen_price    xxpo_rcv_and_rtn_txns.kousen_price%TYPE               --�a����K���z
     ,fukakin_price   xxpo_rcv_and_rtn_txns.fukakin_price%TYPE              --���ۋ��z
     ,lot_no          ic_lots_mst.lot_no%TYPE                               --���b�gno
     ,quantity        xxpo_rcv_and_rtn_txns.quantity%TYPE           --����ԕi����
     ,unit_price      xxpo_rcv_and_rtn_txns.unit_price%TYPE                 --�P��
     ,kousen_type     xxpo_rcv_and_rtn_txns.kousen_type%TYPE                --���K�敪
     ,kousen_name     fnd_lookup_values.meaning%TYPE                        --���K�敪��
     ,kousen          xxpo_rcv_and_rtn_txns.kousen_rate_or_unit_price%TYPE  --���K
     ,rcv_rtn_uom     xxpo_rcv_and_rtn_txns.rcv_rtn_uom%TYPE                --����ԕi�P��
     ,fukakin_type    xxpo_rcv_and_rtn_txns.fukakin_type%TYPE               --���ۋ��敪
     ,fukakin_name    fnd_lookup_values.meaning%TYPE                        --���ۋ��敪��
     ,fukakin         xxpo_rcv_and_rtn_txns.fukakin_rate_or_unit_price%TYPE --���ۋ�
     ,zeiritu         fnd_lookup_values.lookup_code%TYPE                    --�ŗ�
     ,order1          fnd_lookup_values.lookup_code%TYPE                    --�\����
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  --�w�b�_�p
  TYPE rec_header  IS RECORD(
      deliver_from_date   VARCHAR2(14)                                 --�[����FROM(YYYY�NMM��DD��)
     ,deliver_to_date     VARCHAR2(14)                                 --�[����TO  (YYYY�NMM��DD��)
     ,user_id             xxpo_per_all_people_f_v.person_id%TYPE       --�S����ID
     ,user_name           per_all_people_f.per_information18%TYPE      --�S����
     ,user_dept           xxcmn_locations_all.location_short_name%TYPE --����
     ,user_vender         xxpo_per_all_people_f_v.attribute4%TYPE      --�����R�[�h
     ,user_vender_id      po_vendors.vendor_id%TYPE                    -- �d����ID
     ,user_vender_site    po_lines_all.attribute2%TYPE                 --�����T�C�g�R�[�h
    ) ;
--
  gr_header_rec rec_header;
--
  --�L�[����p
  TYPE rec_keybreak  IS RECORD(
      lot       VARCHAR2(200)
     ,hutai     VARCHAR2(200)
     ,item      VARCHAR2(200)
     ,deliver   VARCHAR2(200)
     ,detail    VARCHAR2(200)
     ,middle    VARCHAR2(200)
     ,dept      VARCHAR2(200)
    ) ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;  -- �c�ƒP��
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- ���[ID
  gd_exec_date              DATE         ;    -- ���{��
--
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
  ------------------------------
  -- ���b�N�A�b�v�p
  ------------------------------
  gv_tax_class              fnd_lookup_values.lookup_code%TYPE ;
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(vendor_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_vendor_type IN vendor_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<vendor_code_loop>>
    FOR ln_cnt IN 1..itbl_vendor_type.COUNT LOOP
      lv_in := lv_in || ',''' || itbl_vendor_type(ln_cnt) || '''';
    END LOOP vendor_code_loop;
--
    RETURN(
      SUBSTR(lv_in, gn_two));
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(dept_code_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_dept_code_type IN dept_code_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<dept_code_type_loop>>
    FOR ln_cnt IN 1..itbl_dept_code_type.COUNT LOOP
      lv_in := lv_in || ',''' || itbl_dept_code_type(ln_cnt) || '''';
    END LOOP dept_code_type_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_two));
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_set_xml
   * Description      : xml���ڃZ�b�g
   ***********************************************************************************/
  FUNCTION fnc_set_xml(
      ic_type              IN        CHAR       --   �^�O�^�C�v  T:�^�O
                                                              -- D:�f�[�^
                                                              -- N:�f�[�^(NULL�̏ꍇ�^�O�������Ȃ�)
                                                              -- Z:�f�[�^(NULL�̏ꍇ0�\��)
     ,iv_name              IN        VARCHAR2                --   �^�O��
     ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   �^�O�f�[�^(�ȗ���
     ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   �������i�o�C�g�j(�ȗ���
     ,iv_index             IN        NUMBER    DEFAULT NULL  --   �C���f�b�N�X(�ȗ���
    )  RETURN BOOLEAN
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_set_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    ln_xml_idx NUMBER;
    ln_work    NUMBER;
--
  BEGIN
--
    IF (ic_type = gc_n) THEN
      --NULL�̏ꍇ�^�O�������Ȃ��Ή�
      IF (iv_value IS NULL) THEN
        RETURN TRUE;
      END IF;
--
      BEGIN
        ln_work := TO_NUMBER(iv_value);
      EXCEPTION
        WHEN OTHERS THEN
          RETURN TRUE;
      END;
    END IF;
--
    IF (iv_index IS NULL) THEN
      ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
    ELSE
      ln_xml_idx := iv_index;
    END IF;
--
    --�^�O�Z�b�g
    gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<�^�O��>
    IF (ic_type = gc_t) THEN
      gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<�^�O�̂�>
    ELSE
      gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<�^�O �� �f�[�^>
      IF (ic_type = gc_z) THEN
        gt_xml_data_table(ln_xml_idx).tag_value := NVL(iv_value, 0) ; --Null�̏ꍇ�O�\��
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_value := iv_value ;         --Null�ł����̂܂ܕ\��
      END IF;
    END IF;
--
    --�����؂�
    IF (in_lengthb IS NOT NULL) THEN
      gt_xml_data_table(ln_xml_idx).tag_value
        := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
    END IF;
--
    RETURN TRUE;
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RETURN FALSE;
  END fnc_set_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_set_param
   * Description      : �p�����[�^�̎擾
   ***********************************************************************************/
  PROCEDURE prc_set_param
    (
      ov_errbuf             OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_out_flg            IN  VARCHAR2       -- �o�͋敪
     ,iv_deliver_from       IN  VARCHAR2       -- �[����FROM
     ,iv_deliver_to         IN  VARCHAR2       -- �[����TO
     ,iv_vendor_code1       IN  VARCHAR2       -- �����P
     ,iv_vendor_code2       IN  VARCHAR2       -- �����Q
     ,iv_vendor_code3       IN  VARCHAR2       -- �����R
     ,iv_vendor_code4       IN  VARCHAR2       -- �����S
     ,iv_vendor_code5       IN  VARCHAR2       -- �����T
     ,iv_mediator_code1     IN  VARCHAR2       -- �����҂P
     ,iv_mediator_code2     IN  VARCHAR2       -- �����҂Q
     ,iv_mediator_code3     IN  VARCHAR2       -- �����҂R
     ,iv_mediator_code4     IN  VARCHAR2       -- �����҂S
     ,iv_mediator_code5     IN  VARCHAR2       -- �����҂T
     ,iv_dept_code1         IN  VARCHAR2       -- �S�������P
     ,iv_dept_code2         IN  VARCHAR2       -- �S�������Q
     ,iv_dept_code3         IN  VARCHAR2       -- �S�������R
     ,iv_dept_code4         IN  VARCHAR2       -- �S�������S
     ,iv_dept_code5         IN  VARCHAR2       -- �S�������T
     ,iv_po_num             IN  VARCHAR2       -- �����ԍ�
     ,iv_item_code          IN  VARCHAR2       -- �i�ڃR�[�h
     ,iv_security_flg       IN  VARCHAR2       -- �Z�L�����e�B�敪
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_set_param' ; -- �v���O������
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
    ln_vendor_code       NUMBER DEFAULT 0; -- �����
    ln_mediator_code NUMBER DEFAULT 0; -- ������
    ln_dept_code         NUMBER DEFAULT 0; -- �S������
--
    -- *** ���[�J���E��O���� ***
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�o�͒l�i�[
    gv_report_id                   := 'XXPO360006T'  ;      -- ���[ID
    gd_exec_date                   := SYSDATE        ;      -- ���{��
--
    -- �o�͋敪
    gr_param_rec.out_flg           := iv_out_flg     ;
    -- �[����(FROM)
    gr_param_rec.deliver_from      := SUBSTR(TO_CHAR(iv_deliver_from), 1, 10) ;
    -- �[����(TO)
    gr_param_rec.deliver_to        := SUBSTR(TO_CHAR(iv_deliver_to), 1, 10)   ;
    -- �����ԍ�
    gr_param_rec.po_num            := iv_po_num      ;
    -- �i�ڃR�[�h
    gr_param_rec.item_code         := iv_item_code   ;
    -- �Z�L�����e�B�敪
    gr_param_rec.security_flg      := iv_security_flg;
--
    -- �����P
    IF TRIM(iv_vendor_code1) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code1;
    END IF;
    -- �����Q
    IF TRIM(iv_vendor_code2) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code2;
    END IF;
    -- �����R
    IF TRIM(iv_vendor_code3) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code3;
    END IF;
    -- �����S
    IF TRIM(iv_vendor_code4) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code4;
    END IF;
    -- �����T
    IF TRIM(iv_vendor_code5) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code5;
    END IF;
--
    -- �����҂P
    IF TRIM(iv_mediator_code1) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code1;
    END IF;
    -- �����҂Q
    IF TRIM(iv_mediator_code2) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code2;
    END IF;
    -- �����҂R
    IF TRIM(iv_mediator_code3) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code3;
    END IF;
    -- �����҂S
    IF TRIM(iv_mediator_code4) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code4;
    END IF;
    -- �����҂T
    IF TRIM(iv_mediator_code5) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code5;
    END IF;
--
    -- �S�������P
    IF TRIM(iv_dept_code1) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code1;
    END IF;
    -- �S�������Q
    IF TRIM(iv_dept_code2) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code2;
    END IF;
    -- �S�������R
    IF TRIM(iv_dept_code3) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code3;
    END IF;
    -- �S�������S
    IF TRIM(iv_dept_code4) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code4;
    END IF;
    -- �S�������T
    IF TRIM(iv_dept_code5) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code5;
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
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_set_param ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(G-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
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
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �c�ƒP�ʎ擾
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( 'ORG_ID' ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-00005'    ) ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �Ώ۔N��
    -- ====================================================
    -- ���t�ϊ�
    gr_header_rec.deliver_from_date :=   SUBSTR(gr_param_rec.deliver_from,1,4) || gc_jp_yy
                                      || SUBSTR(gr_param_rec.deliver_from,6,2) || gc_jp_mm
                                      || SUBSTR(gr_param_rec.deliver_from,9,2) || gc_jp_dd ;
    gr_header_rec.deliver_to_date   :=   SUBSTR(gr_param_rec.deliver_to,1,4) || gc_jp_yy
                                      || SUBSTR(gr_param_rec.deliver_to,6,2) || gc_jp_mm
                                      || SUBSTR(gr_param_rec.deliver_to,9,2) || gc_jp_dd ;
--
    --���t�^�ݒ�
    gr_param_rec.deliver_from_date :=  FND_DATE.STRING_TO_DATE( gr_param_rec.deliver_from
                                                              , gc_char_d_format) - 1;
    gr_param_rec.deliver_to_date   :=  FND_DATE.STRING_TO_DATE( gr_param_rec.deliver_to
                                                              , gc_char_d_format) + 1;
--
    -- ====================================================
    -- �S�������E�S���Җ�
    -- ====================================================
    BEGIN
      gr_header_rec.user_id   := FND_GLOBAL.USER_ID;
      gr_header_rec.user_dept := xxcmn_common_pkg.get_user_dept(gr_header_rec.user_id);
      gr_header_rec.user_name := xxcmn_common_pkg.get_user_name(gr_header_rec.user_id);
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := gv_status_warn ;
    END;
--
    -- ====================================================
    -- ���O�C�����[�U�[�̎����擾
    -- ====================================================
    BEGIN
      SELECT xssv.vendor_code
            ,xssv.vendor_site_code
            ,vnd.vendor_id
        INTO gr_header_rec.user_vender
            ,gr_header_rec.user_vender_site
            ,gr_header_rec.user_vender_id
      FROM  xxpo_security_supply_v xssv
           ,xxcmn_vendors2_v       vnd
      WHERE xssv.vendor_code    = vnd.segment1 (+)
        AND xssv.user_id        = gr_header_rec.user_id
        AND xssv.security_class = gr_param_rec.security_flg
        AND gr_param_rec.deliver_from_date + 1  --���-1���Ă��邽��
            BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+)
        ;
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              ,'APP-XXCMN-10001'
                                              ,'TABLE'
                                              ,gv_seqrt_view
                                              ,'KEY'
                                              ,gv_seqrt_view_key  ) ;
        RAISE get_value_expt ;
    END;
--
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
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
  END prc_initialize ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(G-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
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
    -- *** ���[�J���E�萔 ***
    cv_item_class          CONSTANT VARCHAR2(  5) := '''5''';        -- �i�ڋ敪�i���i�j
    cv_crlf                CONSTANT VARCHAR2( 10) := CHR(13) || CHR(10); -- ���s�R�[�h
    cv_type_uke            CONSTANT VARCHAR2(  5) := '''1''';        --����ԕi     ���p���t
    cv_type_hen            CONSTANT VARCHAR2(  5) := '''2''';        --�d���ԕi     ���p���t
    cv_type_nasi           CONSTANT VARCHAR2(  5) := '''3''';        --�d���Ȃ��ԕi ���p���t
    cv_approved            CONSTANT VARCHAR2( 10) := '''APPROVED'''; --���F�ς�     ���p���t
    cv_kakutei             CONSTANT VARCHAR2(  5) := '''35''';       --���z�m��     ���p���t
    cv_torikesi            CONSTANT VARCHAR2(  5) := '''99''';       --���         ���p���t
    cv_type_tax_rate       CONSTANT VARCHAR2(100) := '''XXCMN_CONSUMPTION_TAX_RATE''' ;
                                                                     --�����
    cv_type_kousen         CONSTANT VARCHAR2(100) := '''XXPO_KOUSEN_TYPE''' ;     --���K�敪
    cv_type_fukakin        CONSTANT VARCHAR2(100) := '''XXPO_FUKAKIN_TYPE''' ;    --���ۋ��敪
    cv_ja                  CONSTANT VARCHAR2(100) := '''JA''' ;                   --���{��
    cv_code_format         CONSTANT VARCHAR2(100) := '''9999''' ;        --�O���[�v�p�t�H�[�}�b�g
    cv_zero                CONSTANT VARCHAR2(100) := '''0''' ;           --�O���[�v�p�t�H�[�}�b�g
    cv_seq_gaibu           CONSTANT NUMBER        := '2' ;                 --�Z�L�����e�B �O���q��
    cv_sts_var_n           CONSTANT VARCHAR2(  1) := 'N' ;                 --'N' �������t���O�p
    cv_sts_var_y           CONSTANT VARCHAR2(  1) := 'Y' ;                 --'Y' ���z�m��t���O�p
--
    -- *** ���[�J���E�ϐ� ***
    lv_date_from  VARCHAR2(10) ;
    lv_date_to    VARCHAR2(10) ;
    lv_dept       VARCHAR2(100) ;
    lv_assen      VARCHAR2(100) ;
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_group_by   VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_in         VARCHAR2(32000) ;
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
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
--
    lv_date_from := TO_CHAR(gr_param_rec.deliver_from_date , gc_char_d_format);
    lv_date_to   := TO_CHAR(gr_param_rec.deliver_to_date   , gc_char_d_format);
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
    lv_dept := 'DECODE( xrart.txns_type ,' || cv_type_nasi
      ||            ' , xrart.department_code, ph.attribute10)';
--
    lv_assen := 'DECODE( xrart.txns_type , ' || cv_type_nasi
      ||             ' , xvv_assen.segment1 , xvv_med.segment1) ';
--
    IF (gr_param_rec.out_flg = gv_out_syukei) THEN
      --���̓p�����[�^��3.�W�v
      lv_select := 'SELECT '
        ||   ' NULL txns_id '
        || ' , ' || lv_dept || ' break_dtl '
        || ' , ' || lv_dept || ' break_mid '
        || ' , ' || lv_dept || ' dept_code '
        || ' , DECODE( xrart.txns_type , ' || cv_type_nasi || ' , xlv.location_name '
        ||                           ' , xlv_p.location_name) dept_name '
        || ' , xvv_part.segment1                 siire_no '
        || ' , xvv_part.vendor_short_name        siire_sht '
        || ' , ' || lv_assen || ' assen_no '
        || ' , LPAD(NVL(' || lv_assen || ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
        ||                                                                       ' assen_order '
        || ' , DECODE( xrart.txns_type , ' || cv_type_nasi || ' , xvv_assen.vendor_short_name '
        ||                           ' , xvv_med.vendor_short_name) assen_sht '
        || ' , NULL po_header_id '
        || ' , NULL txns_date '
        || ' , NULL txns_type '
        || ' , NULL po_no '
        || ' , NULL moto_line_no '
        || ' , NULL rcv_rtn_no '
        || ' , NULL item_no '
        || ' , NULL item_name '
        || ' , NULL item_sht '
        || ' , NULL futai_code '
        || ' , NULL kobiki_rate '
        || ' , AVG(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi
        ||                                  ' , xrart.kobki_converted_unit_price'
        ||                                  ' , ' || cv_type_hen
        ||                                  ' , xrart.kobki_converted_unit_price'
        ||                                  ' , pll.attribute2), 0)) kobikigo'
        || ' , SUM(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi ||' ,xrart.kousen_price * -1'
        ||                                  ' , ' || cv_type_hen  ||' ,xrart.kousen_price * -1'
        ||                                  ' , pll.attribute5) , 0)) kousen_price '
        || ' , SUM(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi ||' ,xrart.fukakin_price * -1'
        ||                                  ' , ' || cv_type_hen  ||' ,xrart.fukakin_price * -1'
        ||                                  ' , pll.attribute8) , 0)) fukakin_price '
        || ' , NULL lot_no '
        || ' , SUM(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi ||' ,xrart.quantity * -1'
        ||                                  ' , ' || cv_type_hen  ||' ,xrart.quantity * -1'
        ||                                  ' , xrart.quantity) , 0)) quantity '
        || ' , NULL unit_price '
        || ' , NULL kousen_type '
        || ' , NULL kousen_name '
        || ' , NULL kousen '
        || ' , xrart.rcv_rtn_uom rcv_rtn_uom '
        || ' , NULL fukakin_type '
        || ' , NULL fukakin_name '
        || ' , NULL fukakin '
        || ' , MAX(NVL(DECODE(xrart.txns_type,' || cv_type_nasi || ',NVL(flv_u_tax.lookup_code,0) '
        ||                               ' , flv_p_tax.lookup_code) , 0))  zeiritu '
        || ' , NULL  order1 '
        ;
    ELSE
      lv_select := 'SELECT '
        ||   ' xrart.txns_id txns_id '
        ||  ', LPAD(NVL( '|| lv_dept ||  ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
        || '|| LPAD(NVL(xvv_part.segment1 , '|| cv_code_format||'), 4, '|| cv_zero ||')'
        || '|| LPAD(NVL( ' || lv_assen || ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
        ||                                                        ' break_dtl ' --���u���C�N�L�[
        ;
      IF (gr_param_rec.out_flg = gv_out_assen) THEN
        lv_select := lv_select
          || ',  LPAD(NVL( '|| lv_dept ||  ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
          || '|| LPAD(NVL( ' || lv_assen || ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
          ||                                                      ' break_mid ' --���u���C�N�L�[
          ;
      ELSE
        lv_select := lv_select
          || ',  LPAD(NVL('|| lv_dept ||  ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
          || '|| LPAD(NVL(xvv_part.segment1 , '|| cv_code_format||'), 4, '|| cv_zero ||')'
          ||                                                      ' break_mid ' --���u���C�N�L�[
          ;
      END IF;
--
      --���o��
      lv_select := lv_select
        || ', ' || lv_dept ||                ' dept_code'                       --��L�[�����R�[�h
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||', xlv.location_name'
        ||       ' , xlv_p.location_name)        dept_name '                    --������
        || ',xvv_part.segment1                 siire_no'                        --�����d����ԍ�
        || ',xvv_part.vendor_short_name        siire_sht'                       --����
        || ' , ' || lv_assen || ' assen_no '                                    --�����Ҏd����ԍ�
        || ' , LPAD(NVL(' || lv_assen || ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
        ||                                                     ' assen_order '  --�����ҏ���
        || ' , DECODE( xrart.txns_type , ' || cv_type_nasi || ' , xvv_assen.vendor_short_name '
        ||                           ' , xvv_med.vendor_short_name) assen_sht '
        ;
      --����
      lv_select := lv_select
        || ',ph.po_header_id po_header_id '                  --����ID
        || ',TO_CHAR( xrart.txns_date ,''' || gc_char_md_format || ''') txns_date' --�����
        || ',xrart.txns_type                   txns_type'    --����^�C�v
        || ',CASE '
        || ' WHEN xrart.txns_type = '|| cv_type_uke ||' THEN '
        ||   ' xrart.source_document_number '                -- ����̏ꍇ,���������הԍ�
        || ' WHEN xrart.txns_type IN('|| cv_type_hen || ',' || cv_type_nasi|| ') THEN '
        ||   ' xrart.rcv_rtn_number '                        --�d����ԕi�̏ꍇ,����ԕi�ԍ�
        || ' END  po_no '                                    --�����ԍ�
        || ',xrart.source_document_line_num   moto_line_no ' --���������הԍ�
        || ',xrart.rcv_rtn_number             rcv_rtn_no '   --����ԕi�ԍ�
        || ',ximv.item_no                     item_no '
        || ',ximv.item_name                   item_name '
        || ',ximv.item_short_name             item_sht '
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||',xrart.futai_code '
        ||       ' , pl.attribute3)           futai_code '   --�t��
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||', xrart.kobiki_rate '
        ||                          ','|| cv_type_hen  ||', xrart.kobiki_rate '
        ||       ' , pll.attribute1)          kobiki_rate '  --������
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||', xrart.kobki_converted_unit_price '
        ||                          ','|| cv_type_hen  ||', xrart.kobki_converted_unit_price '
        ||       ' , pll.attribute2)          kobikigo '     --������P��
        || ',DECODE( xrart.txns_type ,' || cv_type_nasi  || ', xrart.kousen_price * -1 '
        ||                          ',' || cv_type_hen   || ', xrart.kousen_price * -1 '
        ||       ' , pll.attribute5)          kousen_price ' --�a����K���z
        || ',DECODE( xrart.txns_type ,' || cv_type_nasi  || ', xrart.fukakin_price * -1 '
        ||                          ',' || cv_type_hen   || ', xrart.fukakin_price * -1 '
        ||       ', pll.attribute8)           fukakin_price ' --���ۋ��z
        || ',DECODE(ximv.lot_ctl,'   || gv_lot_n_div || ',NULL,ilm.lot_no) AS lot_no '-- ���b�gNO
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.quantity * -1 '
        || ',DECODE(xrart.txns_type,'  || cv_type_hen  || ', xrart.quantity * -1 '
        || ', xrart.quantity))  quantity '  --����ԕi����
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.unit_price '
        ||                          ','|| cv_type_hen  || ', xrart.unit_price '
        ||       ' , pl.attribute8)           unit_price '   --�P��'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', flv_u_kosen.lookup_code '
        ||                          ','|| cv_type_hen  || ', flv_u_kosen.lookup_code '
        ||       ' , flv_p_kosen.lookup_code) kousen_name '  --���K�敪
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', flv_u_kosen.meaning '
        ||                          ','|| cv_type_hen  || ', flv_u_kosen.meaning '
        ||       ' , flv_p_kosen.meaning)     kousen_name '  --���K�敪��
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.kousen_rate_or_unit_price '
        ||                          ','|| cv_type_hen  || ', xrart.kousen_rate_or_unit_price '
        ||       ' , pll.attribute4)          kousen '       --���K'
        || ',xrart.rcv_rtn_uom                 rcv_rtn_uom ' --����ԕi�P��'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', flv_u_fuka.lookup_code '
        ||                          ','|| cv_type_hen  || ', flv_u_fuka.lookup_code '
        ||       ' , flv_p_fuka.lookup_code)  fukakin_name ' --���ۋ��敪'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', flv_u_fuka.meaning '
        ||                          ','|| cv_type_hen  || ', flv_u_fuka.meaning '
        ||       ' , flv_p_fuka.meaning)      fukakin_name ' --���ۋ��敪��'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.fukakin_rate_or_unit_price '
        ||                          ','|| cv_type_hen  || ', xrart.fukakin_rate_or_unit_price '
        ||       ' , pll.attribute7)          fukakin '      --���ۋ�'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||', NVL(flv_u_tax.lookup_code, 0) '
        ||       ' , NVL(flv_p_tax.lookup_code, 0))   zeiritu '      --�ŗ�'
        || ',DECODE( xic6.item_class_code '
        ||       ' , '|| cv_item_class || ', ilm.attribute1||ilm.attribute2 '
        ||       ' ,ilm.lot_no )              order1 '       --�\����'
        ;
    END IF;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_from := ' FROM '
      || '    xxpo_rcv_and_rtn_txns xrart '                       --����ԕi�A�h�I��
      || 'LEFT JOIN ic_lots_mst ilm '                            --opm���b�g�}�X�^
      ||  ' ON (  ilm.lot_id = xrart.lot_id '
      ||    ' AND ilm.item_id = xrart.item_id ) '
      || 'INNER JOIN xxcmn_item_mst2_v ximv '                     --opm�i�ڏ��view
      ||  ' ON (  ximv.item_id = xrart.item_id '
      ||    ' AND ximv.start_date_active <= xrart.txns_date '
      ||    ' AND ximv.end_date_active   >= xrart.txns_date ) '
      || 'INNER JOIN xxcmn_item_categories2_v gic '               --�i�ڃJ�e�S������
      ||  ' ON (  gic.item_id  = ximv.item_id ) '
      || 'INNER JOIN xxcmn_item_categories6_v xic6 '              --�i�ڃJ�e�S������6
      ||  ' ON (  xic6.item_id   = gic.item_id ) '
      || 'INNER JOIN (SELECT mcb.segment1  AS category_code '
      || ',  mcb.category_id AS category_id '
      || ',  mcst.category_set_id AS category_set_id '
      || ',  mcst.category_set_name '
      || '  FROM   mtl_category_sets_tl  mcst, '
      || '   mtl_category_sets_b   mcsb, '
      || '   mtl_categories_b      mcb '
      || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
      || '  AND   mcst.language         = ''' || gc_language_code || ''''
      || '  AND   mcsb.structure_id     = mcb.structure_id '
      || '  AND   mcst.category_set_name = ''' || gc_cat_set_item_class || '''' || ') xgcv'
      ||  ' ON (  xgcv.category_set_id   = gic.category_set_id '
      ||    ' AND xgcv.category_id       = gic.category_id ) '
      || 'INNER JOIN xxcmn_locations2_v xlv '                     --���Ə����view
      ||  ' ON (  xlv.location_code = xrart.department_code '
      ||    ' AND xlv.start_date_active <= xrart.txns_date '
      ||    ' AND xlv.end_date_active   >= xrart.txns_date ) '
      || 'INNER JOIN xxcmn_vendors2_v xvv_part '                  --�d������(�����)
      ||  ' ON (  xvv_part.vendor_id = xrart.vendor_id '
      ||    ' AND xvv_part.start_date_active <= xrart.txns_date '
      ||    ' AND xvv_part.end_date_active   >= xrart.txns_date ) '
      || 'LEFT JOIN xxcmn_vendors2_v xvv_assen '                  --�d������(������)
      ||  ' ON (  xvv_assen.vendor_id = xrart.assen_vendor_id '
      ||    ' AND xvv_assen.start_date_active <= xrart.txns_date '
      ||    ' AND xvv_assen.end_date_active   >= xrart.txns_date ) '
      || 'INNER JOIN fnd_lookup_values flv_u_tax '                --�N�C�b�N�R�[�h(�����)
      ||  ' ON (  flv_u_tax.lookup_type = ' || cv_type_tax_rate
      ||    ' AND flv_u_tax.language = ' || cv_ja
      ||    ' AND flv_u_tax.start_date_active <= xrart.txns_date '
      ||    ' AND NVL(flv_u_tax.end_date_active, xrart.txns_date)  >= xrart.txns_date ) '
      || 'LEFT JOIN fnd_lookup_values flv_u_kosen '              --�N�C�b�N�R�[�h(���K�敪)
      ||  ' ON (  flv_u_kosen.lookup_type = '||cv_type_kousen
      ||    ' AND flv_u_kosen.language = ' || cv_ja
      ||    ' AND flv_u_kosen.lookup_code = xrart.kousen_type  '
      ||    ' AND flv_u_kosen.start_date_active <= xrart.txns_date '
      ||    ' AND NVL(flv_u_kosen.end_date_active, xrart.txns_date)  >= xrart.txns_date ) '
      || 'LEFT JOIN fnd_lookup_values flv_u_fuka '               --�N�C�b�N�R�[�h(���ۋ��敪)
      ||  ' ON (  flv_u_fuka.lookup_type = '|| cv_type_fukakin
      ||    ' AND flv_u_fuka.language = ' || cv_ja
      ||    ' AND flv_u_fuka.lookup_code = xrart.fukakin_type  '
      ||    ' AND flv_u_fuka.start_date_active <= xrart.txns_date '
      ||    ' AND NVL(flv_u_fuka.end_date_active, xrart.txns_date)  >= xrart.txns_date ) '
      || 'LEFT JOIN (          po_headers_all ph '               --�����w�b�_
      || '          INNER JOIN xxpo_headers_all xpha '           --�����w�b�_(�A�h�I��)
      ||            ' ON (  xpha.po_header_number = ph.segment1 ) '
      || '          INNER JOIN po_lines_all pl '                 --��������
      ||            ' ON (  pl.po_header_id = ph.po_header_id ) '
      || '          INNER JOIN xxcmn_locations2_v xlv_p '        --���Ə����view
      ||            ' ON (  xlv_p.location_code = ph.attribute10 '
      ||              ' AND TO_CHAR(xlv_p.start_date_active,'''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND TO_CHAR(xlv_p.end_date_active,  '''||gc_char_d_format||''')'
      ||                  ' >= ph.attribute4 )'
      || '          INNER JOIN po_line_locations_all pll '       --�[������
      ||            ' ON (  pll.po_line_id = pl.po_line_id ) '
      || '          LEFT JOIN xxcmn_vendors2_v xvv_med '        --�d������(������)
      ||            ' ON (  xvv_med.vendor_id = ph.attribute3 '
      ||              ' AND TO_CHAR(xvv_med.start_date_active,'''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND TO_CHAR(xvv_med.end_date_active,  '''||gc_char_d_format||''')'
      ||                  ' >= ph.attribute4 ) '
      || '          INNER JOIN fnd_lookup_values flv_p_tax '     --�N�C�b�N�R�[�h(�����)
      ||            ' ON (  flv_p_tax.lookup_type = ' || cv_type_tax_rate
      ||              ' AND flv_p_tax.language = '|| cv_ja
      ||              ' AND TO_CHAR(flv_p_tax.start_date_active,'''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND NVL(TO_CHAR(flv_p_tax.end_date_active, '''||gc_char_d_format||'''),'
      ||                  ' ph.attribute4) >= ph.attribute4 )'
      || '          LEFT JOIN fnd_lookup_values flv_p_kosen '   --�N�C�b�N�R�[�h(���K�敪)
      ||            ' ON (  flv_p_kosen.lookup_type = '|| cv_type_kousen
      ||              ' AND flv_p_kosen.language = '|| cv_ja
      ||              ' AND flv_p_kosen.lookup_code = pll.attribute3 '
      ||              ' AND TO_CHAR(flv_p_kosen.start_date_active, '''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND NVL(TO_CHAR(flv_p_kosen.end_date_active, '''||gc_char_d_format||'''), '
      ||                  ' ph.attribute4) >= ph.attribute4 )'
      || '          LEFT JOIN fnd_lookup_values flv_p_fuka '    --�N�C�b�N�R�[�h(���ۋ��敪)
      ||            ' ON (  flv_p_fuka.lookup_type = '||cv_type_fukakin
      ||              ' AND flv_p_fuka.language = '|| cv_ja
      ||              ' AND flv_p_fuka.lookup_code = pll.attribute6 '
      ||              ' AND TO_CHAR(flv_p_tax.start_date_active,'''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND NVL(TO_CHAR(flv_p_tax.end_date_active, '''||gc_char_d_format||'''), '
      ||                  ' ph.attribute4) >= ph.attribute4 )'
      || '          ) ' ----left join�̊���I��
      || '  ON (  xrart.source_document_number = ph.segment1 '
      ||    ' AND xrart.source_document_line_num = pl.line_num )'
      ;
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_where := ' WHERE '
     || '     xrart.txns_date > FND_DATE.STRING_TO_DATE('''|| lv_date_from ||''''
     ||                          ', '''||gc_char_d_format||''')'
     || ' AND xrart.txns_date < FND_DATE.STRING_TO_DATE('''|| lv_date_to ||''''
     ||                                        ', '''||gc_char_d_format||''')'
     || ' AND ('
     ||        ' (    xrart.txns_type IN('|| cv_type_hen ||',' || cv_type_nasi|| ')'
     ||        '  AND xrart.quantity > 0 '
     ||        ' )'
     ||        ' OR '
     ||        ' (xrart.txns_type NOT IN('|| cv_type_hen ||',' || cv_type_nasi|| '))'
     ||     ' ) '
     ;
--
      lv_where := lv_where
        || ' AND DECODE(ph.po_header_id, NULL, ''' || gn_sales_class || ''',ph.org_id)'
        ||     ' = '''|| gn_sales_class || ''''
        || ' AND DECODE(ph.po_header_id, NULL, ' || cv_approved || ' , ph.authorization_status) '
        ||     ' = ' || cv_approved
        || ' AND DECODE(ph.po_header_id, NULL, ' || cv_kakutei || ', ph.attribute1)'
        ||     ' >= ' || cv_kakutei
        || ' AND DECODE(ph.po_header_id, NULL, '|| cv_kakutei ||', ph.attribute1)'
        ||     ' <  ' || cv_torikesi
        || ' AND DECODE(ph.po_header_id, NULL, '''|| cv_sts_var_n ||''', pl.cancel_flag)'
        ||     ' =  ''' || cv_sts_var_n || ''''      -- ����t���O
        || ' AND DECODE(ph.po_header_id, NULL, '''|| cv_sts_var_y ||''', pl.attribute14)'
        ||     ' =  ''' || cv_sts_var_y || ''''      -- ���z�m��t���O
        ;
--
    --�S������
    IF (gr_param_rec.dept_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_where := lv_where
        || '     AND ' || lv_dept || ' = ''' || gr_param_rec.dept_code(gn_one) || '''';
    ELSIF (gr_param_rec.dept_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(gr_param_rec.dept_code);
      lv_where := lv_where
        || '     AND ' || lv_dept || ' IN(' || lv_in || ')';
    END IF;
--
    --�����
    IF (gr_param_rec.vendor_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_where := lv_where
        || '     AND xvv_part.segment1 = ''' || gr_param_rec.vendor_code(gn_one) || '''';
    ELSIF (gr_param_rec.vendor_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(gr_param_rec.vendor_code);
      lv_where := lv_where
        || '     AND xvv_part.segment1 IN(' || lv_in || ') ';
    END IF;
--
    --������
    IF (gr_param_rec.mediator_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_where := lv_where
        || '     AND ' || lv_assen || ' = ''' || gr_param_rec.mediator_code(gn_one) || '''';
    ELSIF (gr_param_rec.mediator_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(gr_param_rec.mediator_code);
      lv_where := lv_where
        || '     AND ' || lv_assen || ' IN(' || lv_in || ') ';
    END IF;
--
    --�����ԍ�
    IF(gr_param_rec.po_num IS NOT NULL) THEN
      lv_where := lv_where
        || ' AND ph.segment1 = '''|| gr_param_rec.po_num ||''''
        ;
    END IF;
--
    --�i��
    IF(gr_param_rec.item_code IS NOT NULL) THEN
      lv_where := lv_where
        || ' AND ximv.item_no = '''|| gr_param_rec.item_code ||''''
        ;
    END IF;
--
    --�Z�L�����e�B
    IF (gr_param_rec.security_flg = cv_seq_gaibu) THEN
      lv_where := lv_where
        || ' AND (((DECODE( xrart.txns_type  , '|| cv_type_nasi ||', xrart.assen_vendor_id '
        || '   , ph.attribute3) = '''|| gr_header_rec.user_vender_id ||'''';--1.
--
      IF (gr_header_rec.user_vender_id IS NULL) THEN
        -- �d����ID�Ȃ�
        lv_where := lv_where
          || '      OR (( '
          || '            DECODE( xrart.txns_type  , '|| cv_type_nasi ||', xrart.vendor_id '
          || '              , ph.vendor_id) IS NULL)))';
      ELSE
        -- �d����ID����
        lv_where := lv_where
          || '      OR (( '
          || '            DECODE( xrart.txns_type  , '|| cv_type_nasi ||', xrart.vendor_id '
          || '              , ph.vendor_id) = ' || gr_header_rec.user_vender_id || ')))';
      END IF;                                                                  --2.
--
      IF (gr_header_rec.user_vender_site IS NOT NULL) THEN
        lv_where := lv_where
          ||      '  AND ((xrart.txns_type IN( '|| cv_type_uke ||','|| cv_type_hen ||'))'
          ||      '    AND  NOT EXISTS(SELECT po_line_id '
          ||                         ' FROM   po_lines_all pl_sub '
          ||                         ' WHERE  pl_sub.po_header_id = ph.po_header_id '
          ||                         ' AND  NVL(pl_sub.attribute2,''*'') '
          ||                            ' <> '''|| gr_header_rec.user_vender_site ||''''
          ||                        ' )) '
          ||      '  OR ((xrart.txns_type = '|| cv_type_nasi ||')'
          ||      '    AND  NOT EXISTS(SELECT xrart_sub.factory_code '
          ||                         ' FROM   xxpo_rcv_and_rtn_txns xrart_sub '
          ||                         ' WHERE  xrart_sub.rcv_rtn_number = xrart.rcv_rtn_number '
          ||                         ' AND  NVL(xrart_sub.factory_code,''*'') '
          ||                            ' <> '''|| gr_header_rec.user_vender_site ||''''
          ||                        ' )) '
          ;
      END IF;
      lv_where := lv_where
        ||        ' )'                                                         --2.�̕�
        ||     ' )'                                                            --1.�̕�
        ;
    END IF;
--
    -- ----------------------------------------------------
    -- �f�q�n�t�o  �a�x�吶��
    -- ----------------------------------------------------
    IF (gr_param_rec.out_flg = gv_out_syukei) THEN
      lv_group_by := ' GROUP BY '
        ||   ' DECODE( xrart.txns_type ,' || cv_type_nasi
        ||                            ', xrart.department_code , ph.attribute10) '
        || ', DECODE( xrart.txns_type , ' || cv_type_nasi
        ||                           ' , xlv.location_name  , xlv_p.location_name)'
        || ' , DECODE( xrart.txns_type ,' || cv_type_nasi
        ||                            ', xlv.description       , xlv_p.description) '
        || ' , xvv_part.segment1 '
        || ' , xvv_part.vendor_short_name '
        || ' , DECODE( xrart.txns_type ,' || cv_type_nasi || ','
        || '     xvv_assen.segment1,xvv_med.segment1) '
        || ' , DECODE( xrart.txns_type ,' || cv_type_nasi || ',xvv_assen.vendor_short_name,'
        || '     xvv_med.vendor_short_name) '
        || ' , xrart.rcv_rtn_uom '
        ;
    END IF;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY dept_code';
    IF (gr_param_rec.out_flg = gv_out_syukei) THEN
      lv_order_by := lv_order_by || ' , siire_no '   --�����R�[�h
                                 || ' , assen_order '     --�����҃R�[�h(Null��擪�ɂ���j
      ;
    ELSE
      IF (gr_param_rec.out_flg = gv_out_assen) THEN
        lv_order_by := lv_order_by || ' , assen_order '  --�����҃R�[�h
                                   || ' , xvv_part.segment1' --�����R�[�h
        ;
      ELSE
        lv_order_by := lv_order_by || ' , xvv_part.segment1' --�����R�[�h
                                   || ' , assen_order '  --�����҃R�[�h
        ;
      END IF;
      lv_order_by := lv_order_by || ' , txns_date'           -- �[����
                                 || ' , po_no'               -- �����ԍ�
                                 || ' , item_no'             -- �i�ڃR�[�h
                                 || ' , futai_code'          -- �t�уR�[�h
                                 || ' , order1'              -- �\�������P
      ;
    END IF;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_group_by || lv_order_by ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
--
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql ;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(G-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init            CONSTANT VARCHAR2(100) := '*' ;  -- ����於
    lc_break_null            CONSTANT VARCHAR2(100) := '**' ;  -- �i�ڋ敪
--
    lc_sum_assensya          CONSTANT VARCHAR2(100) :='�y�����Ҍv�z';
    lc_sum_torihikisaki      CONSTANT VARCHAR2(100) :='�y�����v�z';
    lc_report_name           CONSTANT VARCHAR2(100) :='�d��������ו\';
    lc_caption_assen         CONSTANT VARCHAR2(100) := '�����ҕ�' ;
    lc_caption_torihiki      CONSTANT VARCHAR2(100) := '������' ;
    lc_caption_sum           CONSTANT VARCHAR2(100) := '�W�v' ;
--
    lc_out_assen             CONSTANT VARCHAR2(1)  :='1';
    lc_out_torihiki          CONSTANT VARCHAR2(1)  :='2';
    lc_out_syukei            CONSTANT VARCHAR2(1)  :='3';
    lc_flg_y                 CONSTANT VARCHAR2(1)  := 'Y';
    lc_flg_n                 CONSTANT VARCHAR2(1)  := 'N';
--
    lc_depth_g_lot           CONSTANT NUMBER :=  1;  -- ���b�g
    lc_depth_g_hutai         CONSTANT NUMBER :=  3;  -- �t��
    lc_depth_g_item          CONSTANT NUMBER :=  5;  -- �i��
    lc_depth_g_deliver_date  CONSTANT NUMBER :=  7;  -- �[����
    lc_depth_g_detail        CONSTANT NUMBER :=  9;  -- �����ҁE�����
    lc_depth_g_middle        CONSTANT NUMBER := 11;  -- �����҂������
    lc_depth_g_dept          CONSTANT NUMBER := 13;  -- ����
    lc_zero                  CONSTANT NUMBER := 0;
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lb_isfirst              BOOLEAN       DEFAULT TRUE ;
    ln_group_depth          NUMBER;        -- ���s�[�x(�J�n�^�O�o�͗p
    lr_now_key              rec_keybreak;
    lr_pre_key              rec_keybreak;
--
    -- ���z�v�Z�p
    ln_siire                NUMBER DEFAULT 0;         -- �d�����z
    ln_sasihiki             NUMBER DEFAULT 0;         -- �������z
    ln_tax_siire            NUMBER DEFAULT 0;         -- �����(�d�����z)
    ln_tax_kousen           NUMBER DEFAULT 0;         -- �����(���K���z)
    ln_tax_sasihiki         NUMBER DEFAULT 0;         -- �����(�������z)
    ln_jun_siire            NUMBER DEFAULT 0;         -- ���d�����z
    ln_jun_kosen            NUMBER DEFAULT 0;         -- �����K���z
    ln_jun_sasihiki         NUMBER DEFAULT 0;         -- ���������z
    -- �������v�p
    ln_sum_post_qty              NUMBER DEFAULT 0;         -- ���ɑ���
    ln_sum_post_siire            NUMBER DEFAULT 0;         -- �d�����z
    ln_sum_post_kosen            NUMBER DEFAULT 0;         -- ���K���z
    ln_sum_post_huka             NUMBER DEFAULT 0;         -- ���ۋ��z
    ln_sum_post_sasihiki         NUMBER DEFAULT 0;         -- �������z
    ln_sum_post_tax_siire        NUMBER DEFAULT 0;         -- �����(�d�����z)
    ln_sum_post_tax_kousen       NUMBER DEFAULT 0;         -- �����(���K���z)
    ln_sum_post_tax_sasihiki     NUMBER DEFAULT 0;         -- �����(�������z)
    ln_sum_post_jun_siire        NUMBER DEFAULT 0;         -- ���d�����z
    ln_sum_post_jun_kosen        NUMBER DEFAULT 0;         -- �����K���z
    ln_sum_post_jun_sasihiki     NUMBER DEFAULT 0;         -- ���������z
    --�����v�p
    ln_sum_qty              NUMBER DEFAULT 0;         -- ���ɑ���
    ln_sum_siire            NUMBER DEFAULT 0;         -- �d�����z
    ln_sum_kosen            NUMBER DEFAULT 0;         -- ���K���z
    ln_sum_huka             NUMBER DEFAULT 0;         -- ���ۋ��z
    ln_sum_sasihiki         NUMBER DEFAULT 0;         -- �������z
    ln_sum_tax_siire        NUMBER DEFAULT 0;         -- �����(�d�����z)
    ln_sum_tax_kousen       NUMBER DEFAULT 0;         -- �����(���K���z)
    ln_sum_tax_sasihiki     NUMBER DEFAULT 0;         -- �����(�������z)
    ln_sum_jun_siire        NUMBER DEFAULT 0;         -- ���d�����z
    ln_sum_jun_kosen        NUMBER DEFAULT 0;         -- �����K���z
    ln_sum_jun_sasihiki     NUMBER DEFAULT 0;         -- ���������z
--
    lb_ret                  BOOLEAN;
    ln_loop_index           NUMBER DEFAULT 0;
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;           -- �擾���R�[�h�Ȃ�
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �w�b�_�[�f�[�^���o�E�o�͏���
    -- =====================================================
    -- �w�b�_�[�J�n�^�O
    lb_ret := fnc_set_xml('T', 'user_info');
--
    -- ���[�h�c
    lb_ret := fnc_set_xml('D', 'report_id', gv_report_id);
--
    -- �S���ҕ���
    lb_ret := fnc_set_xml('D', 'exec_user_dept', gr_header_rec.user_dept, 10);
--
    -- �S���Җ�
    lb_ret := fnc_set_xml('D', 'exec_user_name', gr_header_rec.user_name, 14);
--
    -- �o�͓�
    lb_ret := fnc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
--
    -- ���ofrom
    lb_ret := fnc_set_xml('D', 'deliver_from', gr_header_rec.deliver_from_date);
--
    -- ���oto
    lb_ret := fnc_set_xml('D', 'deliver_to', gr_header_rec.deliver_to_date);
--
    -- �o�͋敪
    lb_ret := fnc_set_xml('D', 'out_flg', gr_param_rec.out_flg);
--
    -- ���v�̖���
    IF    (gr_param_rec.out_flg = lc_out_torihiki) THEN
      lb_ret := fnc_set_xml('D', 'detail_sum_name', lc_sum_assensya);
      lb_ret := fnc_set_xml('D', 'middle_sum_name', lc_sum_torihikisaki);
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_torihiki);
    ELSIF (gr_param_rec.out_flg = lc_out_assen) THEN
      lb_ret := fnc_set_xml('D', 'detail_sum_name', lc_sum_torihikisaki);
      lb_ret := fnc_set_xml('D', 'middle_sum_name', lc_sum_assensya);
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_assen);
    ELSE
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_sum);
    END IF;
--
    -- �w�b�_�[�I���^�O
    lb_ret := fnc_set_xml('T','/user_info');
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    --=====================================================
    prc_get_report_data(
        ot_data_rec   => gt_main_data   --    �擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- �f�[�^���J�n�^�O
    lb_ret := fnc_set_xml('T', 'data_info');
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR ln_loop_index IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- �L�[�u���C�N
      -- =====================================================
      --�L�[���ꔻ�f�p�ϐ�������
      ln_group_depth     := 0;
      lr_now_key.dept    := gt_main_data(ln_loop_index).dept_code;
      lr_now_key.middle  := gt_main_data(ln_loop_index).break_mid;
      lr_now_key.detail  := gt_main_data(ln_loop_index).break_dtl;
      lr_now_key.deliver := lr_now_key.detail||'-'||gt_main_data(ln_loop_index).txns_date;
      lr_now_key.item    := lr_now_key.deliver||'-'||gt_main_data(ln_loop_index).item_no;
      lr_now_key.hutai   := lr_now_key.item||'-'||gt_main_data(ln_loop_index).futai_code;
      lr_now_key.lot     := lr_now_key.hutai||'-'||gt_main_data(ln_loop_index).lot_no;
--
      -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
      IF ( lb_isfirst ) THEN
        ln_group_depth := lc_depth_g_dept; --�J�n�^�O�\���p
        lb_isfirst := FALSE;
      ELSE
        --�L�[���ꔻ�f�@�ׂ������ɔ��f
        -- ���b�g
        IF ( NVL(lr_now_key.lot, lc_break_null ) <> lr_pre_key.lot ) THEN
          lb_ret := fnc_set_xml('T', '/g_lot');
          ln_group_depth := lc_depth_g_lot;
--
          -- �t��
          IF ( NVL(lr_now_key.hutai, lc_break_null ) <> lr_pre_key.hutai ) THEN
            lb_ret := fnc_set_xml('T', '/lg_lot');
            lb_ret := fnc_set_xml('T', '/g_hutai');
            ln_group_depth := lc_depth_g_hutai;
--
            -- �i��
            IF ( NVL(lr_now_key.item, lc_break_null ) <> lr_pre_key.item ) THEN
              lb_ret := fnc_set_xml('T', '/lg_hutai');
              lb_ret := fnc_set_xml('T', '/g_item');
              ln_group_depth := lc_depth_g_item;
--
              -- �[����
              IF ( NVL(lr_now_key.deliver, lc_break_null ) <> lr_pre_key.deliver ) THEN
                lb_ret := fnc_set_xml('T', '/lg_item');
                lb_ret := fnc_set_xml('T', '/g_deliver_date');
                ln_group_depth := lc_depth_g_deliver_date;
--
                -- �ڍ׍��v(�����ҁ������
                IF ( NVL(lr_now_key.detail, lc_break_null ) <> lr_pre_key.detail ) THEN
                  lb_ret := fnc_set_xml('T', '/lg_deliver_date');
                  lb_ret := fnc_set_xml('T', '/g_detail');
                  ln_group_depth := lc_depth_g_detail;
--
                  -- �����v(������ or �����
                  IF ( NVL(lr_now_key.middle, lc_break_null ) <> lr_pre_key.middle ) THEN
                    lb_ret := fnc_set_xml('T', '/lg_detail');
                    IF (NVL(lr_now_key.dept, lc_break_null ) <> lr_pre_key.dept ) THEN
                      -- �W�v�ʂ̏ꍇ�͏o�͂��Ȃ�
                      IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
                        -- �������v�o�͂���ꍇ
                        lb_ret := fnc_set_xml('Z', 'whse_subtotal', ln_sum_post_qty);
                                                                                        --���ɑ���
                        lb_ret := fnc_set_xml('Z', 'purchs_amnt_subtotal', ln_sum_post_siire);
                                                                                        --�d�����z
                        lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_subtotal',
                                                              ln_sum_post_kosen);       --���K���z
                        lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate1_subtotal',
                                                              ln_sum_post_huka);        --���ۋ��z
                        lb_ret := fnc_set_xml('Z', 'deduction_amnt_subtotal',
                                                              ln_sum_post_sasihiki);
                                                                                        --�������z
                        lb_ret := fnc_set_xml('Z', 'purchs_amnt_tax_subtotal',
                                                              ln_sum_post_tax_siire);   --�Ŏd��
                        lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_tax_subtotal',
                                                              ln_sum_post_tax_kousen);  --�Ō��K
                        lb_ret := fnc_set_xml('Z', 'deduction_amnt_tax_subtotal',
                                                              ln_sum_post_tax_sasihiki);--�ō���
                        lb_ret := fnc_set_xml('Z', 'pure_purchs_amnt_subtotal',
                                                               ln_sum_post_jun_siire);  --���d��
                        lb_ret := fnc_set_xml('Z', 'pure_commi_unt_price_rate_subtotal',
                                                              ln_sum_post_jun_kosen);   --�����K
                        lb_ret := fnc_set_xml('Z', 'pure_deduction_amnt_subtotal',
                                                              ln_sum_post_jun_sasihiki);--������
                        lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate3_subtotal',
                                                              ln_sum_post_huka);        --���ۋ��z
                        lb_ret := fnc_set_xml('D', 'flg' , lc_flg_y);     -- �o�̓t���O
                        -- �������v�p�ϐ�������
                        ln_sum_post_qty           := lc_zero;
                        ln_sum_post_siire         := lc_zero;
                        ln_sum_post_kosen         := lc_zero;
                        ln_sum_post_huka          := lc_zero;
                        ln_sum_post_sasihiki      := lc_zero;
                        ln_sum_post_tax_siire     := lc_zero;
                        ln_sum_post_tax_kousen    := lc_zero;
                        ln_sum_post_tax_sasihiki  := lc_zero;
                        ln_sum_post_jun_siire     := lc_zero;
                        ln_sum_post_jun_kosen     := lc_zero;
                        ln_sum_post_jun_sasihiki  := lc_zero;
                        ln_sum_post_huka          := lc_zero;
                      END IF;
                    ELSE
                      lb_ret := fnc_set_xml('D', 'flg' , lc_flg_n);     -- �o�̓t���O
                    END IF;
                    lb_ret := fnc_set_xml('D', 'total_flg' , lc_flg_n); -- ���v�o�̓t���O
                    lb_ret := fnc_set_xml('T', '/g_middle');
                    ln_group_depth := lc_depth_g_middle;
--
                    -- ����
                    IF ( NVL(lr_now_key.dept, lc_break_null ) <> lr_pre_key.dept ) THEN
                      lb_ret := fnc_set_xml('T', '/lg_middle');
                      lb_ret := fnc_set_xml('T', '/g_dept');
                      ln_group_depth := lc_depth_g_dept;
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
--
        --------------------------------------
        -- �J�n�^�O
        --------------------------------------
      IF (ln_group_depth >= lc_depth_g_dept) THEN
        -- ����
        lb_ret := fnc_set_xml('T', 'g_dept');
        lb_ret := fnc_set_xml('D', 'dept_code', gt_main_data(ln_loop_index).dept_code);
        lb_ret := fnc_set_xml('D', 'dept_name', gt_main_data(ln_loop_index).dept_name, 20);
        lb_ret := fnc_set_xml('T', 'lg_middle');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_middle) THEN
        -- �����v(������ or �����
        lb_ret := fnc_set_xml('T', 'g_middle');
        lb_ret := fnc_set_xml('D', 'mid_code', gt_main_data(ln_loop_index).break_mid);
        IF (gr_param_rec.out_flg = '1') THEN
          lb_ret := fnc_set_xml('D', 'middle_code', gt_main_data(ln_loop_index).assen_no);
          lb_ret := fnc_set_xml('D', 'middle_name', gt_main_data(ln_loop_index).assen_sht, 20);
        ELSIF (gr_param_rec.out_flg = '2') THEN
          lb_ret := fnc_set_xml('D', 'middle_code', gt_main_data(ln_loop_index).siire_no);
          lb_ret := fnc_set_xml('D', 'middle_name', gt_main_data(ln_loop_index).siire_sht, 20);
        END IF;
        lb_ret := fnc_set_xml('T', 'lg_detail');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_detail) THEN
        -- �ڍ׍��v(�����ҁ������
        lb_ret := fnc_set_xml('T', 'g_detail');
        lb_ret := fnc_set_xml('D', 'dtl_code', gt_main_data(ln_loop_index).break_dtl);
        IF (gr_param_rec.out_flg = '1') THEN
          lb_ret := fnc_set_xml('D', 'detail_code', gt_main_data(ln_loop_index).siire_no);
          lb_ret := fnc_set_xml('D', 'detail_name', gt_main_data(ln_loop_index).siire_sht, 20);
        ELSIF (gr_param_rec.out_flg = '2') THEN
          lb_ret := fnc_set_xml('D', 'detail_code', gt_main_data(ln_loop_index).assen_no);
          lb_ret := fnc_set_xml('D', 'detail_name', gt_main_data(ln_loop_index).assen_sht, 20);
        END IF;
        lb_ret := fnc_set_xml('T', 'lg_deliver_date');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_deliver_date) THEN
        -- �[����
        lb_ret := fnc_set_xml('T', 'g_deliver_date');
        lb_ret := fnc_set_xml('D', 'deliver_date', gt_main_data(ln_loop_index).txns_date);
        lb_ret := fnc_set_xml('T', 'lg_item');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_item) THEN
        -- �i��
        lb_ret := fnc_set_xml('T', 'g_item');
        lb_ret := fnc_set_xml('D', 'item_code', gt_main_data(ln_loop_index).item_no);
        lb_ret := fnc_set_xml('D', 'item_name', gt_main_data(ln_loop_index).item_sht, 20);
        lb_ret := fnc_set_xml('T', 'lg_hutai');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_hutai) THEN
        -- �t��
        lb_ret := fnc_set_xml('T', 'g_hutai');
        lb_ret := fnc_set_xml('D', 'hutai', gt_main_data(ln_loop_index).futai_code, 1);
        lb_ret := fnc_set_xml('T', 'lg_lot');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_lot) THEN
        -- ���b�g
        lb_ret := fnc_set_xml('T', 'g_lot');
        lb_ret := fnc_set_xml('D', 'lot_no', gt_main_data(ln_loop_index).lot_no);
      END IF;
--
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
--
      --���׊J�n
      lb_ret := fnc_set_xml('T', 'line');
--
      --�����R�[�h
      lb_ret := fnc_set_xml('D', 'dept_code', gt_main_data(ln_loop_index).dept_code);
--
      --������
      lb_ret := fnc_set_xml('D','dept_name',gt_main_data(ln_loop_index).dept_name, 20);
--
      IF (gr_param_rec.out_flg != gv_out_torihiki) THEN
        --�����R�[�h�i�d����ԍ��j
        lb_ret := fnc_set_xml('D', 'part_code', gt_main_data(ln_loop_index).siire_no);
--
        --����於
        lb_ret := fnc_set_xml('D', 'part_name', gt_main_data(ln_loop_index).siire_sht, 20);
      END IF;
--
      IF (gr_param_rec.out_flg != gv_out_assen) THEN
        --�����҃R�[�h
        lb_ret := fnc_set_xml('D', 'med_code', gt_main_data(ln_loop_index).assen_no);
--
        --�����Җ�
        lb_ret := fnc_set_xml('D', 'med_name', gt_main_data(ln_loop_index).assen_sht, 20);
      END IF;
--
      --����No.
      lb_ret := fnc_set_xml('D', 'po_number', gt_main_data(ln_loop_index).po_no);
--
      --������
      lb_ret := fnc_set_xml('N', 'Powder_influence_rate', gt_main_data(ln_loop_index).kobiki_rate);
--
      --������P��
      lb_ret := fnc_set_xml('N', 'Powder_influence_unit_price'
                               , gt_main_data(ln_loop_index).kobikigo);
--
      --�d�����z
      ln_siire :=  NVL(gt_main_data(ln_loop_index).quantity, 0)
                 * NVL(gt_main_data(ln_loop_index).kobikigo, 0);
      lb_ret := fnc_set_xml('Z', 'purchase_amount', ln_siire);
--
      --���K���z
      lb_ret := fnc_set_xml(  'Z'
                            , 'commission_unit_price_rate'
                            , gt_main_data(ln_loop_index).kousen_price);
--
      --���ۋ��z
      lb_ret := fnc_set_xml(  'Z'
                            , 'levy_unit_price_rate1'
                            , gt_main_data(ln_loop_index).fukakin_price);
--
      --�������z
      ln_sasihiki :=  ln_siire
                    - gt_main_data(ln_loop_index).kousen_price
                    - gt_main_data(ln_loop_index).fukakin_price;
      lb_ret := fnc_set_xml('Z', 'deduction_amount', ln_sasihiki);
--
      --���ɑ���
      lb_ret := fnc_set_xml('N', 'Warehousing_total', gt_main_data(ln_loop_index).quantity);
--
      --�P��
      lb_ret := fnc_set_xml('N', 'unit_price',gt_main_data(ln_loop_index).unit_price);
--
      --���K�敪
      lb_ret := fnc_set_xml('D', 'commission_division', gt_main_data(ln_loop_index).kousen_name, 2);
--
      --���K
      lb_ret := fnc_set_xml('N', 'commission', gt_main_data(ln_loop_index).kousen);
--
      --�����(�d�����z)
      ln_tax_siire := ln_siire * NVL(gt_main_data(ln_loop_index).zeiritu, 0) / 100;
      lb_ret := fnc_set_xml('Z', 'purchase_amount_tax', ln_tax_siire);
--
      --�����(���K���z)
      ln_tax_kousen :=  gt_main_data(ln_loop_index).kousen_price
                      * NVL(gt_main_data(ln_loop_index).zeiritu, 0) / 100;
      lb_ret := fnc_set_xml('Z', 'commission_unit_price_rate_tax', ln_tax_kousen);
--
      --�����(�������z)
      ln_tax_sasihiki := ln_tax_siire - ln_tax_kousen;
      lb_ret := fnc_set_xml('Z', 'deduction_amount_tax', ln_tax_sasihiki);
--
      --�P��
      lb_ret := fnc_set_xml(  'D'
                            , 'Warehousing_total_uom'
                            , gt_main_data(ln_loop_index).rcv_rtn_uom, 4);
--
      --���ۋ��敪
      lb_ret := fnc_set_xml('D', 'levy_division', gt_main_data(ln_loop_index).fukakin_name, 2);
--
      --���ۋ�
      lb_ret := fnc_set_xml('N', 'levy_unit_price_rate2', gt_main_data(ln_loop_index).fukakin);
--
      --���d�����z
      ln_jun_siire := ln_siire + ln_tax_siire;
      lb_ret := fnc_set_xml('Z', 'pure_purchase_amount', ln_jun_siire);
--
      --�����K���z
      ln_jun_kosen := gt_main_data(ln_loop_index).kousen_price + ln_tax_kousen;
      lb_ret := fnc_set_xml('Z', 'pure_commission_unit_price_rate', ln_jun_kosen);
--
      --���ۋ��z(3�i��)
      lb_ret := fnc_set_xml(  'Z'
                            , 'levy_unit_price_rate3'
                            , gt_main_data(ln_loop_index).fukakin_price);
--
      --���������z
      ln_jun_sasihiki := ln_jun_siire - ln_jun_kosen - gt_main_data(ln_loop_index).fukakin_price;
      lb_ret := fnc_set_xml('Z', 'pure_deduction_amount', ln_jun_sasihiki);
--
--
      -- ���ׂP�s�I��
      lb_ret := fnc_set_xml('T', '/line');
--
      --���㏈��
      lr_pre_key := lr_now_key;
--
      -- �W�v�ʂ̏ꍇ�͏o�͂��Ȃ�
      IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
        -- �������v���Z
        ln_sum_post_qty          := ln_sum_post_qty
                                          + NVL(gt_main_data(ln_loop_index).quantity, 0);
        ln_sum_post_siire        := ln_sum_post_siire
                                          + NVL(ln_siire, 0);
        ln_sum_post_kosen        := ln_sum_post_kosen
                                          + NVL(gt_main_data(ln_loop_index).kousen_price, 0);
        ln_sum_post_huka         := ln_sum_post_huka
                                          + NVL(gt_main_data(ln_loop_index).fukakin_price, 0);
        ln_sum_post_sasihiki     := ln_sum_post_sasihiki
                                          + NVL(ln_sasihiki, 0);
        ln_sum_post_tax_siire    := ln_sum_post_tax_siire
                                          + NVL(ln_tax_siire, 0);
        ln_sum_post_tax_kousen   := ln_sum_post_tax_kousen
                                          + NVL(ln_tax_kousen, 0);
        ln_sum_post_tax_sasihiki := ln_sum_post_tax_sasihiki
                                          + NVL(ln_tax_sasihiki, 0);
        ln_sum_post_jun_siire    := ln_sum_post_jun_siire
                                          + NVL(ln_jun_siire, 0);
        ln_sum_post_jun_kosen    := ln_sum_post_jun_kosen
                                          + NVL(ln_jun_kosen, 0);
        ln_sum_post_jun_sasihiki := ln_sum_post_jun_sasihiki
                                          + NVL(ln_jun_sasihiki, 0);
      END IF;
--
      --�����v���Z
      ln_sum_qty          := ln_sum_qty        + NVL(gt_main_data(ln_loop_index).quantity, 0);
      ln_sum_siire        := ln_sum_siire      + NVL(ln_siire, 0);
      ln_sum_kosen        := ln_sum_kosen      + NVL(gt_main_data(ln_loop_index).kousen_price, 0);
      ln_sum_huka         := ln_sum_huka       + NVL(gt_main_data(ln_loop_index).fukakin_price, 0);
      ln_sum_sasihiki     := ln_sum_sasihiki   + NVL(ln_sasihiki, 0);
      ln_sum_tax_siire    := ln_sum_tax_siire  + NVL(ln_tax_siire, 0);
      ln_sum_tax_kousen   := ln_sum_tax_kousen + NVL(ln_tax_kousen, 0);
      ln_sum_tax_sasihiki := ln_sum_tax_sasihiki + NVL(ln_tax_sasihiki, 0);
      ln_sum_jun_siire    := ln_sum_jun_siire    + NVL(ln_jun_siire, 0);
      ln_sum_jun_kosen    := ln_sum_jun_kosen    + NVL(ln_jun_kosen, 0);
      ln_sum_jun_sasihiki := ln_sum_jun_sasihiki + NVL(ln_jun_sasihiki, 0);
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I���^�O
    -- =====================================================
    -- ���b�g
    lb_ret := fnc_set_xml('T', '/g_lot');
    lb_ret := fnc_set_xml('T', '/lg_lot');
--
    -- �t��
    lb_ret := fnc_set_xml('T', '/g_hutai');
    lb_ret := fnc_set_xml('T', '/lg_hutai');
--
    -- �i��
    lb_ret := fnc_set_xml('T', '/g_item');
    lb_ret := fnc_set_xml('T', '/lg_item');
--
    -- �[����
    lb_ret := fnc_set_xml('T', '/g_deliver_date');
    lb_ret := fnc_set_xml('T', '/lg_deliver_date');
--
    -- �ڍ׍��v(�����ҁ������
    lb_ret := fnc_set_xml('T', '/g_detail');
    lb_ret := fnc_set_xml('T', '/lg_detail');
--
    -- �����v(������ or �����
    -- �������v�o��
    IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
      lb_ret := fnc_set_xml('Z', 'whse_subtotal', ln_sum_post_qty);     --���ɑ���
      lb_ret := fnc_set_xml('Z', 'purchs_amnt_subtotal', ln_sum_post_siire);
                                                                        --�d�����z
      lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_subtotal',
                                              ln_sum_post_kosen);       --���K���z
      lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate1_subtotal',
                                              ln_sum_post_huka);        --���ۋ��z
      lb_ret := fnc_set_xml('Z', 'deduction_amnt_subtotal', ln_sum_post_sasihiki);
                                                                        --�������z
      lb_ret := fnc_set_xml('Z', 'purchs_amnt_tax_subtotal',
                                              ln_sum_post_tax_siire);   --�Ŏd��
      lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_tax_subtotal',
                                              ln_sum_post_tax_kousen);  --�Ō��K
      lb_ret := fnc_set_xml('Z', 'deduction_amnt_tax_subtotal',
                                              ln_sum_post_tax_sasihiki);--�ō���
      lb_ret := fnc_set_xml('Z', 'pure_purchs_amnt_subtotal',
                                              ln_sum_post_jun_siire);   --���d��
      lb_ret := fnc_set_xml('Z', 'pure_commi_unt_price_rate_subtotal',
                                              ln_sum_post_jun_kosen);   --�����K
      lb_ret := fnc_set_xml('Z', 'pure_deduction_amnt_subtotal',
                                              ln_sum_post_jun_sasihiki);--������
      lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate3_subtotal',
                                              ln_sum_post_huka);        --���ۋ��z
    END IF;
    IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
      lb_ret := fnc_set_xml('D', 'flg');
    END IF;
    lb_ret := fnc_set_xml('D', 'total_flg' ,lc_flg_y);
--
    lb_ret := fnc_set_xml('T', '/g_middle');
    lb_ret := fnc_set_xml('T', '/lg_middle');
--
    -- �����v�\��
    lb_ret := fnc_set_xml('Z', 'sum_Warehousing_total', ln_sum_qty);                    --���ɑ���
    lb_ret := fnc_set_xml('Z', 'sum_purchase_amount', ln_sum_siire);                    --�d�����z
    lb_ret := fnc_set_xml('Z', 'sum_commission_unit_price_rate', ln_sum_kosen);         --���K���z
    lb_ret := fnc_set_xml('Z', 'sum_levy_unit_price_rate1', ln_sum_huka);               --���ۋ��z
    lb_ret := fnc_set_xml('Z', 'sum_deduction_amount', ln_sum_sasihiki);                --�������z
    lb_ret := fnc_set_xml('Z', 'sum_purchase_amount_tax', ln_sum_tax_siire);            --�Ŏd��
    lb_ret := fnc_set_xml('Z', 'sum_commission_unit_price_rate_tax', ln_sum_tax_kousen);--�Ō��K
    lb_ret := fnc_set_xml('Z', 'sum_deduction_amount_tax', ln_sum_tax_sasihiki);        --�ō���
    lb_ret := fnc_set_xml('Z', 'sum_pure_purchase_amount', ln_sum_jun_siire);           --���d��
    lb_ret := fnc_set_xml('Z', 'sum_pure_commission_unit_price_rate', ln_sum_jun_kosen);--�����K
    lb_ret := fnc_set_xml('Z', 'sum_pure_deduction_amount', ln_sum_jun_sasihiki);       --������
    lb_ret := fnc_set_xml('Z', 'sum_levy_unit_price_rate3', ln_sum_huka);               --���ۋ��z
--
    lb_ret := fnc_set_xml('T', '/g_dept');
--
    -- �f�[�^���I���^�O
    lb_ret := fnc_set_xml('T', '/data_info');
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,'APP-XXCMN-10122'  ) ;
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
  END prc_create_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_out_flg           IN     VARCHAR2   --�o�͋敪
     ,iv_deliver_from      IN     VARCHAR2   --�[����FROM
     ,iv_deliver_to        IN     VARCHAR2   --�[����TO
     ,iv_dept_code1        IN     VARCHAR2   --�S�������P
     ,iv_dept_code2        IN     VARCHAR2   --�S�������Q
     ,iv_dept_code3        IN     VARCHAR2   --�S�������R
     ,iv_dept_code4        IN     VARCHAR2   --�S�������S
     ,iv_dept_code5        IN     VARCHAR2   --�S�������T
     ,iv_vendor_code1      IN     VARCHAR2   -- �����1
     ,iv_vendor_code2      IN     VARCHAR2   -- �����2
     ,iv_vendor_code3      IN     VARCHAR2   -- �����3
     ,iv_vendor_code4      IN     VARCHAR2   -- �����4
     ,iv_vendor_code5      IN     VARCHAR2   -- �����5
     ,iv_mediator_code1    IN     VARCHAR2   -- ������1
     ,iv_mediator_code2    IN     VARCHAR2   -- ������2
     ,iv_mediator_code3    IN     VARCHAR2   -- ������3
     ,iv_mediator_code4    IN     VARCHAR2   -- ������4
     ,iv_mediator_code5    IN     VARCHAR2   -- ������5
     ,iv_po_num            IN     VARCHAR2   -- �����ԍ�
     ,iv_item_code         IN     VARCHAR2   -- �i�ڃR�[�h
     ,iv_security_flg      IN     VARCHAR2   -- �Z�L�����e�B�敪
     ,ov_errbuf            OUT    VARCHAR2   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT    VARCHAR2   -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    prc_set_param(
        ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,iv_out_flg            => iv_out_flg            -- �o�͋敪
       ,iv_deliver_from       => iv_deliver_from       -- �[����FROM
       ,iv_deliver_to         => iv_deliver_to         -- �[����TO
       ,iv_vendor_code1       => iv_vendor_code1       -- �����P
       ,iv_vendor_code2       => iv_vendor_code2       -- �����Q
       ,iv_vendor_code3       => iv_vendor_code3       -- �����R
       ,iv_vendor_code4       => iv_vendor_code4       -- �����S
       ,iv_vendor_code5       => iv_vendor_code5       -- �����T
       ,iv_mediator_code1     => iv_mediator_code1     -- �����҂P
       ,iv_mediator_code2     => iv_mediator_code2     -- �����҂Q
       ,iv_mediator_code3     => iv_mediator_code3     -- �����҂R
       ,iv_mediator_code4     => iv_mediator_code4     -- �����҂S
       ,iv_mediator_code5     => iv_mediator_code5     -- �����҂T
       ,iv_dept_code1         => iv_dept_code1         -- �S�������P
       ,iv_dept_code2         => iv_dept_code2         -- �S�������Q
       ,iv_dept_code3         => iv_dept_code3         -- �S�������R
       ,iv_dept_code4         => iv_dept_code4         -- �S�������S
       ,iv_dept_code5         => iv_dept_code5         -- �S�������T
       ,iv_po_num             => iv_po_num             -- �����ԍ�
       ,iv_item_code          => iv_item_code          -- �i�ڃR�[�h
       ,iv_security_flg       => iv_security_flg       -- �Z�L�����e�B�敪
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <g_dept>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <g_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </g_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </g_dept>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �w�l�k�w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode               OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_out_flg            IN    VARCHAR2  --�o�͋敪
     ,iv_deliver_from       IN    VARCHAR2  --�[����FROM
     ,iv_deliver_to         IN    VARCHAR2  --�[����TO
     ,iv_dept_code1         IN    VARCHAR2  --�S�������P
     ,iv_dept_code2         IN    VARCHAR2  --�S�������Q
     ,iv_dept_code3         IN    VARCHAR2  --�S�������R
     ,iv_dept_code4         IN    VARCHAR2  --�S�������S
     ,iv_dept_code5         IN    VARCHAR2  --�S�������T
     ,iv_vendor_code1       IN    VARCHAR2  -- �����1
     ,iv_vendor_code2       IN    VARCHAR2  -- �����2
     ,iv_vendor_code3       IN    VARCHAR2  -- �����3
     ,iv_vendor_code4       IN    VARCHAR2  -- �����4
     ,iv_vendor_code5       IN    VARCHAR2  -- �����5
     ,iv_mediator_code1     IN    VARCHAR2  -- ������1
     ,iv_mediator_code2     IN    VARCHAR2  -- ������2
     ,iv_mediator_code3     IN    VARCHAR2  -- ������3
     ,iv_mediator_code4     IN    VARCHAR2  -- ������4
     ,iv_mediator_code5     IN    VARCHAR2  -- ������5
     ,iv_po_num             IN    VARCHAR2  -- �����ԍ�
     ,iv_item_code          IN    VARCHAR2  -- �i�ڃR�[�h
     ,iv_security_flg       IN    VARCHAR2  -- �Z�L�����e�B�敪
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_out_flg         =>  iv_out_flg        --�o�͋敪
       ,iv_deliver_from    =>  iv_deliver_from   --�[����FROM
       ,iv_deliver_to      =>  iv_deliver_to     --�[����TO
       ,iv_dept_code1      =>  iv_dept_code1     --�S�������P
       ,iv_dept_code2      =>  iv_dept_code2     --�S�������Q
       ,iv_dept_code3      =>  iv_dept_code3     --�S�������R
       ,iv_dept_code4      =>  iv_dept_code4     --�S�������S
       ,iv_dept_code5      =>  iv_dept_code5     --�S�������T
       ,iv_vendor_code1    =>  iv_vendor_code1   -- �����1
       ,iv_vendor_code2    =>  iv_vendor_code2   -- �����2
       ,iv_vendor_code3    =>  iv_vendor_code3   -- �����3
       ,iv_vendor_code4    =>  iv_vendor_code4   -- �����4
       ,iv_vendor_code5    =>  iv_vendor_code5   -- �����5
       ,iv_mediator_code1  =>  iv_mediator_code1 -- ������1
       ,iv_mediator_code2  =>  iv_mediator_code2 -- ������2
       ,iv_mediator_code3  =>  iv_mediator_code3 -- ������3
       ,iv_mediator_code4  =>  iv_mediator_code4 -- ������4
       ,iv_mediator_code5  =>  iv_mediator_code5 -- ������5
       ,iv_po_num          =>  iv_po_num         -- �����ԍ�
       ,iv_item_code       =>  iv_item_code      -- �i�ڃR�[�h
       ,iv_security_flg    =>  iv_security_flg   -- �Z�L�����e�B�敪
       ,ov_errbuf          =>  lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         =>  lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          =>  lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF (( lv_retcode = gv_status_error )
      OR ( lv_retcode = gv_status_warn )) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo360006c ;
/
