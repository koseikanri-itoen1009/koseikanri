/*============================================================================
* �t�@�C���� : XxcsoQuoteHeaderSalesSumVOImpl
* �T�v����   : ���σw�b�_�̔��Q�Ɨp�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�y���  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * ���σw�b�_�̔̔������Q�Ƃ��邽�߂̃r���[�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteHeaderSalesSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteHeaderSalesSumVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param quoteHeaderId ���σw�b�_�[ID
   *****************************************************************************
   */
  public void initQuery(
    Number quoteHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, quoteHeaderId);

    executeQuery();
  }
}