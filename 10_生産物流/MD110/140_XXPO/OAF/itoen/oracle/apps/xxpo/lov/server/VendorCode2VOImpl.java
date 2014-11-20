/*============================================================================
* �t�@�C���� : VendorCode2VOImpl
* �T�v����   : �����LOV�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-05-21 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.lov.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �����LOV�r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE�ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class VendorCode2VOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public VendorCode2VOImpl()
  {
  }

  /***************************************************************************
   * �������������s�����\�b�h�ł��B
   * @param vendorCode �����
   ***************************************************************************
   */
  public void initQuery(String vendorCode)
  {
    // WHERE��Ɏ�����ǉ�
    setWhereClause(null);
    setWhereClause(" vendor_code = :0");
    setWhereClauseParam(0, vendorCode);

    // �������s
    executeQuery();
  }
}