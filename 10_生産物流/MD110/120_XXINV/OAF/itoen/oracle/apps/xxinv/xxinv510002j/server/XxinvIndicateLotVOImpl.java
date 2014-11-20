/*============================================================================
* �t�@�C���� : XxinvIndicateLotVOImpl
* �T�v����   : �o�ɁE���Ƀ��b�g���׉��(�w�����b�g�ڍ�)�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-11 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510002j.server;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �o�ɁE���Ƀ��b�g���׉��(�w�����b�g�ڍ�)�r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */

public class XxinvIndicateLotVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvIndicateLotVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param movLineId      - �ړ�����ID
   * @param productFlg     - ���i���ʋ敪
   * @param lotCtl         - ���b�g�Ǘ��敪
   * @param numOfCases     - �P�[�X����
   ****************************************************************************/
  public void initQuery(
    String      movLineId,
    String      productFlg,
    String      lotCtl,
    Number      numOfCases
    )
  {
    // ������
    setWhereClauseParams(null);
          
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, lotCtl);
    setWhereClauseParam(1, numOfCases);
    setWhereClauseParam(2, movLineId);

    // ���i���ʋ敪��1�F���i�̏ꍇ�A�����N�������ŗL�L���̏���
    if (XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg))
    {
      setOrderByClause("manufactured_date,koyu_code");   
    // ����ȊO�̓��b�gNo�̏���
    } else
    {
      setOrderByClause("TO_NUMBER(lot_no)");      
    } 
    
    // SELECT�����s
    executeQuery();
  }
}