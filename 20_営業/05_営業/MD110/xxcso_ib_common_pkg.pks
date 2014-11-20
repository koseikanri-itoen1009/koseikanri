CREATE OR REPLACE PACKAGE xxcso_ib_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_IB_COMMON_PKG(SPEC)
 * Description      : ���ʊ֐��iXXCSOIB���ʁj
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  get_ib_ext_attribs     F     V     �����}�X�^�ǉ������l�擾�֐�
 *  get_ib_ext_attribs2    F     V     �����}�X�^�ǉ������l�擾�֐��Q
 *  get_ib_ext_attribs_id  F     V     �����}�X�^�ǉ�����ID�擾�֐�
 *  get_ib_ext_attrib_info2 F    R     �����}�X�^�ǉ������l���擾�֐��Q
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   N.Yabuki         �V�K�쐬
 *  2009/01/16    1.1   N.Yabuki         �����}�X�^�ǉ������l���擾�֐��Q��ǉ�
 *
 *****************************************************************************************/
--
  -- �����}�X�^�ǉ������l�擾�֐�
  FUNCTION get_ib_ext_attribs(
    in_instance_id       IN  NUMBER,   -- �C���X�^���XID
    iv_attribute_code    IN  VARCHAR2  -- ������`
  )
  RETURN VARCHAR2;
--
  -- �����}�X�^�ǉ������l�擾�֐��Q
  FUNCTION get_ib_ext_attribs2(
    in_instance_id       IN  NUMBER,   -- �C���X�^���XID
    iv_attribute_code    IN  VARCHAR2  -- ������`
  )
  RETURN VARCHAR2;
--
  -- �����}�X�^�ǉ�����ID�擾�֐�
  FUNCTION get_ib_ext_attribs_id(
    iv_attribute_code    IN  VARCHAR2,  -- �����R�[�h
    id_standard_date     IN  DATE       -- ���
  )
  RETURN NUMBER;
--
  -- �����}�X�^�ǉ������l���擾�֐��Q
  FUNCTION get_ib_ext_attrib_info2(
    in_instance_id       IN  NUMBER,   -- �C���X�^���XID
    iv_attribute_code    IN  VARCHAR2  -- ������`
  )
  RETURN CSI_IEA_VALUES%ROWTYPE;
--
END xxcso_ib_common_pkg;
/
