CREATE OR REPLACE PACKAGE BODY xxpo330001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo330001c(BODY)
 * Description      : �d���E�L���x���i�d����ԕi�j
 * MD.050/070       : �d���E�L���x���i�d����ԕi�jIssue2.0  (T_MD050_BPO_330)
 *                    �ԕi�w����                            (T_MD070_BPO_33B)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_check_param_info   �p�����[�^�`�F�b�N(B-1)
 *  prc_get_report_data    ���׃f�[�^�擾(B-3)
 *  func_dtl_cnt           ���׃f�[�^�����擾
 *  prc_create_xml_data    �w�l�k�f�[�^�쐬(B-5)
 *  convert_into_xml       XML�f�[�^�ϊ�
 *  func_rank_edit         �����N�P�E�����N�Q�E�����N�R��ҏW�E���� (B-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/21    1.0   Yusuke Tabata   �V�K�쐬
 *  2008/04/28    1.1   Yusuke Tabata   �����ύX#43�^TE080�s��Ή�
 *  2008/05/01    1.2   Yasuhisa Yamamoto TE080�s��Ή�(330_8)
 *  2008/05/02    1.3   Yasuhisa Yamamoto TE080�s��Ή�(330_10)
 *  2008/05/02    1.4   Yasuhisa Yamamoto TE080�s��Ή�(330_11)
 *
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
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'xxpo330001c' ;   -- �p�b�P�[�W��
  gc_report_id              CONSTANT VARCHAR2(12) := 'XXPO330001T' ;   -- ���[ID
  gc_language_code          CONSTANT VARCHAR2(2)  := 'JA' ;            -- ����LANGUAGE_CODE
  --SQL�p
  gc_category_name_prod     CONSTANT VARCHAR2(8)  := '���i�敪' ;     -- �J�e�S���Z�b�g���F���i�敪
  gc_category_name_item     CONSTANT VARCHAR2(8)  := '�i�ڋ敪' ;     -- �J�e�S���Z�b�g���F�i�ڋ敪
  gc_txns_type_rtn_order    CONSTANT VARCHAR2(1)  := '2' ;            -- ���ы敪:�d����ԕi
  gc_txns_type_rtn_noorder  CONSTANT VARCHAR2(1)  := '3' ;            -- ���ы敪:�������d����ԕi
  gc_drop_ship_type_normal  CONSTANT VARCHAR2(1)  := '1' ;            -- �����敪:�ʏ�
  gc_drop_ship_type_sup_req CONSTANT VARCHAR2(1)  := '3' ;            -- �����敪:�x���˗�
  gc_rtn_quant_0            CONSTANT NUMBER       :=  0  ;            -- ����:0��
  gc_creation_date_format   CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �쐬�������t�^�t�H�[�}�b�g
  gc_rtn_date_format        CONSTANT VARCHAR2(19) := 'YYYY/MM/DD' ;            -- �ԕi�������t�^�t�H�[�}�b�g
  -- �G���[�R�[�h
  gc_application          CONSTANT VARCHAR2(5)  := 'XXPO' ;            -- �A�v���P�[�V����
  gc_err_code_data_0      CONSTANT VARCHAR2(15) := 'APP-XXPO-00009' ;  -- �f�[�^�O�����b�Z�[�W
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXPO-10026' ;  -- �f�[�^���擾���b�Z�[�W
  gc_err_code_type_chk    CONSTANT VARCHAR2(15) := 'APP-XXPO-10034' ;  -- �^�`�F�b�N�G���[���b�Z�[�W
  gc_note_code_in_param   CONSTANT VARCHAR2(15) := 'APP-XXPO-30022' ;  -- �p�����[�^���
  gc_note_code_tax_info   CONSTANT VARCHAR2(15) := 'APP-XXPO-30034' ;  -- �P������ŕ���
  --�p�����[�^�o�͗p
  gc_rtn_number           CONSTANT VARCHAR2(15) := '�ԕi�ԍ�' ;
  gc_dept_code            CONSTANT VARCHAR2(15) := '�S������' ;
  gc_tantousya_code       CONSTANT VARCHAR2(15) := '�S����' ;
  gc_creation_date_from   CONSTANT VARCHAR2(15) := '�쐬����FROM' ;
  gc_creation_date_to     CONSTANT VARCHAR2(15) := '�쐬����TO' ;
  gc_vendor_code          CONSTANT VARCHAR2(15) := '�����' ;
  gc_assen_code           CONSTANT VARCHAR2(15) := '������' ;
  gc_location_code        CONSTANT VARCHAR2(15) := '�[����' ;
  gc_rtn_date_from        CONSTANT VARCHAR2(15) := '�ԕi��FROM' ;
  gc_rtn_date_to          CONSTANT VARCHAR2(15) := '�ԕi��TO' ;
  gc_prod_div             CONSTANT VARCHAR2(15) := '���i�敪' ;
  gc_item_div             CONSTANT VARCHAR2(15) := '�i�ڋ敪' ;
  gc_tag_type_t           CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d           CONSTANT VARCHAR2(1)  := 'D' ;
  --���b�Z�[�W�p
  gc_msg_param            CONSTANT VARCHAR2(5)  := 'PARAM' ;
  gc_msg_format           CONSTANT VARCHAR2(6)  := 'FORMAT' ;
  gc_msg_table            CONSTANT VARCHAR2(5)  := 'TABLE' ;
  gc_msg_data             CONSTANT VARCHAR2(4)  := 'DATA';
  gc_table_name           CONSTANT VARCHAR2(20) := '����ԕi����';
-- 08/05/02 Y.Yamamoto ADD v1.3 Start
  --�N�C�b�N�R�[�h�p
  gc_kousen_type          CONSTANT VARCHAR2(16) := 'XXPO_KOUSEN_TYPE';  -- �N�C�b�N�R�[�h(���K�敪)
  gc_fukakin_type         CONSTANT VARCHAR2(17) := 'XXPO_FUKAKIN_TYPE'; -- �N�C�b�N�R�[�h(���ۋ��敪)
-- 08/05/02 Y.Yamamoto ADD v1.3 End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
     rtn_number          xxpo_rcv_and_rtn_txns.rcv_rtn_number%TYPE    -- �ԕi�ԍ�
     ,dept_code          xxcmn_locations_v.location_code%TYPE         -- �S������
     ,tantousya_code     per_all_people_f.employee_number%TYPE        -- �S����
     ,creation_date_from VARCHAR2(19)                                 -- �쐬����FROM
     ,creation_date_to   VARCHAR2(19)                                 -- �쐬����TO
     ,vendor_code        xxpo_rcv_and_rtn_txns.vendor_code%TYPE       -- �����
     ,assen_code         xxpo_rcv_and_rtn_txns.assen_vendor_code%TYPE -- ������
     ,location_code      xxpo_rcv_and_rtn_txns.location_code%TYPE     -- �[����
     ,rtn_date_from      VARCHAR2(19)                                 -- �ԕi��FROM
     ,rtn_date_to        VARCHAR2(19)                                 -- �ԕi��TO
     ,prod_div           xxpo_categories_v.category_code%TYPE         -- ���i�敪
     ,item_div           xxpo_categories_v.category_code%TYPE         -- �i�ڋ敪
    ) ;
  -- �ԕi�w�����f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD
    (
    rtn_number              xxpo_rcv_and_rtn_txns.rcv_rtn_number%TYPE               --����ԕi�ԍ�
    ,vendor_code            xxpo_rcv_and_rtn_txns.vendor_code%TYPE                  --�����R�[�h
    ,vendor_id              xxpo_rcv_and_rtn_txns.vendor_id%TYPE                    --�����ID
    ,verndor_name           xxcmn_vendors2_v.vendor_full_name%TYPE                  --����於��(������)
    ,assen_code             xxpo_rcv_and_rtn_txns.assen_vendor_code%TYPE            --�����҃R�[�h
    ,assen_name             xxcmn_vendors2_v.vendor_full_name%TYPE                  --�����Җ���(������)
    ,location_code          xxpo_rcv_and_rtn_txns.location_code%TYPE                --���o�ɐ�R�[�h
    ,location_name          xxcmn_item_locations2_V.description%TYPE                --�ۊǏꏊ��
    ,rtn_date               xxpo_rcv_and_rtn_txns.txns_date%TYPE                    --�����
    ,header_desc            xxpo_rcv_and_rtn_txns.header_description%TYPE           --�w�b�_�E�v
    ,dept_code              xxpo_rcv_and_rtn_txns.department_code%TYPE              --�S�������R�[�h
    ,item_code              xxpo_rcv_and_rtn_txns.item_code%TYPE                    --�i��
    ,futai_code             xxpo_rcv_and_rtn_txns.futai_code%TYPE                   --�t�уR�[�h
    ,item_name              xxcmn_item_mst2_v.item_name%TYPE                        --�i�ږ�
    ,stock_quant            ic_lots_mst.attribute6%TYPE                             --�݌ɓ���
-- 08/05/02 Y.Yamamoto ADD v1.4 Start
    ,quantity               xxpo_rcv_and_rtn_txns.quantity%TYPE                     --����
-- 08/05/02 Y.Yamamoto ADD v1.4 End
    ,rtn_quant              xxpo_rcv_and_rtn_txns.rcv_rtn_quantity%TYPE             --����ԕi����
    ,rtn_uom                xxpo_rcv_and_rtn_txns.rcv_rtn_uom%TYPE                  --����ԕi�P��
    ,rtn_unit_price         xxpo_rcv_and_rtn_txns.unit_price%TYPE                   --�P��
    ,lot_number             xxpo_rcv_and_rtn_txns.lot_number%TYPE                   --���b�gNo
    ,make_date              ic_lots_mst.attribute1%TYPE                             --�����N����
    ,limit_date             ic_lots_mst.attribute3%TYPE                             --�ܖ�����
    ,lot_sign               ic_lots_mst.attribute2%TYPE                             --�ŗL�L��
    ,factory_code           xxpo_rcv_and_rtn_txns.factory_code%TYPE                 --�H��R�[�h
    ,delivery_code          xxpo_rcv_and_rtn_txns.delivery_code%TYPE                --�z����R�[�h
    ,factory_name           xxcmn_vendors2_v.vendor_short_name%TYPE                 --�H�ꖼ
    ,delivery_name          xxcmn_vendors2_v.vendor_short_name%TYPE                 --�z���於
    ,stocking_type          ic_lots_mst.attribute9%TYPE                             --�d���`��
    ,nendo                  ic_lots_mst.attribute11%TYPE                            --�N�x
    ,reaf_devision          ic_lots_mst.attribute10%TYPE                            --�����敪
    ,home                   ic_lots_mst.attribute12%TYPE                            --�Y�n
    ,pack_type              ic_lots_mst.attribute13%TYPE                            --�^�C�v
    ,rank1                  ic_lots_mst.attribute14%TYPE                            --�����N�P
    ,rank2                  ic_lots_mst.attribute15%TYPE                            --�����N�Q
    ,rank3                  ic_lots_mst.attribute19%TYPE                            --�����N�R
    ,line_desc              xxpo_rcv_and_rtn_txns.line_description%TYPE             --���דE�v
    ,kobiki_rate            xxpo_rcv_and_rtn_txns.kobiki_rate%TYPE                  --������
    ,kousen_type            xxpo_rcv_and_rtn_txns.kousen_type%TYPE                  --���K�敪
    ,fukakin_type           xxpo_rcv_and_rtn_txns.fukakin_type%TYPE                 --���ۋ��敪
    ,kobiki_unt_price       xxpo_rcv_and_rtn_txns.kobki_converted_unit_price%TYPE   --������P��
    ,kousen_unt_price       xxpo_rcv_and_rtn_txns.kousen_rate_or_unit_price%TYPE    --���K
    ,fukakin_unt_price      xxpo_rcv_and_rtn_txns.fukakin_rate_or_unit_price%TYPE   --���ۋ�
    ,kobiki_price           xxpo_rcv_and_rtn_txns.kobki_converted_price%TYPE        --��������z
    ,kousen_price           xxpo_rcv_and_rtn_txns.kousen_price%TYPE                 --�a����K���z
    ,fukakin_price          xxpo_rcv_and_rtn_txns.fukakin_price%TYPE                --���ۋ��z
    ,drop_ship_type         xxpo_rcv_and_rtn_txns.drop_ship_type%TYPE               --�����敪
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
  TYPE dtl_cnt_map IS TABLE OF NUMBER INDEX BY VARCHAR2(30) ;  -- ��Ɨp���l�^�z��
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
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
  /**********************************************************************************
   * Function Name    : func_rank_edit
   * Description      : �����N�P�E�����N�Q�E�����N�R��ҏW�E���� B-4
   *                    EX ) R1(�����N�P)�|R2(�����N�Q�j�|R3�i�����N�R)
   ***********************************************************************************/
  FUNCTION func_rank_edit
    (
      iv_rank1         IN VARCHAR2   -- �����N�P
     ,iv_rank2         IN VARCHAR2   -- �����N�Q
     ,iv_rank3         IN VARCHAR2   -- �����N�R
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'func_rank_edit' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    cv_blank       CONSTANT VARCHAR2(1) :=' ';
    cv_hyphen      CONSTANT VARCHAR2(1) :='-';
    -- *** ���[�J���ϐ� ***
    ov_edit_data         VARCHAR2(32) ;
--
  BEGIN
--
    -- �����N�P:NULL�̏ꍇ�F���p���ݸ
    IF (iv_rank1 IS NULL) THEN
      ov_edit_data := cv_blank ;
    ELSE
      ov_edit_data := iv_rank1 ;
    END IF ;
    -- ʲ�ݑ}��
    ov_edit_data := ov_edit_data || cv_hyphen ;
    -- �����N�Q:NULL�̏ꍇ�F���p���ݸ
    IF (iv_rank2 IS NULL) THEN
      ov_edit_data := ov_edit_data || cv_blank ;
    ELSE
      ov_edit_data := ov_edit_data || iv_rank2 ;
    END IF ;
    -- ʲ�ݑ}��
    ov_edit_data   := ov_edit_data || cv_hyphen ;
    -- �����N�R:NULL�̏ꍇ�F���p���ݸ
    IF (iv_rank3 IS NULL) THEN
      ov_edit_data := ov_edit_data || cv_blank ;
    ELSE
      ov_edit_data := ov_edit_data || iv_rank3 ;
    END IF ;
    RETURN(ov_edit_data) ;
--
  END func_rank_edit ;
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
--
    --�f�[�^�̏ꍇ
    IF (ic_type = gc_tag_type_d) THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
  /**********************************************************************************
   * Function Name    : func_dtl_cnt
   * Description      : ���׌����z��쐬
   ***********************************************************************************/
  FUNCTION func_dtl_cnt(
    it_dtl_data  IN tab_data_type_dtl
  )RETURN dtl_cnt_map
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_dtl_cnt'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- ���׌����J�E���^
    lv_dtl_cnt NUMBER := 1;
    -- �J�E���^�i�[�p�e�[�u���^�ϐ�
    ot_dtl_cnt_map dtl_cnt_map ;
--
  BEGIN
--
    -- �����Ǎ�����
    <<dtl_data_loop>>
    FOR i in 1..it_dtl_data.count LOOP
      IF (NOT(it_dtl_data.EXISTS(i+1))) THEN
        -- ���׌����J�E���^�l���C���f�b�N�X�F�ԕiNo�̍\���̂֊i�[
        ot_dtl_cnt_map(it_dtl_data(i).rtn_number) := lv_dtl_cnt;
      ELSIF (it_dtl_data(i).rtn_number <> it_dtl_data(i+1).rtn_number) THEN
        -- ���׌����J�E���^�l���C���f�b�N�X�F�ԕiNo�̍\���̂֊i�[
        ot_dtl_cnt_map(it_dtl_data(i).rtn_number) := lv_dtl_cnt;
        -- ���׌����J�E���^������
        lv_dtl_cnt := 1 ;
      ELSE
        -- ���׌����C���N�������g
        lv_dtl_cnt := lv_dtl_cnt + 1;
      END IF ;
    END LOOP dtl_data_loop;
--
    RETURN ot_dtl_cnt_map ;
--
  END func_dtl_cnt;
--
   /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : �p�����[�^�`�F�b�N(B-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
    (
      ir_param      IN     rec_param_data       -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    ln_ret_date                DATE ;        -- ���ʊ֐��߂�l�F���l�^
    lv_err_code               VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
    lv_msg_param_value        VARCHAR2(15);
    lv_msg_format_value       VARCHAR2(21);
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
    -- �p�����[�^���o��
    -- ====================================================
    --�p�����[�^�o��
    -- �ԕi�ԍ�
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_rtn_number
                               ,gc_msg_data
                               ,ir_param.rtn_number));
    -- �S������
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_dept_code
                               ,gc_msg_data
                               ,ir_param.dept_code));
    -- �S����
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_tantousya_code
                               ,gc_msg_data
                               ,ir_param.tantousya_code));
     -- �쐬����FROM
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_creation_date_from
                               ,gc_msg_data
                               ,ir_param.creation_date_from));
    -- �쐬����TO
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_creation_date_to
                               ,gc_msg_data
                               ,ir_param.creation_date_to));
    -- �����
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_vendor_code
                               ,gc_msg_data
                               ,ir_param.vendor_code));
    -- ������
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_assen_code
                               ,gc_msg_data
                               ,ir_param.assen_code));
    -- �[����
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_location_code
                               ,gc_msg_data
                               ,ir_param.location_code));
    -- �ԕi��FROM
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_rtn_date_from
                               ,gc_msg_data
                               ,ir_param.rtn_date_from));
    -- �ԕi��TO
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_rtn_date_to
                               ,gc_msg_data
                               ,ir_param.rtn_date_to));
    -- ���i�敪
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_prod_div
                               ,gc_msg_data
                               ,ir_param.prod_div));
    -- �i�ڋ敪
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_item_div
                               ,gc_msg_data
                               ,ir_param.item_div));
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    -- ====================================================
    -- ���t�ϊ�(YYYY/MM/DD)�`�F�b�N
    -- �ԕi��FROM
    IF ( ir_param.rtn_date_from IS NOT NULL ) THEN
      ln_ret_date := FND_DATE.STRING_TO_DATE(
                                         ir_param.rtn_date_from
                                         ,gc_rtn_date_format
                                         );
      IF ( ln_ret_date IS NULL ) THEN
        lv_err_code := gc_err_code_type_chk ;
        lv_msg_param_value  := gc_rtn_date_from ;
        lv_msg_format_value := gc_rtn_date_format;
        RAISE parameter_check_expt ;
      END IF ;
    END IF;
    -- �ԕi��TO
    IF ( ir_param.rtn_date_to IS NOT NULL ) THEN
      ln_ret_date := FND_DATE.STRING_TO_DATE(
                                            ir_param.rtn_date_to
                                            ,gc_rtn_date_format
                                            );
      IF ( ln_ret_date IS NULL ) THEN
        lv_err_code := gc_err_code_type_chk ;
        lv_msg_param_value  := gc_rtn_date_to ;
        lv_msg_format_value := gc_rtn_date_format;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
    -- ���t�ϊ�(YYYY/MM/DD HH24:MI:SS)�`�F�b�N
    -- �쐬����FROM
    IF ( ir_param.creation_date_from IS NOT NULL ) THEN
      ln_ret_date := FND_DATE.STRING_TO_DATE(
                                            ir_param.creation_date_from
                                            ,gc_creation_date_format
                                           );
      IF ( ln_ret_date IS NULL ) THEN
        lv_err_code := gc_err_code_type_chk ;
        lv_msg_param_value  := gc_creation_date_from ;
        lv_msg_format_value := gc_creation_date_format;
        RAISE parameter_check_expt ;
      END IF ;
    END IF;
    -- �쐬����TO
    IF ( ir_param.creation_date_to IS NOT NULL ) THEN
      ln_ret_date := FND_DATE.STRING_TO_DATE(
                                            ir_param.creation_date_to
                                            ,gc_creation_date_format
                                           );
      IF ( ln_ret_date IS NULL ) THEN
        lv_err_code := gc_err_code_type_chk ;
        lv_msg_param_value  := gc_creation_date_to ;
        lv_msg_format_value := gc_creation_date_format;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O ***
    WHEN parameter_check_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                            ,lv_err_code
                                            ,gc_msg_param
                                            ,lv_msg_param_value
                                            ,gc_msg_format
                                            ,lv_msg_format_value
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
  END prc_check_param_info ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(B-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data
    (
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ���[�J���E�ϐ� ***
    lv_sql_body    VARCHAR2(10000);
--
  BEGIN
--
    lv_sql_body := lv_sql_body || 'SELECT xrcart.rcv_rtn_number AS rtn_number';  -- ����ԕi�ԍ�
    lv_sql_body := lv_sql_body || ',xrcart.vendor_code AS vendor_code';          -- �����R�[�h
    lv_sql_body := lv_sql_body || ',xrcart.vendor_id AS vendor_id';              -- �����ID
    lv_sql_body := lv_sql_body || ',xvv1.vendor_full_name AS verndor_name';      -- ����於��(������)
    lv_sql_body := lv_sql_body || ',xrcart.assen_vendor_code AS assen_code';     -- �����҃R�[�h
    lv_sql_body := lv_sql_body || ',xvv2.vendor_full_name AS assen_name';        -- �����Җ���(������)
    lv_sql_body := lv_sql_body || ',xrcart.location_code AS location_code';      -- ���o�ɐ�R�[�h
    lv_sql_body := lv_sql_body || ',xilv.description AS location_name';          -- �ۊǏꏊ��
    lv_sql_body := lv_sql_body || ',xrcart.txns_date AS rtn_date';               -- �����
    lv_sql_body := lv_sql_body || ',xrcart.header_description AS header_desc';   -- �w�b�_�E�v
    lv_sql_body := lv_sql_body || ',xrcart.department_code AS dept_code';        -- �S�������R�[�h
    lv_sql_body := lv_sql_body || ',xrcart.item_code AS item_code';              -- �i��
    lv_sql_body := lv_sql_body || ',xrcart.futai_code AS futai_code';            -- �t�уR�[�h
    lv_sql_body := lv_sql_body || ',ximv.item_name AS item_name';                -- ������
    lv_sql_body := lv_sql_body || ',xrcart.conversion_factor AS stock_quant';    -- �݌ɓ���(���Z����)
-- 08/05/02 Y.Yamamoto ADD v1.4 Start
    lv_sql_body := lv_sql_body || ',xrcart.quantity AS quantity';                -- ����
-- 08/05/02 Y.Yamamoto ADD v1.4 End
    lv_sql_body := lv_sql_body || ',xrcart.rcv_rtn_quantity AS rtn_quant';       -- ����ԕi����
    lv_sql_body := lv_sql_body || ',xrcart.rcv_rtn_uom AS rtn_uom';              -- ����ԕi�P��
    lv_sql_body := lv_sql_body || ',xrcart.unit_price AS rtn_unit_price';        -- �P��
    lv_sql_body := lv_sql_body || ',xrcart.lot_number AS lot_number';            -- ���b�gNo
    lv_sql_body := lv_sql_body || ',ilm.attribute1 AS make_date';                -- �����N����
    lv_sql_body := lv_sql_body || ',ilm.attribute3 AS limit_date';               -- �ܖ�����
    lv_sql_body := lv_sql_body || ',ilm.attribute2 AS lot_sign';                 -- �ŗL�L��
    lv_sql_body := lv_sql_body || ',xrcart.factory_code  AS factory_code';       -- �H��R�[�h
    lv_sql_body := lv_sql_body || ',xrcart.delivery_code AS delivery_code';      -- �z����R�[�h
    lv_sql_body := lv_sql_body || ',xvsv1.vendor_site_short_name AS factory_name';     -- ����
    lv_sql_body := lv_sql_body || ',xvsv2.vendor_site_short_name AS delivery_name';    -- ����
    lv_sql_body := lv_sql_body || ',ilm.attribute9 AS stocking_type';      -- �d���`��
    lv_sql_body := lv_sql_body || ',ilm.attribute11 AS nendo';             -- �N�x
    lv_sql_body := lv_sql_body || ',ilm.attribute10 AS reaf_devision';     -- �����敪
    lv_sql_body := lv_sql_body || ',ilm.attribute12 AS home';              -- �Y�n
    lv_sql_body := lv_sql_body || ',ilm.attribute13 AS pack_type';         -- �^�C�v
    lv_sql_body := lv_sql_body || ',ilm.attribute14 AS rank1';             -- �����N�P
    lv_sql_body := lv_sql_body || ',ilm.attribute15 AS rank2';             -- �����N�Q
    lv_sql_body := lv_sql_body || ',ilm.attribute19 AS rank3';             -- �����N�R
    lv_sql_body := lv_sql_body || ',xrcart.line_description AS line_desc'; -- ���דE�v
    lv_sql_body := lv_sql_body || ',xrcart.kobiki_rate AS kobiki_rate';    -- ������
-- 08/05/02 Y.Yamamoto Update v1.3 Start
--    lv_sql_body := lv_sql_body || ',xrcart.kousen_type AS kousen_type';    -- ���K�敪
--    lv_sql_body := lv_sql_body || ',xrcart.fukakin_type AS fukakin_type';  -- ���ۋ��敪
    lv_sql_body := lv_sql_body || ',xlvv1.meaning AS kousen_type';         -- ���K�敪����
    lv_sql_body := lv_sql_body || ',xlvv2.meaning AS fukakin_type';        -- ���ۋ��敪����
-- 08/05/02 Y.Yamamoto Update v1.3 End
    lv_sql_body := lv_sql_body || ',xrcart.kobki_converted_unit_price AS kobiki_unt_price';     -- ������P��
    lv_sql_body := lv_sql_body || ',xrcart.kousen_rate_or_unit_price AS kousen_unt_price';      -- ���K
    lv_sql_body := lv_sql_body || ',xrcart.fukakin_rate_or_unit_price AS fukakin_unt_price';    -- ���ۋ�
    lv_sql_body := lv_sql_body || ',xrcart.kobki_converted_price AS kobiki_price';  -- ��������z
    lv_sql_body := lv_sql_body || ',xrcart.kousen_price AS kousen_price';           -- �a����K���z
    lv_sql_body := lv_sql_body || ',xrcart.fukakin_price AS fukakin_price';         -- ���ۋ��z
    lv_sql_body := lv_sql_body || ',xrcart.drop_ship_type AS drop_ship_type';       -- �����敪
    ---------------------------------------------------------------------------------------
    -- FROM��
    lv_sql_body := lv_sql_body || ' FROM xxpo_rcv_and_rtn_txns xrcart'; -- ����ԕi���сi�A�h�I���j
    lv_sql_body := lv_sql_body || ',xxpo_categories_v xcv1';            -- XXPO�J�e�S�����VIEW(���i����)
    lv_sql_body := lv_sql_body || ',xxpo_categories_v xcv2';            -- XXPO�J�e�S�����VIEW(�i�ڕ���)
    lv_sql_body := lv_sql_body || ',gmi_item_categories gic1';         -- OPM�i�ڃJ�e�S������(���i����)
    lv_sql_body := lv_sql_body || ',gmi_item_categories gic2';         -- OPM�i�ڃJ�e�S������(�i�ڕ���)
    lv_sql_body := lv_sql_body || ',ic_lots_mst ilm';                  -- OPM���b�g�}�X�^
    lv_sql_body := lv_sql_body || ',xxcmn_item_mst2_v ximv';           -- OPM�i�ڏ��VIEW
    lv_sql_body := lv_sql_body || ',xxcmn_item_locations2_v xilv';     -- OPM�ۊǏꏊ���VIEW
    lv_sql_body := lv_sql_body || ',xxcmn_vendors2_v xvv1';            -- �d������VIEW(����於��)
    lv_sql_body := lv_sql_body || ',xxcmn_vendors2_v xvv2';            -- �d������VIEW(�����Җ���)
    lv_sql_body := lv_sql_body || ',xxcmn_vendor_sites2_v xvsv1';      -- �d����T�C�g���VIEW(�H�ꖼ��)
    lv_sql_body := lv_sql_body || ',xxcmn_vendor_sites2_v xvsv2';      -- �d����T�C�g���VIEW(�z���於��)
    lv_sql_body := lv_sql_body || ',per_all_people_f papf';            -- �]�ƈ��}�X�^
    lv_sql_body := lv_sql_body || ',fnd_user fu';                      -- ���O�C�����[�U�}�X�^
-- 08/05/02 Y.Yamamoto ADD v1.3 Start
    lv_sql_body := lv_sql_body || ',xxcmn_lookup_values2_v xlvv1';     -- �N�C�b�N�R�[�h(���K�敪)
    lv_sql_body := lv_sql_body || ',xxcmn_lookup_values2_v xlvv2';     -- �N�C�b�N�R�[�h(���ۋ��敪)
-- 08/05/02 Y.Yamamoto ADD v1.3 End
    ---------------------------------------------------------------------------------------
    -- WHERE��
    -- OPM���b�g�}�X�^����
    lv_sql_body := lv_sql_body || ' WHERE ilm.item_id(+) = xrcart.item_id';
    lv_sql_body := lv_sql_body || ' AND ilm.lot_id(+) = xrcart.lot_id';
    -- OPM�i�ڏ��VIEW2����
    lv_sql_body := lv_sql_body || ' AND ximv.item_id = xrcart.item_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date BETWEEN ximv.start_date_active
                                                         AND ximv.end_date_active';
    -- OPM�ۊǏꏊ���VIEW2����
    lv_sql_body := lv_sql_body || ' AND xilv.inventory_location_id = xrcart.location_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xilv.date_from';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xilv.date_to,xrcart.txns_date )';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xilv.disable_date,xrcart.txns_date)';
    -- OPM�i�ڃJ�e�S������(�i�ڋ敪)����
    lv_sql_body := lv_sql_body || ' AND xrcart.item_id         = gic2.item_id';
    lv_sql_body := lv_sql_body || ' AND xcv2.category_set_id   = gic2.category_set_id';
    lv_sql_body := lv_sql_body || ' AND xcv2.category_id       = gic2.category_id';
    lv_sql_body := lv_sql_body || ' AND xcv2.category_set_name =' || cv_sc || gc_category_name_item || cv_sc;
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xcv2.disable_date, xrcart.txns_date )';
    -- OPM�i�ڃJ�e�S������(���i�敪)����
    lv_sql_body := lv_sql_body || ' AND xrcart.item_id         = gic1.item_id';
    lv_sql_body := lv_sql_body || ' AND xcv1.category_set_id   = gic1.category_set_id';
    lv_sql_body := lv_sql_body || ' AND xcv1.category_id       = gic1.category_id';
    lv_sql_body := lv_sql_body || ' AND xcv1.category_set_name ='|| cv_sc || gc_category_name_prod || cv_sc ;
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xcv1.disable_date, xrcart.txns_date )';
    -- ����於�̎擾����
    lv_sql_body := lv_sql_body || ' AND xvv1.vendor_id = xrcart.vendor_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvv1.start_date_active';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvv1.end_date_active, xrcart.txns_date )';
    -- �����Җ��̎擾����
-- 08/05/01 Y.Yamamoto Update v1.2 Start
--    lv_sql_body := lv_sql_body || ' AND xvv2.vendor_id = xrcart.assen_vendor_id';
--    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvv2.start_date_active';
--    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvv2.end_date_active, xrcart.txns_date )';
    lv_sql_body := lv_sql_body || ' AND xvv2.vendor_id(+) = xrcart.assen_vendor_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvv2.start_date_active(+)';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvv2.end_date_active(+), xrcart.txns_date )';
-- 08/05/01 Y.Yamamoto Update v1.2 End
    -- �H�ꖼ�̎擾����
    lv_sql_body := lv_sql_body || ' AND xvsv1.vendor_id = xrcart.vendor_id';
    lv_sql_body := lv_sql_body || ' AND xvsv1.vendor_site_code = xrcart.factory_code';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvsv1.start_date_active';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvsv1.end_date_active, xrcart.txns_date )';
    -- �z���於�̎擾����
    lv_sql_body := lv_sql_body || ' AND xvsv2.vendor_id(+) = xrcart.vendor_id';
    lv_sql_body := lv_sql_body || ' AND xvsv2.vendor_site_code(+) = xrcart.delivery_code';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvsv2.start_date_active(+)';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvsv2.end_date_active(+), xrcart.txns_date)';
    -- �]�ƈ��}�X�^����
    lv_sql_body := lv_sql_body || ' AND papf.person_id    = fu.employee_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= papf.effective_start_date';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= papf.effective_end_date';
    -- ����ԕi���уA�h�I���i��
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_type IN ('|| cv_sc || gc_txns_type_rtn_order  || cv_sc ||
                                                           ','|| cv_sc || gc_txns_type_rtn_noorder|| cv_sc || ')';
    lv_sql_body := lv_sql_body || ' AND xrcart.drop_ship_type IN ('|| cv_sc || gc_drop_ship_type_normal  || cv_sc ||
                                                                ','|| cv_sc || gc_drop_ship_type_sup_req || cv_sc ||')';
    lv_sql_body := lv_sql_body || ' AND xrcart.quantity <> ' || gc_rtn_quant_0;
    -- ���[�U�}�X�^����
    lv_sql_body := lv_sql_body || ' AND xrcart.created_by = fu.user_id';
-- 08/05/02 Y.Yamamoto ADD v1.3 Start
    -- �N�C�b�N�R�[�h����
    lv_sql_body := lv_sql_body || ' AND xlvv1.lookup_type = '|| cv_sc || gc_kousen_type|| cv_sc;
    lv_sql_body := lv_sql_body || ' AND xlvv1.lookup_code = xrcart.kousen_type';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xlvv1.start_date_active';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xlvv1.end_date_active, xrcart.txns_date )';
    lv_sql_body := lv_sql_body || ' AND xlvv2.lookup_type = '|| cv_sc || gc_fukakin_type|| cv_sc;
    lv_sql_body := lv_sql_body || ' AND xlvv2.lookup_code = xrcart.fukakin_type';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xlvv2.start_date_active';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xlvv2.end_date_active, xrcart.txns_date )';
-- 08/05/02 Y.Yamamoto ADD v1.3 End
    ---------------------------------------------------------------------------------------
    -- ����ԕi���сi�A�h�I���j�̃p�����[�^�[�ɂ��i���ݏ���
    -- �ԕiNo
    IF (ir_param.rtn_number  IS NOT NULL) THEN
       lv_sql_body := lv_sql_body || ' AND xrcart.rcv_rtn_number = '
                                       || cv_sc || ir_param.rtn_number  || cv_sc;
    END IF ;
    -- �S������
    IF (ir_param.dept_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.department_code = '
                                      || cv_sc || ir_param.dept_code || cv_sc;
    END IF ;
    -- �S����
    IF (ir_param.tantousya_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number= '
                                      || cv_sc || ir_param.tantousya_code || cv_sc;
    END IF ;
    -- �����
    IF (ir_param.vendor_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.vendor_code = '
                                      || cv_sc || ir_param.vendor_code || cv_sc;
    END IF ;
    -- ������
    IF (ir_param.assen_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.assen_vendor_code = '
                                      || cv_sc || ir_param.assen_code || cv_sc;
    END IF;
    -- �[����
    IF (ir_param.location_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.location_code = '
                                      || cv_sc || ir_param.location_code || cv_sc;
    END IF ;
    -- �쐬��TO
    IF (ir_param.creation_date_from  IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.creation_date >=
                                      (FND_DATE.STRING_TO_DATE('
                                      || cv_sc || ir_param.creation_date_from || cv_sc
                                      ||  ','
                                      || cv_sc ||gc_creation_date_format || cv_sc || '))';
    END IF ;
    -- �쐬��TO
    IF (ir_param.creation_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.creation_date <=
                                      (FND_DATE.STRING_TO_DATE('
                                      || cv_sc || ir_param.creation_date_to || cv_sc
                                      ||  ','
                                      || cv_sc ||gc_creation_date_format || cv_sc || '))';
    END IF ;
    -- �ԕi��FROM
    IF (ir_param.rtn_date_from IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >=
                                      (FND_DATE.STRING_TO_DATE('
                                      || cv_sc || ir_param.rtn_date_from || cv_sc
                                      ||  ','
                                      || cv_sc || gc_rtn_date_format || cv_sc ||'))';
    END IF ;
    -- �ԕi��TO
    IF (ir_param.rtn_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <=
                                     FND_DATE.STRING_TO_DATE('
                                     || cv_sc || ir_param.rtn_date_to|| cv_sc
                                     ||  ','
                                     || cv_sc ||gc_rtn_date_format || cv_sc || ')';
    END IF ;
     -- �i�ڃJ�e�S��(���i�敪)�̍i���ݏ����̒ǉ�
    IF (ir_param.prod_div IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xcv1.category_code = '|| cv_sc || ir_param.prod_div || cv_sc;
    END IF ;
    -- �i�ڃJ�e�S��(�i�ڋ敪)�̍i���ݏ����̒ǉ�
    IF (ir_param.item_div IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xcv2.category_code = '|| cv_sc || ir_param.item_div || cv_sc;
    END IF ;
    -- �\�[�g��
    lv_sql_body := lv_sql_body || ' ORDER BY rtn_number';          -- ����ԕi�ԍ�
    lv_sql_body := lv_sql_body || ' ,vendor_code';                 -- �����R�[�h
    lv_sql_body := lv_sql_body || ' ,assen_code';                  -- �����҃R�[�h
    lv_sql_body := lv_sql_body || ' ,rtn_date';                    -- �����
    lv_sql_body := lv_sql_body || ' ,location_code';               -- ���o�ɐ�R�[�h
    lv_sql_body := lv_sql_body || ' ,xrcart.rcv_rtn_line_number';  -- ���הԍ�
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec ;
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
  END prc_get_report_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(B-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iox_xml_data      IN OUT NOCOPY XML_DATA
     ,it_param_data     IN  tab_data_type_dtl -- 02.�擾���R�[�h�Q
     ,ov_errbuf         OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode        OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg         OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E��O���� ***
    dtldata_notfound_expt      EXCEPTION ;     -- �Ώۃf�[�^0����O
    -- *** ���[�J���ϐ� ***
    lv_rtn_price     NUMBER := 0 ;  -- �ԕi���z�Z7�o�p
    lv_sum_rtn_quant NUMBER := 0 ;  -- ���v�ԕi����������
    lv_sum_price     NUMBER := 0 ;  -- ���v���z��������
    lv_dtl_cnt       NUMBER := 0 ;  -- �ԕiNo���̖��׌���
    lv_cnt           NUMBER := 1 ;  -- �J�E���^
    -- �������i�[�ϐ�
    lv_dept_postal_code VARCHAR2(8)  ;  -- �X�֔ԍ�
    lv_dept_address     VARCHAR2(60) ;  -- �Z��
    lv_dept_tel_num     VARCHAR2(15) ;  -- �d�b�ԍ�
    lv_dept_fax_num     VARCHAR2(15) ;  -- FAX�ԍ�
    lv_dept_formal_name VARCHAR2(60) ;  -- ������
    -- �P������ŕ����i�[
    lv_tax_info         VARCHAR2(150) ;
    -- ���׌����i�[�p
    lt_dtl_cnt_map      dtl_cnt_map ;
--
  BEGIN
--
    -- ----------------------------------------------------
    -- ��������
    -- ----------------------------------------------------
    -- �P������ŕ����擾
    lv_tax_info := xxcmn_common_pkg.get_msg(gc_application,gc_note_code_tax_info) ;
    -- ���׌����擾
    lt_dtl_cnt_map := func_dtl_cnt(it_param_data) ;
--
    -- ----------------------------------------------------
    -- �J�n�^�O
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �f�[�^�J�n�^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'datainfo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �ԕiL�f�J�n�^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_rtn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    -- �f�[�^���擾�̏ꍇ
    IF (it_param_data.count = 0) THEN
      ------------------------------
      -- �ԕi�f�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_rtn' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      -- ���[�h�c
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value :=gc_report_id ;
      ------------------------------
      -- ���׃y�[�WL�f�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_class_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- ���׃y�[�W�f�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl_class' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
       -- �f�[�^�Ȃ����b�Z�[�W
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'msg' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application
                                                 ,gc_err_code_data_0 ) ;
      ------------------------------
      -- ���׃y�[�W�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl_class' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- ���׃y�[�WL�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_class_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �ԕi�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_rtn' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �ԕiL�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_rtn_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �f�[�^�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/datainfo' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
      RAISE dtldata_notfound_expt ;
--
    ELSE
      <<param_data_loop>>
      FOR i IN 1..it_param_data.count LOOP
        -- ----------------------------------------------------
        -- �Z�o����
        -- ----------------------------------------------------
        -- �ԕi���z�v�Z
        -- ������P���ݒ�L�̏ꍇ
-- 08/05/02 Y.Yamamoto Update v1.4 Start
        IF (it_param_data(i).kobiki_unt_price IS NOT NULL ) THEN
--          lv_rtn_price := TRUNC((it_param_data(i).kobiki_unt_price * it_param_data(i).rtn_quant)
--                            -it_param_data(i).kousen_price -it_param_data(i).fukakin_price) ;
          lv_rtn_price := TRUNC((it_param_data(i).kobiki_unt_price * it_param_data(i).quantity)
                            -it_param_data(i).kousen_price -it_param_data(i).fukakin_price) ;
         -- ������P���ݒ薳�̏ꍇ
        ELSE
--          lv_rtn_price := TRUNC((it_param_data(i).rtn_unit_price   * it_param_data(i).rtn_quant)
--                            -it_param_data(i).kousen_price -it_param_data(i).fukakin_price) ;
          lv_rtn_price := TRUNC((it_param_data(i).rtn_unit_price   * it_param_data(i).quantity)
                            -it_param_data(i).kousen_price -it_param_data(i).fukakin_price) ;
        END IF;
-- 08/05/02 Y.Yamamoto Update v1.4 End
        -- ���v�ԕi����������
        lv_sum_rtn_quant := lv_sum_rtn_quant + it_param_data(i).rtn_quant ;
        -- ���v���z��������
        lv_sum_price := lv_sum_price + lv_rtn_price ;
        -- �Z�N�V�����J�n
        IF (lv_cnt = 1 )THEN
          -- �Z�N�V�������ւ̏o�͌������擾
          lv_dtl_cnt := lt_dtl_cnt_map(it_param_data(i).rtn_number);
          -----------------------------------------
          -- �Z�N�V������������
          -----------------------------------------
          ------------------------------
          -- �ԕi�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_rtn' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- ���[�h�c
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value :=gc_report_id ;
          -- ���s��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value :=TO_CHAR( SYSDATE, gc_creation_date_format ) ;
          -- �ԕi�ԍ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_num' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value :=it_param_data(i).rtn_number ;
          -- �����CD
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_cd' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).vendor_code ;
          -- ����於
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).verndor_name ;
          -- ������CD
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'assen_cd' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).assen_code ;
          -- �����Ж�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'assen_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).assen_name ;
          -- �o�Ɍ�CD
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_id' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).location_code ;
          -- �o�Ɍ���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).location_name ;
          -- �x������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_cond' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_term_of_payment( it_param_data(i).vendor_id, '') ;
          -- �ԕi��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_param_data(i).rtn_date,gc_rtn_date_format) ;
          -- �E�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_desc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).header_desc ;
          --�������擾
          xxcmn_common_pkg.get_dept_info(
                        iv_dept_cd           => it_param_data(i).dept_code   -- �����R�[�h(���Ə�CD)
                        ,id_appl_date        => it_param_data(i).rtn_date    -- �ԕi��(���)
                        ,ov_postal_code      => lv_dept_postal_code          -- �X�֔ԍ�
                        ,ov_address          => lv_dept_address              -- �Z��
                        ,ov_tel_num          => lv_dept_tel_num              -- �d�b�ԍ�
                        ,ov_fax_num          => lv_dept_fax_num              -- FAX�ԍ�
                        ,ov_dept_formal_name => lv_dept_formal_name          -- ����������
                        ,ov_errbuf           => lv_errbuf                    -- �G���[�E���b�Z�[�W
                        ,ov_retcode          => lv_retcode                   -- ���^�[���E�R�[�h
                        ,ov_errmsg           => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
                        );
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt ;
          END IF ;
--
          -- ���t���Z��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_addr' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_address ;
          -- ���t���d�b�ԍ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_tel' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_tel_num ;
          -- ���t��FAX�ԍ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_fax' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_fax_num ;
          -- ���t��������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_formal_name;
          ------------------------------
          -- ���׃y�[�WL�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_class_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        END IF ;
        -- ���ׂ̃y�[�W�擪�f�[�^�̏ꍇ
        IF (MOD(lv_cnt,6)=1) THEN
          ------------------------------
          -- ���׃y�[�W�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���׃��X�g�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        END IF ;
        ------------------------------
        -- ���ׂf�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- �i�ځi�i�ڃR�[�h�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_cd' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).item_code ;
        -- �t��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_cd' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).futai_code ;
        -- �i�ځi�i�ږ��́j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).item_name ;
        -- �݌ɓ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'stock_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).stock_quant ;
        -- �ԕi��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).rtn_quant ;
        -- �P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_uom' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).rtn_uom ;
        -- �P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).rtn_unit_price ;
        -- �ԕi���z
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_rtn_price ;
        -- ���b�gNo.
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).lot_number ;
        -- ������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'make_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).make_date ;
        -- �ܖ�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'limit_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).limit_date ;
        -- �ŗL�L��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sign' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).lot_sign ;
        -- �����敪���R�̏ꍇ�͔z������w��
        IF (it_param_data(i).drop_ship_type = 3) THEN
          -- �z����i�z����R�[�h�j
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'fac_del_cd' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).delivery_code ;
          -- �z����i�z���於�́j
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'fac_del_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).delivery_name ;
        -- ����ȊO�̏ꍇ�͍H����w��
        ELSE
          -- �H��i�H��R�[�h�j
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'fac_del_cd' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).factory_code ;
          -- �H��i�H�ꖼ�́j
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'fac_del_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).factory_name ;
        END IF ;
        -- �d���`��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'stocking_type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).stocking_type ;
        -- �N�x
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'year' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).nendo ;
        -- �����敪
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'reaf_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).reaf_devision ;
        -- �Y�n
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'home' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).home ;
        -- �^�C�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).pack_type ;
        -- �����N
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rank' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := func_rank_edit(it_param_data(i).rank1
                                                     ,it_param_data(i).rank2
                                                     ,it_param_data(i).rank3) ;
        -- �E�v�i���דE�v�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_desc' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).line_desc ;
        -- ���^�敪�i�����j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kobiki_rate' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kobiki_rate ;
        -- ���^�敪�i���K�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kousen_type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kousen_type ;
        -- ���^�敪�i���ۋ��j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fukakin_type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).fukakin_type ;
        -- �P���^�|���i�����j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kobiki_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kobiki_unt_price ;
        -- �P���^�|���i���K�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kousen_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kousen_unt_price ;
        -- �P���^�|���i���ۋ��j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fukakin_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).fukakin_unt_price ;
        -- ���z�i�����j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kobiki_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kobiki_price ;
        -- ���z�i���K�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kosen_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kousen_price ;
        -- ���z�i���ۋ��j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fukakin_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).fukakin_price ;
        ------------------------------
        -- ���ׂf�I���^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- �U���ז��ɃO���[�v��
        -- �Z�N�V�����ŏI���R�[�h�̏ꍇ
        IF ((MOD(lv_cnt,6)=0) OR (lv_cnt = lv_dtl_cnt)) THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �Z�N�V�����ŏI�y�[�W�̏ꍇ
          IF (CEIL(lv_cnt/6) = CEIL(lv_dtl_cnt/6)) THEN
            -- ���v�ԕi�����o��
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_rtn_quant' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
            gt_xml_data_table(gl_xml_idx).tag_value := lv_sum_rtn_quant ;
            -- ���v���z���o��
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_price' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
            gt_xml_data_table(gl_xml_idx).tag_value := lv_sum_price ;
          ELSE
            -- ���v�ԕi����NULL���o��
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_rtn_quant' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
            gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
            -- ���v���z��NULL���o��
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_price' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
            gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
          END IF ;
          -- �P������ŕ����o��
          -- �P�s��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_info_01' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(lv_tax_info, 0 , 48) ;
          -- �Q�s��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_info_02' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(lv_tax_info, 49 , 150) ;
          ------------------------------
          -- ���׃y�[�W�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        END IF ;
        -- �Z�N�V�����i�ԕiNo���j���ŏI���R�[�h���O���[�v�^�O�����B
        IF (lv_cnt = lv_dtl_cnt) THEN
         ------------------------------
         -- ���׃y�[�WL�f�I���^�O
         ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_class_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �ԕi�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_rtn' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          gt_xml_data_table(gl_xml_idx).tag_value :=gc_report_id ;
          -- �J�E���^������
          lv_cnt := 1;
          -- ���v�ԕi��������
          lv_sum_rtn_quant := 0;
          -- ���v���z��������
          lv_sum_price := 0 ;
        ELSE
          -- �J�E���^�C���N�������g
          lv_cnt    := lv_cnt + 1 ;
        END IF ;
      END LOOP param_data_loop ;
    END IF ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- �ԕiL�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_rtn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �f�[�^�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/datainfo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
  EXCEPTION
--
  -- *** �Ώۃf�[�^0����O�n���h�� ***
  WHEN dtldata_notfound_expt THEN
    ov_retcode := gv_status_warn ;
    ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                           ,gc_err_code_no_data
                                           ,gc_msg_table
                                           ,gc_table_name ) ;
    FND_FILE.PUT_LINE(FND_FILE.LOG,ov_errmsg) ;
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
     iv_rtn_number          IN     VARCHAR2     -- 01 : �ԕi�ԍ�
     ,iv_dept_code          IN     VARCHAR2     -- 02 : �S������
     ,iv_tantousya_code     IN     VARCHAR2     -- 03 : �S����
     ,iv_creation_date_from IN     VARCHAR2     -- 04 : �쐬����FROM
     ,iv_creation_date_to   IN     VARCHAR2     -- 05 : �쐬����TO
     ,iv_vendor_code        IN     VARCHAR2     -- 06 : �����
     ,iv_assen_code         IN     VARCHAR2     -- 07 : ������
     ,iv_location_code      IN     VARCHAR2     -- 08 : �[����
     ,iv_rtn_date_from      IN     VARCHAR2     -- 09 : �ԕi��FROM
     ,iv_rtn_date_to        IN     VARCHAR2     -- 10 : �ԕi��TO
     ,iv_prod_div           IN     VARCHAR2     -- 11 : ���i�敪
     ,iv_item_div           IN     VARCHAR2     -- 12 : �i�ڋ敪
     ,ov_errbuf     OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    lr_param rec_param_data ;
    lr_data_rec tab_data_type_dtl ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���̓p�����[�^�i�[
    -- ===============================================
     lr_param.rtn_number         := iv_rtn_number ;         -- �ԕi�ԍ�
     lr_param.dept_code          := iv_dept_code ;          -- �S������
     lr_param.tantousya_code     := iv_tantousya_code ;     -- �S����
     lr_param.creation_date_from := iv_creation_date_from ; -- �쐬����FROM
     lr_param.creation_date_to   := iv_creation_date_to ;   -- �쐬����TO
     lr_param.vendor_code        := iv_vendor_code ;        -- �����
     lr_param.assen_code         := iv_assen_code ;         -- ������
     lr_param.location_code      := iv_location_code ;      -- �[����
     lr_param.rtn_date_from      := iv_rtn_date_from ;      -- �ԕi��FROM
     lr_param.rtn_date_to        := iv_rtn_date_to ;        -- �ԕi��TO
     lr_param.prod_div           := iv_prod_div ;           -- ���i�敪
     lr_param.item_div           := iv_item_div ;           -- �i�ڋ敪
    -- ===============================================
    -- ���̓p�����[�^�`�F�b�N B-1
    -- ===============================================
    prc_check_param_info(
      lr_param,          -- ���̓p�����[�^�Q
      lv_errbuf,         -- �G���[�E���b�Z�[�W
      lv_retcode,        -- ���^�[���E�R�[�h
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ===============================================
    -- �f�[�^���o/�f�[�^���HB-3,4
    -- ===============================================
    prc_get_report_data(
      lr_param                      -- 01.���̓p�����[�^�Q
     ,ot_data_rec  => lr_data_rec   -- 02.�擾���R�[�h�Q
     ,ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ===============================================
    -- �f�[�^�o�� B-5
    -- ===============================================
    prc_create_xml_data(
     xml_data_table
     ,lr_data_rec  -- �擾���R�[�h�Q
     ,lv_errbuf    -- �G���[�E���b�Z�[�W
     ,lv_retcode   -- ���^�[���E�R�[�h
     ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    --XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- �ҏW�����f�[�^���^�O�ɕϊ�
      lv_xml_string := convert_into_xml
                       (
                           iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                          ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                          ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                        ) ;
      -- �w�l�k�^�O�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_loop ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg  ;
    ov_errbuf  := lv_errbuf  ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main    (
      errbuf                OUT    VARCHAR2 -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2 -- �G���[�R�[�h
     ,iv_rtn_number         IN     VARCHAR2 -- 01 : �ԕi�ԍ�
     ,iv_dept_code          IN     VARCHAR2 -- 02 : �S������
     ,iv_tantousya_code     IN     VARCHAR2 -- 03 : �S����
     ,iv_creation_date_from IN     VARCHAR2 -- 04 : �쐬����FROM
     ,iv_creation_date_to   IN     VARCHAR2 -- 05 : �쐬����TO
     ,iv_vendor_code        IN     VARCHAR2 -- 06 : �����
     ,iv_assen_code         IN     VARCHAR2 -- 07 : ������
     ,iv_location_code      IN     VARCHAR2 -- 08 : �[����
     ,iv_rtn_date_from      IN     VARCHAR2 -- 09 : �ԕi��FROM
     ,iv_rtn_date_to        IN     VARCHAR2 -- 10 : �ԕi��TO
     ,iv_prod_div           IN     VARCHAR2 -- 11 : ���i�敪
     ,iv_item_div           IN     VARCHAR2 -- 12 : �i�ڋ敪
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxpo330001c.main';  -- �v���O������
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
     iv_rtn_number            -- 01 : �ԕi�ԍ�
     ,iv_dept_code            -- 02 : �S������
     ,iv_tantousya_code       -- 03 : �S����
     ,iv_creation_date_from   -- 04 : �쐬����FROM
     ,iv_creation_date_to     -- 05 : �쐬����TO
     ,iv_vendor_code          -- 06 : �����
     ,iv_assen_code           -- 07 : ������
     ,iv_location_code        -- 08 : �[����
     ,iv_rtn_date_from        -- 09 : �ԕi��FROM
     ,iv_rtn_date_to          -- 10 : �ԕi��TO
     ,iv_prod_div             -- 11 : ���i�敪
     ,iv_item_div             -- 12 : �i�ڋ敪
     ,lv_errbuf               -- �G���[�E���b�Z�[�W
     ,lv_retcode              -- ���^�[���E�R�[�h
     ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo330001c;
/