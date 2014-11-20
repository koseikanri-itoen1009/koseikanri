CREATE OR REPLACE PACKAGE BODY xxcmn770004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770004C(body)
 * Description      : �󕥂��̑����у��X�g
 * MD.050/070       : �����Y�؏������[Issue1.0 (T_MD050_BPO_770)
 *                    �����Y�؏������[Issue1.0 (T_MD070_BPO_77D)
 * Version          : 1.9
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(D-1)
 *  prc_get_report_data       PROCEDURE : �f�[�^�擾(D-2)
 *  fnc_item_unit_pric_get    FUNCTION  : �W�������̎擾
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/09    1.0   C.Kinjo          �V�K�쐬
 *  2008/05/12    1.1   M.Hamamoto       ���ד��̒��o���s���Ă��Ȃ�
 *  2008/05/16    1.2   T.Endou          �s�ID:5,6,7,8�Ή�
 *                                       5 YYYYM�ł�����ɒ��o�����悤�ɏC��
 *                                       6 �w�b�_�̏o�͓��t�Ɓu�S���F�v�����킹�܂���
 *                                       7 ���[���������[ID���̉��ɂ��܂���
 *                                       8 �i�ڋ敪���́A���i�敪���̂̕����ő咷���l�����܂���
 *  2008/05/28    1.3   Y.Ishikawa       ���b�g�Ǘ��O�̏ꍇ�A���b�g����NULL���o�͂���B
 *  2008/05/30    1.4   Y.Ishikawa       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *  2008/06/13    1.5   T.Endou          ���ד��������ꍇ�́A�\�蒅�ד����g�p����
 *                                       ���Y�����ڍׁi�A�h�I���j��������������O��
 *  2008/06/19    1.6   Y.Ishikawa       ����敪���p�p�A���{�Ɋւ��ẮA�󕥋敪���|���Ȃ�
 *  2008/06/25    1.7   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/07    1.8   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma04_v�v
 *  2008/08/20    1.9   A.Shiina         �����w�E#14�Ή�
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770004C' ;           -- �p�b�P�[�W��
  gv_print_name             CONSTANT VARCHAR2(20) := '�󕥂��̑����у��X�g' ;   -- ���[��
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- �A�v���P�[�V����
--
  ------------------------------
  -- �����Ǘ��敪
  ------------------------------
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0' ;   --���ی���
  gc_cost_st              CONSTANT VARCHAR2(1) := '1' ;   --�W������
--
  ------------------------------
  -- ���b�g�Ǘ��敪
  ------------------------------
  gv_lot_n                CONSTANT xxcmn_lot_each_item_v.lot_ctl%TYPE := 0; -- ���b�g�Ǘ��Ȃ�
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_goods_class  CONSTANT VARCHAR2(100) := '���i�敪' ;
  gc_cat_set_item_class   CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
--
  ------------------------------
  -- ����敪��
  ------------------------------
  gv_haiki                   CONSTANT VARCHAR2(100) := '�p�p' ;
  gv_mihon                   CONSTANT VARCHAR2(100) := '���{' ;
--
  ------------------------------
  -- ���t���ڕҏW�֘A
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
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
  gc_ja                  CONSTANT VARCHAR2( 5) := 'JA' ;
  ------------------------------
  -- ���l�E���z�����_�ʒu
  ------------------------------
  gn_quantity_decml        NUMBER  := 3;
  gn_amount_decml          NUMBER  := 0;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(7)                             -- �����N��
     ,goods_class         mtl_categories_b.segment1%TYPE          -- ���i�敪
     ,item_class          mtl_categories_b.segment1%TYPE          -- �i�ڋ敪
     ,div_type1           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�P
     ,div_type2           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�Q
     ,div_type3           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�R
     ,div_type4           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�S
     ,div_type5           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�T
     ,reason_code         sy_reas_cds_tl.reason_code%TYPE         -- ���R�R�[�h
    ) ;
--
  -- ���у��X�g�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
      div_tocode         VARCHAR2(100)                                 -- �󕥐�R�[�h
     ,div_toname         VARCHAR2(100)                                 -- �󕥐於
     ,h_reason_code      gmd_routings_b.attribute14%TYPE               -- ���R�R�[�h
     ,h_reason_name      sy_reas_cds_tl.reason_desc1%TYPE              -- ���R�R�[�h��
     ,dept_code          oe_order_headers_all.attribute11%TYPE         -- ���ѕ����R�[�h
     ,dept_name          xxcmn_locations2_v.location_short_name%TYPE   -- ���ѕ�����
     ,trans_date         DATE                                          -- �����
     ,h_div_code         xxcmn_rcv_pay_mst.new_div_account%TYPE        -- �󕥋敪
     ,h_div_name         fnd_lookup_values.meaning%TYPE                -- �󕥋敪��
     ,item_id            ic_item_mst_b.item_id%TYPE                    -- �i�ڂh�c
     ,h_item_code        ic_item_mst_b.item_no%TYPE                    -- �i�ڃR�[�h
     ,h_item_name        xxcmn_item_mst_b.item_short_name%TYPE         -- �i�ږ�
     ,locat_code         mtl_item_locations.segment1%TYPE              -- �q�ɃR�[�h
     ,locat_name         mtl_item_locations.description%TYPE           -- �q�ɖ�
     ,wip_date           ic_lots_mst.attribute1%TYPE                   -- ������
     ,lot_no             ic_lots_mst.lot_no%TYPE                       -- ���b�gNo
     ,original_char      ic_lots_mst.attribute2%TYPE                   -- �ŗL�L��
     ,use_by_date        ic_lots_mst.attribute3%TYPE                   -- �ܖ�����
     ,cost_kbn           ic_item_mst_b.attribute15%TYPE                -- �����Ǘ��敪
     ,lot_kbn            xxcmn_lot_each_item_v.lot_ctl%TYPE            -- ���b�g�Ǘ��敪
     ,actual_unit_price  xxcmn_lot_cost.unit_ploce%TYPE                -- ���ی���
     ,trans_qty          ic_tran_pnd.trans_qty%TYPE                    -- �������
     ,description        ic_lots_mst.attribute18%TYPE                  -- �E�v
   ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �w�b�_���擾�p
  ------------------------------
-- ���[���
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- �S����
  gv_goods_class_name       mtl_categories_tl.description%TYPE;               -- ���i�敪��
  gv_item_class_name        mtl_categories_tl.description%TYPE;               -- �i�ڋ敪��
  gv_reason_name            sy_reas_cds_tl.reason_desc1%TYPE;                 -- ���R�R�[�h��
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
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(D-1)
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
    -- *** ���[�J���萔 ***
    -- -------------------------------
    -- �G���[���b�Z�[�W�o�͗p
    -- -------------------------------
    -- �G���[�R�[�h
    lc_err_code        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010' ;
    -- �g�[�N����
    lc_token_name_01   CONSTANT VARCHAR2(100) := 'PARAMETER' ;
    lc_token_name_02   CONSTANT VARCHAR2(100) := 'VALUE' ;
    -- �g�[�N���l
    lc_token_value     CONSTANT VARCHAR2(100) := '�����N��' ;
--
    -- *** ���[�J���ϐ� ***
    -- -------------------------------
    -- �G���[�n���h�����O�p
    -- -------------------------------
    ln_ret_num                NUMBER ;        -- ���ʊ֐��߂�l�F���l�^
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
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
    -- ���i�敪�擾
    -- ====================================================
    BEGIN
      SELECT cat.description
      INTO   gv_goods_class_name
      FROM   xxcmn_categories_v cat
      WHERE  cat.category_set_name = gc_cat_set_goods_class
      AND    cat.segment1          = ir_param.goods_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- �i�ڋ敪�擾
    -- ====================================================
    BEGIN
      SELECT cat.description
      INTO   gv_item_class_name
      FROM   xxcmn_categories_v cat
      WHERE  cat.category_set_name = gc_cat_set_item_class
      AND    cat.segment1          = ir_param.item_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- ���R�R�[�h���擾
    -- ====================================================
    gv_reason_name := NULL;
    IF ( ir_param.reason_code IS NOT NULL ) THEN
      BEGIN
        SELECT sy.reason_desc1
        INTO   gv_reason_name
        FROM   sy_reas_cds_tl sy
        WHERE  sy.reason_code   = ir_param.reason_code
          AND  sy.language = gc_ja
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END ;
    END IF;
--
    -- ====================================================
    -- �����N��
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.exec_year_month ) ;
    BEGIN
      IF ( ln_ret_num = 1 ) THEN
        RAISE parameter_check_expt ;
      END IF ;
    EXCEPTION
      --*** �p�����[�^�`�F�b�N��O ***
      WHEN parameter_check_expt THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( iv_application   => gc_application
                                              ,iv_name          => lc_err_code
                                              ,iv_token_name1   => lc_token_name_01
                                              ,iv_token_name2   => lc_token_name_02
                                              ,iv_token_value1  => lc_token_value
                                              ,iv_token_value2  => ir_param.exec_year_month ) ;
        ov_errmsg  := lv_errmsg ;
        ov_errbuf  := lv_errmsg ;
        ov_retcode := gv_status_error ;
    END;
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
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(D-2)
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
    cv_div_type    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_NEW_ACCOUNT_DIV';
    cv_out_flag    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
    cv_line_type   CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_LINE_TYPE';
    cv_deal_div    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_DEALINGS_DIV';
    cv_yes                  CONSTANT VARCHAR2( 1) := 'Y' ;
    cv_doc_type_porc        CONSTANT VARCHAR2(10) := 'PORC' ;
    cv_doc_type_omso        CONSTANT VARCHAR2(10) := 'OMSO' ;
    cv_doc_type_prod        CONSTANT VARCHAR2(10) := 'PROD' ;
    cv_doc_type_xfer        CONSTANT VARCHAR2(10) := 'XFER' ;
    cv_doc_type_trni        CONSTANT VARCHAR2(10) := 'TRNI' ;
    cv_doc_type_adji        CONSTANT VARCHAR2(10) := 'ADJI' ;
    cv_po                   CONSTANT VARCHAR2(10) := 'PO' ;
    cv_ship_type            CONSTANT VARCHAR2( 2) := '1' ;
    cv_pay_type             CONSTANT VARCHAR2( 2) := '2' ;
    cv_comp_flg             CONSTANT VARCHAR2( 2) := '1' ;
    cv_ovlook_pay           CONSTANT VARCHAR2(10) := 'X942' ; -- �َ��i�ڕ��o
    cv_sonota_pay           CONSTANT VARCHAR2(10) := 'X951' ; -- ���̑����o
    cv_move_result          CONSTANT VARCHAR2(10) := 'X122' ; -- �ړ�����
    cv_vendor_rma           CONSTANT VARCHAR2( 5) := 'X201' ; -- �d����ԕi
    cv_hamaoka_rcv          CONSTANT VARCHAR2( 5) := 'X988' ; -- �l�����
    cv_party_inv            CONSTANT VARCHAR2( 5) := 'X977' ; -- �����݌�
    cv_move_correct         CONSTANT VARCHAR2( 5) := 'X123' ; -- �ړ����ђ���
    cv_div_pay              CONSTANT VARCHAR2( 2) := '-1' ;
    cv_div_rcv              CONSTANT VARCHAR2( 2) := '1' ;
    lc_f_day                CONSTANT VARCHAR2(2)  := '01';
    lc_f_time               CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time               CONSTANT VARCHAR2(10) := ' 23:59:59';
    cv_div_kind_transfer    CONSTANT VARCHAR2(10) := '�i��U��';   -- ����敪�F�i��U��
    cv_div_item_transfer    CONSTANT VARCHAR2(10) := '�i�ڐU��';   -- ����敪�F�i�ڐU��
    cv_line_type_material   CONSTANT VARCHAR2( 2) := '1';     -- ���C���^�C�v�F����
    cv_line_type_product    CONSTANT VARCHAR2( 2) := '-1';    -- ���C���^�C�v�F���i
--
    -- *** ���[�J���E�ϐ� ***
    lv_sql1        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_sql2        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    -- ��View
    lv_sql_xfer        VARCHAR2(9000);
    lv_sql_trni        VARCHAR2(9000);
    lv_sql_adji1       VARCHAR2(9000);
    lv_sql_adji2       VARCHAR2(9000);
    lv_sql_adji_x201   VARCHAR2(9000);
    lv_sql_adji_x988   VARCHAR2(9000);
    lv_sql_adji_x123   VARCHAR2(9000);
    lv_sql_prod1       VARCHAR2(9000);
    lv_sql_prod2       VARCHAR2(9000);
    lv_sql_porc1       VARCHAR2(9000);
    lv_sql_porc2       VARCHAR2(9000);
    lv_sql_omso        VARCHAR2(9000);
    lv_sql_para        VARCHAR2(2000);
    lv_select          VARCHAR2(2000);
    lv_from            VARCHAR2(2000);
    lv_where           VARCHAR2(2000);
    lv_order_by        VARCHAR2(2000);
    --�ϑ�����(xfer)
    lv_select_xfer     VARCHAR2(3000);
    lv_from_xfer       VARCHAR2(3000);
    lv_where_xfer      VARCHAR2(3000);
    --�ϑ��Ȃ�(trni)
    lv_select_trni     VARCHAR2(3000);
    lv_from_trni       VARCHAR2(3000);
    lv_where_trni      VARCHAR2(3000);
    --���Y�֘A(adji)
    lv_select_adji     VARCHAR2(3000);
    lv_from_adji       VARCHAR2(3000);
    lv_where_adji      VARCHAR2(3000);
    --�݌Ɋ֘A(prod)
    lv_select_prod     VARCHAR2(3000);
    lv_from_prod       VARCHAR2(3000);
    lv_where_prod      VARCHAR2(5000);
    --�w���֘A(porc)
    lv_select_porc     VARCHAR2(3000);
    lv_from_porc       VARCHAR2(3000);
    lv_where_porc      VARCHAR2(3000);
    --�󒍊֘A(omso)
    lv_select_omso     VARCHAR2(3000);
    lv_from_omso       VARCHAR2(3000);
    lv_where_omso      VARCHAR2(3000);
--  ���o�p�J�n�I�����t
    ld_start_date      DATE;
    ld_end_date        DATE;
    lv_start_date      VARCHAR2(20);
    lv_end_date        VARCHAR2(20);
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
    -- �W�v���Ԑݒ�
    ld_start_date := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month ||
                                             lc_f_day, gc_char_d_format);
    lv_start_date := TO_CHAR(ld_start_date, gc_char_d_format) || lc_f_time ;
    ld_end_date   := LAST_DAY(ld_start_date);
    lv_end_date   := TO_CHAR(ld_end_date, gc_char_d_format) || lc_e_time ;
--
    -- �󕥋敪(�V�o���󕥋敪)���Ұ��l�ݒ�
    lv_sql_para :=
           '   AND rpmv.new_div_account in (''' || ir_param.div_type1 || ''''     -- �󕥋敪�P
      ;
    -- �󕥋敪�Q�����͂���Ă���ꍇ
    IF ( ir_param.div_type2 IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' , ''' || ir_param.div_type2 || ''' '
             ;
    END IF;
    -- �󕥋敪�R�����͂���Ă���ꍇ
    IF ( ir_param.div_type3 IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' , ''' || ir_param.div_type3 || ''' '
             ;
    END IF;
    -- �󕥋敪�S�����͂���Ă���ꍇ
    IF ( ir_param.div_type4 IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' , ''' || ir_param.div_type4 || ''' '
             ;
    END IF;
    -- �󕥋敪�T�����͂���Ă���ꍇ
    IF ( ir_param.div_type5 IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' , ''' || ir_param.div_type5 || ''' '
             ;
    END IF;
    lv_sql_para := lv_sql_para
           || ')'
           ;
    -- ���R�R�[�h�����͂���Ă���ꍇ
    IF ( ir_param.reason_code IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' AND rpmv.reason_code  = ''' || ir_param.reason_code || ''''
             ;
    END IF;
    -- ====================================================
    -- ����SELECT��
    -- ====================================================
    lv_select := '  ,trn.trans_date           AS trans_date'        -- �����
              || '  ,rpmv.new_div_account     AS new_div_account'   -- �󕥋敪
              || '  ,xlv1.meaning             AS div_name'          -- �󕥋敪��
              || '  ,trn.item_id              AS item_id'           -- �i�ڂh�c
              || '  ,xlei.item_code           AS item_code'         -- �i�ڃR�[�h
              || '  ,xlei.item_short_name     AS item_name'         -- �i�ږ���
              || '  ,trn.whse_code            AS whse_code'         -- �q�ɃR�[�h
              || '  ,iwm.whse_name            AS whse_name'         -- �q�ɖ���
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_attribute1)     AS wip_date'          -- ������
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_no)             AS lot_no'            -- ���b�g
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_attribute2)     AS original_char'     -- �ŗL�L��
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_attribute3)     AS use_by_date'       -- �ܖ�����
              || '  ,xlei.item_attribute15    AS cost_mng_clss'     -- �����Ǘ��敪
              || '  ,xlei.lot_ctl             AS lot_ctl'           -- ���b�g�Ǘ��敪
              || '  ,xlei.actual_unit_price   AS actual_unit_price' -- ���ےP��
-- 2008/08/20 v1.9 UPDATE START
--              || '  ,trn.trans_qty            AS trans_qty'         -- ����
              || '  ,trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div) AS trans_qty' -- ����
-- 2008/08/20 v1.9 UPDATE END
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_attribute18)    AS lot_desc'          -- �E�v
              ;
    -- ====================================================
    -- ����FROM��
    -- ====================================================
    lv_from := ',xxcmn_lot_each_item_v     xlei'    -- ���b�g�ʕi�ڏ��
            || ',ic_whse_mst               iwm'     -- OPM�q�Ƀ}�X�^
            || ',xxcmn_lookup_values2_v    xlv1'    -- �N�C�b�N�R�[�h(�󕥋敪)
            || ',xxcmn_lookup_values2_v    xlv2'    -- �N�C�b�N�R�[�h(���[��)
            ;
    -- ====================================================
    -- ����WHERE��
    -- ====================================================
    lv_where := ' AND trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--�����
      || '   AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--�����
      || '   AND xlei.prod_div   = ''' || ir_param.goods_class || ''''  -- ���Ұ��F���i�敪
      || '   AND xlei.item_div   = ''' || ir_param.item_class || ''''   -- ���Ұ��F�i�ڋ敪
      || lv_sql_para   -- ���Ұ��ݒ�
    --�}�X�^�֘A
    ---------------------------------------------------------------------------------------------
    -- ���b�g�ʕi�ڏ��VIEW�̍i���ݏ���
      || ' AND trn.item_id             = xlei.item_id'
      || ' AND trn.lot_id              = xlei.lot_id'
      || ' AND (xlei.start_date_active IS NULL OR'
      || ' xlei.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlei.end_date_active   IS NULL OR'
      || ' xlei.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- OPM�q�Ƀ}�X�^�̍i���ݏ���
      || ' AND trn.whse_code           = iwm.whse_code'
    ---------------------------------------------------------------------------------------------
    -- �N�C�b�N�R�[�hIEW�̍i���ݏ���
      -- �󕥋敪
      || ' AND xlv1.lookup_type         = ''' || cv_div_type || ''''
      || ' AND rpmv.new_div_account     = xlv1.lookup_code'
      || ' AND (xlv1.start_date_active IS NULL OR'
      || ' xlv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv1.end_date_active   IS NULL OR'
      || ' xlv1.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv1.language           = ''' || gc_ja || ''''
      || ' AND xlv1.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv1.enabled_flag       = ''' || cv_yes || ''''
      -- ���[��
      || ' AND xlv2.lookup_type        = ''' || cv_out_flag || ''''
      || ' AND rpmv.dealings_div       = xlv2.meaning'
      || ' AND (xlv2.start_date_active IS NULL OR'
      || ' xlv2.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv2.end_date_active   IS NULL OR'
      || ' xlv2.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv2.language           = ''' || gc_ja || ''''
      || ' AND xlv2.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv2.enabled_flag       = ''' || cv_yes || ''''
      || ' AND xlv2.attribute4         IS NOT NULL'   -- ���[�t���O�i770D�̏ꍇ�j
      ;
    -- ----------------------------------------------------
    -- �w�e�d�q����_����
    -- ----------------------------------------------------
--
    lv_select_xfer := ' SELECT '
      || '   NULL                     AS div_tocode'        -- �󕥐�R�[�h
      || '  ,NULL                     AS div_toname'        -- �󕥐於��
      || '  ,rpmv.reason_code         AS reason_code'       -- ���R�R�[�h
      || '  ,srct.reason_desc1        AS reason_name'       -- ���R����
      || '  ,NULL                     AS post_code'         -- �����R�[�h
      || '  ,NULL                     AS post_name'         -- ������
      ;
--
    lv_from_xfer := ' FROM'
      || ' xxcmn_rcv_pay_mst_xfer_v  rpmv'    -- ��View_XFER
      || ',ic_tran_pnd               trn'     -- OPM�ۗ��݌Ƀg����
      || ',(SELECT    reason_code'            -- ���R�R�[�h
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_xfer_mst               ixm'     -- �n�o�l�݌ɓ]���}�X�^
      || ',xxinv_mov_req_instr_lines xmril'   -- �ړ��˗��^�w�����ׁi�A�h�I���j
      ;
--
    lv_where_xfer := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_xfer || ''''
      || '   AND trn.reason_code         = ''' || cv_move_result || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND rpmv.rcv_pay_div        = CASE'
                                     || '    WHEN trn.trans_qty >= 0 THEN ''' || cv_div_rcv || ''''
                                     || '    ELSE ''' || cv_div_pay || ''''
                                     || '  END'
      || '   AND trn.doc_id              = ixm.transfer_id'
      || '   AND ixm.attribute1          = xmril.mov_line_id'
    ---------------------------------------------------------------------------------------------
    -- ���R�R�[�h�̍i���ݏ���
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- �r�p�k����
    lv_sql_xfer := lv_select_xfer || lv_select ||
                   lv_from_xfer   || lv_from   ||
                   lv_where_xfer  || lv_where;
--
    -- ----------------------------------------------------
    -- �s�q�m�h����_����
    -- ----------------------------------------------------
--
    lv_select_trni := ' SELECT '
      || '   NULL                     AS div_tocode'        -- �󕥐�R�[�h
      || '  ,NULL                     AS div_toname'        -- �󕥐於��
      || '  ,rpmv.reason_code         AS reason_code'       -- ���R�R�[�h
      || '  ,srct.reason_desc1        AS reason_name'       -- ���R����
      || '  ,NULL                     AS post_code'         -- �����R�[�h
      || '  ,NULL                     AS post_name'         -- ������
      ;
--
    lv_from_trni := ' FROM'
      || ' xxcmn_rcv_pay_mst_trni_v    rpmv'  -- ��View_TRNI
      || ',ic_tran_cmp                 trn'   -- OPM�݌Ƀg����
      || ',(SELECT    reason_code'            -- ���R�R�[�h
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_adjs_jnl                 iaj'   -- �n�o�l�݌ɒ����W���[�i��
      || ',ic_jrnl_mst                 ijm'   -- �n�o�l�W���[�i���}�X�^
      || ',xxinv_mov_req_instr_lines   xmril' -- �ړ��˗��^�w�����ׁi�A�h�I���j
      ;
--
    lv_where_trni := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_trni || ''''
      || '   AND trn.reason_code         = ''' || cv_move_result || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.line_type           = rpmv.rcv_pay_div'
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND rpmv.rcv_pay_div        = CASE'
                                     || '    WHEN trn.trans_qty >= 0 THEN ''' || cv_div_rcv || ''''
                                     || '    ELSE ''' || cv_div_pay || ''''
                                     || '  END'
      || '   AND trn.doc_type            = iaj.trans_type'
      || '   AND trn.doc_id              = iaj.doc_id'
      || '   AND trn.doc_line            = iaj.doc_line'
      || '   AND iaj.journal_id          = ijm.journal_id'
      || '   AND ijm.attribute1          = xmril.mov_line_id'
    ---------------------------------------------------------------------------------------------
    -- ���R�R�[�h�̍i���ݏ���
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- �r�p�k����
    lv_sql_trni := lv_select_trni || lv_select ||
                   lv_from_trni   || lv_from   ||
                   lv_where_trni  || lv_where;
--
    -- ------------------------------------------------------------------------
    -- �`�c�i�h����_����(�َ��i�ڕ��o�A���̑����o�A�d����ԕi�A�l������A
    --                   �����݌ɁA�ړ����ђ����ȊO)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- �󕥐�R�[�h
      || '  ,NULL                     AS div_toname'        -- �󕥐於��
      || '  ,rpmv.reason_code         AS reason_code'       -- ���R�R�[�h
      || '  ,srct.reason_desc1        AS reason_name'       -- ���R����
      || '  ,NULL                     AS post_code'         -- �����R�[�h
      || '  ,NULL                     AS post_name'         -- ������
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- ��View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM�݌Ƀg����
      || ',(SELECT    reason_code'            -- ���R�R�[�h
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         <> ''' || cv_ovlook_pay || ''''   -- �َ��i�ڕ��o
      || '   AND trn.reason_code         <> ''' || cv_sonota_pay || ''''   -- ���̑����o
      || '   AND trn.reason_code         <> ''' || cv_vendor_rma || ''''   -- �d����ԕi
      || '   AND trn.reason_code         <> ''' || cv_hamaoka_rcv || ''''  -- �l�����
      || '   AND trn.reason_code         <> ''' || cv_party_inv || ''''    -- �����݌�
      || '   AND trn.reason_code         <> ''' || cv_move_correct || '''' -- �ړ����ђ���
      || '   AND trn.reason_code         = rpmv.reason_code'
    ---------------------------------------------------------------------------------------------
    -- ���R�R�[�h�̍i���ݏ���
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- �r�p�k����
    lv_sql_adji1 := lv_select_adji || lv_select ||
                    lv_from_adji   || lv_from   ||
                    lv_where_adji  || lv_where;
--
    -- ------------------------------------------------------------------------
    -- �`�c�i�h����_����(�َ��i�ڕ��o�A���̑����o)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- �󕥐�R�[�h
      || '  ,NULL                     AS div_toname'        -- �󕥐於��
      || '  ,rpmv.reason_code         AS reason_code'       -- ���R�R�[�h
      || '  ,srct.reason_desc1        AS reason_name'       -- ���R����
      || '  ,NULL                     AS post_code'         -- �����R�[�h
      || '  ,NULL                     AS post_name'         -- ������
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- ��View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM�݌Ƀg����
      || ',(SELECT    reason_code'            -- ���R�R�[�h
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND (trn.reason_code         = ''' || cv_ovlook_pay || ''''   -- �َ��i�ڕ��o
      || '    OR trn.reason_code         = ''' || cv_sonota_pay || ''')'   -- ���̑����o
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND rpmv.rcv_pay_div        = CASE'
                                     || '    WHEN trn.trans_qty >= 0 THEN ''' || cv_div_rcv || ''''
                                     || '    ELSE ''' || cv_div_pay || ''''
                                     || '  END'
    ---------------------------------------------------------------------------------------------
    -- ���R�R�[�h�̍i���ݏ���
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- �r�p�k����
    lv_sql_adji2 := lv_select_adji || lv_select ||
                    lv_from_adji   || lv_from   ||
                    lv_where_adji  || lv_where;
--
    -- ------------------------------------------------------------------------
    -- �`�c�i�h����_����(�d����ԕi)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- �󕥐�R�[�h
      || '  ,NULL                     AS div_toname'        -- �󕥐於��
      || '  ,rpmv.reason_code         AS reason_code'       -- ���R�R�[�h
      || '  ,srct.reason_desc1        AS reason_name'       -- ���R����
      || '  ,NULL                     AS post_code'         -- �����R�[�h
      || '  ,NULL                     AS post_name'         -- ������
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- ��View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM�݌Ƀg����
      || ',(SELECT    reason_code'            -- ���R�R�[�h
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_adjs_jnl                 iaj'   -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst                 ijm'   -- OPM�W���[�i���}�X�^
      || ',xxpo_rcv_and_rtn_txns       xrrt'  -- ����ԕi���уA�h�I��
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         = ''' || cv_vendor_rma || ''''   -- �d����ԕi
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND iaj.trans_type          = trn.doc_type'
      || '   AND iaj.doc_id              = trn.doc_id'
      || '   AND iaj.doc_line            = trn.doc_line'
      || '   AND ijm.journal_id          = iaj.journal_id'
      || '   AND xrrt.txns_id            = ijm.attribute1'
    ---------------------------------------------------------------------------------------------
    -- ���R�R�[�h�̍i���ݏ���
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- �r�p�k����
    lv_sql_adji_x201 := lv_select_adji || lv_select ||
                        lv_from_adji   || lv_from   ||
                        lv_where_adji  || lv_where;
--
    -- ������
    lv_select_adji   := '';
    lv_from_adji     := '';
    lv_where_adji    := '';
    -- ------------------------------------------------------------------------
    -- �`�c�i�h����_����(�l�����)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- �󕥐�R�[�h
      || '  ,NULL                     AS div_toname'        -- �󕥐於��
      || '  ,rpmv.reason_code         AS reason_code'       -- ���R�R�[�h
      || '  ,srct.reason_desc1        AS reason_name'       -- ���R����
      || '  ,NULL                     AS post_code'         -- �����R�[�h
      || '  ,NULL                     AS post_name'         -- ������
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- ��View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM�݌Ƀg����
      || ',(SELECT    reason_code'            -- ���R�R�[�h
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_adjs_jnl                 iaj'   -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst                 ijm'   -- OPM�W���[�i���}�X�^
      || ',xxpo_namaha_prod_txns       xnpt'  -- ���t���уA�h�I��
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         = ''' || cv_hamaoka_rcv || ''''   -- �l�����
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND iaj.trans_type          = trn.doc_type'
      || '   AND iaj.doc_id              = trn.doc_id'
      || '   AND iaj.doc_line            = trn.doc_line'
      || '   AND ijm.journal_id          = iaj.journal_id'
      || '   AND xnpt.entry_number       = ijm.attribute1'
    ---------------------------------------------------------------------------------------------
    -- ���R�R�[�h�̍i���ݏ���
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- �r�p�k����
    lv_sql_adji_x988 := lv_select_adji || lv_select ||
                        lv_from_adji   || lv_from   ||
                        lv_where_adji  || lv_where;
--
    -- ������
    lv_select_adji   := '';
    lv_from_adji     := '';
    lv_where_adji    := '';
    -- ------------------------------------------------------------------------
    -- �`�c�i�h����_����(�ړ����ђ���)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- �󕥐�R�[�h
      || '  ,NULL                     AS div_toname'        -- �󕥐於��
      || '  ,rpmv.reason_code         AS reason_code'       -- ���R�R�[�h
      || '  ,srct.reason_desc1        AS reason_name'       -- ���R����
      || '  ,NULL                     AS post_code'         -- �����R�[�h
      || '  ,NULL                     AS post_name'         -- ������
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- ��View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM�݌Ƀg����
      || ',(SELECT    reason_code'            -- ���R�R�[�h
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_adjs_jnl                 iaj'   -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst                 ijm'   -- OPM�W���[�i���}�X�^
      || ',xxinv_mov_req_instr_lines   xmrl'  -- �ړ��˗�/�x������
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         = ''' || cv_move_correct || ''''   -- �ړ����ђ���
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND rpmv.rcv_pay_div        = CASE'
                                     || '    WHEN trn.trans_qty >= 0 THEN ''' || cv_div_pay || ''''
                                     || '    WHEN trn.trans_qty < 0 THEN ''' || cv_div_rcv || ''''
                                     || '    ELSE rpmv.rcv_pay_div'
                                     || '  END'
      || '   AND iaj.trans_type          = trn.doc_type'
      || '   AND iaj.doc_id              = trn.doc_id'
      || '   AND iaj.doc_line            = trn.doc_line'
      || '   AND ijm.journal_id          = iaj.journal_id'
      || '   AND xmrl.mov_line_id        = ijm.attribute1'
    ---------------------------------------------------------------------------------------------
    -- ���R�R�[�h�̍i���ݏ���
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- �r�p�k����
    lv_sql_adji_x123 := lv_select_adji || lv_select ||
                        lv_from_adji   || lv_from   ||
                        lv_where_adji  || lv_where;
--
    -- ----------------------------------------------------
    -- �o�q�n�c����_����(�m�t�k�k)_�i��E�i�ڐU�ֈȊO
    -- ----------------------------------------------------
--
    lv_select_prod := ' SELECT '
      || '   TO_CHAR(rpmv.line_type)  AS div_tocode'        -- �󕥐�R�[�h
      || '  ,xlv3.meaning             AS div_toname'        -- �󕥐於��
      || '  ,NULL                     AS reason_code'       -- ���R�R�[�h
      || '  ,NULL                     AS reason_name'       -- ���R����
      || '  ,rpmv.result_post         AS post_code'         -- �����R�[�h
      || '  ,loca.location_short_name AS post_name'         -- ������
      ;
--
    lv_from_prod := ' FROM'
      || ' xxcmn_rcv_pay_mst_prod_v    rpmv'  -- ��View_PROD
      || ',ic_tran_pnd                 trn'   -- OPM�ۗ��݌Ƀg����
      -- �}�X�^���
      || ',xxcmn_locations2_v        loca'    -- ���Ə����VIEW
      || ',xxcmn_lookup_values2_v    xlv3'    -- �N�C�b�N�R�[�h(���C���^�C�v)
      || ',xxcmn_lookup_values2_v    xlv4'    -- �N�C�b�N�R�[�h(����敪)
      ;
--
    lv_where_prod := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_prod || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.reverse_id          IS NULL'
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.line_type           = rpmv.line_type'
      || '   AND trn.doc_id              = rpmv.doc_id'
      || '   AND trn.doc_line            = rpmv.doc_line'
    --�}�X�^�֘A
    ---------------------------------------------------------------------------------------------
    -- ���Ə����VIEW�̍i���ݏ���
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- �N�C�b�N�R�[�hIEW�̍i���ݏ���
      -- ���C���^�C�v
      || ' AND xlv3.lookup_type(+)     = ''' || cv_line_type || ''''
      || ' AND rpmv.line_type          = xlv3.lookup_code(+)'
      || ' AND (xlv3.start_date_active IS NULL OR'
      || ' xlv3.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv3.end_date_active   IS NULL OR'
      || ' xlv3.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv3.language(+)        = ''' || gc_ja || ''''
      || ' AND xlv3.source_lang(+)     = ''' || gc_ja || ''''
      || ' AND xlv3.enabled_flag(+)    = ''' || cv_yes || ''''
      -- ����敪
      || ' AND xlv4.lookup_type     = ''' || cv_deal_div || ''''
      || ' AND rpmv.dealings_div    = xlv4.lookup_code'
      || ' AND (xlv4.start_date_active IS NULL OR'
      || ' xlv4.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv4.end_date_active   IS NULL OR'
      || ' xlv4.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv4.language        = ''' || gc_ja || ''''
      || ' AND xlv4.source_lang     = ''' || gc_ja || ''''
      || ' AND xlv4.enabled_flag    = ''' || cv_yes || ''''
      || ' AND xlv4.meaning        <> ''' || cv_div_kind_transfer || ''''   -- �i��U��
      || ' AND xlv4.meaning        <> ''' || cv_div_item_transfer || ''''   -- �i�ڐU��
      ;
--
    -- �r�p�k����
    lv_sql_prod1 := lv_select_prod || lv_select ||
                    lv_from_prod   || lv_from   ||
                    lv_where_prod  || lv_where;
--
    -- ������
    lv_select_prod := '';
    lv_from_prod   := '';
    lv_where_prod  := '';
--
    -- ----------------------------------------------------
    -- �o�q�n�c����_����(�m�t�k�k)_�i��E�i�ڐU��
    -- ----------------------------------------------------
--
    lv_select_prod := ' SELECT '
      || '   TO_CHAR(rpmv.line_type)  AS div_tocode'        -- �󕥐�R�[�h
      || '  ,xlv3.meaning             AS div_toname'        -- �󕥐於��
      || '  ,NULL                     AS reason_code'       -- ���R�R�[�h
      || '  ,NULL                     AS reason_name'       -- ���R����
      || '  ,rpmv.result_post         AS post_code'         -- �����R�[�h
      || '  ,loca.location_short_name AS post_name'         -- ������
      || '  ,trn.trans_date           AS trans_date'        -- �����
      || '  ,rpmv.new_div_account     AS new_div_account'   -- �󕥋敪
      || '  ,xlv1.meaning             AS div_name'          -- �󕥋敪��
      || '  ,trn.item_id              AS item_id'           -- �i�ڂh�c
      || '  ,xlei.item_code           AS item_code'         -- �i�ڃR�[�h
      || '  ,xlei.item_short_name     AS item_name'         -- �i�ږ���
      || '  ,trn.whse_code            AS whse_code'         -- �q�ɃR�[�h
      || '  ,iwm.whse_name            AS whse_name'         -- �q�ɖ���
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute1)     AS wip_date'          -- ������
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_no)             AS lot_no'            -- ���b�g
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute2)     AS original_char'     -- �ŗL�L��
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute3)     AS use_by_date'       -- �ܖ�����
      || '  ,xlei.item_attribute15    AS cost_mng_clss'     -- �����Ǘ��敪
      || '  ,xlei.lot_ctl             AS lot_ctl'           -- ���b�g�Ǘ��敪
      || '  ,xlei.actual_unit_price   AS actual_unit_price' -- ���ےP��
      || '  ,trn.trans_qty            AS trans_qty'         -- ����
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute18)    AS lot_desc'          -- �E�v
      ;
--
    lv_from_prod := ' FROM'
      || ' xxcmn_rcv_pay_mst_prod_v    rpmv'  -- ��View_PROD
      || ',ic_tran_pnd                 trn'   -- OPM�ۗ��݌Ƀg����
      || ',ic_tran_pnd                 trn2'  -- OPM�ۗ��݌Ƀg����
      || ',xxcmn_lot_each_item_v       xlei'  -- ���b�g�ʕi�ڏ��
      || ',xxcmn_lot_each_item_v       xlei2' -- ���b�g�ʕi�ڏ��
      -- �}�X�^���
      || ',ic_whse_mst               iwm'     -- OPM�q�Ƀ}�X�^
      || ',xxcmn_locations2_v        loca'    -- ���Ə����VIEW
      || ',xxcmn_lookup_values2_v    xlv1'    -- �N�C�b�N�R�[�h(�󕥋敪)
      || ',xxcmn_lookup_values2_v    xlv2'    -- �N�C�b�N�R�[�h(���[��)
      || ',xxcmn_lookup_values2_v    xlv3'    -- �N�C�b�N�R�[�h(���C���^�C�v)
      || ',xxcmn_lookup_values2_v    xlv4'    -- �N�C�b�N�R�[�h(����敪)
      ;
--
    lv_where_prod := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_prod || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.reverse_id          IS NULL'
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.line_type           = rpmv.line_type'
      || '   AND trn.doc_id              = rpmv.doc_id'
      || '   AND trn.doc_line            = rpmv.doc_line'
      || '   AND trn2.line_type  = CASE'
                        || '   WHEN trn.line_type = ''' || cv_line_type_product || ''''
                        || '        THEN ''' || cv_line_type_material || ''''
                        || '   WHEN trn.line_type = ''' || cv_line_type_material || ''''
                        || '        THEN ''' || cv_line_type_product || ''''
                        || '   END'
      || '   AND trn2.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn2.reverse_id          IS NULL'
      || '   AND trn.doc_id               = trn2.doc_id'
      || '   AND trn.doc_line             = trn2.doc_line'
    -- �p�����[�^
      || '   AND trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--�����
      || '   AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--�����
      || '   AND trn2.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--�����
      || '   AND trn2.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--�����
      || '   AND xlei.prod_div = ''' || ir_param.goods_class || ''''
      || '   AND xlei.item_div = ''' || ir_param.item_class || ''''
      || lv_sql_para   -- ���Ұ��ݒ�
    --�}�X�^�֘A
    ---------------------------------------------------------------------------------------------
    -- ���b�g�ʕi�ڏ��VIEW�̍i���ݏ���
      || ' AND trn.item_id             = xlei.item_id'
      || ' AND trn.lot_id              = xlei.lot_id'
      || ' AND (xlei.start_date_active IS NULL OR'
      || ' xlei.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlei.end_date_active   IS NULL OR'
      || ' xlei.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND trn2.item_id             = xlei2.item_id'
      || ' AND trn2.lot_id              = xlei2.lot_id'
      || ' AND (xlei2.start_date_active IS NULL OR'
      || ' xlei2.start_date_active  <= TRUNC(trn2.trans_date))'
      || ' AND (xlei2.end_date_active   IS NULL OR'
      || ' xlei2.end_date_active    >= TRUNC(trn2.trans_date))'
      || ' AND xlei.item_div = CASE'
                            || '   WHEN trn.line_type = ''' || cv_line_type_product || ''' THEN '
                            || '        rpmv.item_div_origin '
                            || '   WHEN trn.line_type = ''' || cv_line_type_material || '''  THEN'
                            || '        rpmv.item_div_ahead '
                            || ' END'
      || ' AND xlei2.item_div = CASE'
                            || '   WHEN trn.line_type = ''' || cv_line_type_material || ''' THEN'
                            || '        rpmv.item_div_origin'
                            || '   WHEN trn.line_type = ''' || cv_line_type_product || ''' THEN'
                            || '        rpmv.item_div_ahead'
                            || ' END'
      || ' AND rpmv.item_id  = trn.item_id'
    ---------------------------------------------------------------------------------------------
    -- OPM�q�Ƀ}�X�^�̍i���ݏ���
      || ' AND trn.whse_code           = iwm.whse_code'
    ---------------------------------------------------------------------------------------------
    -- ���Ə����VIEW�̍i���ݏ���
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- �N�C�b�N�R�[�hIEW�̍i���ݏ���
      -- �󕥋敪
      || ' AND xlv1.lookup_type         = ''' || cv_div_type || ''''
      || ' AND rpmv.new_div_account     = xlv1.lookup_code'
      || ' AND (xlv1.start_date_active IS NULL OR'
      || ' xlv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv1.end_date_active   IS NULL OR'
      || ' xlv1.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv1.language           = ''' || gc_ja || ''''
      || ' AND xlv1.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv1.enabled_flag       = ''' || cv_yes || ''''
      -- ���[��
      || ' AND xlv2.lookup_type        = ''' || cv_out_flag || ''''
      || ' AND rpmv.dealings_div       = xlv2.meaning'
      || ' AND (xlv2.start_date_active IS NULL OR'
      || ' xlv2.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv2.end_date_active   IS NULL OR'
      || ' xlv2.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv2.language           = ''' || gc_ja || ''''
      || ' AND xlv2.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv2.enabled_flag       = ''' || cv_yes || ''''
      || ' AND xlv2.attribute4         IS NOT NULL'   -- ���[�t���O�i770D�̏ꍇ�j
      -- ���C���^�C�v
      || ' AND xlv3.lookup_type(+)     = ''' || cv_line_type || ''''
      || ' AND rpmv.line_type          = xlv3.lookup_code(+)'
      || ' AND (xlv3.start_date_active IS NULL OR'
      || ' xlv3.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv3.end_date_active   IS NULL OR'
      || ' xlv3.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv3.language(+)        = ''' || gc_ja || ''''
      || ' AND xlv3.source_lang(+)     = ''' || gc_ja || ''''
      || ' AND xlv3.enabled_flag(+)    = ''' || cv_yes || ''''
      -- ����敪
      || ' AND xlv4.lookup_type     = ''' || cv_deal_div || ''''
      || ' AND rpmv.dealings_div    = xlv4.lookup_code'
      || ' AND (xlv4.start_date_active IS NULL OR'
      || ' xlv4.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv4.end_date_active   IS NULL OR'
      || ' xlv4.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv4.language        = ''' || gc_ja || ''''
      || ' AND xlv4.source_lang     = ''' || gc_ja || ''''
      || ' AND xlv4.enabled_flag    = ''' || cv_yes || ''''
      || ' AND xlv4.meaning      in (''' || cv_div_kind_transfer || ''','
                                 || '''' || cv_div_item_transfer || ''')'   -- �i��U��,�i�ڐU��
      ;
--
    -- �r�p�k����
    lv_sql_prod2 := lv_select_prod ||
                    lv_from_prod   ||
                    lv_where_prod;
--
    -- ----------------------------------------------------
    -- �o�n�q�b����_����(PO)
    -- ----------------------------------------------------
--
    lv_select_porc := ' SELECT '
      || '   CASE'
      || '    WHEN rpmv.source_document_code = ''' || cv_po || ''' THEN xvv1.segment1'
      || '    ELSE NULL'
      || '   END AS div_tocode'    -- �󕥐�R�[�h
      || '  ,CASE'
      || '    WHEN rpmv.source_document_code = ''' || cv_po || ''' THEN xvv1.vendor_short_name'
      || '    ELSE NULL'
      || '   END AS div_toname'    -- �󕥐於��
      || '  ,NULL                     AS reason_code'       -- ���R�R�[�h
      || '  ,NULL                     AS reason_name'       -- ���R����
      || '  ,rpmv.result_post         AS post_code'         -- �����R�[�h
      || '  ,loca.location_short_name AS post_name'         -- ������
      ;
--
    lv_from_porc := ' FROM'
      || ' xxcmn_rcv_pay_mst_porc_po_v rpmv'  -- ��View_PORC
      || ',ic_tran_pnd                 trn'   -- OPM�ۗ��݌Ƀg����
      -- �}�X�^���
      || ',xxcmn_vendors2_v          xvv1'    -- �d������view2
      || ',xxcmn_locations2_v        loca'    -- ���Ə����VIEW
      ;
--
    lv_where_porc := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_porc || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.doc_id              = rpmv.doc_id'
      || '   AND trn.doc_line            = rpmv.doc_line'
      || '   AND trn.line_id             = rpmv.line_id '
    --�}�X�^�֘A
    ---------------------------------------------------------------------------------------------
    -- ���Ə����VIEW�̍i���ݏ���
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- �d������VIEW�̍i���ݏ���
      || ' AND rpmv.vendor_id          = xvv1.vendor_id(+)'
      || ' AND (xvv1.start_date_active IS NULL OR'
      || ' xvv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xvv1.end_date_active   IS NULL OR'
      || ' xvv1.end_date_active    >= TRUNC(trn.trans_date))'
      ;
--
    -- �r�p�k����
    lv_sql_porc1 := lv_select_porc || lv_select ||
                    lv_from_porc   || lv_from   ||
                    lv_where_porc  || lv_where;
--
    -- ������
    lv_select_porc := '';
    lv_from_porc   := '';
    lv_where_porc  := '';
    -- ----------------------------------------------------
    -- �o�n�q�b����_����(RMA)
    -- ----------------------------------------------------
--
    lv_select_porc := ' SELECT '
      || '   NULL                     AS div_tocode'        -- �󕥐�R�[�h
      || '  ,NULL                     AS div_toname'        -- �󕥐於��
      || '  ,NULL                     AS reason_code'       -- ���R�R�[�h
      || '  ,NULL                     AS reason_name'       -- ���R����
      || '  ,rpmv.result_post         AS post_code'         -- �����R�[�h
      || '  ,loca.location_short_name AS post_name'         -- ������
      || '  ,trn.trans_date           AS trans_date'        -- �����
      || '  ,rpmv.new_div_account     AS new_div_account'   -- �󕥋敪
      || '  ,xlv1.meaning             AS div_name'          -- �󕥋敪��
      || '  ,NVL(rpmv.item_id,trn.item_id) AS item_id'      -- �i�ڂh�c
      || '  ,ximv.item_no             AS item_code'         -- �i�ڃR�[�h
      || '  ,ximv.item_short_name     AS item_name'         -- �i�ږ���
      || '  ,trn.whse_code            AS whse_code'         -- �q�ɃR�[�h
      || '  ,iwm.whse_name            AS whse_name'         -- �q�ɖ���
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute1)     AS wip_date'          -- ������
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_no)             AS lot_no'            -- ���b�g
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute2)     AS original_char'     -- �ŗL�L��
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute3)     AS use_by_date'       -- �ܖ�����
      || '  ,xlei.item_attribute15    AS cost_mng_clss'     -- �����Ǘ��敪
      || '  ,xlei.lot_ctl             AS lot_ctl'           -- ���b�g�Ǘ��敪
      || '  ,xlei.actual_unit_price   AS actual_unit_price' -- ���ےP��
-- 2008/08/20 v1.9 UPDATE START
/*
      || '  ,NVL2(rpmv.item_id, '
      ||      ' trn.trans_qty, '
      ||      ' DECODE(rpmv.dealings_div_name,''' || gv_haiki || ''' '
      ||      '       ,trn.trans_qty '
      ||      '       , ''' || gv_mihon || ''' '
      ||      '       ,trn.trans_qty '
      ||      ',trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div))) trans_qty ' -- ����
*/
      ||      ',DECODE(rpmv.dealings_div_name,''' || gv_haiki || ''' '
      ||      '       ,trn.trans_qty '
      ||      '       , ''' || gv_mihon || ''' '
      ||      '       ,trn.trans_qty '
      ||      ',trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div)) trans_qty ' -- ����
-- 2008/08/20 v1.9 UPDATE END
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute18)    AS lot_desc'          -- �E�v
      ;
--
    lv_from_porc := ' FROM'
      || ' xxcmn_rcv_pay_mst_porc_rma04_v rpmv'  -- ��View_PORC
      || ',ic_tran_pnd                  trn'   -- OPM�ۗ��݌Ƀg����
      || ',xxcmn_item_mst2_v            ximv'  -- �i�ڃ}�X�^VIEW
      || ',xxcmn_locations2_v           loca'  -- ���Ə����VIEW
      ;
--
    lv_where_porc := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_porc || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.doc_id              = rpmv.doc_id'
      || '   AND trn.doc_line            = rpmv.doc_line'
      || '   AND trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--�����
      || '   AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--�����
      || '   AND rpmv.prod_div   = ''' || ir_param.goods_class || ''''  -- ���Ұ��F���i�敪
      || '   AND rpmv.item_div   = ''' || ir_param.item_class || ''''   -- ���Ұ��F�i�ڋ敪
      || lv_sql_para   -- ���Ұ��ݒ�
    --�}�X�^�֘A
    ---------------------------------------------------------------------------------------------
    -- ���b�g�ʕi�ڏ��VIEW�̍i���ݏ���
      || ' AND trn.item_id             = xlei.item_id'
      || ' AND trn.lot_id              = xlei.lot_id'
      || ' AND (xlei.start_date_active IS NULL OR'
      || ' xlei.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlei.end_date_active   IS NULL OR'
      || ' xlei.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- �i�ڃ}�X�^���VIEW�̍i���ݏ���
      || ' AND ximv.item_id           = NVL(rpmv.item_id, trn.item_id)'
      || ' AND (ximv.start_date_active IS NULL OR'
      || ' ximv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (ximv.end_date_active   IS NULL OR'
      || ' ximv.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- OPM�q�Ƀ}�X�^�̍i���ݏ���
      || ' AND trn.whse_code           = iwm.whse_code'
    ---------------------------------------------------------------------------------------------
    -- ���Ə����VIEW�̍i���ݏ���
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- �N�C�b�N�R�[�hIEW�̍i���ݏ���
      -- �󕥋敪
      || ' AND xlv1.lookup_type         = ''' || cv_div_type || ''''
      || ' AND rpmv.new_div_account     = xlv1.lookup_code'
      || ' AND (xlv1.start_date_active IS NULL OR'
      || ' xlv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv1.end_date_active   IS NULL OR'
      || ' xlv1.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv1.language           = ''' || gc_ja || ''''
      || ' AND xlv1.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv1.enabled_flag       = ''' || cv_yes || ''''
      -- ���[��
      || ' AND xlv2.lookup_type        = ''' || cv_out_flag || ''''
      || ' AND rpmv.dealings_div       = xlv2.meaning'
      || ' AND (xlv2.start_date_active IS NULL OR'
      || ' xlv2.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv2.end_date_active   IS NULL OR'
      || ' xlv2.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv2.language           = ''' || gc_ja || ''''
      || ' AND xlv2.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv2.enabled_flag       = ''' || cv_yes || ''''
      || ' AND xlv2.attribute4         IS NOT NULL'   -- ���[�t���O�i770D�̏ꍇ�j
      ;
--
    -- �r�p�k����
    lv_sql_porc2 := lv_select_porc ||
                    lv_from_porc   || lv_from   ||
                    lv_where_porc  ;
--
    -- ----------------------------------------------------
    -- �n�l�r�n����_����
    -- ----------------------------------------------------
--
    lv_select_omso := ' SELECT '
      || '   CASE'
      || '    WHEN rpmv.shipment_provision_div = ''' || cv_ship_type || ''''
      || '      OR rpmv.shipment_provision_div = ''' || cv_pay_type  || ''''
      || '    THEN xpv.party_number'
      || '    ELSE NULL'
      || '   END AS div_tocode'    -- �󕥐�R�[�h
      || '  ,CASE'
      || '    WHEN rpmv.shipment_provision_div = ''' || cv_ship_type || ''''
      || '      OR rpmv.shipment_provision_div = ''' || cv_pay_type || ''''
      || '    THEN xpv.party_short_name'
      || '    ELSE NULL'
      || '   END AS div_toname'    -- �󕥐於��
      || '  ,NULL                     AS reason_code'       -- ���R�R�[�h
      || '  ,NULL                     AS reason_name'       -- ���R����
      || '  ,rpmv.result_post         AS post_code'         -- �����R�[�h
      || '  ,loca.location_short_name AS post_name'         -- ������
      || '  ,trn.trans_date           AS trans_date'        -- �����
      || '  ,rpmv.new_div_account     AS new_div_account'   -- �󕥋敪
      || '  ,xlv1.meaning             AS div_name'          -- �󕥋敪��
      || '  ,NVL(rpmv.item_id,trn.item_id) AS item_id'      -- �i�ڂh�c
      || '  ,ximv.item_no             AS item_code'         -- �i�ڃR�[�h
      || '  ,ximv.item_short_name     AS item_name'         -- �i�ږ���
      || '  ,trn.whse_code            AS whse_code'         -- �q�ɃR�[�h
      || '  ,iwm.whse_name            AS whse_name'         -- �q�ɖ���
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute1)     AS wip_date'          -- ������
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_no)             AS lot_no'            -- ���b�g
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute2)     AS original_char'     -- �ŗL�L��
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute3)     AS use_by_date'       -- �ܖ�����
      || '  ,xlei.item_attribute15    AS cost_mng_clss'     -- �����Ǘ��敪
      || '  ,xlei.lot_ctl             AS lot_ctl'           -- ���b�g�Ǘ��敪
      || '  ,xlei.actual_unit_price   AS actual_unit_price' -- ���ےP��
-- 2008/08/20 v1.9 UPDATE START
/*
      || '  ,NVL2(rpmv.item_id, '
      ||      ' trn.trans_qty, '
      ||      ' DECODE(rpmv.dealings_div_name,''' || gv_haiki || ''' '
      ||      '       ,trn.trans_qty '
      ||      '       , ''' || gv_mihon || ''' '
      ||      '       ,trn.trans_qty '
      ||      ',trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div))) trans_qty ' -- ����
*/
      ||      ',DECODE(rpmv.dealings_div_name,''' || gv_haiki || ''' '
      ||      '       ,trn.trans_qty '
      ||      '       , ''' || gv_mihon || ''' '
      ||      '       ,trn.trans_qty '
      ||      ',trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div)) trans_qty ' -- ����
-- 2008/08/20 v1.9 UPDATE END
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute18)    AS lot_desc'          -- �E�v
      ;
--
    lv_from_omso := ' FROM'
      || ' xxcmn_rcv_pay_mst_omso_v    rpmv'  -- ��View_OMSO
      || ',ic_tran_pnd                 trn'   -- OPM�ۗ��݌Ƀg����
      -- �}�X�^���
      || ',xxcmn_party_sites2_v      xpsv'    -- �p�[�e�B�T�C�g���View
      || ',xxcmn_parties2_v          xpv'     -- �p�[�e�B���View
      || ',xxcmn_locations2_v        loca'    -- ���Ə����VIEW
      || ',xxcmn_item_mst2_v         ximv'  -- �i�ڃ}�X�^VIEW
      ;
--
    lv_where_omso := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_omso || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.line_detail_id      = rpmv.doc_line'
      || '   AND trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--�����
      || '   AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--�����
      || '   AND rpmv.prod_div   = ''' || ir_param.goods_class || ''''  -- ���Ұ��F���i�敪
      || '   AND rpmv.item_div   = ''' || ir_param.item_class || ''''   -- ���Ұ��F�i�ڋ敪
      || '   AND DECODE(rpmv.arrival_date,NULL,rpmv.schedule_arrival_date,rpmv.arrival_date)'
      || '     >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--���ד�
      || '   AND DECODE(rpmv.arrival_date,NULL,rpmv.schedule_arrival_date,rpmv.arrival_date)'
      || '   <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--���ד�
      || lv_sql_para   -- ���Ұ��ݒ�
    --�}�X�^�֘A
    ---------------------------------------------------------------------------------------------
    -- ���b�g�ʕi�ڏ��VIEW�̍i���ݏ���
      || ' AND trn.item_id             = xlei.item_id'
      || ' AND trn.lot_id              = xlei.lot_id'
      || ' AND (xlei.start_date_active IS NULL OR'
      || ' xlei.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlei.end_date_active   IS NULL OR'
      || ' xlei.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- �i�ڃ}�X�^���VIEW�̍i���ݏ���
      || ' AND ximv.item_id           = NVL(rpmv.item_id, trn.item_id)'
      || ' AND (ximv.start_date_active IS NULL OR'
      || ' ximv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (ximv.end_date_active   IS NULL OR'
      || ' ximv.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- OPM�q�Ƀ}�X�^�̍i���ݏ���
      || ' AND trn.whse_code           = iwm.whse_code'
    ---------------------------------------------------------------------------------------------
    -- ���Ə����VIEW�̍i���ݏ���
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- �N�C�b�N�R�[�hIEW�̍i���ݏ���
      -- �󕥋敪
      || ' AND xlv1.lookup_type         = ''' || cv_div_type || ''''
      || ' AND rpmv.new_div_account     = xlv1.lookup_code'
      || ' AND (xlv1.start_date_active IS NULL OR'
      || ' xlv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv1.end_date_active   IS NULL OR'
      || ' xlv1.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv1.language           = ''' || gc_ja || ''''
      || ' AND xlv1.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv1.enabled_flag       = ''' || cv_yes || ''''
      -- ���[��
      || ' AND xlv2.lookup_type        = ''' || cv_out_flag || ''''
      || ' AND rpmv.dealings_div       = xlv2.meaning'
      || ' AND (xlv2.start_date_active IS NULL OR'
      || ' xlv2.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv2.end_date_active   IS NULL OR'
      || ' xlv2.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv2.language           = ''' || gc_ja || ''''
      || ' AND xlv2.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv2.enabled_flag       = ''' || cv_yes || ''''
      || ' AND xlv2.attribute4         IS NOT NULL'   -- ���[�t���O�i770D�̏ꍇ�j
    ---------------------------------------------------------------------------------------------
    -- �p�[�e�B���VIEW�̍i���ݏ���
      || ' AND xpsv.party_site_id(+) = rpmv.deliver_to_id'
      || ' AND xpsv.party_id = xpv.party_id(+)'
      || ' AND (xpsv.start_date_active IS NULL OR'
      || ' xpsv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xpsv.end_date_active   IS NULL OR'
      || ' xpsv.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND (xpv.start_date_active IS NULL OR'
      || ' xpv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xpv.end_date_active   IS NULL OR'
      || ' xpv.end_date_active    >= TRUNC(trn.trans_date))'
      ;
--
    -- �r�p�k����
    lv_sql_omso := lv_select_omso ||
                   lv_from_omso   || lv_from   ||
                   lv_where_omso  ;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_order_by := ' ORDER BY'
                || ' new_div_account'   -- �󕥋敪
                || ',reason_code'       -- ���R�R�[�h
                || ',item_code'         -- �i�ڃR�[�h
                || ',whse_code'         -- �q�ɃR�[�h
                || ',lot_no'            -- ���b�gNo
                ;
    lv_sql1 :=  lv_sql_xfer
            ||  ' UNION ALL '
            ||  lv_sql_trni
            ||  ' UNION ALL '
            ||  lv_sql_adji1
            ||  ' UNION ALL '
            ||  lv_sql_adji2
            ||  ' UNION ALL '
            ||  lv_sql_adji_x201
            ||  ' UNION ALL '
            ||  lv_sql_adji_x988
            ||  ' UNION ALL '
            ;
    lv_sql2 :=  lv_sql_adji_x123
            ||  ' UNION ALL '
            ||  lv_sql_prod1
            ||  ' UNION ALL '
            ||  lv_sql_prod2
            ||  ' UNION ALL '
            ||  lv_sql_porc1
            ||  ' UNION ALL '
            ||  lv_sql_porc2
            ||  ' UNION ALL '
            ||  lv_sql_omso
            ||  lv_order_by
            ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql1 || lv_sql2 ;
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
   * Procedure Name   : fnc_item_unit_pric_get
   * Description      : �W�������̎擾
   ***********************************************************************************/
  FUNCTION fnc_item_unit_pric_get(
       iv_item_id    IN   VARCHAR2  -- �i�ڂh�c
      ,id_trans_date IN   DATE)     -- �����
      RETURN NUMBER
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_item_unit_pric_get' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    -- �����߂�l
    on_unit_price NUMBER DEFAULT 0;
--
  BEGIN
    -- =========================================
    -- �W�������}�X�^���W���P�����擾���܂��B=
    -- =========================================
    BEGIN
      SELECT stnd_unit_price as price
      INTO   on_unit_price
      FROM   xxcmn_stnd_unit_price_v xsup
      WHERE  xsup.item_id    = iv_item_id
        AND (xsup.start_date_active IS NULL OR
             xsup.start_date_active  <= TRUNC(id_trans_date))
        AND (xsup.end_date_active   IS NULL OR
             xsup.end_date_active    >= TRUNC(id_trans_date));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_unit_price :=  0;
    END;
    RETURN  on_unit_price;
--
  END fnc_item_unit_pric_get;
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
    lc_flg_y                CONSTANT VARCHAR2(1) := 'Y';
    lc_flg_n                CONSTANT VARCHAR2(1) := 'N';
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_div_code         VARCHAR2(100) DEFAULT lc_break_init ;  -- �󕥋敪
    lv_reason_code      VARCHAR2(100) DEFAULT lc_break_init ;  -- ���R�R�[�h
    lv_item_code        VARCHAR2(100) DEFAULT lc_break_init ;  -- �i�ڃR�[�h
    lv_cost_kbn         VARCHAR2(100) DEFAULT lc_break_init ;  -- �����Ǘ��敪
    lv_locat_code       VARCHAR2(100) DEFAULT lc_break_init ;  -- �q�ɃR�[�h
    lv_lot_no           VARCHAR2(100) DEFAULT lc_break_init ;  -- ���b�gNo
    lv_flg              VARCHAR2(1)   DEFAULT lc_break_init;
--
    -- �v�Z�p
    ln_quantity         NUMBER DEFAULT 0 ;      -- ����
    ln_amount           NUMBER DEFAULT 0 ;      -- ���z
    ln_stand_unit_price NUMBER DEFAULT 0 ;      -- �W������
--
    lr_data_dtl         rec_data_type_dtl;      -- �\����
--
    lb_ret                  BOOLEAN;
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
    ---------------------
    -- XML�^�O�}������
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR       -- �^�O�^�C�v  T:�^�O
                                                  -- D:�f�[�^
                                                  -- N:�f�[�^(NULL�̏ꍇ�^�O�������Ȃ�)
                                                  -- Z:�f�[�^(NULL�̏ꍇ0�\��)
       ,iv_name              IN        VARCHAR2                --   �^�O��
       ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   �^�O�f�[�^(�ȗ���
       ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   �������i�o�C�g�j(�ȗ���
       ,iv_index             IN        NUMBER    DEFAULT NULL  --   �C���f�b�N�X(�ȗ���
      )
    IS
      -- *** ���[�J���ϐ� ***
      ln_xml_idx  NUMBER;
      ln_work     NUMBER;
      lv_work     VARCHAR2(32000);
--
    BEGIN
--
      IF (ic_type = gc_n) THEN
        --NULL�̏ꍇ�^�O�������Ȃ��Ή�
        IF (iv_value IS NULL) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      END IF;
--
      --�C���f�b�N�X
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      lv_work := iv_value;
--
      --�^�O�Z�b�g
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<�^�O��>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<�^�O�̂�>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<�^�O �� �f�[�^>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(lv_work, 0) ; --Null�̏ꍇ�O�\��
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := lv_work ;         --Null�ł����̂܂ܕ\��
        END IF;
      END IF;
--
      --�����؂�
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
      END IF;
--
    END prc_set_xml ;
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
    prc_set_xml('T', 'user_info');
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
--
    -- ���[�h�c
    prc_set_xml('D', 'report_id', gv_report_id);
    -- ���{��
    prc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
    -- �S������
    prc_set_xml('D', 'exec_user_dept', gv_user_dept, 10);
    -- �S���Җ�
    prc_set_xml('D', 'exec_user_name', gv_user_name, 14);
    -- �����N��
    prc_set_xml('D', 'exec_year', SUBSTR(ir_param.exec_year_month, 1, 4) );
    prc_set_xml('D', 'exec_month', TO_CHAR( SUBSTR(ir_param.exec_year_month, 5, 2), '00') );
    -- ���i�敪
    prc_set_xml('D', 'prod_div', ir_param.goods_class);
    prc_set_xml('D', 'prod_div_name', gv_goods_class_name, 20);
    -- �i�ڋ敪
    prc_set_xml('D', 'item_div', ir_param.item_class);
    prc_set_xml('D', 'item_div_name', gv_item_class_name, 20);
    -- ���R�R�[�h(�p�����[�^)
    prc_set_xml('D', 'p_reason_code', ir_param.reason_code);
    prc_set_xml('D', 'p_reason_name', gv_reason_name, 20);
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T','/user_info');
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- -----------------------------------------------------
    -- �󕥋敪�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_div');
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- ���׏o��(���Ŏ�)
      -- =====================================================
      IF  (( NVL( gt_main_data(i).h_div_code, lc_break_null ) <> lv_div_code )
           OR  ( NVL( gt_main_data(i).h_reason_code, lc_break_null ) <> lv_reason_code )
           OR  ( NVL( gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_code ))
      AND (( lv_locat_code <> lc_break_init ) AND ( lv_lot_no <> lc_break_init )) THEN
--
        -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
        IF (lv_cost_kbn = gc_cost_st ) THEN
          ln_amount := ln_stand_unit_price * ln_quantity;
        END IF;
        -- -----------------------------------------------------
        -- ���b�g�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        IF ( lv_flg <> lc_flg_y ) THEN
          prc_set_xml('T', 'lg_lot');
        END IF;
        -- -----------------------------------------------------
        -- ���b�g�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_lot');
        -- -----------------------------------------------------
        -- ���ׂf�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �q��
        prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
        prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
        -- ������
        prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
        -- ���b�g�m��
        prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
        -- �ŗL�L��
        prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
        -- �ܖ�����
        prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
        -- ����
        prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
        -- �P��
        -- �����Ǘ��敪���u���ی����v�̏ꍇ
        IF (lv_cost_kbn = gc_cost_ac ) THEN
           -- ���b�g�Ǘ��敪���u���b�g�Ǘ��L��v�̏ꍇ
          IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
            prc_set_xml('D', 'unit_price',
                                  TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
           -- ���b�g�Ǘ��敪���u���b�g�Ǘ������v�̏ꍇ
          ELSE
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          END IF;
        -- �����Ǘ��敪���u�W�������v�̏ꍇ
        ELSIF (lv_cost_kbn = gc_cost_st ) THEN
          prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
        -- ����ȊO
        ELSE
          prc_set_xml('D', 'unit_price', '0');
        END IF;
        -- ���o�ɋ��z
        prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
        -- �󕥐�
        prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
        prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
        -- ���ѕ���
        prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
        prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
        -- �E�v
        prc_set_xml('D', 'description', lr_data_dtl.description, 20);
        lv_flg := lc_flg_y;
        -- -----------------------------------------------------
        -- ���b�g�f�I���^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', '/g_lot');
        -- �v�Z���ڏ�����
        ln_quantity := 0;
        ln_amount   := 0;
      END IF;
--
      -- =====================================================
      -- �󕥋敪�u���C�N
      -- =====================================================
      -- �󕥋敪���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).h_div_code, lc_break_null ) <> lv_div_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_div_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ���b�g�k�f�I���^�O�o��
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- ���R�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_reason');
          ------------------------------
          -- ���R�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_reason');
          ------------------------------
          -- �󕥋敪�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_div');
        END IF ;
--
        -- -----------------------------------------------------
        -- �󕥋敪�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_div');
        -- -----------------------------------------------------
        -- �󕥋敪�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �󕥋敪
        prc_set_xml('D', 'div_code', gt_main_data(i).h_div_code);
        prc_set_xml('D', 'div_name', gt_main_data(i).h_div_name, 20);
        -- -----------------------------------------------------
        -- ���R�R�[�h�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'lg_reason');
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_div_code := NVL( gt_main_data(i).h_div_code, lc_break_null )  ;
        lv_reason_code  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ���R�R�[�h�u���C�N
      -- =====================================================
      -- ���R�R�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).h_reason_code, lc_break_null ) <> lv_reason_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_reason_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ���b�g�k�f�I���^�O�o��
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- ���R�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_reason');
        END IF ;
--
        -- -----------------------------------------------------
        -- ���R�R�[�h�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_reason');
        -- -----------------------------------------------------
        -- ���R�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���R
        prc_set_xml('D', 'reason_code', gt_main_data(i).h_reason_code);
        prc_set_xml('D', 'reason_name', gt_main_data(i).h_reason_name, 20);
        ------------------------------
        -- �i�ڂk�f�J�n�^�O
        ------------------------------
          prc_set_xml('T', 'lg_item');
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_reason_code := NVL( gt_main_data(i).h_reason_code, lc_break_null ) ;
        lv_item_code   := lc_break_init ;
        lv_cost_kbn    := lc_break_init ;
--
      END IF ;
      -- =====================================================
      -- �i�ڃu���C�N
      -- =====================================================
      -- �i�ڂ��؂�ւ�����ꍇ
      IF  (NVL(gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_code ) THEN
--
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF  ( lv_item_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ���b�g�k�f�I���^�O�o��
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
        END IF ;
--
        -- -----------------------------------------------------
        -- �i�ڂf�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_item');
        -- -----------------------------------------------------
        -- �i�ڂf�^�O�o��
        -- -----------------------------------------------------
        -- �i��
        prc_set_xml('D', 'item_code', gt_main_data(i).h_item_code);
        prc_set_xml('D', 'item_name', gt_main_data(i).h_item_name, 20);
--
        -- �W���������擾
        ln_stand_unit_price := fnc_item_unit_pric_get( gt_main_data(i).item_id,
                                                       gt_main_data(i).trans_date);
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_code  := NVL( gt_main_data(i).h_item_code, lc_break_null ) ;
        lv_cost_kbn   := NVL( gt_main_data(i).cost_kbn, lc_break_null ) ;
        lv_locat_code := lc_break_init ;
        lv_lot_no     := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      IF (( lv_locat_code <> lc_break_init ) AND ( lv_lot_no <> lc_break_init )) THEN
        IF   (( lr_data_dtl.locat_code <> gt_main_data(i).locat_code )    -- �q�ɃR�[�h
           OR ( lr_data_dtl.lot_no     <> gt_main_data(i).lot_no )) THEN   -- ���b�gNo
--
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_stand_unit_price * ln_quantity;
          END IF;
          -- -----------------------------------------------------
          -- ���b�g�k�f�J�n�^�O�o��
          -- -----------------------------------------------------
          IF ( lv_flg <> lc_flg_y ) THEN
            prc_set_xml('T', 'lg_lot');
          END IF;
          -- -----------------------------------------------------
          -- ���b�g�f�J�n�^�O�o��
          -- -----------------------------------------------------
          prc_set_xml('T', 'g_lot');
          -- -----------------------------------------------------
          -- ���ׂf�f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- �q��
          prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
          prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
          -- ������
          prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
          -- ���b�g�m��
          prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
          -- �ŗL�L��
          prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
          -- �ܖ�����
          prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
          -- ����
          prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- �P��
          -- �����Ǘ��敪���u���ی����v�̏ꍇ
          IF (lv_cost_kbn = gc_cost_ac ) THEN
            -- ���b�g�Ǘ��敪���u���b�g�Ǘ��L��v�̏ꍇ
            IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
              prc_set_xml('D', 'unit_price',
                                    TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
            -- ���b�g�Ǘ��敪���u���b�g�Ǘ������v�̏ꍇ
            ELSE
              prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
            END IF;
          -- �����Ǘ��敪���u�W�������v�̏ꍇ
          ELSIF (lv_cost_kbn = gc_cost_st ) THEN
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          -- ����ȊO
          ELSE
            prc_set_xml('D', 'unit_price', '0');
          END IF;
          -- ���o�ɋ��z
          prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
          -- �󕥐�
          prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
          prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
          -- ���ѕ���
          prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
          prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
          -- �E�v
          prc_set_xml('D', 'description', lr_data_dtl.description, 20);
          lv_flg := lc_flg_y;
          -- -----------------------------------------------------
          -- ���b�g�f�I���^�O�o��
          -- -----------------------------------------------------
          prc_set_xml('T', '/g_lot');
          -- �v�Z���ڏ�����
          ln_quantity := 0;
          ln_amount   := 0;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- �W�v����
      -- -----------------------------------------------------
      -- ���ʉ��Z
      ln_quantity := ln_quantity + NVL(gt_main_data(i).trans_qty, 0);
      -- ���z���Z�i�����Ǘ��敪���u���ی����v�̏ꍇ�j
      IF (lv_cost_kbn = gc_cost_ac ) THEN
        -- ���b�g�Ǘ��敪���u���b�g�Ǘ��L��v�̏ꍇ
        IF (gt_main_data(i).lot_kbn <> gv_lot_n) THEN
          ln_amount := ln_amount
                   + (NVL(gt_main_data(i).trans_qty,0) * NVL(gt_main_data(i).actual_unit_price,0));
        -- ���b�g�Ǘ��敪���u���b�g�Ǘ������v�̏ꍇ
        ELSE
          ln_amount := ln_amount
                   + (NVL(gt_main_data(i).trans_qty,0) * NVL(ln_stand_unit_price,0));
        END IF;
      END IF;
--
      -- �l��ޔ�
      lv_locat_code := NVL(gt_main_data(i).locat_code, lc_break_null );
      lv_lot_no     := NVL(gt_main_data(i).lot_no, lc_break_null );
      lr_data_dtl   := gt_main_data(i);
--
      -- �Ō�̖��ׂ��o��
      IF ( gt_main_data.LAST = i ) THEN
--
        -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
        IF (lv_cost_kbn = gc_cost_st ) THEN
          ln_amount := ln_stand_unit_price * ln_quantity;
        END IF;
        -- -----------------------------------------------------
        -- ���b�g�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        IF ( lv_flg <> lc_flg_y ) THEN
          prc_set_xml('T', 'lg_lot');
        END IF;
        -- -----------------------------------------------------
        -- ���b�g�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_lot');
        -- -----------------------------------------------------
        -- ���ׂf�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �q��
        prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
        prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
        -- ������
        prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
        -- ���b�g�m��
        prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
        -- �ŗL�L��
        prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
        -- �ܖ�����
        prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
        -- ����
        prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
        -- �P��
        -- �����Ǘ��敪���u���ی����v�̏ꍇ
        IF (lv_cost_kbn = gc_cost_ac ) THEN
          -- ���b�g�Ǘ��敪���u���b�g�Ǘ��L��v�̏ꍇ
          IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
            prc_set_xml('D', 'unit_price',
                                  TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
          -- ���b�g�Ǘ��敪���u���b�g�Ǘ������v�̏ꍇ
          ELSE
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          END IF;
        -- �����Ǘ��敪���u�W�������v�̏ꍇ
        ELSIF (lv_cost_kbn = gc_cost_st ) THEN
          prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
        -- ����ȊO
        ELSE
          prc_set_xml('D', 'unit_price', '0');
        END IF;
        -- ���o�ɋ��z
        prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
        -- �󕥐�
        prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
        prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
        -- ���ѕ���
        prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
        prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
        -- �E�v
        prc_set_xml('D', 'description', lr_data_dtl.description, 20);
        lv_flg := lc_flg_y;
        -- -----------------------------------------------------
        -- ���b�g�f�I���^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', '/g_lot');
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    -- ---------------------------
    -- ���b�g�k�f�I���^�O�o��
    -- ---------------------------
    prc_set_xml('T', '/lg_lot');
    ------------------------------
    -- �i�ڂf�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_item');
    ------------------------------
    -- �i�ڂk�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_item');
    ------------------------------
    -- ���R�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_reason');
    ------------------------------
    -- ���R�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_reason');
   ------------------------------
    -- �󕥋敪�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_div');
   ------------------------------
    -- �󕥋敪�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_div');
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/data_info');
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' ) ;
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
      iv_exec_year_month    IN     VARCHAR2         -- 01 : �����N��
     ,iv_goods_class        IN     VARCHAR2         -- 02 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         -- 03 : �i�ڋ敪
     ,iv_div_type1          IN     VARCHAR2         -- 04 : �󕥋敪�P
     ,iv_div_type2          IN     VARCHAR2         -- 05 : �󕥋敪�Q
     ,iv_div_type3          IN     VARCHAR2         -- 06 : �󕥋敪�R
     ,iv_div_type4          IN     VARCHAR2         -- 07 : �󕥋敪�S
     ,iv_div_type5          IN     VARCHAR2         -- 08 : �󕥋敪�T
     ,iv_reason_code        IN     VARCHAR2         -- 09 : ���R�R�[�h
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
    lv_work_date            VARCHAR2(30); -- �ϊ��p
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
    gv_report_id               := 'XXCMN770004T' ;           -- ���[ID
    gd_exec_date               := SYSDATE ;                  -- ���{��
    -- �p�����[�^�i�[
    -- �����N��
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_exec_year_month, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.exec_year_month     := iv_exec_year_month;
    ELSE
      lr_param_rec.exec_year_month     := lv_work_date;
    END IF;
    lr_param_rec.goods_class      := iv_goods_class;       -- ���i�敪
    lr_param_rec.item_class       := iv_item_class;        -- �i�ڋ敪
    lr_param_rec.div_type1        := iv_div_type1;         -- �󕥋敪�P
    lr_param_rec.div_type2        := iv_div_type2;         -- �󕥋敪�Q
    lr_param_rec.div_type3        := iv_div_type3;         -- �󕥋敪�R
    lr_param_rec.div_type4        := iv_div_type4;         -- �󕥋敪�S
    lr_param_rec.div_type5        := iv_div_type5;         -- �󕥋敪�T
    lr_param_rec.reason_code      := iv_reason_code;       -- ���R�R�[�h
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <position>1</position>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_exec_year_month    IN     VARCHAR2         --   01 : �����N��
     ,iv_goods_class        IN     VARCHAR2         --   02 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   03 : �i�ڋ敪
     ,iv_div_type1          IN     VARCHAR2         --   04 : �󕥋敪�P
     ,iv_div_type2          IN     VARCHAR2         --   05 : �󕥋敪�Q
     ,iv_div_type3          IN     VARCHAR2         --   06 : �󕥋敪�R
     ,iv_div_type4          IN     VARCHAR2         --   07 : �󕥋敪�S
     ,iv_div_type5          IN     VARCHAR2         --   08 : �󕥋敪�T
     ,iv_reason_code        IN     VARCHAR2         --   09 : ���R�R�[�h
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
        iv_exec_year_month   => iv_exec_year_month   --   01 : �����N��
       ,iv_goods_class       => iv_goods_class       --   02 : ���i�敪
       ,iv_item_class        => iv_item_class        --   03 : �i�ڋ敪
       ,iv_div_type1         => iv_div_type1         --   04 : �󕥋敪�P
       ,iv_div_type2         => iv_div_type2         --   05 : �󕥋敪�Q
       ,iv_div_type3         => iv_div_type3         --   06 : �󕥋敪�R
       ,iv_div_type4         => iv_div_type4         --   07 : �󕥋敪�S
       ,iv_div_type5         => iv_div_type5         --   08 : �󕥋敪�T
       ,iv_reason_code       => iv_reason_code       --   09 : ���R�R�[�h
       ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END xxcmn770004c ;
/
