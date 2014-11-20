CREATE OR REPLACE PACKAGE BODY xxpo360005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360005C(body)
 * Description      : �d���i���[�j
 * MD.050/070       : �d���i���[�jIssue1.0  (T_MD050_BPO_360)
 *                    ��s������            (T_MD070_BPO_36F)
 * Version          : 1.13
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_get_in_statement      FUNCTION  : IN��̓��e��Ԃ��܂��B(vendor_type)
 *  fnc_get_in_statement      FUNCTION  : IN��̓��e��Ԃ��܂��B(dept_code_type)
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_out_xml               PROCEDURE : XML�o�͏���
 *  prc_initialize            PROCEDURE : �O����(F-2)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(F-3)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬
 *  prc_set_param             PROCEDURE : �p�����[�^�̎擾
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/04    1.0   T.Endou          �V�K�쐬
 *  2008/05/09    1.1   T.Endou          �����Ȃ��d����ԕi�f�[�^�����o����Ȃ��Ή�
 *  2008/05/13    1.2   T.Endou          OPM�i�ڏ��VIEW�Q�Ƃ��폜
 *  2008/05/13    1.3   T.Endou          �����Ȃ��d����ԕi�̂Ƃ��Ɏg�p����P�����s��
 *                                       �u�P���v����u������P���v�ɏC��
 *  2008/05/14    1.4   T.Endou          �Z�L�����e�B�v���s��Ή�
 *  2008/05/23    1.5   Y.Majikina       ���ʎ擾���ڂ̕ύX�B���z�v�Z�̕s�����C��
 *  2008/05/26    1.6   T.Endou          ��������d����ԕi�̏ꍇ�́A�ȉ����g�p����C��
 *                                       1.�ԕi�A�h�I��.������P��
 *                                       2.�ԕi�A�h�I��.�a������K���z
 *                                       3.�ԕi�A�h�I��.���ۋ��z
 *  2008/05/26    1.7   T.Endou          �O���q�Ƀ��[�U�[�̃Z�L�����e�B�͕s�v�Ȃ��ߍ폜
 *  2008/06/25    1.8   T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/10/22    1.9   I.Higa           �����̎擾���ڂ��s���i�d���於�ː������j
 *  2008/10/24    1.10  T.Ohashi         T_S_432�Ή��i�h�̂̕t�^�j
 *  2008/11/04    1.11  Y.Yamamoto       ������Q#471
 *  2008/11/28    1.12  T.Yoshimoto      �{�ԏ�Q#204
 *  2009/01/08    1.13  N.Yoshida        �{�ԏ�Q#970
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XPO360005C';  -- �p�b�P�[�W��
  gv_print_name             CONSTANT VARCHAR2(20) := '��s������';  -- ���[��
  gv_report_id              CONSTANT VARCHAR2(12) := 'XXPO360005T'; -- ���[ID
  gd_exec_date              CONSTANT DATE         := SYSDATE;       -- ���{��
--
  gv_org_id                 CONSTANT VARCHAR2(20) := 'ORG_ID'; -- �c�ƒP��
--
  gv_xxcmn_consumption_tax_rate CONSTANT VARCHAR2(26) := 'XXCMN_CONSUMPTION_TAX_RATE'; -- �����
  gv_seqrt_view             CONSTANT VARCHAR2(30) := '�L���x���Z�L�����e�Bview' ;
  gv_seqrt_view_key         CONSTANT VARCHAR2(20) := '�]�ƈ�ID' ;
-- add start 1.10
  gv_keishou                CONSTANT VARCHAR2(10) := '�a' ;
-- add end 1.10
--
  ------------------------------
  -- �Z�L�����e�B�敪
  ------------------------------
  gc_seqrt_class_vender   CONSTANT VARCHAR2(1) := '2'; -- �����i�����ҁj
  gc_seqrt_class_outside  CONSTANT VARCHAR2(1) := '4'; -- �O���q��
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ; -- �A�v���P�[�V����
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;  -- �A�v���P�[�V�����iXXPO�j
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_yyyy_format     CONSTANT VARCHAR2(30) := 'YYYY' ;
  gc_char_yy_format       CONSTANT VARCHAR2(30) := 'YY' ;
  gc_char_mm_format       CONSTANT VARCHAR2(30) := 'MM' ;
  gc_char_dd_format       CONSTANT VARCHAR2(30) := 'DD' ;
  gc_char_yyyymm_format   CONSTANT VARCHAR2(30) := 'YYYY/MM' ;
--
  gv_s01                  CONSTANT VARCHAR2(3) := '/01';
  gn_zero                 CONSTANT NUMBER := 0;
  gn_one                  CONSTANT NUMBER := 1;
  gn_10                   CONSTANT NUMBER := 10;
  gn_11                   CONSTANT NUMBER := 11;
  gn_15                   CONSTANT NUMBER := 15;
  gn_16                   CONSTANT NUMBER := 16;
  gn_20                   CONSTANT NUMBER := 20;
  gn_21                   CONSTANT NUMBER := 21;
  gn_30                   CONSTANT NUMBER := 30;
-- add start 1.10
  gn_40                   CONSTANT NUMBER := 40;
-- add end 1.10
  gv_n                    CONSTANT VARCHAR2(1) := 'N';
  gv_ja                   CONSTANT VARCHAR2(2) := 'JA';
  gv_ast                  CONSTANT VARCHAR2(1) := '*';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE vendor_type    IS TABLE OF xxcmn_vendors2_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE dept_code_type IS TABLE OF po_headers_all.attribute10%TYPE INDEX BY BINARY_INTEGER;
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data IS RECORD(
      deliver_from       VARCHAR2(10)   -- �[����FROM
     ,deliver_to         VARCHAR2(10)   -- �[����TO
     ,d_deliver_from     DATE           -- �[����FROM(���t�^)
     ,d_deliver_to       DATE           -- �[����TO(���t�^)
     ,vendor_code        vendor_type    -- �����P�`�T
     ,assen_vendor_code  vendor_type    -- �����҂P�`�T
     ,dept_code          dept_code_type -- �S�������P�`�T
     ,security_flg       VARCHAR2(1)    -- �Z�L�����e�B�敪
    ) ;
--
  -- ��s�������f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
      segment1_s           xxcmn_vendors2_v.segment1%TYPE         -- �d����R�[�h
     ,segment1_a           xxcmn_vendors2_v.segment1%TYPE         -- �����҃R�[�h
     ,vendor_name          xxcmn_vendors2_v.vendor_name%TYPE      -- �d���於
     ,zip                  xxcmn_vendors2_v.zip%TYPE              -- �X�֔ԍ�
     ,address_line1        xxcmn_vendors2_v.address_line1%TYPE    -- �����Z���P
     ,address_line2        xxcmn_vendors2_v.address_line2%TYPE    -- �����Z���Q
     ,phone                xxcmn_vendors2_v.phone%TYPE            -- �����d�b
     ,fax                  xxcmn_vendors2_v.fax%TYPE              -- �����FAX
     ,vendor_full_name     xxcmn_vendors2_v.vendor_full_name%TYPE -- �����Җ��P
     ,attribute10          po_headers_all.attribute10%TYPE        -- �����R�[�h(����)
     ,quantity             xxpo_rcv_and_rtn_txns.quantity%TYPE    -- ����
     ,purchase_amount      NUMBER                                 -- �d�����z
     ,attribute5           po_line_locations_all.attribute5%TYPE  -- �a������K���z
     ,attribute8           po_line_locations_all.attribute8%TYPE  -- ���ۋ��z
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
     ,purchase_amount_tax  NUMBER                                 -- �d�����z(�����)
     ,attribute5_tax       po_line_locations_all.attribute5%TYPE  -- �a������K���z(�����)
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;        -- �c�ƒP��
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE; -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;      -- �S����
  gv_user_vender            xxpo_per_all_people_f_v.attribute4%TYPE;      -- �d����R�[�h
  gv_user_vender_site       xxpo_per_all_people_f_v.attribute6%TYPE;      -- �d����T�C�g�R�[�h
  gn_user_vender_id         po_vendors.vendor_id%TYPE;                    -- �d����ID
--
  gn_tax                    NUMBER; -- ����ŌW��
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
      lv_in := lv_in || '''' || itbl_vendor_type(ln_cnt) || ''',';
    END LOOP vendor_code_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
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
      lv_in := lv_in || '''' || itbl_dept_code_type(ln_cnt) || ''',';
    END LOOP dept_code_type_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
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
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml
   * Description      : XML�o�͏���
   ***********************************************************************************/
  PROCEDURE prc_out_xml(
      ov_errbuf         OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param          IN  rec_param_data -- ���̓p�����[�^�Q
     ,it_xml_data_table IN  XML_DATA       -- �擾���R�[�h�Q
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml' ; -- �v���O������
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
    lv_xml_string        VARCHAR2(32000);
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
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- �w�l�k�w�b�_�[�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- �w�l�k�f�[�^���o��
    <<xml_data_table>>
    FOR i IN 1 .. it_xml_data_table.COUNT LOOP
      -- �ҏW�����f�[�^���^�O�ɕϊ�
      lv_xml_string := fnc_conv_xml(
                          iv_name   => it_xml_data_table(i).tag_name    -- �^�O�l�[��
                         ,iv_value  => it_xml_data_table(i).tag_value   -- �^�O�f�[�^
                         ,ic_type   => it_xml_data_table(i).tag_type    -- �^�O�^�C�v
                        ) ;
      -- �w�l�k�^�O�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- �w�l�k�t�b�_�[�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  END prc_out_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(F-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ov_errbuf     OUT    VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param      IN     rec_param_data   -- ���̓p�����[�^�Q
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
    get_value_expt    EXCEPTION ;     -- �l�擾�G���[
    lv_tax            fnd_lookup_values.lookup_code%TYPE; -- �����
    ld_deliver_from   DATE; -- �[����FROM�̔N����1��
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
    gn_sales_class := FND_PROFILE.VALUE( gv_org_id ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-00005' ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- ����Ŏ擾
    -- ====================================================
    -- �[����FROM�̔N����1��
    ld_deliver_from := FND_DATE.STRING_TO_DATE(
      (TO_CHAR(ir_param.d_deliver_from,gc_char_yyyymm_format) || gv_s01),gc_char_dt_format);
    BEGIN
      SELECT
        flv.lookup_code
      INTO
        lv_tax
      FROM
        xxcmn_lookup_values2_v flv
      WHERE
            flv.lookup_type = gv_xxcmn_consumption_tax_rate
        AND ((flv.start_date_active <= ld_deliver_from)
          OR (flv.start_date_active IS NULL))
        AND ((flv.end_date_active   >= ld_deliver_from)
          OR (flv.end_date_active   IS NULL));
      -- ����ŌW��
      gn_tax := TO_NUMBER(lv_tax) / 100;
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gc_application_po
                      ,'APP-XXPO-00006');
        lv_retcode  := gv_status_error ;
        RAISE get_value_expt ;
    END;
--
    -- ====================================================
    -- �S���������擾
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- �d����R�[�h�E�d����T�C�g�R�[�h�擾
    -- ====================================================
    BEGIN
--
      SELECT xssv.vendor_code
            ,xssv.vendor_site_code
            ,vnd.vendor_id
        INTO gv_user_vender
            ,gv_user_vender_site
            ,gn_user_vender_id
      FROM  xxpo_security_supply_v xssv
           ,xxcmn_vendors2_v       vnd
      WHERE xssv.vendor_code    = vnd.segment1 (+)
        AND xssv.user_id        = gn_user_id
        AND xssv.security_class = ir_param.security_flg
        AND FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
            BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+) ;
--
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                              ,'APP-XXCMN-10001'
                                              ,'TABLE'
                                              ,gv_seqrt_view
                                              ,'KEY'
                                              ,gv_seqrt_view_key ) ;
        lv_retcode := gv_status_error;
        RAISE get_value_expt ;
    END;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
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
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(F-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ov_errbuf     OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param      IN  rec_param_data            -- ���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- �擾���R�[�h�Q
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
    cv_item_class       CONSTANT VARCHAR2( 1) := '5';        -- �i�ڋ敪(���i)
    cv_pln_cancel_flag  CONSTANT VARCHAR2( 1) := 'Y';        -- ����t���O(���)
    cv_poh_approved     CONSTANT VARCHAR2(10) := 'APPROVED'; -- �����X�e�[�^�X(���F�ς�)
--
    cv_poh_decision     CONSTANT VARCHAR2( 2) := '35';       -- ������޵ݽð��(���z�m��)
    cv_poh_cancel       CONSTANT VARCHAR2( 2) := '99';       -- ������޵ݽð��(���)
--
    cv_txn_type_acc     CONSTANT VARCHAR2( 1) := '1';-- ���ы敪:XXPO_TXNS_TYPE(���)
    cv_txn_type_rtn     CONSTANT VARCHAR2( 1) := '2';-- ���ы敪:XXPO_TXNS_TYPE(�d����ԕi)
    cv_txn_type_rtn_3   CONSTANT VARCHAR2( 1) := '3';-- ���ы敪:XXPO_TXNS_TYPE(�����Ȃ��d����ԕi)
--
    -- *** ���[�J���E�ϐ� ***
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_in         VARCHAR2(1000) ;
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;  -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
    lv_sql :=
         ' SELECT'
      || '   xvv_s.segment1            AS segment1_s          ' -- �d����ԍ�
      || '  ,xvv_a.segment1            AS segment1_a          ' -- �����҃R�[�h
      || '  ,xvv_s.vendor_full_name    AS vendor_name         ' -- �d���於
      || '  ,xvv_s.zip                 AS zip                 ' -- �X�֔ԍ�
      || '  ,xvv_s.address_line1       AS address_line1       ' -- �����Z���P
      || '  ,xvv_s.address_line2       AS address_line2       ' -- �����Z���Q
      || '  ,xvv_s.phone               AS phone               ' -- �����d�b
      || '  ,xvv_s.fax                 AS fax                 ' -- �����FAX
      || '  ,xvv_a.vendor_full_name    AS vendor_full_name    ' -- �����Җ��P
      || '  ,comm.attribute10          AS attribute10         ' -- �����R�[�h(����)
      || '  ,comm.quantity             AS quantity            ' -- ����
      || '  ,comm.purchase_amount      AS purchase_amount     ' -- �d�����z
      || '  ,comm.attribute5           AS attribute5          ' -- �a������K���z
      || '  ,comm.attribute8           AS attribute8          ' -- ���ۋ��z
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
      || '  ,comm.purchase_amount_tax  AS purchase_amount_tax ' -- �d�����z(�����)
      || '  ,comm.attribute5_tax       AS attribute5_tax      ' -- �a������K���z(�����)
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
      || ' FROM'
      || '   ('
      || '    SELECT'
      || '      com.vendor_id     AS vendor_id'
      || '     ,com.attribute3    AS attribute3'
      || '     ,com.attribute10   AS attribute10'
      || '     ,SUM(com.sum_quantity) AS quantity'
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
--      || '     ,SUM(NVL(com.sum_quantity,0) * com.unit_price) AS purchase_amount'
      || '     ,SUM(ROUND(NVL(com.sum_quantity,0) * com.unit_price)) AS purchase_amount'
      || '     ,SUM(com.attribute5) AS attribute5'
      || '     ,SUM(ROUND(ROUND(NVL(com.sum_quantity,0) * com.unit_price ) * ' || gn_tax || ')) AS purchase_amount_tax'
      || '     ,SUM(ROUND(com.attribute5 * ' || gn_tax || ')) AS attribute5_tax'
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
      || '     ,SUM(com.attribute8) AS attribute8'
      || '   FROM'
      || '     ('
      || '      SELECT'
      || '        poh.vendor_id   AS vendor_id '  -- �d����ԍ�(�����)
      || '       ,poh.attribute3  AS attribute3'  -- �d����ԍ�(������)
      || '       ,poh.attribute10 AS attribute10' -- �����R�[�h
-- 2008/11/28 v1.12 T.Yoshimoto Mod Start �{��#204
--      || '       ,pla.unit_price  AS unit_price'  -- �P��(������P��)
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute2,0)) AS unit_price'  -- �P��(������P��)
      || '         FROM   po_line_locations_all plla' -- �����[������
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS unit_price'
-- 2008/11/28 v1.12 T.Yoshimoto Mod End �{��#204
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute5,0)) AS attribute5'-- �a������K���z
      || '         FROM   po_line_locations_all plla' -- �����[������
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS attribute5'
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute8,0)) AS attribute8'-- ���ۋ��z
      || '         FROM   po_line_locations_all plla' -- �����[������
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS attribute8'
      || '       ,xrart.sum_quantity AS sum_quantity'; -- ����ԕi
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '      FROM'
      || '        po_headers_all        poh'   -- �����w�b�_
      || '       ,po_lines_all          pla'   -- ��������
      || '       ,xxpo_headers_all      xha'   -- �����w�b�_�i�A�h�I���j
      || '       ,xxcmn_locations2_v    xlv'   -- ���Ə����VIEW2
      || '      ,('
      || '        SELECT'
      || '          xrart.source_document_number   AS source_document_number'
      || '         ,xrart.source_document_line_num AS source_document_line_num'
      || '         ,MAX(xrart.txns_date)           AS txns_date'
      || '         ,SUM(xrart.quantity)            AS sum_quantity'
      || '        FROM'
      || '          xxpo_rcv_and_rtn_txns xrart' -- ����ԕi����(�A�h�I��)
      || '        WHERE'
      || '          xrart.txns_type = ''' || cv_txn_type_acc || '''' -- ���
      || '        GROUP BY'
      || '          xrart.source_document_number'
      || '         ,xrart.source_document_line_num'
      || '       ) xrart';
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '      WHERE'
           -- �����w�b�_
      || '            poh.org_id        = ''' || gn_sales_class || ''''
      || '        AND poh.segment1      = xha.po_header_number'
      || '        AND poh.po_header_id  = pla.po_header_id'
      || '        AND poh.authorization_status =  ''' || cv_poh_approved || ''''
      || '        AND poh.attribute1           >= ''' || cv_poh_decision || '''' -- ���z�m��
      || '        AND poh.attribute1           <  ''' || cv_poh_cancel   || '''' -- ���
      || '        AND ( '
      || '             (pla.cancel_flag = ''' || gv_n || ''') '
      || '          OR (pla.cancel_flag IS NULL) '     -- �L�����Z���t���O
      || '            ) '
           -- ����ԕi���уA�h�I��
      || '        AND xrart.source_document_number   = poh.segment1'
      || '        AND xrart.source_document_line_num = pla.line_num'
      || '        AND xrart.txns_date '
      || '          BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                        || gc_char_d_format || ''')'
      || '            AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                      || gc_char_d_format || ''')';
--
    -- �p�����[�^�S������
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_sql := lv_sql
        || '        AND poh.attribute10 = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '        AND poh.attribute10  IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- ����
      || '        AND xlv.start_date_active <= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '        AND ((xlv.end_date_active >= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                || gc_char_d_format || '''))'
      || '          OR (xlv.end_date_active IS NULL)) '
      || '        AND poh.attribute10 = xlv.location_code ';
--
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || '        AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
        || '          OR ( poh.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || '        AND  NOT EXISTS(SELECT po_line_id '
          || '                        FROM   po_lines_all pl_sub '
          || '                        WHERE  pl_sub.po_header_id = poh.po_header_id '
          || '                        AND  NVL(pl_sub.attribute2,''' || gv_ast || ''') '
          || '                          <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
-- ��������d����ԕi
    lv_sql := lv_sql
      || '      UNION ALL'
      || '      SELECT'
      || '        poh.vendor_id      AS vendor_id '    -- �d����ԍ�(�����)
      || '       ,poh.attribute3     AS attribute3'    -- �d����ԍ�(������)
      || '       ,poh.attribute10    AS attribute10'   -- �����R�[�h
      || '       ,xrart.unit_price   AS unit_price'    -- �P��(������P��)
      || '       ,xrart.attribute5   AS attribute5'    -- �a������K���z
      || '       ,xrart.attribute8   AS attribute8'    -- ���ۋ��z
      || '       ,xrart.sum_quantity AS sum_quantity'; -- ����ԕi
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '      FROM'
      || '        po_headers_all        poh'   -- �����w�b�_
      || '       ,po_lines_all          pla'   -- ��������
      || '       ,xxpo_headers_all      xha'   -- �����w�b�_�i�A�h�I���j
      || '       ,xxcmn_locations2_v    xlv'   -- ���Ə����VIEW2
      || '       ,('
      || '         SELECT'
      || '          xrart.source_document_number    AS source_document_number'
      || '         ,xrart.source_document_line_num  AS source_document_line_num'
      || '         ,MAX(xrart.txns_date)            AS txns_date'
      || '         ,SUM(xrart.quantity * -1)        AS sum_quantity'     -- �}�C�i�X
      || '         ,AVG(xrart.kobki_converted_unit_price) AS unit_price' -- ������P��
      || '         ,SUM(xrart.kousen_price * -1)    AS attribute5'       -- �a������K���z
      || '         ,SUM(xrart.fukakin_price * -1)   AS attribute8'       -- ���ۋ��z
      || '         FROM'
      || '           xxpo_rcv_and_rtn_txns xrart' -- ����ԕi����(�A�h�I��)
      || '         WHERE'
      || '               xrart.txns_type  = ''' || cv_txn_type_rtn || '''' -- �d����ԕi
      || '           AND xrart.txns_date '
      || '             BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                           || gc_char_d_format || ''')'
      || '           AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                 || gc_char_d_format || ''')'
      || '           AND xrart.quantity > ' || gn_zero || ''
      || '         GROUP BY'
      || '           xrart.source_document_number'
      || '          ,xrart.source_document_line_num'
      || '        ) xrart';
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '      WHERE'
           -- �����w�b�_
      || '            poh.org_id        = ''' || gn_sales_class || ''''
      || '        AND poh.segment1      = xha.po_header_number'
      || '        AND poh.po_header_id  = pla.po_header_id'
      || '        AND poh.authorization_status =  ''' || cv_poh_approved || ''''
      || '        AND poh.attribute1           >= ''' || cv_poh_decision || '''' -- ���z�m��
      || '        AND poh.attribute1           <  ''' || cv_poh_cancel   || '''' -- ���
      || '        AND ( '
      || '             (pla.cancel_flag = ''' || gv_n || ''') '
      || '          OR (pla.cancel_flag IS NULL) '     -- �L�����Z���t���O
      || '            ) '
           -- ����ԕi���уA�h�I��
      || '        AND xrart.source_document_number   = poh.segment1'
      || '        AND xrart.source_document_line_num = pla.line_num'
      || '        AND xrart.txns_date '
      || '          BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                        || gc_char_d_format || ''')'
      || '            AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                      || gc_char_d_format || ''')';
--
    -- �p�����[�^�S������
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_sql := lv_sql
        || '        AND poh.attribute10 = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '        AND poh.attribute10  IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- ����
      || '        AND xlv.start_date_active <= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '        AND ((xlv.end_date_active >= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                || gc_char_d_format || '''))'
      || '          OR (xlv.end_date_active IS NULL)) '
      || '        AND poh.attribute10 = xlv.location_code ';
--
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || '        AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
        || '          OR ( poh.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || '        AND  NOT EXISTS(SELECT po_line_id '
          || '                        FROM   po_lines_all pl_sub '
          || '                        WHERE  pl_sub.po_header_id = poh.po_header_id '
          || '                        AND  NVL(pl_sub.attribute2,''' || gv_ast || ''') '
          || '                          <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
-- �����Ȃ��d����ԕi
    lv_sql :=  lv_sql
      || ' UNION ALL'
      || '      SELECT'
      || '        xrart.vendor_id                    AS vendor_id '  -- �d����ԍ�(�����)
      || '       ,TO_CHAR(xrart.assen_vendor_id)     AS attribute3'  -- �d����ԍ�(������)
      || '       ,xrart.department_code              AS attribute10' -- �����R�[�h
      || '       ,xrart.kobki_converted_unit_price   AS unit_price'  -- �P��
      || '       ,xrart.kousen_price * -1            AS attribute5'  -- �a������K���z
      || '       ,xrart.fukakin_price * -1           AS attribute8'  -- ���ۋ��z
      || '       ,xrart.quantity * -1                AS sum_quantity'; -- ����
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '   FROM '
      || '     xxpo_rcv_and_rtn_txns xrart'  -- ����ԕi����(�A�h�I��)
      || '    ,xxcmn_locations2_v    xlv ';  -- ���Ə����VIEW2
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '   WHERE '
      || '         xrart.txns_type = ''' || cv_txn_type_rtn_3 || '''' -- �����Ȃ��d����ԕi
      || '     AND xrart.quantity  > ' || gn_zero || ''
      || '     AND xrart.txns_date'
      || '           BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                         || gc_char_d_format || ''')'
      || '     AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                               || gc_char_d_format || ''')';
--
    -- �p�����[�^�S������
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_sql := lv_sql
        || '     AND xrart.department_code = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '     AND xrart.department_code IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- ����
      || '     AND xlv.start_date_active <= '
      || '       FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                             || gc_char_d_format || ''')'
      || '     AND ((xlv.end_date_active >= '
      || '       FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                             || gc_char_d_format || '''))'
      || '       OR (xlv.end_date_active IS NULL)) '
      || '     AND xrart.department_code = xlv.location_code ';
--
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || ' AND (   ( xrart.assen_vendor_id = ''' || gn_user_vender_id || ''')'
        || '      OR ( xrart.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || ' AND  NOT EXISTS(SELECT xrart_sub.factory_code '
          || '                 FROM   xxpo_rcv_and_rtn_txns xrart_sub '
          || '                 WHERE  xrart_sub.rcv_rtn_number = xrart.rcv_rtn_number '
          || '                   AND  NVL(xrart_sub.factory_code,''' || gv_ast || ''') '
          || '                        <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
--
    lv_sql := lv_sql
      || '     ) com '
      || '   GROUP BY '
      || '     com.vendor_id '
      || '    ,com.attribute3 '
      || '    ,com.attribute10 '
      || '   ) comm '
      || '  ,xxcmn_vendors2_v xvv_s ' -- �d������VIEW2 �����
      || '  ,('
      || '    SELECT'
      || '      xvv_a.vendor_id        AS vendor_id'
      || '     ,xvv_a.segment1         AS segment1'
      || '     ,xvv_a.vendor_full_name AS vendor_full_name'
      || '    FROM xxcmn_vendors2_v xvv_a'
      || '    WHERE'
      || '      xvv_a.start_date_active <= '
      || '        FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '    AND ((xvv_a.end_date_active >= '
      || '      FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                            || gc_char_d_format || '''))'
      || '      OR (xvv_a.end_date_active IS NULL)) '
      || '   ) xvv_a' -- �d������VIEW2 ����
      || ' WHERE '
      -- ������
      || '   xvv_a.vendor_id(+) = comm.attribute3 '
      -- �����
      || '   AND xvv_s.start_date_active <= '
      || '     FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                           || gc_char_d_format || ''')'
      || '   AND ((xvv_s.end_date_active >= '
      || '     FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                           || gc_char_d_format || '''))'
      || '     OR (xvv_s.end_date_active IS NULL)) '
      || '   AND xvv_s.vendor_id = comm.vendor_id ';
--
      -- �p�����[�^������
      IF (ir_param.assen_vendor_code.COUNT = gn_one) THEN
        -- 1���̂�
        lv_sql := lv_sql
          || '     AND xvv_a.segment1 = ''' || ir_param.assen_vendor_code(gn_one) || '''';
      ELSIF (ir_param.assen_vendor_code.COUNT > gn_one) THEN
        -- 1���ȏ�
        lv_in := fnc_get_in_statement(ir_param.assen_vendor_code);
        lv_sql := lv_sql
          || '     AND xvv_a.segment1 IN(' || lv_in || ') ';
      END IF;
      -- �p�������
      IF (ir_param.vendor_code.COUNT = gn_one) THEN
        -- 1���̂�
        lv_sql := lv_sql
          || '     AND xvv_s.segment1 = ''' || ir_param.vendor_code(gn_one) || '''';
      ELSIF (ir_param.vendor_code.COUNT > gn_one) THEN
        -- 1���ȏ�
        lv_in := fnc_get_in_statement(ir_param.vendor_code);
        lv_sql := lv_sql
          || '     AND xvv_s.segment1 IN(' || lv_in || ') ';
      END IF;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || ' ORDER BY'
      || '  segment1_s' -- �d����R�[�h
      || ' ,segment1_a' -- �����҃R�[�h
      ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref;
    IF ( ot_data_rec.COUNT = 0 ) THEN
      -- �擾�f�[�^���O���̏ꍇ
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param          IN  rec_param_data    -- �p�����[�^
     ,it_data_rec       IN  tab_data_type_dtl -- �擾���R�[�h�Q
     ,ot_xml_data_table OUT XML_DATA          -- XML�f�[�^
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
    lc_break_init           VARCHAR2(100) DEFAULT '*' ;            -- �����l
    lc_break_null           VARCHAR2(100) DEFAULT '**' ;           -- �m�t�k�k����
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_company_code         VARCHAR2(100) DEFAULT lc_break_init;   -- ��ЃR�[�h
-- add start 1.10
    ln_vendor_name_len      NUMBER;                                -- ����於�̕�����
-- add end 1.10
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;  -- �擾���R�[�h�Ȃ�
--
    lv_from_year            VARCHAR2(4); -- ���ԊJ�n�F�N
    lv_from_month           VARCHAR2(2); -- ���ԊJ�n�F��
    lv_from_date            VARCHAR2(2); -- ���ԊJ�n�F��
    lv_to_year              VARCHAR2(4); -- ���ԏI���F�N
    lv_to_month             VARCHAR2(2); -- ���ԏI���F��
    lv_to_date              VARCHAR2(2); -- ���ԏI���F��
    lv_to_year_yy           VARCHAR2(2); -- ���ԏI���F�N(YY)
--
    lv_postal_code      xxcmn_locations2_v.zip%TYPE;           -- �X�֔ԍ�
    lv_address          xxcmn_locations2_v.address_line1%TYPE; -- �Z��
    lv_tel_num          xxcmn_locations2_v.phone%TYPE;         -- �d�b�ԍ�
    lv_fax_num          xxcmn_locations2_v.fax%TYPE;           -- FAX�ԍ�
    lv_dept_formal_name xxcmn_locations2_v.location_name%TYPE; -- ����������
--
    ln_quantity                   NUMBER; -- ����
    ln_purchase_amount            NUMBER; -- �d�����z
    ln_purchase_amount_tax        NUMBER; -- �����:�d�����z
    ln_pure_purchase_amount       NUMBER; -- ���d�����z
    ln_cupr_tax                   NUMBER; -- �����:���K���z
    ln_pure_cupr_tax              NUMBER; -- �����K���z
    ln_deduction_amount           NUMBER; -- �������z
    ln_deduction_amount_tax       NUMBER; -- �����:�������z
    ln_pure_deduction_amount      NUMBER; -- ���������z
--
    lt_xml_idx                NUMBER DEFAULT 0; -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
    lv_errmsg_no_data         VARCHAR2(5000);   -- �f�[�^�Ȃ����b�Z�[�W
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    lv_from_year  := TO_CHAR(ir_param.d_deliver_from,gc_char_yyyy_format);
    lv_from_month := TO_CHAR(ir_param.d_deliver_from,gc_char_mm_format);
    lv_from_date  := TO_CHAR(ir_param.d_deliver_from,gc_char_dd_format);
    lv_to_year    := TO_CHAR(ir_param.d_deliver_to,gc_char_yyyy_format);
    lv_to_year_yy := TO_CHAR(ir_param.d_deliver_to,gc_char_yy_format);
    lv_to_month   := TO_CHAR(ir_param.d_deliver_to,gc_char_mm_format);
    lv_to_date    := TO_CHAR(ir_param.d_deliver_to,gc_char_dd_format);
    -- -----------------------------------------------------
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ���[�h�c
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_id' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := gv_report_id ;
    -- ���{��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'exec_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- �N
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_name_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_year_yy ;
    -- ��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_name_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_month ;
    -- �N�F���ԊJ�n
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_year ;
    -- ���F���ԊJ�n
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_month ;
    -- ���F���ԊJ�n
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_date ;
    -- �N�F���ԏI��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_year ;
    -- ���F���ԏI��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_month ;
    -- ���F���ԏI��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_date ;
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �����k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    -- �����m�F
    IF (it_data_rec.COUNT = gn_zero) THEN
      -- �O�����b�Z�[�W�o��
      lv_errmsg_no_data := xxcmn_common_pkg.get_msg( gc_application_po
                                                   ,'APP-XXPO-00009' ) ;
--
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_company_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'msg' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := lv_errmsg_no_data;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    END IF;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..it_data_rec.COUNT LOOP
      -- =====================================================
      -- �����R�[�h�u���C�N
      -- =====================================================
      -- �����R�[�h���؂�ւ�����ꍇ
      IF ( NVL( it_data_rec(i).segment1_s, lc_break_null ) <> lv_company_code ) THEN
--
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_company_code <> lc_break_init ) THEN
          ------------------------------
          -- �����҃R�[�h�w�b�_�f�I���^�O
          ------------------------------
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_mediator_code' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �����R�[�h�w�b�_�f�I���^�O
          ------------------------------
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/g_company_code' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �����f�J�n�^�O�o��
        -- -----------------------------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_company_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
-- add start 1.10
        -- ����於�̕������擾
        ln_vendor_name_len := LENGTH(it_data_rec(i).vendor_name);
-- add end 1.10
        -- ����於�P
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- mod start 1.10
--        ot_xml_data_table(lt_xml_idx).tag_value :=
--          SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_15) ;
        IF (ln_vendor_name_len <= gn_20) THEN
          -- �h�̂�t����
          ot_xml_data_table(lt_xml_idx).tag_value :=
            SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_20) || gv_keishou ;
        ELSE
          ot_xml_data_table(lt_xml_idx).tag_value :=
            SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_20) ;
        END IF;
-- mod end 1.10
        -- ����於�Q
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_name2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- mod start 1.10
--        ot_xml_data_table(lt_xml_idx).tag_value :=
--          SUBSTR(it_data_rec(i).vendor_name,gn_16,gn_30) ;
        IF (ln_vendor_name_len >= gn_21) THEN
          -- �h�̂�t����
          ot_xml_data_table(lt_xml_idx).tag_value :=
            SUBSTR(it_data_rec(i).vendor_name,gn_21,gn_40) || gv_keishou ;
        ELSE
          ot_xml_data_table(lt_xml_idx).tag_value :=
            SUBSTR(it_data_rec(i).vendor_name,gn_21,gn_40) ;
        END IF;
-- mod end 1.10
        -- �M�ЃR�[�h
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'your_company_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).segment1_s ;
        -- �X�֔ԍ�
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_postal_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).zip ;
        -- �����Z���P
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_address' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).address_line1,gn_one,gn_15) ;
        -- �����Z���Q
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_address2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).address_line2,gn_one,gn_15) ;
        -- �����TEL
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_telephone_number' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).phone,gn_one,gn_15) ;
        -- �����FAX
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_fax_number' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).fax,gn_one,gn_15) ;
        -- �������̎擾
        xxcmn_common_pkg.get_dept_info(
          iv_dept_cd          => it_data_rec(i).attribute10  -- �����R�[�h(���Ə�CD)
         ,id_appl_date        => ir_param.d_deliver_from -- ���
         ,ov_postal_code      => lv_postal_code      -- �X�֔ԍ�
         ,ov_address          => lv_address          -- �Z��
         ,ov_tel_num          => lv_tel_num          -- �d�b�ԍ�
         ,ov_fax_num          => lv_fax_num          -- FAX�ԍ�
         ,ov_dept_formal_name => lv_dept_formal_name -- ����������
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg);
        -- ���t���Z��
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_address' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_address,gn_one,gn_15) ;
        -- ���t��TEL
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_telephone_number' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_tel_num,gn_one,gn_15) ;
        -- ���t��FAX
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_fax_number' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_fax_num,gn_one,gn_15) ;
        -- ���t������
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_dept_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_dept_formal_name,gn_one,gn_15) ;
        ------------------------------
        -- �����҃w�b�_
        ------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_mediator_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_company_code  := NVL( it_data_rec(i).segment1_s, lc_break_null )  ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      -- ���׃N���A
      ln_quantity              := 0; -- ����
      ln_purchase_amount       := 0; -- �d�����z
      ln_purchase_amount_tax   := 0; -- �����:�d�����z
      ln_pure_purchase_amount  := 0; -- ���d�����z
      ln_cupr_tax              := 0; -- �����:���K���z
      ln_pure_cupr_tax         := 0; -- �����K���z
      ln_deduction_amount      := 0; -- �������z
      ln_deduction_amount_tax  := 0; -- �����:�������z
      ln_pure_deduction_amount := 0; -- ���������z
      -- -----------------------------------------------------
      -- ����
      -- -----------------------------------------------------
      -- �����҃w�b�_
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      -- �����҃R�[�h
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).segment1_a;
      -- �����Җ�
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_one,gn_10) ;
      -- �����Җ��Q
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name2' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_11,gn_20) ;
      -- �����Җ��R
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name3' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_21,gn_30) ;
      -- ����
      ln_quantity := ROUND(it_data_rec(i).quantity,3);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'quantity' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_quantity);
      -- �d�����z
-- 2008/11/04 v1.11 Y.Yamamoto update start
--      ln_purchase_amount := ROUND(it_data_rec(i).purchase_amount);
      ln_purchase_amount := TRUNC(it_data_rec(i).purchase_amount);
-- 2008/11/04 v1.11 Y.Yamamoto update end
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_purchase_amount);
      -- �����:�d�����z
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
--      ln_purchase_amount_tax := ROUND(ln_purchase_amount * gn_tax);
      ln_purchase_amount_tax := it_data_rec(i).purchase_amount_tax;
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_tax' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_purchase_amount_tax);
      -- ���d�����z
      ln_pure_purchase_amount := ln_purchase_amount + ln_purchase_amount_tax;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_purchase_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_purchase_amount);
      -- ���K
      IF (it_data_rec(i).attribute5 IS NOT NULL) THEN
        -- ���K���z
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).attribute5;
        -- �����:���K���z
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
--        ln_cupr_tax := ROUND(it_data_rec(i).attribute5 * gn_tax);
        ln_cupr_tax := it_data_rec(i).attribute5_tax;
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_tax' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_cupr_tax);
        -- �����K���z
        ln_pure_cupr_tax := it_data_rec(i).attribute5 + ln_cupr_tax;
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_commission_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_cupr_tax);
      END IF;
      -- ����
      IF (it_data_rec(i).attribute8 IS NOT NULL) THEN
        -- ���ۋ��z
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(it_data_rec(i).attribute8);
        -- ���ۋ��z(3�i��)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(it_data_rec(i).attribute8);
      END IF;
      -- �������z
      ln_deduction_amount :=
        ln_purchase_amount - NVL(it_data_rec(i).attribute5,0) - NVL(it_data_rec(i).attribute8,0);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_deduction_amount);
      -- �����:�������z
      ln_deduction_amount_tax := ln_purchase_amount_tax - ln_cupr_tax;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount_tax' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_deduction_amount_tax);
      -- ���������z
      ln_pure_deduction_amount :=
        ln_pure_purchase_amount - ln_pure_cupr_tax - NVL(it_data_rec(i).attribute8,0);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_deduction_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_deduction_amount);
      -- �����҃w�b�_
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- �����҃R�[�h�f�I���^�O
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_mediator_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����R�[�h�f�I���^�O
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/g_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����k�f�I���^�O
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
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
  END prc_create_xml_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_set_param
   * Description      : �p�����[�^�̎擾
   ***********************************************************************************/
  PROCEDURE prc_set_param(
      ov_errbuf             OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_deliver_from       IN  VARCHAR2       -- �[����FROM
     ,iv_deliver_to         IN  VARCHAR2       -- �[����TO
     ,iv_vendor_code1       IN  VARCHAR2       -- �����P
     ,iv_vendor_code2       IN  VARCHAR2       -- �����Q
     ,iv_vendor_code3       IN  VARCHAR2       -- �����R
     ,iv_vendor_code4       IN  VARCHAR2       -- �����S
     ,iv_vendor_code5       IN  VARCHAR2       -- �����T
     ,iv_assen_vendor_code1 IN  VARCHAR2       -- �����҂P
     ,iv_assen_vendor_code2 IN  VARCHAR2       -- �����҂Q
     ,iv_assen_vendor_code3 IN  VARCHAR2       -- �����҂R
     ,iv_assen_vendor_code4 IN  VARCHAR2       -- �����҂S
     ,iv_assen_vendor_code5 IN  VARCHAR2       -- �����҂T
     ,iv_dept_code1         IN  VARCHAR2       -- �S�������P
     ,iv_dept_code2         IN  VARCHAR2       -- �S�������Q
     ,iv_dept_code3         IN  VARCHAR2       -- �S�������R
     ,iv_dept_code4         IN  VARCHAR2       -- �S�������S
     ,iv_dept_code5         IN  VARCHAR2       -- �S�������T
     ,iv_security_flg       IN  VARCHAR2       -- �Z�L�����e�B�敪
     ,or_param_rec          OUT rec_param_data -- ���̓p�����[�^�Q
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
    ln_assen_vendor_code NUMBER DEFAULT 0; -- ������
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
    -- �[����(FROM)���t�^
    or_param_rec.d_deliver_from := FND_DATE.STRING_TO_DATE(iv_deliver_from,gc_char_dt_format);
    -- �[����(TO)  ���t�^
    or_param_rec.d_deliver_to   := FND_DATE.STRING_TO_DATE(iv_deliver_to,gc_char_dt_format);
    -- �[����(FROM)
    or_param_rec.deliver_from   := TO_CHAR(or_param_rec.d_deliver_from ,gc_char_d_format);
    -- �[����(TO)
    or_param_rec.deliver_to     := TO_CHAR(or_param_rec.d_deliver_to ,gc_char_d_format);
    -- �Z�L�����e�B�敪
    or_param_rec.security_flg   := iv_security_flg;
--
    -- �����P
    IF (TRIM(iv_vendor_code1) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code1;
    END IF;
    -- �����Q
    IF (TRIM(iv_vendor_code2) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code2;
    END IF;
    -- �����R
    IF (TRIM(iv_vendor_code3) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code3;
    END IF;
    -- �����S
    IF (TRIM(iv_vendor_code4) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code4;
    END IF;
    -- �����T
    IF (TRIM(iv_vendor_code5) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code5;
    END IF;
--
    -- �����҂P
    IF (TRIM(iv_assen_vendor_code1) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code1;
    END IF;
    -- �����҂Q
    IF (TRIM(iv_assen_vendor_code2) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code2;
    END IF;
    -- �����҂R
    IF (TRIM(iv_assen_vendor_code3) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code3;
    END IF;
    -- �����҂S
    IF (TRIM(iv_assen_vendor_code4) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code4;
    END IF;
    -- �����҂T
    IF (TRIM(iv_assen_vendor_code5) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code5;
    END IF;
--
    -- �S�������P
    IF (TRIM(iv_dept_code1) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code1;
    END IF;
    -- �S�������Q
    IF (TRIM(iv_dept_code2) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code2;
    END IF;
    -- �S�������R
    IF (TRIM(iv_dept_code3) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code3;
    END IF;
    -- �S�������S
    IF (TRIM(iv_dept_code4) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code4;
    END IF;
    -- �S�������T
    IF (TRIM(iv_dept_code5) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code5;
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
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf             OUT VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_deliver_from       IN  VARCHAR2        -- �[����FROM
     ,iv_deliver_to         IN  VARCHAR2        -- �[����TO
     ,iv_vendor_code1       IN  VARCHAR2        -- �����P
     ,iv_vendor_code2       IN  VARCHAR2        -- �����Q
     ,iv_vendor_code3       IN  VARCHAR2        -- �����R
     ,iv_vendor_code4       IN  VARCHAR2        -- �����S
     ,iv_vendor_code5       IN  VARCHAR2        -- �����T
     ,iv_assen_vendor_code1 IN  VARCHAR2        -- �����҂P
     ,iv_assen_vendor_code2 IN  VARCHAR2        -- �����҂Q
     ,iv_assen_vendor_code3 IN  VARCHAR2        -- �����҂R
     ,iv_assen_vendor_code4 IN  VARCHAR2        -- �����҂S
     ,iv_assen_vendor_code5 IN  VARCHAR2        -- �����҂T
     ,iv_dept_code1         IN  VARCHAR2        -- �S�������P
     ,iv_dept_code2         IN  VARCHAR2        -- �S�������Q
     ,iv_dept_code3         IN  VARCHAR2        -- �S�������R
     ,iv_dept_code4         IN  VARCHAR2        -- �S�������S
     ,iv_dept_code5         IN  VARCHAR2        -- �S�������T
     ,iv_security_flg       IN  VARCHAR2        -- �Z�L�����e�B�敪
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
    lr_param_rec         rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string        VARCHAR2(32000) ;
    ln_retcode           NUMBER ;
--
    ------------------------------
    -- �w�l�k�p
    ------------------------------
    lt_main_data              tab_data_type_dtl; -- �擾���R�[�h�\
    lt_xml_data_table         XML_DATA;          -- �w�l�k�f�[�^�^�O�\
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
    -- �p�����[�^�i�[
    -- =====================================================
    prc_set_param(
        ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,iv_deliver_from       => iv_deliver_from       -- �[����FROM
       ,iv_deliver_to         => iv_deliver_to         -- �[����TO
       ,iv_vendor_code1       => iv_vendor_code1       -- �����P
       ,iv_vendor_code2       => iv_vendor_code2       -- �����Q
       ,iv_vendor_code3       => iv_vendor_code3       -- �����R
       ,iv_vendor_code4       => iv_vendor_code4       -- �����S
       ,iv_vendor_code5       => iv_vendor_code5       -- �����T
       ,iv_assen_vendor_code1 => iv_assen_vendor_code1 -- �����҂P
       ,iv_assen_vendor_code2 => iv_assen_vendor_code2 -- �����҂Q
       ,iv_assen_vendor_code3 => iv_assen_vendor_code3 -- �����҂R
       ,iv_assen_vendor_code4 => iv_assen_vendor_code4 -- �����҂S
       ,iv_assen_vendor_code5 => iv_assen_vendor_code5 -- �����҂T
       ,iv_dept_code1         => iv_dept_code1         -- �S�������P
       ,iv_dept_code2         => iv_dept_code2         -- �S�������Q
       ,iv_dept_code3         => iv_dept_code3         -- �S�������R
       ,iv_dept_code4         => iv_dept_code4         -- �S�������S
       ,iv_dept_code5         => iv_dept_code5         -- �S�������T
       ,iv_security_flg       => iv_security_flg       -- �Z�L�����e�B�敪
       ,or_param_rec          => lr_param_rec          -- ���̓p�����[�^�Q
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
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data(
        ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param      => lr_param_rec   -- ���̓p�����[�^�Q
       ,ot_data_rec   => lt_main_data   -- �擾���R�[�h�Q
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,it_data_rec       => lt_main_data       -- �擾���R�[�h�Q
       ,ot_xml_data_table => lt_xml_data_table  -- XML�f�[�^
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML�o�͏���
    -- =====================================================
    prc_out_xml(
        ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param          => lr_param_rec      -- ���̓p�����[�^�Q
       ,it_xml_data_table => lt_xml_data_table -- �擾���R�[�h�Q
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF (lt_main_data.COUNT = 0) THEN
      lv_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
    END IF;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_deliver_from       IN     VARCHAR2         -- �[����FROM
     ,iv_deliver_to         IN     VARCHAR2         -- �[����TO
     ,iv_vendor_code1       IN     VARCHAR2         -- �����P
     ,iv_vendor_code2       IN     VARCHAR2         -- �����Q
     ,iv_vendor_code3       IN     VARCHAR2         -- �����R
     ,iv_vendor_code4       IN     VARCHAR2         -- �����S
     ,iv_vendor_code5       IN     VARCHAR2         -- �����T
     ,iv_assen_vendor_code1 IN     VARCHAR2         -- �����҂P
     ,iv_assen_vendor_code2 IN     VARCHAR2         -- �����҂Q
     ,iv_assen_vendor_code3 IN     VARCHAR2         -- �����҂R
     ,iv_assen_vendor_code4 IN     VARCHAR2         -- �����҂S
     ,iv_assen_vendor_code5 IN     VARCHAR2         -- �����҂T
     ,iv_dept_code1         IN     VARCHAR2         -- �S�������P
     ,iv_dept_code2         IN     VARCHAR2         -- �S�������Q
     ,iv_dept_code3         IN     VARCHAR2         -- �S�������R
     ,iv_dept_code4         IN     VARCHAR2         -- �S�������S
     ,iv_dept_code5         IN     VARCHAR2         -- �S�������T
     ,iv_security_flg       IN     VARCHAR2         -- �Z�L�����e�B�敪
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
        ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,iv_deliver_from       => iv_deliver_from       -- �[����FROM
       ,iv_deliver_to         => iv_deliver_to         -- �[����TO
       ,iv_vendor_code1       => iv_vendor_code1       -- �����P
       ,iv_vendor_code2       => iv_vendor_code2       -- �����Q
       ,iv_vendor_code3       => iv_vendor_code3       -- �����R
       ,iv_vendor_code4       => iv_vendor_code4       -- �����S
       ,iv_vendor_code5       => iv_vendor_code5       -- �����T
       ,iv_assen_vendor_code1 => iv_assen_vendor_code1 -- �����҂P
       ,iv_assen_vendor_code2 => iv_assen_vendor_code2 -- �����҂Q
       ,iv_assen_vendor_code3 => iv_assen_vendor_code3 -- �����҂R
       ,iv_assen_vendor_code4 => iv_assen_vendor_code4 -- �����҂S
       ,iv_assen_vendor_code5 => iv_assen_vendor_code5 -- �����҂T
       ,iv_dept_code1         => iv_dept_code1         -- �S�������P
       ,iv_dept_code2         => iv_dept_code2         -- �S�������Q
       ,iv_dept_code3         => iv_dept_code3         -- �S�������R
       ,iv_dept_code4         => iv_dept_code4         -- �S�������S
       ,iv_dept_code5         => iv_dept_code5         -- �S�������T
       ,iv_security_flg       => iv_security_flg       -- �Z�L�����e�B�敪
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
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
END xxpo360005c ;
/
