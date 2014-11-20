/*============================================================================
* �t�@�C���� : XxcsoQuoteSearch1VOImpl
* �T�v����   : ���ό����r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS���g    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ���ό����̔ł����͂��ꂽ�ꍇ�̃r���[�N���X�ł��B
 * @author  SCS���g
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearch1VOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearch1VOImpl()
  {
  }
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param quoteType         ���ώ��
   * @param quoteNumber       ���ϔԍ�
   * @param quoteResionNumber ��
   *****************************************************************************
   */
  public void initQuery(
    String quoteType,
    String quoteNumber,
    String quoteResionNumber
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, quoteType);
    setWhereClauseParam(index++, quoteNumber);
    setWhereClauseParam(index++, quoteResionNumber);

    executeQuery();
  }
}