/*============================================================================
* ファイル名 : XxcsoContractOtherCustFullVOImpl
* 概要説明   : 契約先以外情報取得ビューオブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2015-02-021.0  SCSK山下翔太 新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 契約先以外情報取得ビューオブジェクトクラス
 * @author  SCSK山下翔太
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractOtherCustFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractOtherCustFullVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param contractOtherCustsId 契約先以外ID
   *****************************************************************************
   */
  public void initQuery(
    Number contractOtherCustsId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, contractOtherCustsId);

    executeQuery();
  }
}