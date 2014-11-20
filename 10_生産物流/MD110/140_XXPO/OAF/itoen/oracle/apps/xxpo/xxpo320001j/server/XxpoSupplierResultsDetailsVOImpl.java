/*============================================================================
* �t�@�C���� : XxpoSupplierResultsDetailsVOImpl
* �T�v����   : �d����o�׎���:�o�^���׃r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-12 1.0  �g������   �@�V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * �o�^���׃r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsDetailsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsDetailsVOImpl()
  {
  }
  
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchId �����p�����[�^ID
   ****************************************************************************/
  public void initQuery(
    String  searchId         // �����p�����[�^ID
  )
  {

    // ������
    setWhereClauseParams(null);

    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    //setWhereClauseParam(0, searchId);
    setWhereClause(" po_header_id IN (" + searchId + ") ");

    // SELECT�����s
    executeQuery();
  }
}
