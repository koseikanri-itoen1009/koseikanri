/*============================================================================
* �t�@�C���� : XxcsoReferenceQuotationPriceVOImpl
* �T�v����   : ���l�Z�o�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-14 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * ���l�̎Z�o�����邽�߂̃r���[�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoReferenceQuotationPriceVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoReferenceQuotationPriceVOImpl()
  {
  }
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param InventoryItemId         �i��ID
   * @param AccountNumber           �ڋq�R�[�h
   *****************************************************************************
   */
  public void initQuery(
    String InventoryItemId,
    String AccountNumber
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, InventoryItemId);
    setWhereClauseParam(index++, AccountNumber);

    executeQuery();
  }
}