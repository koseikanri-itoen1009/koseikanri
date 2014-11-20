/*============================================================================
* �t�@�C���� : XxwshResultLotVOImpl
* �T�v����   : ���o�׎��у��b�g���͉��(���у��b�g�ڍ�)�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.server;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * ���o�׎��у��b�g���͉��(���у��b�g�ڍ�)�r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxwshResultLotVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshResultLotVOImpl()
  {
  }

    
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param orderLineId      - �󒍖��׃A�h�I��ID
   * @param documentTypeCode - �����^�C�v
   * @param recordTypeCode   - ���R�[�h�^�C�v
   * @param itemClassCode    - �i�ڋ敪
   * @param numOfCases       - �P�[�X����
   ****************************************************************************/
  public void initQuery(
    String      orderLineId,
    String      documentTypeCode,
    String      recordTypeCode,
    String      itemClassCode,
    Number      numOfCases
    )
  {
    // ������
    setWhereClauseParams(null);
          
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, numOfCases);
    setWhereClauseParam(1, orderLineId);
    setWhereClauseParam(2, documentTypeCode);
    setWhereClauseParam(3, recordTypeCode);

    // �i�ڋ敪��5�F���i�̏ꍇ�A�����N�������ܖ��������ŗL�L���̏���
    if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
    {
      setOrderByClause("manufactured_date,use_by_date,koyu_code");   
    // ����ȊO�̓��b�gNo�̏���
    } else
    {
      setOrderByClause("TO_NUMBER(lot_no)");      
    }

    // SELECT�����s
    executeQuery();
  }
}