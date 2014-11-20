CREATE OR REPLACE PACKAGE BODY gmi_user_autolot AS
/* $Header: gmiltstb.pls 115.0 2003/03/18 15:02:00 jdiiorio noship $ */

PROCEDURE user_lot_number(p_item_id                   IN   NUMBER,
                        p_in_lot_no                   IN   VARCHAR2,
                        p_orgn_code                   IN   VARCHAR2,
                        p_doc_id                      IN   NUMBER,
                        p_line_id                     IN   NUMBER,
                        p_doc_type                    IN   VARCHAR2,
                        p_u_out_lot_no                OUT  NOCOPY VARCHAR2,
                        p_u_sublot_no                 OUT  NOCOPY VARCHAR2,
                        p_u_return_status             OUT  NOCOPY NUMBER)


IS

BEGIN

   p_u_return_status := 0;
   p_u_out_lot_no := NULL;
   p_u_sublot_no := NULL;

  -- 2007/12/12 1.0 ORACLE �ؗS�� ���b�g�ԍ��̔� Add Start
  -- ���b�g�̔Ԕԍ����V�[�P���X���擾
  SELECT TO_CHAR(xxinv_stc_lotno_s1.NEXTVAL)
  INTO p_u_out_lot_no
  FROM dual;
--
EXCEPTION
  WHEN OTHERS THEN
  -- �G���[�̏ꍇ�̓X�e�[�^�X��fatal(-99)��ԋp
    p_u_return_status := -99;
  -- 2007/12/12 1.0 ORACLE �ؗS�� ���b�g�ԍ��̔� Add ENd
END user_lot_number;
END;
/
