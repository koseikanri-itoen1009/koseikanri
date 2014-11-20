CREATE OR REPLACE PACKAGE BODY xxpo780001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxpo780001c(body)
 * Description      : �����Y�؏����i�L���x�����E�j
 * MD.050/070       : �����Y�؏����i�L���x�����E�jIssue1.0  (T_MD050_BPO_780)
 *                    �v�Z��                                (T_MD070_BPO_78A)
 * Version          : 1.7
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_check_param_info      PROCEDURE : �p�����[�^�`�F�b�N(A-1)
 *  prc_initialize            PROCEDURE : �O����(A-2)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(A-3)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬(A-4)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/03    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/02/06    1.1   Masayuki Ikeda   �E�󒍖��׃A�h�I���ƕi�ڃ}�X�^��R�t����ꍇ�A�h�m�u
 *                                         �i�ڃ}�X�^�𒇉��B
 *                                       �E���b�Z�[�W�R�[�h���C��
 *  2008/03/10    1.2   Masayuki Ikeda   �E�ύX�v��No.81�Ή�
 *  2008/06/20    1.3  Yasuhisa Yamamoto ST�s��Ή�#135
 *  2008/07/29    1.4   Satoshi Yunba    �֑������Ή�
 *  2008/12/05    1.5  Tsuyoki Yoshimoto �{�ԏ�Q#446
 *  2008/12/25    1.6  Takao Ohashi      �{�ԏ�Q#848,850
 *  2009/03/04    1.7  Akiyoshi Shiina   �{�ԏ�Q#1266�Ή�
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo780001c' ;   -- �p�b�P�[�W��
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_language_code              CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_enable_flag                CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_lookup_type_shikyu_class   CONSTANT VARCHAR2(100) := 'XXWSH_SHIPPING_SHIKYU_CLASS' ;
  gc_lookup_type_fix_class      CONSTANT VARCHAR2(100) := 'XXWSH_AMOUNT_FIX_CLASS' ;
  gc_lookup_type_tax_rate       CONSTANT VARCHAR2(100) := 'XXCMN_CONSUMPTION_TAX_RATE' ;
  gc_lookup_meaning_shikyu_irai CONSTANT VARCHAR2(100) := '�x���˗�' ;
  gc_lookup_meaning_kakutei     CONSTANT VARCHAR2(100) := '�m��' ;
--
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
  gc_ship_rcv_pay_ctg_mhn       CONSTANT VARCHAR2(2)   := '01' ;    -- ���{�o��
  gc_ship_rcv_pay_ctg_hik       CONSTANT VARCHAR2(2)   := '02' ;    -- �p���o��
  gc_ship_rcv_pay_ctg_kra       CONSTANT VARCHAR2(2)   := '03' ;    -- �q�֓���
  gc_ship_rcv_pay_ctg_hen       CONSTANT VARCHAR2(2)   := '04' ;    -- �ԕi����
  gc_ship_rcv_pay_ctg_ysy       CONSTANT VARCHAR2(2)   := '05' ;    -- �L���o��
  gc_ship_rcv_pay_ctg_yhe       CONSTANT VARCHAR2(2)   := '06' ;    -- �L���ԕi
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- �A�v���P�[�V�����iXXPO�j
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '�N' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '��' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '��' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
-- add start ver1.6
  ------------------------------
  -- �Q�ƃR�[�h
  ------------------------------
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_prov        CONSTANT VARCHAR2(2)  := '30';    -- �x���w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_stck        CONSTANT VARCHAR2(2)  := '20';    -- �o�Ɏ���
-- add end ver1.6
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      fiscal_ym           VARCHAR2(6)                                               -- �Y�ؔN��
     ,dept_code           xxwsh_order_headers_all.performance_management_dept%TYPE  -- �����Ǘ�����
     ,vendor_code         xxwsh_order_headers_all.vendor_code%TYPE                  -- �����
    ) ;
--
  -- �v�Z���f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD 
    (
-- mod start ver1.6
--      v_vendor_name         xxcmn_vendors.vendor_name%TYPE          -- �����F����於��
      vendor_code           xxwsh_order_headers_all.vendor_code%TYPE -- �����F�����R�[�h
     ,v_vendor_name         xxcmn_vendors.vendor_name%TYPE          -- �����F����於��
-- mod end ver1.6
     ,v_zip                 xxcmn_vendors.zip%TYPE                  -- �����F�X�֔ԍ�
     ,v_address_line1       xxcmn_vendors.address_line1%TYPE        -- �����F�Z���P
     ,v_address_line2       xxcmn_vendors.address_line2%TYPE        -- �����F�Z���Q
     ,l_location_name       xxcmn_locations_all.location_name%TYPE  -- ���Ə��F���Ə�����
     ,l_zip                 xxcmn_locations_all.zip%TYPE            -- ���Ə��F�X�֔ԍ�
     ,l_address_line1       xxcmn_locations_all.address_line1%TYPE  -- ���Ə��F�Z���P
     ,l_phone               xxcmn_locations_all.phone%TYPE          -- ���Ə��F�d�b�ԍ�
     ,l_fax                 xxcmn_locations_all.fax%TYPE            -- ���Ə��F�e�`�w�ԍ�
     ,item_class            xxwsh_order_headers_all.item_class%TYPE           -- �i�ڋ敪
     ,arrival_date          xxwsh_order_headers_all.arrival_date%TYPE         -- ���ד�
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
--     ,request_no            xxwsh_order_headers_all.request_no%TYPE
     ,request_no            VARCHAR2(13)                                      -- �˗�No�i�`�[�ԍ��j
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
     ,item_code             xxwsh_order_lines_all.shipping_item_code%TYPE     -- �i�ڃR�[�h
     ,item_name             xxcmn_item_mst_b.item_short_name%TYPE             -- �i�ږ���
     ,unit_price            xxwsh_order_lines_all.unit_price%TYPE             -- �P��
     ,tax_rate              fnd_lookup_values.lookup_code%TYPE                -- ����ŗ�
-- add start ver1.6
     ,amount                NUMBER                                            -- ���z
     ,tax                   NUMBER                                            -- �����
-- add end ver1.6
     ,quantity              xxwsh_order_lines_all.quantity%TYPE               -- �o�׎��ѐ���
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%type ;  -- �c�ƒP��
  gd_fiscal_date_from       DATE ;                                  -- �Ώ۔N����From
  gv_fiscal_date_from_char  VARCHAR2(14) ;                          -- �Ώ۔N����From�i�a��j
  gd_fiscal_date_to         DATE ;                                  -- �Ώ۔N����To
  gv_fiscal_date_to_char    VARCHAR2(14) ;                          -- �Ώ۔N����To�i�a��j
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- ���[ID
  gd_exec_date              DATE         ;    -- ���{��
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
  ------------------------------
  -- ���b�N�A�b�v�p
  ------------------------------
  gv_fix_class              fnd_lookup_values.lookup_code%TYPE ;
  gv_shikyu_class           fnd_lookup_values.lookup_code%TYPE ;
--
  ------------------------------
  -- �v���t�@�C���p
  ------------------------------
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
  gc_prof_mst_org_id        CONSTANT VARCHAR2(30) := 'XXCMN_MASTER_ORG_ID' ; -- �i�ڃ}�X�^�g�D
  gn_prof_mst_org_id        NUMBER ;              -- �i�ڃ}�X�^�g�DID
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
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
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml
    (
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
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : �p�����[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
    (
      ir_param      IN     rec_param_data   -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- �v���O������
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
    ln_ret_num                NUMBER ;        -- ���ʊ֐��߂�l�F���l�^
    lv_err_code               VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �Ώ۔N��
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.fiscal_ym ) ;
    IF ( ln_ret_num = 1 ) THEN
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      lv_err_code := 'APP-XXPO-00004' ;
--      lv_err_code := 'APP-XXPO-10004' ;
      lv_err_code := 'APP-XXPO-10211' ;
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      RAISE parameter_check_expt ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O ***
    WHEN parameter_check_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,lv_err_code    ) ;
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
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(A-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize
    (
      ir_param      IN     rec_param_data   -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
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
    ln_data_cnt           NUMBER := 0 ;   -- �f�[�^�����擾�p
    lv_err_code           VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
    lv_token_name1        VARCHAR2(100) ;      -- ���b�Z�[�W�g�[�N�����P
    lv_token_name2        VARCHAR2(100) ;      -- ���b�Z�[�W�g�[�N�����Q
    lv_token_value1       VARCHAR2(100) ;      -- ���b�Z�[�W�g�[�N���l�P
    lv_token_value2       VARCHAR2(100) ;      -- ���b�Z�[�W�g�[�N���l�Q
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
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      lv_err_code := 'APP-XXPO-00005' ;
--      lv_err_code := 'APP-XXPO-10005' ;
      lv_err_code := 'APP-XXPO-10212' ;
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �Ώ۔N���擾
    -- ====================================================
    -- �Ώ۔N����From
    gd_fiscal_date_from       := FND_DATE.CANONICAL_TO_DATE( ir_param.fiscal_ym || '01' ) ;
    gv_fiscal_date_from_char  := TO_CHAR( gd_fiscal_date_from, 'YYYY' ) || gc_jp_yy
                              || TO_CHAR( gd_fiscal_date_from, 'MM' )   || gc_jp_mm
                              || TO_CHAR( gd_fiscal_date_from, 'DD' )   || gc_jp_dd ;
    -- �Ώ۔N����To
    gd_fiscal_date_to         := LAST_DAY( gd_fiscal_date_from ) ;
    gv_fiscal_date_to_char    := TO_CHAR( gd_fiscal_date_to, 'YYYY' ) || gc_jp_yy
                              || TO_CHAR( gd_fiscal_date_to, 'MM' )   || gc_jp_mm
                              || TO_CHAR( gd_fiscal_date_to, 'DD' )   || gc_jp_dd ;
--
    -- ====================================================
    -- ����Ŏ擾
    -- ====================================================
    SELECT COUNT( lookup_code )
    INTO   ln_data_cnt
    FROM fnd_lookup_values
    WHERE gd_fiscal_date_from BETWEEN NVL( START_DATE_ACTIVE, gd_fiscal_date_from )
                              AND     NVL( END_DATE_ACTIVE  , gd_fiscal_date_from )
    AND   enabled_flag        = gc_enable_flag
    AND   language            = gc_language_code
    AND   source_lang         = gc_language_code
    AND   lookup_type         = gc_lookup_type_tax_rate
    ;
    IF ( ln_data_cnt = 0 ) THEN
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      lv_err_code := 'APP-XXPO-00005' ;
--      lv_err_code := 'APP-XXPO-10006' ;
      lv_err_code := 'APP-XXPO-10213' ;
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �Œ荀�ڂ̒��o
    -- ====================================================
    -- �m��t���O�擾
    BEGIN
      SELECT flv.lookup_code
      INTO   gv_fix_class
      FROM fnd_lookup_values flv
      WHERE gd_exec_date      BETWEEN NVL( flv.start_date_active, gd_exec_date )
                              AND     NVL( flv.end_date_active  , gd_exec_date )
      AND   flv.enabled_flag  = gc_enable_flag
      AND   flv.meaning       = gc_lookup_meaning_kakutei
      AND   flv.lookup_type   = gc_lookup_type_fix_class
      AND   flv.language      = gc_language_code
      AND   flv.source_lang   = gc_language_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code     := 'APP-XXCMN-10121' ;
        lv_token_name1  := 'LOOKUP_TYPE' ;
        lv_token_name2  := 'MEANING' ;
        lv_token_value1 := gc_lookup_type_fix_class  ;
        lv_token_value2 := gc_lookup_meaning_kakutei ;
    END ;
    IF ( lv_err_code IS NOT NULL ) THEN
      RAISE get_value_expt ;
    END IF ;
--
    -- �o�׎x���敪
    BEGIN
      SELECT flv.lookup_code
      INTO   gv_shikyu_class
      FROM fnd_lookup_values flv
      WHERE gd_exec_date      BETWEEN NVL( flv.start_date_active, gd_exec_date )
                              AND     NVL( flv.end_date_active  , gd_exec_date )
      AND   flv.enabled_flag  = gc_enable_flag
      AND   flv.meaning       = gc_lookup_meaning_shikyu_irai
      AND   flv.lookup_type   = gc_lookup_type_shikyu_class
      AND   flv.language      = gc_language_code
      AND   flv.source_lang   = gc_language_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code     := 'APP-XXCMN-10121' ;
        lv_token_name1  := 'LOOKUP_TYPE' ;
        lv_token_name2  := 'MEANING' ;
        lv_token_value1 := gc_lookup_type_shikyu_class  ;
        lv_token_value2 := gc_lookup_meaning_shikyu_irai ;
    END ;
    IF ( lv_err_code IS NOT NULL ) THEN
      RAISE get_value_expt ;
    END IF ;
--
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--
    -- ====================================================
    -- �v���t�@�C���擾
    -- ====================================================
    ------------------------------
    -- �i�ڃ}�X�^�g�D�h�c
    ------------------------------
    gn_prof_mst_org_id := FND_PROFILE.VALUE( gc_prof_mst_org_id ) ;
    IF ( gn_prof_mst_org_id IS NULL ) THEN
      lv_err_code     := 'APP-XXCMN-10002' ;
      lv_token_name1  := 'NG_PROFILE' ;
      lv_token_value1 := gc_prof_mst_org_id  ;
      RAISE get_value_expt ;
    END IF ;
--
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_po
                     ,iv_name           => lv_err_code
                     ,iv_token_name1    => lv_token_name1
                     ,iv_token_name2    => lv_token_name2
                     ,iv_token_value1   => lv_token_value1
                     ,iv_token_value2   => lv_token_value2
                    ) ;
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
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data
    (
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
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
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_main_data
      (
        in_vendor_code      xxwsh_order_headers_all.vendor_code%TYPE
       ,in_dept_code        xxwsh_order_headers_all.performance_management_dept%TYPE
      )
    IS
-- mod start ver1.6
--      SELECT xv.vendor_name     AS v_vendor_name    -- �����F����於��
      SELECT xoha.vendor_code   AS vendor_code      -- �����F�����R�[�h
            ,xv.vendor_name     AS v_vendor_name    -- �����F����於��
-- mod end ver1.6
            ,xv.zip             AS v_zip            -- �����F�X�֔ԍ�
            ,xv.address_line1   AS v_address_line1  -- �����F�Z���P
            ,xv.address_line2   AS v_address_line2  -- �����F�Z���Q
            ,xla.location_name  AS l_location_name  -- ���Ə��F���Ə�����
            ,xla.zip            AS l_zip            -- ���Ə��F�X�֔ԍ�
            ,xla.address_line1  AS l_address_line1  -- ���Ə��F�Z���P
            ,xla.phone          AS l_phone          -- ���Ə��F�d�b�ԍ�
            ,xla.fax            AS l_fax            -- ���Ə��F�e�`�w�ԍ�
            ,mcb.segment1                   AS item_class -- �i�ڋ敪
            ,xoha.arrival_date              AS arrival_date -- ���ד�
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
--            ,xoha.request_no                AS request_no   -- �˗�No�i�`�[�ԍ��j
            ,CASE otta.attribute11
               WHEN gc_ship_rcv_pay_ctg_yhe THEN xoha.request_no || '*'
               ELSE                              xoha.request_no
             END                AS request_no   -- �˗�No�i�`�[�ԍ��j
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
            ,xola.shipping_item_code        AS item_code    -- �i�ڃR�[�h
            ,ximb.item_short_name           AS item_name    -- �i�ږ���
            ,xola.unit_price                AS unit_price   -- �P��
            ,TO_NUMBER( flv.lookup_code )   AS tax_rate     -- ����ŗ�
-- add start ver1.6
            ,SUM(ROUND(CASE
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
             END * xola.unit_price))        AS amount       -- ���z
            ,SUM(ROUND(CASE
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
             END * xola.unit_price * TO_NUMBER( flv.lookup_code ) / 100)) AS tax -- �����
-- add start ver1.6
-- mod start ver1.6
--            ,CASE
            ,SUM(CASE
-- 2008/12/05 v1.5 T.Yoshimoto Mod Start �{��#446
              --WHEN ( otta.order_category_code = 'ORDER'  ) THEN xola.quantity
--              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xola.shipped_quantity
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
-- 2008/12/05 v1.5 T.Yoshimoto Mod End �{��#446
--              WHEN ( otta.order_category_code = 'RETURN' ) THEN xola.quantity * -1
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
--             END quantity                           -- �o�׎��ѐ���
             END) quantity                           -- �o�׎��ѐ���
-- mod end ver1.6
      FROM xxwsh_order_headers_all    xoha    -- �󒍃w�b�_�A�h�I��
          ,oe_transaction_types_all   otta    -- �󒍃^�C�v
          ,xxcmn_vendors              xv      -- �d����A�h�I��
          ,hr_locations_all           hla     -- ���Ə��}�X�^
          ,xxcmn_locations_all        xla     -- ���Ə��A�h�I��
          ,xxwsh_order_lines_all      xola    -- �󒍖��׃A�h�I��
-- add start ver1.6
          ,xxinv_mov_lot_details      xmld    -- �ړ����b�g�ڍ׃A�h�I��
-- add end ver1.6
          ,xxcmn_item_mst_b           ximb    -- �i�ڃA�h�I��
          ,gmi_item_categories        gic     -- �i�ڃJ�e�S������
          ,mtl_categories_b           mcb     -- �i�ڃJ�e�S��
          ,mtl_category_sets_b        mcsb    -- �i�ڃJ�e�S���Z�b�g
          ,mtl_category_sets_tl       mcst    -- �i�ڃJ�e�S���Z�b�g�i���{��j
          ,fnd_lookup_values          flv     -- �N�C�b�N�R�[�h�i����Łj
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
          ,ic_item_mst_b              iimb    -- �n�o�l�i�ڃ}�X�^
          ,mtl_system_items_b         msib    -- �h�m�u�i�ڃ}�X�^
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      WHERE mcsb.structure_id     = mcb.structure_id
      AND   gic.category_id       = mcb.category_id
      ---------------------------------------------------------------------------------------------
      -- �i�ڃJ�e�S���Z�b�g�̍i���ݏ���
      AND   mcst.category_set_name    = gc_cat_set_item_class
      AND   mcst.source_lang          = gc_language_code
      AND   mcst.language             = gc_language_code
      AND   mcsb.category_set_id      = mcst.category_set_id
      AND   gic.category_set_id       = mcsb.category_set_id
      AND   ximb.item_id              = gic.item_id
      ---------------------------------------------------------------------------------------------
      -- �N�C�b�N�R�[�h�i����Łj�̍i���ݏ���
      AND   xoha.arrival_date         BETWEEN NVL( flv.start_date_active, xoha.arrival_date )
                                      AND     NVL( flv.end_date_active  , xoha.arrival_date )
      AND   flv.language              = gc_language_code
      AND   flv.source_lang           = gc_language_code
      AND   flv.lookup_type           = gc_lookup_type_tax_rate
      ---------------------------------------------------------------------------------------------
      -- �i�ڃA�h�I���̍i���ݏ���
      AND   xoha.arrival_date         BETWEEN ximb.start_date_active  -- ���ד��ŗL���ȃf�[�^
                                      AND     ximb.end_date_active    -- 
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      AND   xola.shipping_inventory_item_id = ximb.item_id
      AND   iimb.item_id                    = ximb.item_id
      AND   msib.segment1                   = iimb.item_no
      AND   msib.organization_id            = gn_prof_mst_org_id
      AND   xola.shipping_inventory_item_id = msib.inventory_item_id
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      AND   xola.delete_flag          = 'N'
      AND   xoha.order_header_id      = xola.order_header_id
-- add start ver1.6
      AND   xola.order_line_id        = xmld.mov_line_id
      AND   xmld.document_type_code   = gc_doc_type_prov
      AND   xmld.record_type_code     = gc_rec_type_stck
-- add end ver1.6
      ---------------------------------------------------------------------------------------------
      -- ���Ə��A�h�I���̍i���ݏ���
      AND   xoha.arrival_date         BETWEEN xla.start_date_active     -- ���ד��ŗL���ȃf�[�^
                                      AND     xla.end_date_active       -- 
      AND   hla.location_id           = xla.location_id
-- 2009/03/04 v1.7 UPDATE START
--      AND   xoha.performance_management_dept
      AND xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID)
-- 2009/03/04 v1.7 UPDATE END
                                      = hla.location_code
      ---------------------------------------------------------------------------------------------
      -- �d����A�h�I���̍i���ݏ���
      AND   xoha.arrival_date         BETWEEN xv.start_date_active(+)   -- ���ד��ŗL���ȃf�[�^
                                      AND     xv.end_date_active(+)     -- 
      AND   xoha.vendor_id            = xv.vendor_id(+)
      ---------------------------------------------------------------------------------------------
      -- �󒍃^�C�v�̍i���ݏ���
      AND   otta.org_id               = gn_sales_class              -- �c�ƒP��    ��Profile
      AND   otta.attribute1           = gv_shikyu_class             -- �o�׎x���敪���x���˗�
      AND   xoha.order_type_id        = otta.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I���̍i���ݏ���
      AND   (  in_dept_code          IS NULL                        -- ���Ə����w��̎��Ə�
            OR xoha.performance_management_dept                     -- 
                                      = in_dept_code )              -- 
      AND   (  in_vendor_code        IS NULL                        -- ����恁�w��̎����
            OR xoha.vendor_code       = in_vendor_code )            -- 
      AND   xoha.amount_fix_class     = gv_fix_class                -- �L�����z�m��敪���m��
      AND   xoha.latest_external_flag = 'Y'                         -- �ŐV�t���O      ���ŐV
      AND   xoha.arrival_date         BETWEEN gd_fiscal_date_from   -- ���ד����Y�ؔN���Ɋ܂܂��
                                      AND     gd_fiscal_date_to     -- 
-- add start ver1.6
      GROUP BY xoha.vendor_code         -- �����F�����R�[�h
              ,xv.vendor_name           -- �����F����於��
              ,xv.zip                   -- �����F�X�֔ԍ�
              ,xv.address_line1         -- �����F�Z���P
              ,xv.address_line2         -- �����F�Z���Q
              ,xla.location_name        -- ���Ə��F���Ə�����
              ,xla.zip                  -- ���Ə��F�X�֔ԍ�
              ,xla.address_line1        -- ���Ə��F�Z���P
              ,xla.phone                -- ���Ə��F�d�b�ԍ�
              ,xla.fax                  -- ���Ə��F�e�`�w�ԍ�
              ,mcb.segment1             -- �i�ڋ敪
              ,xoha.arrival_date        -- ���ד�
              ,CASE otta.attribute11
                WHEN gc_ship_rcv_pay_ctg_yhe THEN xoha.request_no || '*'
                ELSE           xoha.request_no
               END                          -- �˗�No�i�`�[�ԍ��j
              ,xola.shipping_item_code      -- �i�ڃR�[�h
              ,ximb.item_short_name         -- �i�ږ���
              ,xola.unit_price              -- �P��
              ,TO_NUMBER( flv.lookup_code ) -- ����ŗ�
-- add end ver1.6
      ORDER BY xoha.vendor_code         -- �����R�[�h
              ,mcb.segment1             -- �i�ڋ敪
              ,xoha.arrival_date        -- ���ד�
              ,xola.shipping_item_code  -- �i�ڃR�[�h
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_main_data
      (
        ir_param.vendor_code    -- �����R�[�h
       ,ir_param.dept_code      -- �����Ǘ�����
      ) ;
    -- �o���N�t�F�b�`
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE cur_main_data ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
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
  PROCEDURE prc_create_xml_data
    (
      ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
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
    lc_break_init           VARCHAR2(100) := '*' ;  -- ����於
    lc_break_null           VARCHAR2(100) := '**' ;  -- �i�ڋ敪
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_vendor_name          VARCHAR2(100) := '*' ;  -- ����於
    lv_item_class           VARCHAR2(100) := '*' ;  -- �i�ڋ敪
--
    -- ���z�v�Z�p
    ln_amount               NUMBER := 0 ;         -- �v�Z�p�F���z
    ln_tax                  NUMBER := 0 ;         -- �v�Z�p�F�����
    ln_balance              NUMBER := 0 ;         -- �v�Z�p�F�L���z
    ln_ttl_amount           NUMBER := 0 ;         -- ����L�����z
    ln_ttl_tax              NUMBER := 0 ;         -- �������œ�
    ln_ttl_balance          NUMBER := 0 ;         -- ����L���z
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;           -- �擾���R�[�h�Ȃ�
--  
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
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
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �����k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vender_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- ����於�̃u���C�N
      -- =====================================================
      -- ����於�̂��؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).v_vendor_name, lc_break_null ) <> lv_vendor_name ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_class_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �W�v�l�o��
          ------------------------------
          -- ����L�����z
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_amount' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_amount ;
          -- �������œ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_tax' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_tax ;
          -- ����L���z
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_balance' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_balance ;
          ------------------------------
          -- �����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vender' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ����悪�擾�ł��Ȃ��ꍇ�A�X�e�[�^�X���x���ɐݒ�
        IF ( gt_main_data(i).v_vendor_name IS NULL ) THEN
          ov_retcode := gv_status_warn ;
        END IF ;

        -- -----------------------------------------------------
        -- �����f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vender' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �����f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���[�h�c
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
        -- ���{��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
--
        -- �����F�X�֔ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_zip_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_zip ;
        -- �����F�Z���P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line1 ;
        -- �����F�Z���Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line2 ;
        -- �����F����於�̂P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).v_vendor_name,  1, 20 ) ;
        -- �����F����於�̂Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).v_vendor_name, 21, 10 ) ;
--
        -- ����From
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'period_from' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_from_char ;
        -- ����To
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'period_to' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_to_char ;
        -- ���Ə��F�X�֔ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_zip_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_zip ;
        -- ���Ə��F�Z���P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).l_address_line1,  1, 15 ) ;
        -- ���Ə��F�Z���Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).l_address_line1, 16, 15 ) ;
        -- ���Ə��F�d�b�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_phone_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_phone ;
        -- ���Ə��F�e�`�w�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_fax_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_fax ;
        -- ���Ə��F���Ə�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- mod start ver1.6
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_location_name ;
        gt_xml_data_table(gl_xml_idx).tag_value 
                                     := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
-- mod end ver1.6
--
        ------------------------------
        -- ���ׂk�f�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_class_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_vendor_name  := NVL( gt_main_data(i).v_vendor_name, lc_break_null )  ;
        lv_item_class   := lc_break_init ;
        -- �W�v�ϐ��O�N���A
        ln_ttl_amount   := 0 ;  -- ����L�����z
        ln_ttl_tax      := 0 ;  -- �������œ�
        ln_ttl_balance  := 0 ;  -- ����L���z
--
      END IF ;
--
      -- =====================================================
      -- �i�ڋ敪�u���C�N
      -- =====================================================
      -- �i�ڋ敪���؂�ւ�����ꍇ
      IF ( gt_main_data(i).item_class <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- -----------------------------------------------------
        -- �i�ڋ敪�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_class' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �����f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �i�ڋ敪
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_class' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_class ;
        -- -----------------------------------------------------
        -- ���ׂk�f�J�n�^�O
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_class   := gt_main_data(i).item_class ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      -- -----------------------------------------------------
      -- �v�Z���ڂ̎Z�o
      -- -----------------------------------------------------
      -- �ʌv�Z����
-- mod start ver1.6
--      ln_amount   := ROUND( gt_main_data(i).quantity * gt_main_data(i).unit_price ) ;
--      ln_tax      := ROUND( ln_amount * gt_main_data(i).tax_rate / 100 ) ;
      ln_amount   := gt_main_data(i).amount;
      ln_tax      := gt_main_data(i).tax;
-- mod end ver1.6
-- 2008/06/20 v1.3 Y.Yamamoto Update Start
--      ln_balance  := ln_amount - ln_tax ;
      ln_balance  := ln_amount + ln_tax ;
-- 2008/06/20 v1.3 Y.Yamamoto Update End
--
      -- �W�v����
      ln_ttl_amount  := ln_ttl_amount  + ln_amount ;  -- ����L�����z
      ln_ttl_tax     := ln_ttl_tax     + ln_tax ;     -- �������œ�
      ln_ttl_balance := ln_ttl_balance + ln_balance ; -- ����L���z
--
      -- -----------------------------------------------------
      -- ���ׂf�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- ���ד�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value
            := TO_CHAR( gt_main_data(i).arrival_date, gc_char_d_format ) ;
      -- �`�[�ԍ�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'slip_num' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).request_no ;
      -- �i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_code ;
      -- �i�ږ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_name ;
      -- �o�׎��ѐ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).quantity ;
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).unit_price ;
      -- ���z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_amount ;
      -- -----------------------------------------------------
      -- ���ׂf�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- ���ׂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_class_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �W�v�l�o��
    ------------------------------
    -- ����L�����z
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_amount' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_amount ;
    -- �������œ�
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_tax' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_tax ;
    -- ����L���z
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_balance' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_balance ;
    ------------------------------
    -- �����f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vender' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vender_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_fiscal_ym          IN     VARCHAR2         --   01 : �Y�ؔN��
     ,iv_dept_code          IN     VARCHAR2         --   02 : �����Ǘ�����
     ,iv_vendor_code        IN     VARCHAR2         --   03 : �����
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
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
    -- ���[�o�͒l�i�[
    gv_report_id              := 'XXPO780001T' ;      -- ���[ID
    gd_exec_date              := SYSDATE ;            -- ���{��
    -- �p�����[�^�i�[
    lr_param_rec.fiscal_ym    := iv_fiscal_ym ;       -- �Y�ؔN��
    lr_param_rec.dept_code    := iv_dept_code ;       -- �����Ǘ�����
    lr_param_rec.vendor_code  := iv_vendor_code ;     -- �����
--
    -- =====================================================
    -- �p�����[�^�`�F�b�N
    -- =====================================================
    prc_check_param_info
      (
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize
      (
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
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
    prc_create_xml_data
      (
        ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
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

    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_vender_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_vender>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_item_class_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_item_class>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_item_class>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_item_class_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_vender>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_vender_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_fiscal_ym          IN     VARCHAR2         --   01 : �Y�ؔN��
     ,iv_dept_code          IN     VARCHAR2         --   02 : �����Ǘ�����
     ,iv_vendor_code        IN     VARCHAR2         --   03 : �����
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
    submain
      (
        iv_fiscal_ym      => iv_fiscal_ym       --   01 : �Y�ؔN��
       ,iv_dept_code      => iv_dept_code       --   02 : �����Ǘ�����
       ,iv_vendor_code    => iv_vendor_code     --   03 : �����
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
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
END xxpo780001c ;
/