/*============================================================================
* ファイル名 : XxpoProvisionInstMakeLineVOImpl
* 概要説明   : 支給指示作成コピー明細ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-06-09 1.0  二瓶大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 支給指示作成コピー明細ビューオブジェクトクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvCopyLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvCopyLineVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param exeType       - 起動タイプ
   * @param orderHeaderId - 受注ヘッダアドオンID
   ****************************************************************************/
  public void initQuery(String exeType, Number orderHeaderId)
  {
    // 初期化
    setWhereClauseParams(null);
    int i = 0;
    setWhereClauseParam(i++, exeType);
    setWhereClauseParam(i++, orderHeaderId);
    // 検索実行
    executeQuery();
  }
}