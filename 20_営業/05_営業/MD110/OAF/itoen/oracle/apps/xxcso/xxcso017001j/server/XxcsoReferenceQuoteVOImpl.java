/*============================================================================
* �t�@�C���� : XxcsoReferenceQuoteVOImpl
* �T�v����   : �����≮�����p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS�y���  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/*******************************************************************************
 * �����≮�őΏۖ��ׂ��g�p���Ă��邩�������邽�߂̃r���[�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoReferenceQuoteVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoReferenceQuoteVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param QuoteHeaderId       ���σw�b�_ID
   *****************************************************************************
   */
  public void initQuery(
    Number quoteHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, quoteHeaderId);

    executeQuery();
  }


}