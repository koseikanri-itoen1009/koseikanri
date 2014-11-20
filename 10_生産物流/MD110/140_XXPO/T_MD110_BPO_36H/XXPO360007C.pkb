CREATE OR REPLACE PACKAGE BODY xxpo360007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360007C(body)
 * Description      : ���o�ɍ��ٕ\
 * MD.050/070       : �d���i���[�jIssue2.0 (T_MD050_BPO_360)
 *                    �d���i���[�jIssue2.0 (T_MD070_BPO_36H)
 * Version          : 1.11
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_get_sai_code          PROCEDURE : ���كR�[�h���擾����B
 *  prc_initialize            PROCEDURE : �O����(H-1)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(H-2)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/03    1.0   N.Chinen         �V�K�쐬
 *  2008/05/19    1.1   Y.Ishikawa       �O�����[�U�[���Ɍx���I���ɂȂ�
 *  2008/05/20    1.2   Y.Majikina       �Z�L�����e�B�O���q�ɂ̕s��Ή�
 *  2008/05/22    1.3   Y.Ishikawa       ���̓p�����[�^���كR�[�h��NULL�̏ꍇ�S�f�[�^�Ώۂɂ���B
 *  2008/05/22    1.4   Y.Ishikawa       �i�ڃR�[�h�̕\���s���C��
 *                                       �w�����𐔗ʁ���������(DFF11)�ɕύX
 *  2008/06/10    1.5   Y.Ishikawa       ���b�g�}�X�^�ɓ������b�gNo�����݂���ꍇ�A
 *                                       2���׏o�͂����
 *  2008/06/17    1.6   I.Higa           xxpo_categories_v���g�p���Ȃ��悤�ɂ���
 *  2008/06/24    1.7   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/04    1.8   Y.Ishikawa       xxcmn_item_categories4_v���g�p���Ȃ��悤�ɂ���
 *  2008/11/21    1.9   T.Yoshimoto      �����w�E#703
 *  2009/03/30    1.10  A.Shiina         �{��#1346�Ή�
 *  2009/09/24    1.11  T.Yoshimoto      �{��#1523�Ή�
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXPO360007C' ;   -- �p�b�P�[�W��
  gv_print_name             CONSTANT VARCHAR2(20) := '���ɗ\��\' ;   -- ���[��
--
  ------------------------------
  -- ���ً敪
  ------------------------------
  gv_diff_lookup_type CONSTANT VARCHAR2(20) := 'XXPO_DIFF_REASON';
  gc_sai_syutunyuumi  CONSTANT VARCHAR2(1)  := '1';
  gc_sai_syutumi      CONSTANT VARCHAR2(1)  := '2';
  gc_sai_nyuumi       CONSTANT VARCHAR2(1)  := '3';
  gc_sai_saiari       CONSTANT VARCHAR2(1)  := '4';
  gc_sai_all          CONSTANT VARCHAR2(1)  := '5';
--
  ------------------------------
  -- ���ً敪�擾�p�萔
  ------------------------------
  gc_true CONSTANT VARCHAR2(1) := 'Y';
  gv_jpn  CONSTANT VARCHAR2(2) := 'JA';
--
  ------------------------------
  -- �Z�L�����e�B�敪
  ------------------------------
  gc_seqrt_class_itoen      CONSTANT VARCHAR2(1) := '1';     -- �ɓ���
  gc_seqrt_class_vender     CONSTANT VARCHAR2(1) := '2';     -- �����i�����ҁj
  gc_seqrt_class_outside    CONSTANT VARCHAR2(1) := '4';     -- �O���q��
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_goods_class        CONSTANT VARCHAR2(100) := '���i�敪' ;
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
  gv_language                   CONSTANT VARCHAR2(3)   := 'JA';             -- ����
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- �A�v���P�[�V����
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;           -- �A�v���P�[�V�����iXXPO�j
--
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '�L���x���Z�L�����e�BVIEW' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := '���[�U�[ID' ;
  gv_vendor_view          CONSTANT VARCHAR2(20) := '�d������VIEW' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- ���b�g�Ǘ��敪
  gv_lot_n_div            CONSTANT VARCHAR2(1) := '0'; -- ���b�g�Ǘ��Ȃ�
--
  -- ���b�g�f�t�H���g��
  gv_lot_default         CONSTANT ic_lots_mst.lot_no%TYPE  := 'DEFAULTLOT'; --�f�t�H���g���b�g��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
      sai_cd           VARCHAR2(1)                          -- ���َ��R
     ,subinv_code      po_headers_all.attribute5%TYPE       -- �ۊǏꏊ�R�[�h
     ,goods_class      mtl_categories_b.segment1%TYPE       -- ���i�敪
     ,item_class       mtl_categories_b.segment1%TYPE       -- �i�ڋ敪
     ,dlv_from         VARCHAR2(10)                         -- �[�i���i�e�q�n�l�j
     ,dlv_to           VARCHAR2(10)                         -- �[�i���i�s�n�j
     ,ship_code_from   po_vendors.segment1%TYPE             -- �o�Ɍ�
     ,order_num        VARCHAR2(100)                        -- �����ԍ�
     ,item_code        ic_item_mst_b.item_no%TYPE           -- �i�ڃR�[�h
     ,position         xxcmn_locations_v.location_code%TYPE -- �S������
     ,seqrt_class      VARCHAR2(1)                          -- �Z�L�����e�B�敪
    );
--
  -- ���ɗ\��\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
      h_vendor_code         xxcmn_item_locations_v.segment1%TYPE           -- ���o��:���ɑq�ɃR�[�h
     ,h_vendor_name         xxcmn_item_locations_v.description%TYPE         -- ���o��:���ɑq�ɖ�
     ,h_deliver_date        po_headers_all.attribute4%TYPE                  -- �[����
     ,h_goods_code          xxpo_categories_v.category_code%TYPE            -- ���o��:���i�敪
     ,h_goods_name          xxpo_categories_v.category_description%TYPE     -- ���o��:���i��
     ,h_item_code           xxpo_categories_v.category_code%TYPE            -- ���o��:�i�ڋ敪
     ,h_item_name           xxpo_categories_v.category_description%TYPE     -- ���o��:�i�ږ�
     ,vendor_code           xxcmn_vendors_v.segment1%TYPE                   -- �o�Ɍ��R�[�h
     ,vendor_name           xxcmn_vendors_v.vendor_short_name%TYPE          -- �o�Ɍ���
     ,po_no                 xxpo_requisition_headers.po_header_number%type  -- �����ԍ�
     ,item_code             xxcmn_item_mst_v.item_no%type                   -- �i�ڃR�[�h
     ,item_name             xxcmn_item_mst_v.item_short_name%type           -- �i�ږ���
     ,add_code              po_lines_all.attribute3%type                    -- �t�уR�[�h
     ,lot_no                ic_lots_mst.lot_no%type                         -- ���b�gno
     ,make_date             ic_lots_mst.attribute1%type                     -- ������
     ,period_date           ic_lots_mst.attribute3%type                     -- �ܖ�����
     ,prop_mark             xxcmn_lookup_values_v.meaning%type              -- �ŗL�L��
     ,inv_qty               po_lines_all.quantity%type                      -- �w����
     ,ship_qty              po_lines_all.attribute6%type                    -- �o�ɐ�
     ,stock_qty             po_lines_all.attribute7%type                    -- ���ɐ�
     ,sai_qty               VARCHAR2(16)                                    -- ���ِ�
     ,order_qty             po_lines_all.attribute11%type              -- ���كR�[�h�擾�p:��������
  );
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
--
  -- �O���q��
  TYPE subinv_code_type IS TABLE OF
    xxpo_security_supply_v.segment1%TYPE INDEX BY BINARY_INTEGER; -- �ۊǑq�ɃR�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;            -- �c�ƒP��
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- �S����
  gv_user_vender            xxpo_per_all_people_f_v.attribute4%TYPE;          -- �d����R�[�h
  gv_user_vender_site       xxpo_per_all_people_f_v.attribute6%TYPE;          -- �d����T�C�g�R�[�h
  gn_user_vender_id         po_vendors.vendor_id%TYPE;                        -- �d����ID
  gv_diff_reason_name       fnd_lookup_values.meaning%TYPE;                   -- ���َ��R��
  gv_subinv_code            subinv_code_type;                          -- �ۊǑq�ɃR�[�h
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- ���[ID
  gd_exec_date              DATE         ;    -- ���{��
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER DEFAULT 0 ;        -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
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
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(whse_code)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_subinv_code IN subinv_code_type
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
    <<subinv_code_loop>>
    FOR ln_cnt IN 1..itbl_subinv_code.COUNT LOOP
      lv_in := lv_in || '''' || itbl_subinv_code(ln_cnt) || ''',';
    END LOOP subinv_code_loop;
--
    RETURN(
      SUBSTR(lv_in,1,LENGTH(lv_in) - 1));
--
  END fnc_get_in_statement;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_sai_code
   * Description      : �u�S�āv�Ŏ擾�������كR�[�h�A���َ��R�����擾����B
   ***********************************************************************************/
  PROCEDURE prc_get_sai_code(
      it_data_rec   IN  tab_data_type_dtl  -- 01.�擾���R�[�h�Q
     ,in_count      IN  NUMBER
     ,on_sai_code   OUT NUMBER
     ,ov_sai_reason OUT VARCHAR2
    )
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_sai_code' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_ship_qty         po_lines_all.attribute6%type;
    lv_stock_qty        po_lines_all.attribute7%type;
    lv_order_qty        po_lines_all.attribute11%type;
--
  BEGIN
--
    lv_ship_qty := it_data_rec(in_count).ship_qty;
    lv_stock_qty := it_data_rec(in_count).stock_qty;
    lv_order_qty := it_data_rec(in_count).order_qty;
--
    -- �u�o�����v�̏ꍇ
    IF (    (lv_ship_qty IS NULL)
        AND (lv_stock_qty IS NULL)) THEN
      on_sai_code := gc_sai_syutunyuumi;
    END IF;
    -- �u�o���v�̏ꍇ
    IF (    (lv_ship_qty IS NULL)
        AND (lv_stock_qty >= 0)) THEN
      on_sai_code := gc_sai_syutumi;
    END IF;
    -- �u�����v�̏ꍇ
    IF (    (lv_ship_qty >= 0)
        AND (lv_stock_qty IS NULL)) THEN
      on_sai_code := gc_sai_nyuumi;
    END IF;
    -- �u���ٗL�v�̏ꍇ
    IF (    (lv_ship_qty IS NOT NULL)
        AND (lv_stock_qty IS NOT NULL)
        AND (   (lv_order_qty - lv_ship_qty != 0)
             OR (lv_order_qty - lv_stock_qty != 0))) THEN
      on_sai_code := gc_sai_saiari;
    END IF;
--
    -- ���َ��R���擾
    BEGIN
      SELECT flv.meaning
      INTO   ov_sai_reason
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type = gv_diff_lookup_type
      AND    flv.enabled_flag = gc_true
      AND    flv.language = USERENV('LANG')
      AND    flv.source_lang = USERENV('LANG')
      AND    (   (flv.start_date_active IS NULL)
              OR (gd_exec_date >= flv.start_date_active))
      AND    (   (flv.end_date_active IS NULL)
              OR (gd_exec_date <= flv.end_date_active))
      AND    flv.lookup_code = on_sai_code;
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  END prc_get_sai_code ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(H-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
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
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
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
    -- �c�ƒP�ʎ擾
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( 'ORG_ID' ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-00005' ) ;
      lv_retcode  := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
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
    -- ���َ��R���擾
    -- ====================================================
    IF ((ir_param.sai_cd IS NOT NULL ) AND (ir_param.sai_cd <> gc_sai_all)) THEN
      SELECT flv.meaning
      INTO   gv_diff_reason_name
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type = gv_diff_lookup_type
      AND    flv.enabled_flag = gc_true
      AND    flv.language = USERENV('LANG')
      AND    flv.source_lang = USERENV('LANG')
      AND    (   (flv.start_date_active IS NULL)
              OR (gd_exec_date >= flv.start_date_active))
      AND    (   (flv.end_date_active IS NULL)
              OR (gd_exec_date <= flv.end_date_active))
      AND    flv.lookup_code = ir_param.sai_cd;
    END IF;
--
    IF ( ir_param.seqrt_class = gc_seqrt_class_outside ) THEN
      -- ====================================================
      -- �ۊǑq�ɃR�[�h�擾(�����̏ꍇ�L)
      -- ====================================================
      BEGIN
        SELECT xssv.segment1
          BULK COLLECT INTO gv_subinv_code
        FROM  xxpo_security_supply_v xssv
        WHERE xssv.user_id        = gn_user_id
          AND xssv.security_class = ir_param.seqrt_class;
--
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                                ,'APP-XXCMN-10001'
                                                ,'TABLE'
                                                ,gv_seqrt_view
                                                ,'KEY'
                                                ,gv_seqrt_view_key  ) ;
          lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
    ELSE
      -- ====================================================
      -- �d����R�[�h�E�d����T�C�g�R�[�h�擾
      -- ====================================================
      BEGIN
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
          AND xssv.security_class = ir_param.seqrt_class
          AND FND_DATE.STRING_TO_DATE( ir_param.dlv_from, gc_char_d_format )
              BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+) ;
--
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                                ,'APP-XXCMN-10001'
                                                ,'TABLE'
                                                ,gv_seqrt_view
                                                ,'KEY'
                                                ,gv_seqrt_view_key  ) ;
          lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
    END IF;
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
   * Description      : ���׃f�[�^�擾(H-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
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
    cv_item_class       CONSTANT VARCHAR2( 1) := '5';          -- �i�ڋ敪�i���i�j
    cv_pln_cancel_flag  CONSTANT VARCHAR2( 1) := 'Y';          -- ����t���O�i����j
    cv_poh_status       CONSTANT VARCHAR2(10) := 'APPROVED';   -- �����X�e�[�^�X�i���F�ς݁j
    cv_poh_make         CONSTANT VARCHAR2( 2) := '20';         -- ������޵ݽð��(�����쐬��)
    cv_poh_cancel       CONSTANT VARCHAR2( 2) := '99';         -- ������޵ݽð��(���)
--
    -- *** ���[�J���E�ϐ� ***
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
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
    lv_select := ' SELECT '
              || ' itmv.segment1                AS h_vendor_code'   -- �w�b�_�F���ɑq�ɃR�[�h
              || ',itmv.description             AS h_vendor_name'   -- �w�b�_�F���ɑq�ɖ�
              || ',substr(poh.attribute4, 6, 5) AS h_deliver_date'  -- �w�b�_�F�[���\���
              || ',ctgg.category_code           AS h_goods_code'  -- �w�b�_�F�J�e�S���R�[�h�i���i�j
              || ',ctgg.category_description    AS h_goods_name'    -- �w�b�_�F�J�e�S���E�v�i���i�j
              || ',ctgi.category_code           AS h_item_code'   -- �w�b�_�F�J�e�S���R�[�h�i�i�ځj
              || ',ctgi.category_description    AS h_item_name'     -- �w�b�_�F�J�e�S���E�v�i�i�ځj
              || ',vnd.segment1                   AS vendor_code'      -- �o�ɑq�ɃR�[�h
              || ',vnd.vendor_short_name          AS vendor_name'      -- �o�ɑq�ɖ�
              || ',poh.segment1                   AS po_no'            -- �����ԍ�
              || ',itm.item_no                    AS item_code'        -- �i�ڃR�[�h
              || ',itm.item_short_name            AS item_name'        -- �i�ږ�
              || ',pln.attribute3                 AS add_code'         -- �t�уR�[�h
              || ',DECODE(itm.lot_ctl,'           || gv_lot_n_div
              || '  ,NULL,lot.lot_no)             AS lot_no'          -- ���b�g�m��
              || ',lot.attribute1                 AS make_date'        -- �����N����
              || ',lot.attribute3                 AS period_date'      -- �ܖ�����
              || ',lot.attribute2                 AS prop_mark'        -- �ŗL�L��
              || ',pln.QUANTITY                   AS inv_qty'          -- �݌ɓ���
              || ',pln.ATTRIBUTE6                 as ship_qty'         -- �o�ɐ�
              || ',pln.ATTRIBUTE7                 as stock_qty'        -- ���ɐ�
-- 2008/11/21 v1.9 T.Yoshimoto Mod Start
--              || ',NVL(pln.quantity, 0) - NVL(pln.attribute7, 0)  as sai_qty'   -- ���ِ�
              || ',NVL(pln.attribute11, 0) - NVL(pln.attribute7, 0)  as sai_qty'   -- ���ِ�
-- 2008/11/21 v1.9 T.Yoshimoto Mod End
              || ',pln.attribute11                as order_qty'        -- ���كR�[�h�擾�p:��������
              ;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_from := ' FROM '
            || ' po_headers_all                poh'     -- �����w�b�_
            || ',po_lines_all                  pln'     -- ��������
            || ',ic_lots_mst                   lot'     -- OPM���b�g�}�X�^
            || ',xxcmn_vendors2_v              vnd'     -- �d������VIEW
            || ',xxcmn_item_mst2_v             itm'     -- OPM�i�ڏ��VIEW
            || ',xxcmn_item_locations2_v       itmv'    -- OPM�ۊǏꏊ���VIEW
             -- XXPO�J�e�S�����VIEW�i���i�j
            || ' ,(SELECT gic.item_id AS item_id '
            || ' ,mcb.segment1  AS category_code '
            || ' ,mct.description  AS category_description'
            || '  FROM   gmi_item_categories    gic, '
            || ' mtl_category_sets_tl  mcst, '
            || ' mtl_category_sets_b   mcsb, '
            || ' mtl_categories_b      mcb, '
            || ' mtl_categories_tl     mct '
            || ' WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || ' AND    mcst.language          = ''' || gv_language || ''''
            || ' AND    mcsb.structure_id      = mcb.structure_id '
            || ' AND    mcb.category_id        = mct.category_id '
            || ' AND    gic.category_id        = mcb.category_id'
            || ' AND    gic.category_set_id    = mcsb.category_set_id'
            || ' AND    mct.language           = ''' || gv_language || ''''
            || ' AND    mcst.category_set_name = ''' || gc_cat_set_goods_class || '''' || ') ctgg '
             -- XXPO�J�e�S�����VIEW�i�i�ځj
            || ' ,(SELECT gic.item_id AS item_id '
            || ' ,mcb.segment1  AS category_code '
            || ' ,mct.description  AS category_description'
            || '  FROM   gmi_item_categories    gic, '
            || ' mtl_category_sets_tl  mcst, '
            || ' mtl_category_sets_b   mcsb, '
            || ' mtl_categories_b      mcb, '
            || ' mtl_categories_tl     mct '
            || ' WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || ' AND    mcst.language          = ''' || gv_language || ''''
            || ' AND    mcsb.structure_id      = mcb.structure_id '
            || ' AND    mcb.category_id        = mct.category_id '
            || ' AND    gic.category_id        = mcb.category_id'
            || ' AND    gic.category_set_id    = mcsb.category_set_id'
            || ' AND    mct.language           = ''' || gv_language || ''''
            || ' AND    mcst.category_set_name = ''' || gc_cat_set_item_class || '''' || ') ctgi '
            ;
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_where := ' WHERE '
             || '     poh.org_id               = ' || gn_sales_class
             || ' AND poh.po_header_id         = pln.po_header_id'
-- 2009/09/24 v1.11 T.Yoshimoto Del Start �{��#1523
             --|| ' AND poh.authorization_status = ''' || cv_poh_status  || ''''
-- 2009/09/24 v1.11 T.Yoshimoto Del End �{��#1523
             || ' AND poh.attribute1          >= ''' || cv_poh_make    || ''''
             || ' AND poh.attribute1           < ''' || cv_poh_cancel  || ''''
             || ' AND pln.cancel_flag         <> ''' || cv_pln_cancel_flag   || ''''
             || ' AND poh.attribute4          >= ''' || ir_param.dlv_from    || ''''
-- 2009/03/30 v1.11 ADD START
             || ' AND poh.org_id               = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.11 ADD END
             ;
--
    -- ���ɑq�ɂ����͂���Ă���ꍇ
    IF (ir_param.subinv_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute5           = ''' || ir_param.subinv_code || ''''
               ;
    END IF;
--
    -- �����ԍ������͂���Ă���ꍇ
    IF (ir_param.order_num IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.segment1 = ''' || ir_param.order_num || ''''
               ;
    END IF;
--
    -- �S�����������͂���Ă���ꍇ
    IF (ir_param.position IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.ATTRIBUTE10 = ''' || ir_param.position || ''''
               ;
    END IF;
--
    -- �[�����s�n�����͂���Ă���ꍇ
    IF (ir_param.dlv_to IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute4      <= ''' || ir_param.dlv_to || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- ���b�g���i�ڂ̍i���ݏ���
    lv_where := lv_where
             || ' AND pln.item_id            = itm.inventory_item_id'
             || ' AND itm.item_id            = lot.item_id'
             || ' AND DECODE(itm.lot_ctl,' || gv_lot_n_div   || ','''
                                           || gv_lot_default || ''''
                                           || ',pln.attribute1) = lot.lot_no '
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN itm.start_date_active AND itm.end_date_active'
             ;
    -- �i�ڂ����͂���Ă���ꍇ
    IF (ir_param.item_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND itm.item_no          = ''' || ir_param.item_code || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �i�ڃJ�e�S���i���i�敪�j�̍i���ݏ���
    lv_where := lv_where
             || ' AND itm.item_id                          = ctgg.item_id'
             ;
    -- ���i�敪�����͂���Ă���ꍇ
    IF (ir_param.goods_class IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND ctgg.category_code   = ''' || ir_param.goods_class || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �i�ڃJ�e�S���i�i�ڋ敪�j�̍i���ݏ���
    lv_where := lv_where
             || ' AND itm.item_id                          = ctgi.item_id'
             ;
    -- �i�ڋ敪�����͂���Ă���ꍇ
    IF (ir_param.item_class IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND ctgi.category_code   = ''' || ir_param.item_class || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �o�Ɍ��̍i���ݏ���
    lv_where := lv_where
             || ' AND poh.vendor_id          = vnd.vendor_id'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN vnd.start_date_active AND vnd.end_date_active'
             ;
    -- �o�Ɍ������͂���Ă���ꍇ
    IF (ir_param.ship_code_from IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND vnd.segment1         = ''' || ir_param.ship_code_from || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- ���ɑq�ɂ̍i���ݏ���
    lv_where := lv_where
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_from || ''','''
                                                  || gc_char_d_format  || ''') >= itmv.date_from'
             || ' AND (   ( itmv.date_to IS NULL)'
             || '      OR (    (itmv.date_to IS NOT NULL)'
             || '          AND (itmv.date_to >= FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_from
                                                  || ''',''' || gc_char_d_format  || '''))))'
             || ' AND itmv.disable_date IS NULL'
             || ' AND poh.attribute5    = itmv.segment1'
             ;
    ---------------------------------------------------------------------------------------------
    -- ���َ��R�̍i���ݏ���
    -- �u�o�����v�̏ꍇ
    IF (ir_param.sai_cd = gc_sai_syutunyuumi) THEN
      lv_where := lv_where
               || ' AND pln.attribute6 IS NULL '
               || ' AND pln.attribute7 IS NULL '
               ;
    END IF;
--
    -- �u�o�v�̏ꍇ
    IF (ir_param.sai_cd = gc_sai_syutumi) THEN
      lv_where := lv_where
               || ' AND pln.attribute6 IS NULL '
               || ' AND pln.attribute7 >= 0 '
               ;
    END IF;
--
    -- �u�����v�̏ꍇ
    IF (ir_param.sai_cd =   gc_sai_nyuumi) THEN
      lv_where := lv_where
               || ' AND pln.attribute6 >= 0 '
               || ' AND pln.attribute7 IS NULL '
               ;
    END IF;
--
    -- �u���ٗL�v�̏ꍇ
    IF (ir_param.sai_cd =   gc_sai_saiari) THEN
      lv_where := lv_where
               || ' AND pln.attribute6 IS NOT NULL '
               || ' AND pln.attribute7 IS NOT NULL '
               || ' AND (   pln.attribute11 - pln.attribute6 != 0 '
               || '      OR pln.attribute11 - pln.attribute7 != 0 ) '
               ;
    END IF;
--
    -- �u�S�āv�̏ꍇ
    -- ��L�̃f�[�^�S�Ă𒊏o
    IF (ir_param.sai_cd =   gc_sai_all) THEN
      lv_where := lv_where
               || ' AND (   (    pln.attribute6 IS NULL '
               || '          AND pln.attribute7 IS NULL ) '
               || '      OR (    pln.attribute6 IS NULL '
               || '          AND pln.attribute7 >= 0 ) '
               || '      OR (    pln.attribute6 >= 0 '
               || '          AND pln.attribute7 IS NULL ) '
               || '      OR (    pln.attribute6 IS NOT NULL '
               || '          AND pln.attribute7 IS NOT NULL '
               || '          AND (   (pln.attribute11 - pln.attribute6 != 0) '
               || '               OR (pln.attribute11 - pln.attribute7 != 0)))) '
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.seqrt_class = gc_seqrt_class_vender) THEN
      lv_where := lv_where
               || ' AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
               ;
      -- ���O�C�����[�U�[�̎d����ID��NULL�̏ꍇ�A����.�d����Ƃ̃`�F�b�N���s��Ȃ�
      IF (gn_user_vender_id IS NULL) THEN
        lv_where := lv_where
                 || '      OR ((poh.vendor_id IS NULL)'
                 ;
      ELSE
        lv_where := lv_where
                 || '      OR ((poh.vendor_id = ' || gn_user_vender_id || ')'
                 ;
      END IF;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND NOT EXISTS(SELECT po_line_id '
                 || '                FROM   po_lines_all pl_sub '
                 || '                WHERE  pl_sub.po_header_id = poh.po_header_id '
                 || '                AND    NVL(pl_sub.attribute2, ''*'') <> '''
                                            || gv_user_vender_site || ''''
                 || '                ) '
                 ;
      END IF;
      lv_where := lv_where
               || '))'
               ;
    END IF;
    -- �u�O���q�Ɂv�̏ꍇ
    IF (ir_param.seqrt_class = gc_seqrt_class_outside) THEN
      IF ( gv_subinv_code.COUNT = 1 ) THEN
        lv_where := lv_where
          || ' AND itmv.segment1 = ''' || gv_subinv_code(1) || '''';
      ELSIF ( gv_subinv_code.COUNT > 1 ) THEN
        lv_where := lv_where
          || ' AND itmv.segment1 IN(' || fnc_get_in_statement(gv_subinv_code) || ')';
      END IF;
    END IF;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY'
                || ' itmv.segment1'          -- �w�b�_�F���ɑq�ɃR�[�h
                || ',ctgg.category_code'     -- �w�b�_�F�J�e�S���R�[�h�i���i�j
                || ',ctgi.category_code'     -- �w�b�_�F�J�e�S���R�[�h�i�i�ځj
                || ',poh.attribute4'         -- �w�b�_�F�[���\���
                || ',vnd.segment1'           -- �o�Ɍ��R�[�h
                || ',poh.segment1'           -- �����ԍ�
                || ',itm.item_no'            -- �i�ڃR�[�h
                || ',pln.attribute3'         -- �t�уR�[�h
                ;
    -- �i�ڋ敪���u���i�v�̏ꍇ�A�����N����||�ŗL�L���Ń\�[�g
    IF ir_param.item_class = cv_item_class THEN
      lv_order_by := lv_order_by
                  || ',lot.attribute1||lot.attribute2'
                  ;
    ELSE
      lv_order_by := lv_order_by
                  || ',lot.lot_no'
                  ;
    END IF;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_order_by ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
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
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
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
    lc_break_init           VARCHAR2(100) DEFAULT '*' ;            -- �����l
    lc_break_null           VARCHAR2(100) DEFAULT '**' ;           -- �m�t�k�k����
--
    -- ���t�N�����擾Format
    lc_dlv_y                VARCHAR2(4) DEFAULT 'YYYY' ;           -- �N�擾
    lc_dlv_m                VARCHAR2(2) DEFAULT 'MM' ;             -- ���擾
    lc_dlv_d                VARCHAR2(2) DEFAULT 'DD' ;             -- ���擾
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_vendor_name          VARCHAR2(100) DEFAULT lc_break_init ;  -- ����於
    lv_goods_class          VARCHAR2(100) DEFAULT lc_break_init ;  -- ���i�敪
    lv_item_class           VARCHAR2(100) DEFAULT lc_break_init ;  -- �i�ڋ敪
    lv_deliver_date         VARCHAR2(100) DEFAULT lc_break_init ;  -- �[����
    lv_item_code            VARCHAR2(100) DEFAULT lc_break_init ;  -- �i�ڃR�[�h
    lv_futai                VARCHAR2(100) DEFAULT lc_break_init ;  -- �t��
    lv_ship_from_code       VARCHAR2(100) DEFAULT lc_break_init ;  -- �o�Ɍ�
    lv_po_no                VARCHAR2(100) DEFAULT lc_break_init ;  -- �����m��
    lv_sai_code             VARCHAR2(100);
    lv_sai_reason           VARCHAR2(100);
--
    -- �v�Z�p
    ln_position             NUMBER        DEFAULT 0 ;              -- �v�Z�p�F�|�W�V����
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data(
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
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
--
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
    -- �S������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_user_dept, 1, 10) ;
    -- �S���Җ�
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_user_name, 1, 14) ;
    -- -----------------------------------------------------
    -- �[�����f FROM�N�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- �[����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_year' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_from,gc_char_dt_format) ,lc_dlv_y);
    -- -----------------------------------------------------
    -- �[�����f FROM���f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- �[����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_month' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_from,gc_char_dt_format) ,lc_dlv_m);
    -- -----------------------------------------------------
    -- �[�����f FROM���f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- �[����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_from,gc_char_dt_format) ,lc_dlv_d);
    -- -----------------------------------------------------
    -- �[�����f TO�N�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- �[����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_year' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_to,gc_char_dt_format) ,lc_dlv_y);
    -- -----------------------------------------------------
    -- �[�����f TO���f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- �[����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_month' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_to,gc_char_dt_format) ,lc_dlv_m);
    -- -----------------------------------------------------
    -- �[�����f TO���f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- �[����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_to,gc_char_dt_format) ,lc_dlv_d);
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
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
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_locat' ;
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
      IF ( NVL( gt_main_data(i).h_vendor_name, lc_break_null ) <> lv_vendor_name ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_vendor_name <> lc_break_init ) THEN
          ------------------------------
          -- �o�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �����f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_locat' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �����f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���ɑq�ɁF�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_vendor_code ;
        -- ���ɑq�ɁF����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gt_main_data(i).h_vendor_name, 1, 20 );
        ------------------------------
        -- ���i�敪�k�f�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_vendor_name  := NVL( gt_main_data(i).h_vendor_name, lc_break_null )  ;
        lv_goods_class  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ���i�敪�u���C�N
      -- =====================================================
      -- ���i�悪�؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).h_goods_code, lc_break_null ) <> lv_goods_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_goods_class <> lc_break_init ) THEN
          ------------------------------
          -- �o�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        ------------------------------
        -- ���i�敪�f�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���i�敪�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���i�敪�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_goods_code ;
        -- ���i�敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gt_main_data(i).h_goods_name, 1, 30 ) ;
        -- -----------------------------------------------------
        -- �i�ڋ敪�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_goods_class  := NVL( gt_main_data(i).h_goods_code, lc_break_null )  ;
        lv_item_class   := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- �i�ڋ敪�u���C�N
      -- =====================================================
      -- �i�ڋ敪���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- �o�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �i�ڋ敪�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �i�ڋ敪�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �i�ڋ敪�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_item_code ;
        -- �i�ڋ敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gt_main_data(i).h_item_name, 1, 30 ) ;
        -- -----------------------------------------------------
        -- �i�ڂk�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_class   := NVL( gt_main_data(i).h_item_code, lc_break_null )  ;
        lv_deliver_date := lc_break_init;
--
      END IF ;
--
      -- =====================================================
      -- �[�����u���C�N
      -- =====================================================
      -- �[�������؂�ւ�����ꍇ
      IF ( NVL( TO_CHAR(gt_main_data(i).h_deliver_date), lc_break_null ) <> lv_deliver_date ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_deliver_date <> lc_break_init ) THEN
          ------------------------------
          -- �o�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �[�����f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �[�����^�O�o��
        -- -----------------------------------------------------
        -- �[����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_deliver_date ;
        -- -----------------------------------------------------
        -- �o�ɖ��ׂk�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_deliver_date := NVL( TO_CHAR(gt_main_data(i).h_deliver_date), lc_break_null )  ;
        lv_item_code    := lc_break_init ;
        -- �W�v�ϐ��O�N���A
        ln_position     := 0 ;  -- �v�Z�p�F�|�W�V����
--
      END IF ;
--
      -- =====================================================
      -- �i�ڃu���C�N
      -- =====================================================
      -- �i�ڂ��؂�ւ�����ꍇ
      IF ( NVL( TO_CHAR(gt_main_data(i).item_code), lc_break_null ) <> lv_item_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_code <> lc_break_init ) THEN
          ------------------------------
          -- �o�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �i�ڂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �i�ڃf�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �|�W�V����
        ln_position := ln_position + 1;
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'position' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ln_position ) ;
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_code ;
        -- �i�ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_name, 1, 20 ) ;
        -- -----------------------------------------------------
        -- �o�ɖ��ׂk�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_code    := NVL( TO_CHAR(gt_main_data(i).item_code), lc_break_null )  ;
        lv_futai        := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- �t�уu���C�N
      -- =====================================================
      -- �t�т��؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).add_code, lc_break_null ) <> lv_futai ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_futai <> lc_break_init ) THEN
          ------------------------------
          -- �o�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�ɖ��ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �o�ɖ��ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���׃f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �t�уR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).add_code ;
        -- -----------------------------------------------------
        -- �o�Ƀw�b�_�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_futai          := NVL( gt_main_data(i).add_code, lc_break_null )  ;
        lv_ship_from_code := lc_break_init ;
        lv_po_no          := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- �o�Ƀw�b�_�u���C�N
      -- =====================================================
      -- �o�Ɍ��܂��͔����m�n���؂�ւ�����ꍇ
      IF  ((NVL(gt_main_data(i).vendor_code, lc_break_null ) <> lv_ship_from_code )
        OR (NVL(gt_main_data(i).po_no      , lc_break_null ) <> lv_po_no          ) ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF   (( lv_ship_from_code <> lc_break_init )
          AND ( lv_po_no          <> lc_break_init ) ) THEN
          ------------------------------
          -- �o�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �o�Ƀw�b�_�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���׃f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �����m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'order_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).po_no ;
        -- �o�ɑq�ɃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_from_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).vendor_code ;
        -- �o�ɑq�ɖ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_from_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gt_main_data(i).vendor_name, 1, 20) ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_ship_from_code := NVL( gt_main_data(i).vendor_code, lc_break_null ) ;
        lv_po_no          := NVL( gt_main_data(i).po_no      , lc_break_null ) ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
--
      -- -----------------------------------------------------
      -- ���b�g�k�f�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���b�g�f�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- ���b�g�m��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).lot_no ;
      -- ������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).make_date, gc_char_d_format), gc_char_d_format);
      -- �ܖ�����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).period_date, gc_char_d_format), gc_char_d_format);
      -- �ŗL�L��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prop_mark ;
      -- ����
      IF ( gt_main_data(i).order_qty IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'frequent_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).order_qty ;
      END IF;
      -- �o�ɐ�
      IF ( gt_main_data(i).ship_qty IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).ship_qty ;
      END IF;
      -- ���ɐ�
      IF ( gt_main_data(i).stock_qty IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'stock_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).stock_qty ;
      END IF;
      -- ���ِ�
      IF ( gt_main_data(i).sai_qty IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).sai_qty ;
      END IF;
      --���ٗ�u�S�āv
      IF (( ir_param.sai_cd IS NULL) OR ( ir_param.sai_cd = gc_sai_all)) THEN
        -- ���كR�[�h�A���َ��R�擾
        prc_get_sai_code(gt_main_data, i, lv_sai_code, lv_sai_reason);
        -- ���كR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_cd' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_sai_code;
        -- ���َ��R
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_reason' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_sai_reason;
      --���ٗ�u�S�āv�ȊO
      ELSIF ( ir_param.sai_cd IS NOT NULL) THEN
        -- ���كR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_cd' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ir_param.sai_cd ;
        -- ���َ��R
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_reason' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_diff_reason_name;
      END IF;
      -- -----------------------------------------------------
      -- ���b�g�f�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���b�g�k�f�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- �o�Ƀw�b�_�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �o�Ƀw�b�_�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �o�ɖ��ׂf�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �o�ɖ��ׂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڂf�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �[�����f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �[�����k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���i�敪�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���i�敪�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
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
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-00009' ) ;
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
  PROCEDURE submain(
      iv_sai_cd           IN  VARCHAR2  -- ���َ��R
     ,iv_rcpt_subinv_code IN  VARCHAR2  -- ���ɑq��
     ,iv_goods_class      IN  VARCHAR2  -- ���i�敪
     ,iv_item_class       IN  VARCHAR2  -- �i�ڋ敪
     ,iv_dlv_from         IN  VARCHAR2  -- �[����from
     ,iv_dlv_to           IN  VARCHAR2  -- �[����to
     ,iv_ship_code_from   IN  VARCHAR2  -- �o�Ɍ�
     ,iv_order_num        IN  VARCHAR2  -- �����ԍ�
     ,iv_item_code        IN  VARCHAR2  -- �i��
     ,iv_position         IN  VARCHAR2  -- �S������
     ,iv_seqrt_class      IN  VARCHAR2  -- �Z�L�����e�B�敪
     ,ov_errbuf          OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         OUT  VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gv_report_id                := 'XXPO360007T' ;    -- ���[ID
    gd_exec_date                := SYSDATE ;          -- ���{��
    -- �p�����[�^�i�[
    lr_param_rec.sai_cd         := iv_sai_cd ;                -- ���َ��R
    lr_param_rec.subinv_code    := iv_rcpt_subinv_code ;      -- ���ɕۊǏꏊ
    lr_param_rec.goods_class    := iv_goods_class ;           -- ���i�敪
    lr_param_rec.item_class     := iv_item_class ;            -- �i�ڋ敪
                                                             -- �[�i���i�e�q�n�l�j
    lr_param_rec.dlv_from       := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                          iv_dlv_from,gc_char_dt_format) ,gc_char_d_format);
                                                             -- �[�i���i�s�n�j
    lr_param_rec.dlv_to         := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                          iv_dlv_to,gc_char_dt_format) ,gc_char_d_format);
    lr_param_rec.ship_code_from := iv_ship_code_from ;        -- �o�Ɍ�
    lr_param_rec.order_num      := iv_order_num ;             -- �����ԍ�
    lr_param_rec.item_code      := iv_item_code ;             -- �i�ڃR�[�h
    lr_param_rec.position       := iv_position ;              -- �S������
    lr_param_rec.seqrt_class    := iv_seqrt_class ;           -- �Z�L�����e�B�敪
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
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
    prc_create_xml_data(
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
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        <lg_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          <g_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            <lg_head>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              <g_head>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              </g_head>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            </lg_head>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          </g_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        </lg_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_locat>' ) ;
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
      errbuf                OUT   VARCHAR2,  -- �G���[���b�Z�[�W
      retcode               OUT   VARCHAR2,  -- �G���[�R�[�h
      iv_sai_cd             IN    VARCHAR2,  -- ���َ��R
      iv_rcpt_subinv_code   IN    VARCHAR2,  -- ���ɑq��
      iv_goods_class        IN    VARCHAR2,  -- ���i�敪
      iv_item_class         IN    VARCHAR2,  -- �i�ڋ敪
      iv_dlv_from           IN    VARCHAR2,  -- �[����from
      iv_dlv_to             IN    VARCHAR2,  -- �[����to
      iv_ship_code_from     IN    VARCHAR2,  -- �o�Ɍ�
      iv_order_num          IN    VARCHAR2,  -- �����ԍ�
      iv_item_code          IN    VARCHAR2,  -- �i��
      iv_position           IN    VARCHAR2,  -- �S������
      iv_seqrt_class        IN    VARCHAR2   -- �Z�L�����e�B�敪
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
      iv_sai_cd           => iv_sai_cd
     ,iv_rcpt_subinv_code => iv_rcpt_subinv_code
     ,iv_goods_class      => iv_goods_class
     ,iv_item_class       => iv_item_class
     ,iv_dlv_from         => iv_dlv_from
     ,iv_dlv_to           => iv_dlv_to
     ,iv_ship_code_from   => iv_ship_code_from
     ,iv_order_num        => iv_order_num
     ,iv_item_code        => iv_item_code
     ,iv_position         => iv_position
     ,iv_seqrt_class      => iv_seqrt_class
     ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error )
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
END xxpo360007c ;
/
